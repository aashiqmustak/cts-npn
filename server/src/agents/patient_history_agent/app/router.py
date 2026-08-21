from fastapi import APIRouter, HTTPException

from .agent import PatientHistoryAgent
from .repository import PatientHistoryRepository
from .schemas import (
    PatientHistoryRequest,
    PatientHistoryResponse,
)
from .service import PatientHistoryService


router = APIRouter(
    prefix="/patient-history",
    tags=["Patient History Agent"],
)


repository = PatientHistoryRepository()
service = PatientHistoryService(repository)
agent = PatientHistoryAgent(service)


@router.get("/health")
async def patient_history_health():

    return {
        "status": "healthy",
        "agent": "patient_history",
        "dataset_records": len(repository.records),
    }


@router.post(
    "/check",
    response_model=PatientHistoryResponse,
)
async def get_patient_history(
    request: PatientHistoryRequest,
) -> PatientHistoryResponse:

    try:

        return agent.process_request(
            request
        )

    except FileNotFoundError as exc:

        raise HTTPException(
            status_code=503,
            detail=f"Dataset unavailable: {exc}",
        )

    except Exception as exc:

        raise HTTPException(
            status_code=500,
            detail=f"Internal Patient History Agent error: {exc}",
        )