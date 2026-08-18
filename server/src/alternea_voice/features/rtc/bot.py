import os
# pyrefly: ignore [missing-import]
import aiohttp
import pathlib
import tomllib
# pyrefly: ignore [missing-import]
from dotenv import load_dotenv

def load_project_env_and_metadata():
    current_dir = pathlib.Path(__file__).resolve().parent
    pyproject_path = None
    for parent in [current_dir] + list(current_dir.parents):
        if (parent / "pyproject.toml").exists():
            pyproject_path = parent / "pyproject.toml"
            break
            
    env_path = None
    for parent in [current_dir] + list(current_dir.parents):
        if (parent / ".env").exists():
            env_path = parent / ".env"
            break
            
    if env_path:
        load_dotenv(dotenv_path=env_path)
    else:
        load_dotenv()
        
    metadata = {}
    if pyproject_path:
        try:
            with open(pyproject_path, "rb") as f:
                data = tomllib.load(f)
                metadata = data.get("project", {})
        except Exception as e:
            print(f"Warning: Could not read pyproject.toml: {e}")
            
    return metadata

project_metadata = load_project_env_and_metadata()

from pipecat.frames.frames import Frame, TranscriptionFrame, LLMRunFrame

from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.runner import PipelineRunner
from pipecat.pipeline.task import PipelineParams, PipelineTask

from pipecat.processors.frame_processor import (
    FrameDirection,
    FrameProcessor,
)

from pipecat.runner.types import RunnerArguments
from pipecat.runner.utils import create_transport

from pipecat.audio.turn.smart_turn.local_smart_turn_v3 import (
    LocalSmartTurnAnalyzerV3,
)

from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.audio.vad.vad_analyzer import VADParams

from pipecat.processors.aggregators.llm_context import LLMContext

from pipecat.processors.aggregators.llm_response_universal import (
    LLMContextAggregatorPair,
    LLMUserAggregatorParams,
)

from pipecat.turns.user_stop import TurnAnalyzerUserTurnStopStrategy
from pipecat.turns.user_turn_strategies import UserTurnStrategies

from pipecat.services.sarvam.stt import SarvamSTTService
from pipecat.services.sarvam.tts import SarvamTTSService
from pipecat.services.groq.llm import GroqLLMService

from pipecat.transports.base_transport import (
    BaseTransport,
    TransportParams,
)

from pipecat.transports.websocket.fastapi import (
    FastAPIWebsocketParams,
)

class TranscriptionLogger(FrameProcessor):

    async def process_frame(
        self,
        frame: Frame,
        direction: FrameDirection,
    ):
        await super().process_frame(frame, direction)

        if isinstance(frame, TranscriptionFrame):
            print(f"Transcription: {frame.text}")

        await self.push_frame(frame, direction)

def create_vad():
    return SileroVADAnalyzer(
        params=VADParams(
            stop_secs=0.5
        )
    )

transport_params = {

    # # Twilio WebSocket
    # "twilio": lambda: FastAPIWebsocketParams(
    #     audio_in_enabled=True,
    #     audio_out_enabled=True,
    #     vad_analyzer=create_vad(),
    # ),

    # Browser WebRTC
    "webrtc": lambda: TransportParams(
        audio_in_enabled=True,
        audio_out_enabled=True,
        vad_analyzer=create_vad(),
    ),
}

async def run_bot(
    transport: BaseTransport,
    runner_args: RunnerArguments,
):
    project_name = project_metadata.get("name", "Alternea-Voice")
    project_version = project_metadata.get("version", "0.1.0")
    print(f"Starting {project_name} (v{project_version})...")

    async with aiohttp.ClientSession() as session:

        stt = SarvamSTTService(
            api_key=os.getenv("SARVAM_API_KEY"),
            settings=SarvamSTTService.Settings(
                model="saarika:v2.5",
            ),
        )

        tts = SarvamTTSService(
            api_key=os.getenv("SARVAM_API_KEY"),
            settings=SarvamTTSService.Settings(
                model="bulbul:v2",
                voice="manisha",
            ),
        )

        llm = GroqLLMService(
            api_key=os.getenv("GROQ_API_KEY"),
            model=os.getenv("GROQ_MODEL", "groq/compound"),
        )

        messages = [
            {
                "role": "system",
                "content": (
                    "You are a helpful AI voice assistant in a WebRTC call. "
                    "Your responses will be spoken aloud. "
                    "Keep responses natural, conversational, and concise. "
                    "Avoid emojis, markdown, bullet points, and special "
                    "characters that are difficult to speak. "
                    "Respond directly to what the user says."
                ),
            }
        ]

        context = LLMContext(messages)


        user_aggregator, assistant_aggregator = (
            LLMContextAggregatorPair(
                context,
                user_params=LLMUserAggregatorParams(
                    user_turn_strategies=UserTurnStrategies(
                        stop=[
                            TurnAnalyzerUserTurnStopStrategy(
                                turn_analyzer=(
                                    LocalSmartTurnAnalyzerV3()
                                )
                            )
                        ]
                    )
                ),
            )
        )


        transcription_logger = TranscriptionLogger()

        pipeline = Pipeline(
            [
                transport.input(),
                stt,
                transcription_logger,
                user_aggregator,
                llm,
                tts,
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
            idle_timeout_secs=(
                runner_args.pipeline_idle_timeout_secs
            ),
        )

        @transport.event_handler("on_client_connected")
        async def on_client_connected(
            transport,
            client,
        ):
            print("Client connected")

            messages.append(
                {
                    "role": "system",
                    "content": (
                        "Please introduce yourself briefly "
                        "and greet the user."
                    ),
                }
            )

            await task.queue_frames(
                [
                    LLMRunFrame()
                ]
            )
        @transport.event_handler("on_client_disconnected")
        async def on_client_disconnected(
            transport,
            client,
        ):
            print("Client disconnected")

            await task.cancel()

        runner = PipelineRunner(
            handle_sigint=runner_args.handle_sigint
        )

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