from typing import Literal

from pydantic import BaseModel, Field

SafetyStatus = Literal["PASS", "REVIEW", "REJECT"]
RiskSeverity = Literal["LOW", "MODERATE", "HIGH", "CRITICAL"]


class Allergy(BaseModel):
    substance: str
    reaction: str | None = None
    severity: RiskSeverity | None = None
    status: Literal["ACTIVE", "INACTIVE"] = "ACTIVE"


class Condition(BaseModel):
    code: str | None = None
    name: str
    status: Literal["ACTIVE", "INACTIVE"] = "ACTIVE"


class CurrentMedication(BaseModel):
    drug_name: str
    rxnorm_id: str | None = None
    dose: str | None = None
    route: str | None = None
    frequency: str | None = None
    status: Literal["ACTIVE", "INACTIVE"] = "ACTIVE"


class RenalFunction(BaseModel):
    egfr: float | None = Field(default=None, description="Estimated glomerular filtration rate")
    creatinine: float | None = None
    unit: str = "mL/min/1.73m2"


class HepaticFunction(BaseModel):
    status: Literal["NORMAL", "MILD_IMPAIRMENT", "MODERATE_IMPAIRMENT", "SEVERE_IMPAIRMENT", "UNKNOWN"] = "UNKNOWN"
    ast: float | None = None
    alt: float | None = None
    bilirubin: float | None = None


class Indication(BaseModel):
    code: str | None = None
    name: str


class PatientContext(BaseModel):
    age: int = Field(..., ge=0, le=120)
    sex: Literal["MALE", "FEMALE", "OTHER", "UNKNOWN"] | None = "UNKNOWN"
    allergies: list[Allergy] = Field(default_factory=list)
    conditions: list[Condition] = Field(default_factory=list)
    current_medications: list[CurrentMedication] = Field(default_factory=list)
    renal_function: RenalFunction | None = None
    hepatic_function: HepaticFunction | None = None
    pregnancy_status: Literal["PREGNANT", "NOT_PREGNANT", "UNKNOWN", "NOT_APPLICABLE"] | None = "UNKNOWN"
    indication: Indication | None = None


class CandidateDrug(BaseModel):
    drug_id: str
    drug_name: str
    rxnorm_id: str | None = None
    ingredient: str | None = None
    strength: str | None = None
    dosage_form: str | None = None
    route: str | None = None


class ClinicalSafetyInput(BaseModel):
    patient_id: str
    candidate_drugs: list[CandidateDrug]
    patient_context: PatientContext


class SafetyChecks(BaseModel):
    allergy: SafetyStatus = "REVIEW"
    drug_interaction: SafetyStatus = "REVIEW"
    drug_disease: SafetyStatus = "REVIEW"
    renal: SafetyStatus = "REVIEW"
    hepatic: SafetyStatus = "REVIEW"
    age: SafetyStatus = "REVIEW"
    indication: SafetyStatus = "REVIEW"
    pregnancy: SafetyStatus | None = None


class SafetyIssue(BaseModel):
    type: str
    severity: RiskSeverity
    reason: str
    source: str | None = None
    source_section: str | None = None


class EligibleCandidate(BaseModel):
    drug_id: str
    drug_name: str | None = None
    eligible: bool
    safety_status: SafetyStatus
    checks: SafetyChecks
    warnings: list[SafetyIssue] = Field(default_factory=list)


class RejectedCandidate(BaseModel):
    drug_id: str
    drug_name: str | None = None
    eligible: bool = False
    safety_status: Literal["REJECT"] = "REJECT"
    reasons: list[SafetyIssue]


class ReviewCandidate(BaseModel):
    drug_id: str
    drug_name: str | None = None
    eligible: bool = False
    safety_status: Literal["REVIEW"] = "REVIEW"
    reasons: list[SafetyIssue]


class Evidence(BaseModel):
    source: str
    section: str | None = None
    document_id: str | None = None
    source_url: str | None = None
    version: str | None = None


class ClinicalSafetyOutput(BaseModel):
    patient_id: str
    eligible_candidates: list[EligibleCandidate] = Field(default_factory=list)
    rejected_candidates: list[RejectedCandidate] = Field(default_factory=list)
    review_required: list[ReviewCandidate] = Field(default_factory=list)
    evidence: list[Evidence] = Field(default_factory=list)
    overall_status: SafetyStatus = "REVIEW"


__all__ = [
    "Allergy",
    "CandidateDrug",
    "ClinicalSafetyInput",
    "ClinicalSafetyOutput",
    "Condition",
    "CurrentMedication",
    "EligibleCandidate",
    "Evidence",
    "HepaticFunction",
    "Indication",
    "PatientContext",
    "RejectedCandidate",
    "RenalFunction",
    "ReviewCandidate",
    "RiskSeverity",
    "SafetyChecks",
    "SafetyIssue",
    "SafetyStatus",
]
