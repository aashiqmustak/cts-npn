import asyncio
import datetime
import pathlib
import sys
import time
from typing import Any

# Ensure server/src is in sys.path
_current = pathlib.Path(__file__).resolve().parent
if str(_current) not in sys.path:
    sys.path.insert(0, str(_current))

# 1. Domain Agents & Services
from agents.alternative_discovery.app.agent import AlternativeDiscoveryAgent
from agents.alternative_discovery.app.repository import (
    AlternativeDiscoveryRepository,
)
from agents.alternative_discovery.app.schemas import (
    AlternativeDiscoveryInput,
    AlternativeDiscoveryOutput,
)
from agents.alternative_discovery.app.service import AlternativeDiscoveryService
from agents.formulary_agent.app.agent import FormularyAgent
from agents.formulary_agent.app.repository import FormularyRepository
from agents.formulary_agent.app.schemas import (
    FormularyRequest,
    FormularyResponse,
)
from agents.formulary_agent.app.service import FormularyService
from agents.pa_agent.app.agent import PAAgent
from agents.pa_agent.app.repository import PARepository
from agents.pa_agent.app.schemas import PARequest, PAResponse
from agents.pa_agent.app.service import PAService
from agents.patient_history_agent.app.agent import PatientHistoryAgent
from agents.patient_history_agent.app.repository import PatientHistoryRepository
from agents.patient_history_agent.app.schemas import (
    PatientHistoryRequest,
    PatientHistoryResponse,
)
from agents.patient_history_agent.app.service import PatientHistoryService
from agents.prescription_agent.app.agent import PrescriptionAgent
from agents.prescription_agent.app.models import PrescriptionOutput
from agents.prescription_agent.app.ocr_service import extract_text_from_file
from agents.ranking_agent.app.agent import RankingAgent
from agents.ranking_agent.app.schemas import RankingInput, RankingOutput
from agents.ranking_agent.app.service import RankingService
from litestar import Litestar, Router, get, post
from litestar.config.cors import CORSConfig
from litestar.exceptions import HTTPException
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.plugins import ScalarRenderPlugin, SwaggerRenderPlugin
from ml.schemas import (
    AbandonmentPredictionInput,
    AbandonmentPredictionOutput,
    AdherencePredictionInput,
    AdherencePredictionOutput,
)
from ml.service import MLPredictorService
from orchestrator.schemas import (
    PrescriptionEvaluationRequest,
    TherapyEvaluationReport,
)
from orchestrator.workflow import MultiAgentOrchestrator
from pydantic import BaseModel

# =====================================================================
# SINGLETON INSTANCES
# =====================================================================
prescription_agent = PrescriptionAgent()

formulary_repo = FormularyRepository()
formulary_service = FormularyService(formulary_repo)
formulary_agent = FormularyAgent(formulary_service)

pa_repo = PARepository()
pa_service = PAService(pa_repo)
pa_agent = PAAgent(pa_service)

patient_history_repo = PatientHistoryRepository()
patient_history_service = PatientHistoryService(patient_history_repo)
patient_history_agent = PatientHistoryAgent(patient_history_service)

ml_service = MLPredictorService()

alt_repo = AlternativeDiscoveryRepository()
alt_service = AlternativeDiscoveryService(alt_repo)
alt_agent = AlternativeDiscoveryAgent(alt_service)

ranking_service = RankingService()
ranking_agent = RankingAgent(ranking_service)

orchestrator = MultiAgentOrchestrator()


# =====================================================================
# 1. PRESCRIPTION NORMALIZATION ROUTER
# =====================================================================
class PrescriptionNormalizePayload(BaseModel):
    patient_id: str
    prescription_text: str
    doctor_id: str = "DOC_001"
    prescription_id: str | None = None


class PrescriptionUploadOCRPayload(BaseModel):
    file_name: str
    file_content_base64: str
    patient_id: str = "PAT_00001"
    doctor_id: str = "DOC_001"


class PrescriptionStatusPayload(BaseModel):
    prescription_id: str
    patient_id: str
    status: str  # "Bought" or "Not Bought"
    doctor_name: str | None = None
    medication_name: str | None = None
    dosage: str | None = None
    instructions: str | None = None
    frequency: str | None = None
    duration_days: int | None = 30
    timestamp: str | None = None


_pending_followup_tasks: dict[str, asyncio.Task] = {}
_followup_records: dict[str, dict[str, Any]] = {}


async def _schedule_followup_call_task(
    prescription_id: str, payload_data: dict[str, Any], delay_seconds: int = 120
):
    try:
        print(
            f"[Follow-up Scheduler] 2-minute timer started for Rx {prescription_id} (Patient {payload_data.get('patient_id')})"
        )
        await asyncio.sleep(delay_seconds)

        # Timer elapsed -> Mark follow-up as triggered
        record = _followup_records.get(prescription_id)
        if record and record.get("status") == "Not Bought":
            record["triggered"] = True
            record["triggered_at"] = datetime.datetime.now(datetime.UTC).isoformat()
            record["call_status"] = "initiated"
            print(
                f"[Follow-up Scheduler] 2-minute timer completed! Automated adherence call triggered for Patient {payload_data.get('patient_id')} (Medication: {payload_data.get('medication_name')})"
            )
    except asyncio.CancelledError:
        print(
            f"[Follow-up Scheduler] Follow-up timer cancelled for Rx {prescription_id} (Prescription was marked as Bought)."
        )
    finally:
        _pending_followup_tasks.pop(prescription_id, None)


@get("/health")
async def rx_health() -> dict[str, str]:
    return {"status": "healthy", "agent": "prescription_agent"}


@post(["/normalize", "/process"])
async def normalize_prescription(
    data: PrescriptionNormalizePayload,
) -> PrescriptionOutput:
    return prescription_agent.process(
        patient_id=data.patient_id,
        prescription_text=data.prescription_text,
        doctor_id=data.doctor_id,
        prescription_id=data.prescription_id,
    )


@post("/upload-ocr")
async def upload_ocr(
    data: PrescriptionUploadOCRPayload,
) -> dict[str, Any]:
    raw_text = extract_text_from_file(data.file_name, data.file_content_base64)
    normalized_output = prescription_agent.process(
        patient_id=data.patient_id,
        prescription_text=raw_text,
        doctor_id=data.doctor_id,
    )
    return {
        "raw_text": raw_text,
        "normalized": normalized_output,
    }


@post("/status")
async def update_prescription_status(
    data: PrescriptionStatusPayload,
) -> dict[str, Any]:
    rx_id = data.prescription_id
    status = data.status.strip()
    patient_id = data.patient_id.strip()

    if rx_id in _pending_followup_tasks:
        _pending_followup_tasks[rx_id].cancel()
        _pending_followup_tasks.pop(rx_id, None)

    import time
    now_iso = datetime.datetime.now(datetime.UTC).isoformat()
    record = {
        "prescription_id": rx_id,
        "patient_id": patient_id,
        "status": status,
        "doctor_name": data.doctor_name or "Attending Physician",
        "medication_name": data.medication_name or "Prescribed Medication",
        "dosage": data.dosage or "",
        "instructions": data.instructions or "",
        "frequency": data.frequency or "",
        "duration_days": data.duration_days or 30,
        "updated_at": now_iso,
        "triggered": False,
        "triggered_at": None,
        "call_status": "none",
        "scheduled_delay_seconds": 120,
    }
    _followup_records[rx_id] = record

    if status.lower() == "not bought":
        record["timer_started_at"] = time.time()
        record["timer_expires_at"] = time.time() + 120
        record["call_status"] = "scheduled_2min"
        task = asyncio.create_task(
            _schedule_followup_call_task(rx_id, record, delay_seconds=120)
        )
        _pending_followup_tasks[rx_id] = task
        return {
            "success": True,
            "prescription_id": rx_id,
            "status": "Not Bought",
            "followup_scheduled": True,
            "delay_seconds": 120,
            "message": "Status updated to Not Bought. 2-minute server follow-up timer initiated.",
        }
    else:
        record["call_status"] = "resolved_bought"
        return {
            "success": True,
            "prescription_id": rx_id,
            "status": "Bought",
            "followup_scheduled": False,
            "message": "Prescription marked as bought.",
        }


@get("/followups/{patient_id:str}")
async def get_patient_followups(patient_id: str) -> list[dict[str, Any]]:
    import time
    results = []
    now = time.time()
    p_norm = patient_id.strip().lower()
    for _rx_id, rec in _followup_records.items():
        rec_pid = str(rec.get("patient_id", "")).strip().lower()
        if rec_pid == p_norm or (p_norm in rec_pid) or (rec_pid in p_norm):
            rec_copy = dict(rec)
            if rec.get("status") == "Not Bought" and not rec.get("triggered", False):
                expires = rec.get("timer_expires_at", 0)
                remaining = max(0, int(expires - now))
                rec_copy["remaining_seconds"] = remaining
            results.append(rec_copy)
    return results


@post("/followups/{prescription_id:str}/dismiss")
async def dismiss_patient_followup(prescription_id: str) -> dict[str, Any]:
    if prescription_id in _followup_records:
        _followup_records[prescription_id]["dismissed"] = True
        _followup_records[prescription_id]["call_status"] = "dismissed"
        return {"success": True, "prescription_id": prescription_id}
    return {"success": False, "error": "Not found"}


prescription_router = Router(
    path="/api/v1/prescription",
    route_handlers=[
        rx_health,
        normalize_prescription,
        upload_ocr,
        update_prescription_status,
        get_patient_followups,
        dismiss_patient_followup,
    ],
    tags=["1. Prescription Agent"],
)


# =====================================================================
# 2. FORMULARY AGENT ROUTER
# =====================================================================
@get("/health")
async def formulary_health() -> dict[str, Any]:
    return {
        "status": "healthy",
        "agent": "formulary",
        "dataset_records": len(formulary_repo.records),
    }


@post("/check")
async def check_formulary(data: FormularyRequest) -> FormularyResponse:
    try:
        return formulary_agent.process_request(data)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503, detail=f"Formulary dataset unavailable: {exc}"
        ) from exc


@get("/search")
async def search_formulary(query: str = "", limit: int = 20) -> list[dict[str, Any]]:
    return formulary_agent.search_drugs(query=query, limit=limit)


@get("/drug/{drug_id:str}")
async def get_formulary_drug(drug_id: str) -> dict[str, Any]:
    details = formulary_agent.get_drug_details(drug_id=drug_id)
    if details is None:
        raise HTTPException(
            status_code=404, detail=f"Drug '{drug_id}' not found in formulary"
        )
    return details


@get("/patient/{patient_id:str}/history")
async def get_patient_formulary_history(
    patient_id: str,
) -> list[dict[str, Any]]:
    return formulary_agent.get_patient_history(patient_id=patient_id)


formulary_router = Router(
    path="/api/v1/formulary",
    route_handlers=[
        formulary_health,
        check_formulary,
        search_formulary,
        get_formulary_drug,
        get_patient_formulary_history,
    ],
    tags=["2. Formulary Agent"],
)


# =====================================================================
# 3. PRIOR AUTHORIZATION (PA) AGENT ROUTER
# =====================================================================
@get("/health")
async def pa_health() -> dict[str, Any]:
    return {
        "status": "healthy",
        "agent": "prior_authorization",
        "dataset_records": len(pa_repo.records),
    }


@post(["/evaluate", "/check"])
async def evaluate_pa(data: PARequest) -> PAResponse:
    try:
        return pa_agent.process_request(data)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503, detail=f"PA dataset unavailable: {exc}"
        ) from exc


@get("/policy/{drug_id:str}")
async def get_pa_policy(drug_id: str, plan_id: str | None = None) -> dict[str, Any]:
    policy = pa_agent.get_pa_policy(drug_id=drug_id, plan_id=plan_id)
    if policy is None:
        raise HTTPException(
            status_code=404, detail=f"PA policy for drug '{drug_id}' not found"
        )
    return policy


@get("/patient/{patient_id:str}/history")
async def get_patient_pa_history(patient_id: str) -> list[dict[str, Any]]:
    return pa_agent.get_patient_history(patient_id=patient_id)


pa_router = Router(
    path="/api/v1/pa",
    route_handlers=[
        pa_health,
        evaluate_pa,
        get_pa_policy,
        get_patient_pa_history,
    ],
    tags=["3. Prior Authorization (PA) Agent"],
)


# =====================================================================
# 4. PATIENT HISTORY AGENT ROUTER
# =====================================================================
@get("/health")
async def history_health() -> dict[str, Any]:
    return {
        "status": "healthy",
        "agent": "patient_history",
        "dataset_records": len(patient_history_repo.records),
    }


@post("/check")
async def get_patient_history(
    data: PatientHistoryRequest,
) -> PatientHistoryResponse:
    try:
        return patient_history_agent.process_request(data)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503, detail=f"Patient history dataset unavailable: {exc}"
        ) from exc


patient_history_router = Router(
    path="/api/v1/patient-history",
    route_handlers=[history_health, get_patient_history],
    tags=["4. Patient History Agent"],
)


# =====================================================================
# 5. ML PREDICTION ROUTER (Adherence + Abandonment)
# =====================================================================
@get("/health")
async def ml_health() -> dict[str, Any]:
    remote = ml_service.check_remote_health()
    return {
        "status": "healthy"
        if remote.get("connected") or ml_service.adherence_model is not None
        else "degraded",
        "service_type": "AWS EC2 ML Inference Service"
        if remote.get("connected")
        else "Local ML Fallback",
        "endpoint_url": ml_service.base_url,
        "remote_service": remote,
        "local_models": {
            "adherence": ml_service.adherence_model is not None,
            "abandonment": ml_service.abandonment_model is not None,
        },
    }


@post("/predict-adherence")
async def predict_adherence_route(
    data: AdherencePredictionInput,
) -> AdherencePredictionOutput:
    return ml_service.predict_adherence(data)


@post("/predict-abandonment")
async def predict_abandonment_route(
    data: AbandonmentPredictionInput,
) -> AbandonmentPredictionOutput:
    return ml_service.predict_abandonment(data)


ml_router = Router(
    path="/api/v1/ml",
    route_handlers=[
        ml_health,
        predict_adherence_route,
        predict_abandonment_route,
    ],
    tags=["5. ML Risk Prediction Layer"],
)


# =====================================================================
# 6. ALTERNATIVE DISCOVERY AGENT ROUTER
# =====================================================================
@get("/health")
async def alt_health() -> dict[str, Any]:
    return {
        "status": "healthy",
        "agent": "alternative_discovery",
        "dataset_records": len(alt_repo.records),
    }


@post("/discover")
async def discover_alternatives_route(
    data: AlternativeDiscoveryInput,
) -> AlternativeDiscoveryOutput:
    return alt_agent.process_request(data)


alternative_discovery_router = Router(
    path="/api/v1/alternatives",
    route_handlers=[alt_health, discover_alternatives_route],
    tags=["6. Alternative Discovery Agent"],
)


# =====================================================================
# 7. RANKING AGENT ROUTER
# =====================================================================
@get("/health")
async def ranking_health() -> dict[str, str]:
    return {"status": "healthy", "agent": "ranking-agent"}


@post(["/rank", "/evaluate"])
async def rank_candidates(data: RankingInput) -> RankingOutput:
    return ranking_agent.process_request(data)


ranking_router = Router(
    path="/api/v1/ranking",
    route_handlers=[ranking_health, rank_candidates],
    tags=["7. Ranking & Clinical Safety Agent"],
)


# =====================================================================
# 8. MULTI-AGENT ORCHESTRATOR PIPELINE ROUTER
# =====================================================================
@get("/health")
async def orchestrator_health() -> dict[str, Any]:
    return {
        "status": "healthy",
        "orchestrator": "CTS PharmaAssist Multi-Agent Pipeline",
        "connected_agents": [
            "prescription_agent",
            "formulary_agent",
            "pa_agent",
            "patient_history_agent",
            "ml_predictor_service",
            "alternative_discovery_agent",
            "ranking_agent",
        ],
    }


@post("/evaluate-prescription")
async def orchestrate_prescription(
    data: PrescriptionEvaluationRequest,
) -> TherapyEvaluationReport:
    return orchestrator.evaluate_prescription(data)


orchestrator_router = Router(
    path="/api/v1/orchestrate",
    route_handlers=[orchestrator_health, orchestrate_prescription],
    tags=["0. End-to-End Orchestrator Pipeline"],
)


# =====================================================================
# SYSTEM ROOT & DEEP HEALTH CHECK
# =====================================================================
@get("/")
async def root() -> dict[str, Any]:
    return {
        "service": "CTS PharmaAssist Multi-Agent Platform",
        "framework": "Litestar ASGI",
        "version": "2.0.0",
        "status": "running",
        "docs_url": "/docs",
        "pipeline_endpoint": "/api/v1/orchestrate/evaluate-prescription",
        "agents": {
            "prescription": "/api/v1/prescription",
            "formulary": "/api/v1/formulary",
            "pa": "/api/v1/pa",
            "patient_history": "/api/v1/patient-history",
            "ml": "/api/v1/ml",
            "alternatives": "/api/v1/alternatives",
            "ranking": "/api/v1/ranking",
            "orchestrate": "/api/v1/orchestrate",
        },
    }


@get("/health")
async def system_health() -> dict[str, Any]:
    remote_ml = ml_service.check_remote_health()
    ml_status = (
        f"healthy (AWS EC2 @ {ml_service.base_url})"
        if remote_ml.get("connected")
        else "healthy (local fallback)"
    )
    return {
        "system_status": "healthy",
        "timestamp": datetime.datetime.now(datetime.UTC).isoformat(),
        "agents": {
            "prescription": "healthy",
            "formulary": f"healthy ({len(formulary_repo.records)} records)",
            "prior_authorization": f"healthy ({len(pa_repo.records)} records)",
            "patient_history": f"healthy ({len(patient_history_repo.records)} records)",
            "ml_models": ml_status,
            "alternative_discovery": f"healthy ({len(alt_repo.records)} records)",
            "ranking_agent": "healthy",
        },
    }


# =====================================================================
# LITESTAR APPLICATION
# =====================================================================
cors_config = CORSConfig(
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

openapi_config = OpenAPIConfig(
    title="CTS PharmaAssist Multi-Agent Platform",
    description="Litestar ASGI API Gateway connecting Prescription, Formulary, PA, Patient History, ML Risk Models, Alternative Discovery, and Ranking Agents.",
    version="2.0.0",
    path="/docs",
    render_plugins=[ScalarRenderPlugin(), SwaggerRenderPlugin()],
)

app = Litestar(
    route_handlers=[
        root,
        system_health,
        orchestrator_router,
        prescription_router,
        formulary_router,
        pa_router,
        patient_history_router,
        ml_router,
        alternative_discovery_router,
        ranking_router,
    ],
    openapi_config=openapi_config,
    cors_config=cors_config,
)


def run_agent_service(host: str = "0.0.0.0", port: int = 8000):
    import uvicorn

    uvicorn.run(app, host=host, port=port)


if __name__ == "__main__":
    run_agent_service()
