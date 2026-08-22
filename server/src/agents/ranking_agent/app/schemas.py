from typing import Any, Literal

from pydantic import BaseModel, Field, model_validator

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
    egfr: float | None = Field(
        default=None, description="Estimated glomerular filtration rate"
    )
    creatinine: float | None = None
    unit: str = "mL/min/1.73m2"
    status: str | None = None


class HepaticFunction(BaseModel):
    status: (
        Literal[
            "NORMAL",
            "MILD_IMPAIRMENT",
            "MODERATE_IMPAIRMENT",
            "SEVERE_IMPAIRMENT",
            "UNKNOWN",
        ]
        | str
    ) = "UNKNOWN"
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
    renal_status: str | None = None
    hepatic_status: str | None = None
    pregnancy_status: (
        Literal["PREGNANT", "NOT_PREGNANT", "UNKNOWN", "NOT_APPLICABLE"] | None
    ) = "UNKNOWN"
    indication: Indication | None = None

    @model_validator(mode="before")
    @classmethod
    def normalize_context(cls, values: Any) -> Any:
        if isinstance(values, dict):
            if "allergies" in values and isinstance(values["allergies"], list):
                values["allergies"] = [
                    {"substance": item} if isinstance(item, str) else item
                    for item in values["allergies"]
                ]
            if "conditions" in values and isinstance(values["conditions"], list):
                values["conditions"] = [
                    {"name": item} if isinstance(item, str) else item
                    for item in values["conditions"]
                ]
            if "current_medications" in values and isinstance(
                values["current_medications"], list
            ):
                values["current_medications"] = [
                    {"drug_name": item} if isinstance(item, str) else item
                    for item in values["current_medications"]
                ]
            if (
                "renal_status" in values
                and values.get("renal_status")
                and not values.get("renal_function")
            ):
                values["renal_function"] = {"status": values["renal_status"]}
            if (
                "hepatic_status" in values
                and values.get("hepatic_status")
                and not values.get("hepatic_function")
            ):
                values["hepatic_function"] = {"status": values["hepatic_status"]}
        return values


class CandidateDrug(BaseModel):
    drug_id: str
    drug_name: str
    rxnorm_id: str | None = None
    ingredient: str | None = None
    strength: str | None = None
    dosage_form: str | None = None
    route: str | None = None
    formulary_tier: int | None = Field(
        default=1, description="Insurance formulary tier (1-4)"
    )
    estimated_cost: float | None = Field(
        default=15.0, description="Estimated out-of-pocket cost"
    )
    relationship: str | None = Field(
        default="SAME_CLASS",
        description="Relationship type: SAME_CLASS, THERAPEUTIC_ALTERNATIVE, SAME_INDICATION",
    )


class RankingInput(BaseModel):
    patient_id: str
    candidate_drugs: list[CandidateDrug]
    patient_context: PatientContext
    original_drug_id: str | None = None
    original_drug_name: str | None = None


# Backwards compatibility alias
ClinicalSafetyInput = RankingInput


class SafetyChecks(BaseModel):
    allergy: SafetyStatus = "PASS"
    drug_interaction: SafetyStatus = "PASS"
    drug_disease: SafetyStatus = "PASS"
    renal: SafetyStatus = "PASS"
    hepatic: SafetyStatus = "PASS"
    age: SafetyStatus = "PASS"
    indication: SafetyStatus = "PASS"
    pregnancy: SafetyStatus | None = None


class SafetyIssue(BaseModel):
    type: str
    severity: RiskSeverity
    reason: str
    source: str | None = None
    source_section: str | None = None


class ScoreBreakdown(BaseModel):
    safety_score: float = Field(
        ..., description="Score for clinical safety profile (max 40)"
    )
    class_alignment_score: float = Field(
        ..., description="Score for therapeutic class/relationship match (max 25)"
    )
    affordability_score: float = Field(
        ..., description="Score for formulary tier and cost (max 20)"
    )
    adherence_simplicity_score: float = Field(
        ..., description="Score for regimen simplicity (max 15)"
    )
    total_score: float = Field(
        ..., description="Composite overall ranking score (0-100)"
    )


class RankedCandidate(BaseModel):
    rank: int = Field(
        ..., description="1-based rank position among eligible candidates"
    )
    drug_id: str
    drug_name: str
    eligible: bool = True
    safety_status: SafetyStatus = "PASS"
    total_score: float = Field(..., description="Composite score between 0 and 100")
    score_breakdown: ScoreBreakdown | None = None
    checks: SafetyChecks = Field(default_factory=SafetyChecks)
    advantages: list[str] = Field(default_factory=list)
    clinical_rationale: str = Field(
        ..., description="Clinical justification for this candidate's ranking"
    )


# Backwards compatibility alias
EligibleCandidate = RankedCandidate


class RejectedCandidate(BaseModel):
    drug_id: str
    drug_name: str | None = None
    eligible: bool = False
    safety_status: Literal["REJECT"] = "REJECT"
    reason: str
    reasons: list[SafetyIssue] = Field(default_factory=list)

    @model_validator(mode="before")
    @classmethod
    def normalize_reasons(cls, values: Any) -> Any:
        if isinstance(values, dict):
            if "reasons" in values and values["reasons"] and not values.get("reason"):
                first = values["reasons"][0]
                if isinstance(first, SafetyIssue):
                    values["reason"] = first.reason
                elif isinstance(first, dict):
                    values["reason"] = first.get("reason", "")
                elif isinstance(first, str):
                    values["reason"] = first
            elif (
                "reason" in values
                and values.get("reason")
                and not values.get("reasons")
            ):
                values["reasons"] = [
                    {
                        "type": "clinical_check",
                        "severity": "HIGH",
                        "reason": values["reason"],
                    }
                ]
            elif not values.get("reason") and not values.get("reasons"):
                values["reason"] = "Clinical safety constraint violation"
                values["reasons"] = [
                    {
                        "type": "clinical_check",
                        "severity": "HIGH",
                        "reason": values["reason"],
                    }
                ]
        return values


class ReviewCandidate(BaseModel):
    drug_id: str
    drug_name: str | None = None
    eligible: bool = False
    safety_status: Literal["REVIEW"] = "REVIEW"
    reason: str
    reasons: list[SafetyIssue] = Field(default_factory=list)
    review_instructions: str = Field(
        default="Physician consultation recommended before dispensing."
    )

    @model_validator(mode="before")
    @classmethod
    def normalize_review(cls, values: Any) -> Any:
        if isinstance(values, dict):
            if "reasons" in values and values["reasons"] and not values.get("reason"):
                first = values["reasons"][0]
                if isinstance(first, SafetyIssue):
                    values["reason"] = first.reason
                elif isinstance(first, dict):
                    values["reason"] = first.get("reason", "")
                elif isinstance(first, str):
                    values["reason"] = first
            elif (
                "reason" in values
                and values.get("reason")
                and not values.get("reasons")
            ):
                values["reasons"] = [
                    {
                        "type": "clinical_check",
                        "severity": "MODERATE",
                        "reason": values["reason"],
                    }
                ]
        return values


class Evidence(BaseModel):
    source: str
    section: str | None = None
    document_id: str | None = None
    source_url: str | None = None
    version: str | None = None


class RankingOutput(BaseModel):
    patient_id: str
    top_recommended_drug: RankedCandidate | None = Field(
        None,
        description="The #1 ranked top alternate drug selected from candidate drugs",
    )
    eligible_candidates: list[RankedCandidate] = Field(
        default_factory=list,
        description="All eligible candidate drugs ordered by ranking score",
    )
    rejected_candidates: list[RejectedCandidate] = Field(
        default_factory=list,
        description="Candidate drugs disqualified with explicit rejection reasons",
    )
    review_required: list[ReviewCandidate] = Field(
        default_factory=list,
        description="Candidates requiring physician/clinical review",
    )
    ranking_summary: str = Field(
        ...,
        description="Executive summary explaining the top drug selection and why rejected alternatives were disqualified",
    )
    evidence: list[Evidence] = Field(default_factory=list)
    overall_status: SafetyStatus = "REVIEW"


# Backwards compatibility alias
ClinicalSafetyOutput = RankingOutput

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
    "RankedCandidate",
    "RankingInput",
    "RankingOutput",
    "RejectedCandidate",
    "RenalFunction",
    "ReviewCandidate",
    "RiskSeverity",
    "SafetyChecks",
    "SafetyIssue",
    "SafetyStatus",
    "ScoreBreakdown",
]
