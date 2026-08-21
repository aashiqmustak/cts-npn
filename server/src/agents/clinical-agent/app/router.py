import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from fastapi import APIRouter, HTTPException, status
from pydantic import ValidationError

try:
    from .agent import ClinicalEligibilityAgent
    from .schemas import ClinicalSafetyInput, ClinicalSafetyOutput
except ImportError:  # pragma: no cover - allows standalone script execution
    from agent import ClinicalEligibilityAgent
    from schemas import ClinicalSafetyInput, ClinicalSafetyOutput

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/clinical-agent", tags=["Clinical Agent"])
agent = ClinicalEligibilityAgent()


@router.get("/health")
async def clinical_agent_health() -> dict[str, str]:
    return {"status": "healthy", "agent": "clinical-eligibility"}


@router.post("/evaluate", response_model=ClinicalSafetyOutput)
async def evaluate_clinical_safety(
    request: ClinicalSafetyInput,
) -> ClinicalSafetyOutput:
    try:
        return agent.process_request(request)
    except ValidationError as exc:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=exc.errors(),
        ) from exc
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except Exception as exc:  # pragma: no cover - defensive API guard
        logger.exception("Unexpected clinical eligibility error")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal clinical agent error",
        ) from exc
