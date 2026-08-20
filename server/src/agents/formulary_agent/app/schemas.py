from datetime import date
from typing import Optional, Union
from pydantic import BaseModel, Field


class FormularyRequest(BaseModel):
    patient_id: str
    drug_id: str
    insurance_plan_id: str
    pharmacy_id: str
    date: Union[date, str]


class Coverage(BaseModel):
    covered: bool
    tier: Optional[int] = None
    patient_cost: Optional[Union[float, int]] = None
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