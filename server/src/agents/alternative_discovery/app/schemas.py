from pydantic import BaseModel, Field
from typing import List, Optional

class OriginalDrug(BaseModel):
    drug_id: str
    drug_name: str
    therapeutic_class: str
    indication: str

class Constraints(BaseModel):
    insurance_plan_id: Optional[str] = None
    generic_only: bool = False
    same_class_preferred: bool = True

class AlternativeDiscoveryInput(BaseModel):
    original_drug: OriginalDrug
    patient_id: str
    constraints: Constraints

class Candidate(BaseModel):
    drug_id: str
    drug_name: str
    relationship: str = Field(description="Must be strictly one of: 'SAME_CLASS', 'THERAPEUTIC_ALTERNATIVE', or 'SAME_INDICATION'")

class AlternativeDiscoveryOutput(BaseModel):
    original_drug: str
    candidates: List[Candidate]
    candidate_count: int
