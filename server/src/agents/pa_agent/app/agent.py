from typing import Any

from .schemas import (
    PARequest,
    PAResponse,
)
from .service import PAService


class PAAgent:
    """
    Prior Authorization (PA) Agent interface.
    Evaluates prior-authorization criteria and identifies readiness, missing information, and evidence.
    """

    def __init__(self, service: PAService):
        self.service = service

    def process_request(self, request: PARequest) -> PAResponse:
        return self.service.evaluate_pa(request)

    def get_patient_history(self, patient_id: str) -> list[dict[str, Any]]:
        return self.service.get_patient_history(patient_id=patient_id)

    def get_pa_policy(self, drug_id: str, plan_id: str | None = None) -> dict[str, Any] | None:
        return self.service.get_pa_policy(drug_id=drug_id, plan_id=plan_id)

    def run(self, task: dict[str, Any] | PARequest) -> dict[str, Any]:
        """
        Generic execution entrypoint for agentic orchestrators and multi-agent systems.
        """
        if isinstance(task, PARequest):
            req = task
        else:
            req = PARequest.model_validate(task)
        res = self.process_request(req)
        return res.model_dump()
