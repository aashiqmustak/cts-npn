from typing import Any

from .schemas import (
    BatchIngestRequest,
    BatchIngestResponse,
    PatientHistoryRequest,
    PatientHistoryResponse,
    PatientRecordIngestResponse,
    PatientRecordInput,
    RAGQueryRequest,
    RAGQueryResponse,
)
from .service import PatientHistoryService


class PatientHistoryAgent:
    def __init__(self, service: PatientHistoryService):
        self.service = service

    def process_request(self, request: PatientHistoryRequest) -> PatientHistoryResponse:
        return self.service.get_patient_history(request)

    def ingest_patient_record(self, record: PatientRecordInput) -> PatientRecordIngestResponse:
        return self.service.ingest_patient_record(record)

    def ingest_batch(self, batch: BatchIngestRequest) -> BatchIngestResponse:
        return self.service.ingest_batch(batch)

    def query_rag(self, rag_req: RAGQueryRequest) -> RAGQueryResponse:
        return self.service.query_rag(rag_req)

    def sync_dataset_to_pinecone(self) -> dict[str, Any]:
        return self.service.sync_dataset_to_pinecone()

    def run(self, task: dict[str, Any] | PatientHistoryRequest) -> dict[str, Any]:
        if isinstance(task, PatientHistoryRequest):
            request = task
        else:
            request = PatientHistoryRequest.model_validate(task)

        response = self.process_request(request)
        return response.model_dump()
