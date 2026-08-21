from pathlib import Path
from typing import Any

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in __import__("sys").path:
    __import__("sys").path.insert(0, str(APP_DIR))

try:
    from .schemas import ClinicalSafetyInput, ClinicalSafetyOutput
    from .service import ClinicalEligibilityService
except ImportError:  # pragma: no cover - allows standalone script execution
    from schemas import ClinicalSafetyInput, ClinicalSafetyOutput
    from service import ClinicalEligibilityService


class ClinicalEligibilityAgent:
    """Clinical safety/eligibility agent wrapper."""

    def __init__(self, service: ClinicalEligibilityService | None = None):
        self.service = service or ClinicalEligibilityService()

    def process_request(self, request: ClinicalSafetyInput) -> ClinicalSafetyOutput:
        return self.service.evaluate(request)

    def run(self, task: dict[str, Any] | ClinicalSafetyInput) -> dict[str, Any]:
        if isinstance(task, ClinicalSafetyInput):
            req = task
        else:
            req = ClinicalSafetyInput.model_validate(task)
        return self.process_request(req).model_dump()
