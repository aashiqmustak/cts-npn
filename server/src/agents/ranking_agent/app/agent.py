from pathlib import Path
from typing import Any

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in __import__("sys").path:
    __import__("sys").path.insert(0, str(APP_DIR))

try:
    from .schemas import RankingInput, RankingOutput
    from .service import RankingService
except ImportError:  # pragma: no cover - allows standalone script execution
    from schemas import RankingInput, RankingOutput
    from service import RankingService


class RankingAgent:
    """Multi-factor clinical safety and candidate ranking agent."""

    def __init__(self, service: RankingService | None = None):
        self.service = service or RankingService()

    def process_request(self, request: RankingInput) -> RankingOutput:
        return self.service.evaluate(request)

    def rank(self, request: RankingInput) -> RankingOutput:
        return self.process_request(request)

    def run(self, task: dict[str, Any] | RankingInput) -> dict[str, Any]:
        if isinstance(task, RankingInput):
            req = task
        else:
            req = RankingInput.model_validate(task)
        return self.process_request(req).model_dump()


# Backwards compatibility alias
ClinicalEligibilityAgent = RankingAgent

__all__ = ["ClinicalEligibilityAgent", "RankingAgent"]
