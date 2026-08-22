import logging
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from fastapi import APIRouter, HTTPException, status
from pydantic import ValidationError

try:
    from .agent import RankingAgent
    from .schemas import RankingInput, RankingOutput
except ImportError:  # pragma: no cover - allows standalone script execution
    from agent import RankingAgent
    from schemas import RankingInput, RankingOutput

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/ranking-agent",
    tags=["Ranking & Clinical Safety Agent"],
)
agent = RankingAgent()


@router.get("/health")
async def ranking_agent_health() -> dict[str, str]:
    return {"status": "healthy", "agent": "ranking-agent"}


@router.post(
    "/rank",
    response_model=RankingOutput,
    summary="Rank candidate alternate drugs and select top-1 recommendation",
)
@router.post(
    "/evaluate",
    response_model=RankingOutput,
    summary="Evaluate and rank clinical alternatives (backwards compatible)",
)
async def evaluate_and_rank_drugs(request: RankingInput) -> RankingOutput:
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
        logger.exception("Unexpected ranking error")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Internal ranking agent error: {exc}",
        ) from exc
