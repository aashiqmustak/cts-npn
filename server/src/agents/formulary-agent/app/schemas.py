from typing import Optional
from pydantic import BaseModel


class Insurance(BaseModel):
    payer_id: str
    plan_id: str


class Prescription(BaseModel):
    drug_id: str
    drug_name: str
    dose: str
    frequency: str
    quantity: int
    days_supply: int


class Pharmacy(BaseModel):
    pharmacy_id: str
    in_network: bool


class FormularyRequest(BaseModel):
    patient_id: str
    insurance: Insurance
    prescription: Prescription
    pharmacy: Pharmacy


class Coverage(BaseModel):
    covered: bool
    status: str
    formulary_tier: Optional[int] = None


class Cost(BaseModel):
    copay: Optional[float] = None
    coinsurance: Optional[float] = None
    estimated_out_of_pocket: Optional[float] = None


class Restrictions(BaseModel):
    prior_authorization: bool
    step_therapy: bool
    quantity_limit: bool
    quantity_limit_value: Optional[int] = None


class PharmacyResult(BaseModel):
    in_network: bool
    preferred_pharmacy: bool


class AccessRisk(BaseModel):
    score: float
    level: str


class Drug(BaseModel):
    drug_id: str
    drug_name: str


class FormularyResponse(BaseModel):
    patient_id: str
    drug: Drug
    coverage: Coverage
    cost: Cost
    restrictions: Restrictions
    pharmacy: PharmacyResult
    access_risk: AccessRisk
    alternative_required: bool