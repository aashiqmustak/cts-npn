from typing import Any

from fastapi import APIRouter, HTTPException, Query

from .agent import FormularyAgent
from .repository import FormularyRepository
from .schemas import (
    FormularyRequest,
    FormularyResponse,
)
from .service import FormularyService

router = APIRouter(
    prefix="/formulary",
    tags=["Formulary Agent"],
)

# Singleton instances for API routing
repository = FormularyRepository()
service = FormularyService(repository)
agent = FormularyAgent(service)


@router.get("/health")
async def formulary_health():
    return {
        "status": "healthy",
        "agent": "formulary",
        "dataset_records": len(repository.records),
    }


@router.post(
    "/check",
    response_model=FormularyResponse,
)
async def check_formulary(
    request: FormularyRequest,
) -> FormularyResponse:
    try:
        return agent.process_request(request)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Dataset unavailable: {exc}",
        )
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(
            status_code=500,
            detail=f"Internal Formulary Agent error: {exc}",
        )


@router.get("/search")
async def search_formulary_drugs(
    query: str = Query(default="", description="Search drug name, NDC, or therapeutic class"),
    limit: int = Query(default=20, ge=1, le=100),
) -> list[dict[str, Any]]:
    return agent.search_drugs(query=query, limit=limit)


@router.get("/drug/{drug_id}")
async def get_drug_details(
    drug_id: str,
) -> dict[str, Any]:
    details = agent.get_drug_details(drug_id=drug_id)
    if details is None:
        raise HTTPException(
            status_code=404,
            detail=f"Drug '{drug_id}' not found in formulary index",
        )
    return details


@router.get("/patient/{patient_id}/history")
async def get_patient_formulary_history(
    patient_id: str,
) -> list[dict[str, Any]]:
    return agent.get_patient_history(patient_id=patient_id)
