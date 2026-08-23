from typing import Any
from fastapi import APIRouter, HTTPException

from .agent import PatientHistoryAgent
from .repository import PatientHistoryRepository
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

router = APIRouter(
    prefix="/patient-history",
    tags=["Patient History Agent (Pinecone RAG)"],
)

repository = PatientHistoryRepository()
service = PatientHistoryService(repository)
agent = PatientHistoryAgent(service)


@router.get("/health")
async def patient_history_health() -> dict[str, Any]:
    pinecone_stats = repository.pinecone.get_stats()
    return {
        "status": "healthy",
        "agent": "patient_history",
        "dataset_records": len(repository.records),
        "pinecone_rag": pinecone_stats,
    }


@router.post(
    "/check",
    response_model=PatientHistoryResponse,
    summary="Compute adherence metrics and optionally retrieve RAG context",
)
async def get_patient_history(
    request: PatientHistoryRequest,
) -> PatientHistoryResponse:
    try:
        return agent.process_request(request)
    except FileNotFoundError as exc:
        raise HTTPException(
            status_code=503,
            detail=f"Dataset unavailable: {exc}",
        ) from exc
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Internal Patient History Agent error: {exc}",
        ) from exc


@router.post(
    "/record",
    response_model=PatientRecordIngestResponse,
    summary="Ingest and vectorize a new patient medication history record from client",
)
async def ingest_patient_record(
    record: PatientRecordInput,
) -> PatientRecordIngestResponse:
    try:
        return agent.ingest_patient_record(record)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to ingest patient record: {exc}",
        ) from exc


@router.post(
    "/records/batch",
    response_model=BatchIngestResponse,
    summary="Batch ingest multiple patient history records",
)
async def ingest_patient_records_batch(
    batch: BatchIngestRequest,
) -> BatchIngestResponse:
    try:
        return agent.ingest_batch(batch)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to batch ingest records: {exc}",
        ) from exc


@router.post(
    "/rag-query",
    response_model=RAGQueryResponse,
    summary="Semantic vector retrieval and clinical summary for patient history",
)
async def rag_query_patient_history(
    request: RAGQueryRequest,
) -> RAGQueryResponse:
    try:
        return agent.query_rag(request)
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"RAG query execution failed: {exc}",
        ) from exc


@router.post(
    "/sync-dataset",
    summary="Bulk index dataset/patient_history.csv records into Pinecone Vector DB",
)
async def sync_dataset_to_pinecone() -> dict[str, Any]:
    try:
        return agent.sync_dataset_to_pinecone()
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Failed to sync dataset to Pinecone: {exc}",
        ) from exc
