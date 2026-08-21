from typing import Any

from .schemas import (
    PatientHistoryRequest,
    PatientHistoryResponse,
)
from .service import PatientHistoryService


class PatientHistoryAgent:
    def __init__(self, service: PatientHistoryService):
        self.service = service

    def process_request(self, request: PatientHistoryRequest) -> PatientHistoryResponse:

        return self.service.get_patient_history(request)

    def run(self, task: dict[str, Any] | PatientHistoryRequest) -> dict[str, Any]:

        if isinstance(task, PatientHistoryRequest):
            request = task

        else:
            request = PatientHistoryRequest.model_validate(task)

        response = self.process_request(request)

        return response.model_dump()
