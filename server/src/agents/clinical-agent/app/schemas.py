from typing import List, Literal, Optional

from pydantic import BaseModel, Field

SafetyStatus = Literal["PASS", "REVIEW", "REJECT"]
RiskSeverity = Literal["LOW", "MODERATE", "HIGH", "CRITICAL"]


class Allergy(BaseModel):
    substance: str
    reaction: Optional[str] = None
    severity: Optional[RiskSeverity] = None
    status: Literal["ACTIVE", "INACTIVE"] = "ACTIVE"


class Condition(BaseModel):
    code: Optional[str] = None
    name: str
    status: Literal["ACTIVE", "INACTIVE"] = "ACTIVE"


class CurrentMedication(BaseModel):
    drug_name: str
    rxnorm_id: Optional[str] = None
    dose: Optional[str] = None
    route: Optional[str] = None
    frequency: Optional[str] = None
    status: Literal["ACTIVE", "INACTIVE"] = "ACTIVE"


class RenalFunction(BaseModel):
    egfr: Optional[float] = Field(default=None, description="Estimated glomerular filtration rate")
    creatinine: Optional[float] = None
    unit: str = "mL/min/1.73m2"


class HepaticFunction(BaseModel):
    status: Literal["NORMAL", "MILD_IMPAIRMENT", "MODERATE_IMPAIRMENT", "SEVERE_IMPAIRMENT", "UNKNOWN"] = "UNKNOWN"
    ast: Optional[float] = None
    alt: Optional[float] = None
    bilirubin: Optional[float] = None


class Indication(BaseModel):
    code: Optional[str] = None
    name: str


class PatientContext(BaseModel):
    age: int = Field(..., ge=0, le=120)
    sex: Optional[Literal["MALE", "FEMALE", "OTHER", "UNKNOWN"]] = "UNKNOWN"
    allergies: List[Allergy] = Field(default_factory=list)
    conditions: List[Condition] = Field(default_factory=list)
    current_medications: List[CurrentMedication] = Field(default_factory=list)
    renal_function: Optional[RenalFunction] = None
    hepatic_function: Optional[HepaticFunction] = None
    pregnancy_status: Optional[Literal["PREGNANT", "NOT_PREGNANT", "UNKNOWN", "NOT_APPLICABLE"]] = "UNKNOWN"
    indication: Optional[Indication] = None


class CandidateDrug(BaseModel):
    drug_id: str
    drug_name: str
    rxnorm_id: Optional[str] = None
    ingredient: Optional[str] = None
    strength: Optional[str] = None
    dosage_form: Optional[str] = None
    route: Optional[str] = None


class ClinicalSafetyInput(BaseModel):
    patient_id: str
    candidate_drugs: List[CandidateDrug]
    patient_context: PatientContext


class SafetyChecks(BaseModel):
    allergy: SafetyStatus = "REVIEW"
    drug_interaction: SafetyStatus = "REVIEW"
    drug_disease: SafetyStatus = "REVIEW"
    renal: SafetyStatus = "REVIEW"
    hepatic: SafetyStatus = "REVIEW"
    age: SafetyStatus = "REVIEW"
    indication: SafetyStatus = "REVIEW"
    pregnancy: Optional[SafetyStatus] = None


class SafetyIssue(BaseModel):
    type: str
    severity: RiskSeverity
    reason: str
    source: Optional[str] = None
    source_section: Optional[str] = None


class EligibleCandidate(BaseModel):
    drug_id: str
    drug_name: Optional[str] = None
    eligible: bool
    safety_status: SafetyStatus
    checks: SafetyChecks
    warnings: List[SafetyIssue] = Field(default_factory=list)


class RejectedCandidate(BaseModel):
    drug_id: str
    drug_name: Optional[str] = None
    eligible: bool = False
    safety_status: Literal["REJECT"] = "REJECT"
    reasons: List[SafetyIssue]


class ReviewCandidate(BaseModel):
    drug_id: str
    drug_name: Optional[str] = None
    eligible: bool = False
    safety_status: Literal["REVIEW"] = "REVIEW"
    reasons: List[SafetyIssue]


class Evidence(BaseModel):
    source: str
    section: Optional[str] = None
    document_id: Optional[str] = None
    source_url: Optional[str] = None
    version: Optional[str] = None


class ClinicalSafetyOutput(BaseModel):
    patient_id: str
    eligible_candidates: List[EligibleCandidate] = Field(default_factory=list)
    rejected_candidates: List[RejectedCandidate] = Field(default_factory=list)
    review_required: List[ReviewCandidate] = Field(default_factory=list)
    evidence: List[Evidence] = Field(default_factory=list)
    overall_status: SafetyStatus = "REVIEW"


__all__ = [
    "SafetyStatus",
    "RiskSeverity",
    "Allergy",
    "Condition",
    "CurrentMedication",
    "RenalFunction",
    "HepaticFunction",
    "Indication",
    "PatientContext",
    "CandidateDrug",
    "ClinicalSafetyInput",
    "SafetyChecks",
    "SafetyIssue",
    "EligibleCandidate",
    "RejectedCandidate",
    "ReviewCandidate",
    "Evidence",
    "ClinicalSafetyOutput",
]
