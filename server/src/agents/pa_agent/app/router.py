from typing import Any

from fastapi import APIRouter, HTTPException, Query

from .agent import PAAgent
from .repository import PARepository
from .schemas import (
    PARequest,
    PAResponse,
)
from .service import PAService

router = APIRouter(
    prefix="/pa",
    tags=["Prior Authorization (PA) Agent"],
)

# Singleton instances for API routing
repository = PARepository()
service = PAService(repository)
agent = PAAgent(service)


@router.get("/health")
async def pa_health():
    return {
        "status": "healthy",
        "agent": "prior_authorization",
        "dataset_records": len(repository.records),
    }


@router.post(
    "/evaluate",
    response_model=PAResponse,
    summary="Evaluate PA criteria and readiness",
)
@router.post(
    "/check",
    response_model=PAResponse,
    include_in_schema=False,
)
async def evaluate_prior_authorization(
    request: PARequest,
) -> PAResponse:
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
            detail=f"Internal PA Agent error: {exc}",
        )


@router.get("/policy/{drug_id}")
async def get_pa_policy_details(
    drug_id: str,
    plan_id: str | None = Query(default=None, description="Insurance Plan ID"),
) -> dict[str, Any]:
    policy = agent.get_pa_policy(drug_id=drug_id, plan_id=plan_id)
    if policy is None:
        raise HTTPException(
            status_code=404,
            detail=f"PA policy for drug '{drug_id}' not found",
        )
    return policy


@router.get("/patient/{patient_id}/history")
async def get_patient_pa_history(
    patient_id: str,
) -> list[dict[str, Any]]:
    return agent.get_patient_history(patient_id=patient_id)
