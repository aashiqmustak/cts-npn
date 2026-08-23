from typing import Any
from pydantic import BaseModel, Field


class PatientHistoryRequest(BaseModel):
    patient_id: str
    drug_id: str
    lookback_days: int = 365
    include_rag: bool = False


class MedicationHistory(BaseModel):
    previous_pdc_180: float
    refill_gap_days_90: int
    prior_abandonment_count_12m: int
    prior_switch_count_12m: int
    medication_count: int
    conditions_count: int


class PatientHistoryResponse(BaseModel):
    patient_id: str
    medication_history: MedicationHistory
    history_status: str
    rag_context: list[dict[str, Any]] = Field(default_factory=list)
    rag_summary: str | None = None


class PatientRecordInput(BaseModel):
    patient_id: str
    drug_id: str
    fill_date: str
    days_supply: int = 30
    status: str = "FILLED"
    condition: str = "Unspecified"
    notes: str = ""
    source: str = "client_submission"


class PatientRecordIngestResponse(BaseModel):
    success: bool
    record_id: str
    patient_id: str
    message: str
    vector_id: str | None = None


class BatchIngestRequest(BaseModel):
    records: list[PatientRecordInput]


class BatchIngestResponse(BaseModel):
    success: bool
    records_ingested: int
    message: str


class RAGQueryRequest(BaseModel):
    patient_id: str
    query: str | None = None
    top_k: int = 5
    condition: str | None = None
    drug_id: str | None = None


class RAGMatchItem(BaseModel):
    id: str
    score: float
    patient_id: str
    drug_id: str
    fill_date: str
    days_supply: int
    status: str
    condition: str
    source: str = "dataset"
    text: str = ""
    notes: str = ""


class RAGQueryResponse(BaseModel):
    patient_id: str
    total_matched: int
    matches: list[RAGMatchItem]
    summary: str
    adherence_metrics: MedicationHistory | None = None
