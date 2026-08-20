from typing import Any

from .schemas import (
    FormularyRequest,
    FormularyResponse,
)
from .service import FormularyService


class FormularyAgent:
    """
    Formulary Agent query interface.
    Handles single-point formulary checks, restriction evaluations, and alternative lookups.
    """

    def __init__(self, service: FormularyService):
        self.service = service

    def process_request(
        self,
        request: FormularyRequest,
    ) -> FormularyResponse:
        return self.service.check_formulary(request)

    def search_drugs(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        return self.service.search_drugs(query=query, limit=limit)

    def get_drug_details(self, drug_id: str) -> dict[str, Any] | None:
        return self.service.get_drug_details(drug_id=drug_id)

    def get_patient_history(self, patient_id: str) -> list[dict[str, Any]]:
        return self.service.get_patient_history(patient_id=patient_id)

    def run(self, task: dict[str, Any] | FormularyRequest) -> dict[str, Any]:
        """
        Generic execution entrypoint for agentic orchestrators and tools.
        """
        if isinstance(task, FormularyRequest):
            req = task
        else:
            req = FormularyRequest.model_validate(task)
        res = self.process_request(req)
        return res.model_dump()
