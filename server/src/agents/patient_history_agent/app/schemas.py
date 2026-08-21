from pydantic import BaseModel


class PatientHistoryRequest(BaseModel):
    patient_id: str
    drug_id: str
    lookback_days: int = 365


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
