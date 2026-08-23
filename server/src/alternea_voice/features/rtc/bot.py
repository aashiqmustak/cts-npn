import inspect
import json
import logging
import os
import pathlib
import sys
import tomllib
from typing import Any

import aiohttp
from dotenv import load_dotenv
from pipecat.adapters.schemas.function_schema import FunctionSchema
from pipecat.audio.turn.smart_turn.local_smart_turn_v3 import (
    LocalSmartTurnAnalyzerV3,
)
from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.audio.vad.vad_analyzer import VADParams
from pipecat.frames.frames import (
    Frame,
    LLMMessagesAppendFrame,
    TranscriptionFrame,
    TTSSpeakFrame,
)
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.runner import PipelineRunner
from pipecat.pipeline.task import PipelineParams, PipelineTask
from pipecat.processors.aggregators.llm_context import LLMContext
from pipecat.processors.aggregators.llm_response_universal import (
    LLMContextAggregatorPair,
    LLMUserAggregatorParams,
)
from pipecat.processors.frame_processor import (
    FrameDirection,
    FrameProcessor,
)
from pipecat.runner.types import RunnerArguments
from pipecat.runner.utils import create_transport
from pipecat.services.groq.llm import GroqLLMService
from pipecat.services.sarvam.stt import SarvamSTTService
from pipecat.services.sarvam.tts import SarvamTTSService
from pipecat.transports.base_transport import (
    BaseTransport,
    TransportParams,
)
from pipecat.turns.user_stop import TurnAnalyzerUserTurnStopStrategy
from pipecat.turns.user_turn_strategies import UserTurnStrategies

# Import backend Multi-Agent Orchestrator
_current = pathlib.Path(__file__).resolve().parent
_server_src = _current.parents[2]
if str(_server_src) not in sys.path:
    sys.path.insert(0, str(_server_src))

from agents.ranking_agent.app.schemas import PatientContext
from orchestrator.schemas import PrescriptionEvaluationRequest
from orchestrator.workflow import MultiAgentOrchestrator

logger = logging.getLogger(__name__)


def load_project_env_and_metadata() -> dict[str, Any]:
    current_dir = pathlib.Path(__file__).resolve().parent
    pyproject_path = None
    for parent in [current_dir, *list(current_dir.parents)]:
        if (parent / "pyproject.toml").exists():
            pyproject_path = parent / "pyproject.toml"
            break

    env_path = None
    for parent in [current_dir, *list(current_dir.parents)]:
        if (parent / ".env").exists():
            env_path = parent / ".env"
            break

    if env_path:
        load_dotenv(dotenv_path=env_path)
    else:
        load_dotenv()

    metadata: dict[str, Any] = {}
    if pyproject_path:
        try:
            with open(pyproject_path, "rb") as f:
                data = tomllib.load(f)
                metadata = data.get("project", {})
        except (OSError, tomllib.TOMLDecodeError) as e:
            logger.warning("Could not read pyproject.toml: %s", e)

    return metadata


project_metadata = load_project_env_and_metadata()
import json
from pipecat.frames.frames import (
    Frame,
    LLMMessagesAppendFrame,
    OutputTransportMessageUrgentFrame,
    TextFrame,
    TranscriptionFrame,
    TTSSpeakFrame,
)

backend_orchestrator = MultiAgentOrchestrator()


class TranscriptionLogger(FrameProcessor):
    async def process_frame(
        self,
        frame: Frame,
        direction: FrameDirection,
    ):
        await super().process_frame(frame, direction)

        if isinstance(frame, TranscriptionFrame) and frame.text and frame.text.strip():
            user_text = frame.text.strip()
            print(f"\n[STT Heard User]: {user_text}\n")
            await self.push_frame(
                OutputTransportMessageUrgentFrame(
                    message=json.dumps(
                        {
                            "type": "transcript",
                            "sender": "user",
                            "text": user_text,
                        }
                    )
                )
            )

        await self.push_frame(frame, direction)


class AssistantTranscriptLogger(FrameProcessor):
    async def process_frame(
        self,
        frame: Frame,
        direction: FrameDirection,
    ):
        await super().process_frame(frame, direction)

        if isinstance(frame, TTSSpeakFrame) and frame.text and frame.text.strip():
            bot_text = frame.text.strip()
            print(f"\n[Alternea Spoken Voice + Text]: {bot_text}\n")
            await self.push_frame(
                OutputTransportMessageUrgentFrame(
                    message=json.dumps(
                        {
                            "type": "transcript",
                            "sender": "agent",
                            "text": bot_text,
                        }
                    )
                )
            )

        await self.push_frame(frame, direction)


def create_vad():
    return SileroVADAnalyzer(params=VADParams(stop_secs=0.5))


transport_params = {
    # Browser WebRTC
    "webrtc": lambda: TransportParams(
        audio_in_enabled=True,
        audio_out_enabled=True,
        vad_analyzer=create_vad(),
    ),
}


async def _safe_execute_callback(result_callback: Any, payload: dict[str, Any]) -> None:
    """Safely invoke async or sync result callback."""
    if not result_callback:
        return
    try:
        if inspect.iscoroutinefunction(result_callback):
            await result_callback(payload)
        elif callable(result_callback):
            result_callback(payload)
    except (RuntimeError, ValueError, TypeError, OSError) as exc:
        logger.error("Error executing result callback: %s", exc)


# =====================================================================
# AGENT BACKEND TOOL HANDLER (Called by LLM)
# =====================================================================
async def handle_evaluate_prescription(*args_list, **kwargs):
    """Executes the 7-stage Clinical Agent pipeline and returns the Top-1 drug."""
    args: dict[str, Any] = {}
    result_callback = None

    # Handle Pipecat 1.7+ FunctionCallParams single object or positional args
    if len(args_list) == 1 and hasattr(args_list[0], "arguments"):
        params = args_list[0]
        raw_args = params.arguments
        result_callback = getattr(params, "result_callback", None)
        if isinstance(raw_args, str):
            try:
                args = json.loads(raw_args)
            except (json.JSONDecodeError, ValueError):
                args = {}
        elif isinstance(raw_args, dict):
            args = raw_args
    elif len(args_list) >= 6:
        _function_name, _tool_call_id, raw_args, _llm, _context, result_callback = (
            args_list[:6]
        )
        if isinstance(raw_args, str):
            try:
                args = json.loads(raw_args)
            except (json.JSONDecodeError, ValueError):
                args = {}
        elif isinstance(raw_args, dict):
            args = raw_args
    else:
        raw_args = kwargs.get("args") or kwargs.get("arguments") or {}
        if isinstance(raw_args, str):
            try:
                args = json.loads(raw_args)
            except (json.JSONDecodeError, ValueError):
                args = {}
        elif isinstance(raw_args, dict):
            args = raw_args
        result_callback = kwargs.get("result_callback")

    prescription_text = str(args.get("prescription_text") or "").strip()
    patient_id = str(args.get("patient_id") or "PAT_001").strip()
    allergies = args.get("allergies") or []
    current_medications = args.get("current_medications") or []

    # Infer condition from drug name if not explicitly provided
    inferred_cond = ["Hypertension"]
    d_low = prescription_text.lower()
    if any(
        k in d_low
        for k in [
            "entresto",
            "valsartan",
            "lisinopril",
            "losartan",
            "amlodipine",
            "telmisartan",
            "enalapril",
            "carvedilol",
            "metoprolol",
        ]
    ):
        inferred_cond = ["Hypertension", "Heart Failure"]
    elif any(
        k in d_low
        for k in [
            "metformin",
            "januvia",
            "jardiance",
            "glipizide",
            "glimepiride",
            "sitagliptin",
            "insulin",
        ]
    ):
        inferred_cond = ["Type 2 Diabetes Mellitus"]
    elif any(
        k in d_low
        for k in ["atorvastatin", "rosuvastatin", "simvastatin", "crestor", "lipitor"]
    ):
        inferred_cond = ["Hyperlipidemia"]
    elif any(k in d_low for k in ["advair", "albuterol", "fluticasone", "symbicort"]):
        inferred_cond = ["Asthma", "COPD"]

    conditions = args.get("conditions") or inferred_cond

    logger.info(
        "[Alternea Agent Bridge] Running Multi-Agent Pipeline for '%s' (Patient: %s)...",
        prescription_text,
        patient_id,
    )

    try:
        # Build patient context
        parsed_allergies = [
            {"substance": a, "severity": "HIGH"} if isinstance(a, str) else a
            for a in allergies
        ]
        parsed_conditions = [
            {"name": c} if isinstance(c, str) else c for c in conditions
        ]
        parsed_meds = [
            {"drug_name": m} if isinstance(m, str) else m for m in current_medications
        ]

        req = PrescriptionEvaluationRequest(
            patient_id=patient_id,
            prescription_text=prescription_text,
            patient_context=PatientContext(
                age=args.get("age", 58),
                allergies=parsed_allergies,  # type: ignore[arg-type]
                conditions=parsed_conditions,  # type: ignore[arg-type]
                current_medications=parsed_meds,  # type: ignore[arg-type]
                renal_status=args.get("renal_status", "NORMAL"),
                hepatic_status=args.get("hepatic_status", "NORMAL"),
            ),
            force_alternative_discovery=True,
        )

        report = backend_orchestrator.evaluate_prescription(req)

        top_drug = report.top_recommended_drug
        top_name = top_drug.drug_name if top_drug else "None"
        top_score = top_drug.total_score if top_drug else 0
        decision = report.action_decision
        rationale = (
            top_drug.clinical_rationale
            if top_drug
            else "Standard clinical evaluation completed."
        )

        rejections = [
            f"{r.drug_name}: {r.reason}" for r in report.rejected_alternatives
        ]

        result_payload = {
            "status": "success",
            "action_decision": decision,
            "top_recommended_drug": top_name,
            "composite_score": top_score,
            "clinical_rationale": rationale,
            "disqualified_alternatives_with_reasons": rejections[:3],
            "executive_summary": report.ranking_result.ranking_summary,
        }

        logger.info(
            "[Alternea Agent Bridge] Multi-Agent Evaluation Complete. Winning Drug: %s (Score: %s/100)",
            top_name,
            top_score,
        )
        await _safe_execute_callback(result_callback, result_payload)
    except (RuntimeError, ValueError, TypeError, KeyError, OSError) as exc:
        logger.exception("Error executing backend multi-agent pipeline")
        await _safe_execute_callback(
            result_callback, {"status": "error", "message": str(exc)}
        )


# Define Tools Schema for Groq LLM using Pipecat's FunctionSchema
agent_tools = [
    FunctionSchema(
        name="evaluate_prescription_and_find_alternatives",
        description="Evaluates a prescription across formulary coverage, patient history, PA rules, ML adherence risk, and finds the Top-1 safest, lowest-cost ranked alternative drug.",
        properties={
            "prescription_text": {
                "type": "string",
                "description": "The drug name and dosage from the prescription (e.g. 'Atorvastatin 20mg once daily' or 'Lipitor').",
            },
            "patient_id": {
                "type": "string",
                "description": "Patient identifier (e.g. 'PAT_001').",
            },
            "allergies": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of documented patient drug allergies.",
            },
            "conditions": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of patient diagnosed medical conditions.",
            },
            "current_medications": {
                "type": "array",
                "items": {"type": "string"},
                "description": "List of concurrent medications the patient is currently taking.",
            },
        },
        required=["prescription_text"],
    )
]


async def run_bot(
    transport: BaseTransport,
    runner_args: RunnerArguments,
):
    project_name = project_metadata.get("name", "Alternea-Voice")
    project_version = project_metadata.get("version", "0.1.0")
    logger.info("Starting %s (v%s)...", project_name, project_version)

    sarvam_key = os.getenv("SARVAM_API_KEY")
    groq_key = os.getenv("GROQ_API_KEY")
    groq_model = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")

    if not sarvam_key:
        logger.warning(
            "SARVAM_API_KEY is not set in .env! Voice STT/TTS requires a Sarvam API key."
        )
    if not groq_key:
        logger.warning(
            "GROQ_API_KEY is not set in .env! Voice LLM requires a Groq API key."
        )

    async with aiohttp.ClientSession():
        stt = SarvamSTTService(
            api_key=sarvam_key or "missing_key",
            settings=SarvamSTTService.Settings(
                model="saaras:v3",
                language="en-IN",
            ),
        )

        tts = SarvamTTSService(
            api_key=sarvam_key or "missing_key",
            settings=SarvamTTSService.Settings(
                model="bulbul:v2",
                voice="anushka",
                language="en-IN",
            ),
        )

        llm = GroqLLMService(
            api_key=groq_key or "missing_key",
            settings=GroqLLMService.Settings(
                model=groq_model,
            ),
        )

        # Register the backend Agent bridge tool with Pipecat LLM
        llm.register_function(
            "evaluate_prescription_and_find_alternatives",
            handle_evaluate_prescription,
        )

        messages = [
            {
                "role": "system",
                "content": (
                    "You are Alternea, an AI Pharmacy & Formulary Optimization Voice Assistant connected directly to the CTS Multi-Agent backend. "
                    "You assist doctors, pharmacists, and patients with finding lower-cost generic alternatives, checking prior-authorizations, "
                    "and evaluating medication safety. "
                    "When the user asks for alternative drugs, cost savings, or prescription evaluation, call the `evaluate_prescription_and_find_alternatives` tool. "
                    "Once the agent returns the Top-1 drug and rationale, speak the recommendation clearly, concisely, and naturally. "
                    "Mention the winning drug name, the score out of 100, and why it is better (e.g. Tier 1 preferred, zero drug interactions). "
                    "Avoid emojis, markdown, asterisks, or complex bullet points that are difficult to speak aloud."
                ),
            }
        ]

        context = LLMContext(messages, tools=agent_tools)

        # Smart turn detection with graceful fallback
        turn_analyzer = None
        try:
            turn_analyzer = LocalSmartTurnAnalyzerV3()
        except (ImportError, RuntimeError, OSError, ValueError) as exc:
            logger.warning("LocalSmartTurnAnalyzerV3 unavailable: %s", exc)

        stop_strategies = (
            [TurnAnalyzerUserTurnStopStrategy(turn_analyzer=turn_analyzer)]
            if turn_analyzer
            else []
        )
        user_params = (
            LLMUserAggregatorParams(
                user_turn_strategies=UserTurnStrategies(stop=stop_strategies)
            )
            if stop_strategies
            else LLMUserAggregatorParams()
        )

        user_aggregator, assistant_aggregator = LLMContextAggregatorPair(
            context,
            user_params=user_params,
        )

        transcription_logger = TranscriptionLogger()
        assistant_transcript_logger = AssistantTranscriptLogger()

        pipeline = Pipeline(
            [
                transport.input(),
                stt,
                transcription_logger,
                user_aggregator,
                llm,
                tts,
                assistant_transcript_logger,
                transport.output(),
                assistant_aggregator,
            ]
        )

        task = PipelineTask(
            pipeline,
            params=PipelineParams(
                enable_metrics=True,
                enable_usage_metrics=True,
            ),
            idle_timeout_secs=(runner_args.pipeline_idle_timeout_secs),
        )

        @transport.event_handler("on_client_connected")
        async def on_client_connected(
            transport,
            client,
        ):
            logger.info("Client connected! Sending spoken greeting...")
            greeting = "Hello! I am Alternea, your AI pharmacy and formulary assistant. How can I assist you with your prescriptions today?"
            await task.queue_frames(
                [
                    TTSSpeakFrame(greeting),
                    LLMMessagesAppendFrame(
                        messages=[
                            {
                                "role": "assistant",
                                "content": greeting,
                            }
                        ]
                    ),
                ]
            )

        @transport.event_handler("on_client_disconnected")
        async def on_client_disconnected(
            transport,
            client,
        ):
            logger.info("Client disconnected.")
            await task.cancel()

        runner = PipelineRunner(handle_sigint=runner_args.handle_sigint)
        await runner.run(task)


async def bot(
    runner_args: RunnerArguments,
):
    """
    Main bot entry point.
    Compatible with Pipecat runner and Pipecat Cloud.
    """
    transport = await create_transport(
        runner_args,
        transport_params,
    )

    await run_bot(
        transport,
        runner_args,
    )


if __name__ == "__main__":
    from pipecat.runner.run import main

    main()
