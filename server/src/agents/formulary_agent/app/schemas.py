from datetime import date

from pydantic import BaseModel


class FormularyRequest(BaseModel):
    patient_id: str
    drug_id: str
    insurance_plan_id: str
    pharmacy_id: str
    date: date | str


class Coverage(BaseModel):
    covered: bool
    tier: int | None = None
    patient_cost: float | int | None = None
    pa_required: bool = False
    step_therapy_required: bool = False
    quantity_limit: bool = False
    in_network: bool = False


class FormularyResponse(BaseModel):
    drug_id: str
    plan_id: str
    coverage: Coverage
    decision: str
    source: str
