from typing import Literal

from pydantic import BaseModel, Field

RiskLevel = Literal["LOW", "MEDIUM", "HIGH"]


class AdherencePredictionInput(BaseModel):
    patient_id: str | None = None
    drug_id: str | None = None
    previous_pdc_180: float = Field(default=0.85, ge=0.0, le=1.0)
    previous_pdc_365: float = Field(default=0.85, ge=0.0, le=1.0)
    refill_gap_days_90: int = Field(default=5, ge=0)
    refill_gap_days_180: int = Field(default=10, ge=0)
    access_friction_score: float = Field(default=0.2, ge=0.0)
    out_of_pocket_cost: float = Field(default=15.0, ge=0.0)
    estimated_patient_cost: float = Field(default=15.0, ge=0.0)
    concurrent_medications_count: int = Field(default=2, ge=0)
    current_medication_count: int = Field(default=2, ge=0)
    prior_medication_count: int = Field(default=3, ge=0)
    active_chronic_count: int = Field(default=1, ge=0)
    formulary_tier: int = Field(default=1, ge=1, le=4)
    prior_auth_required: int = Field(default=0, ge=0, le=1)
    access_friction_level: Literal["LOW", "MEDIUM", "HIGH"] = "LOW"


class AdherencePredictionOutput(BaseModel):
    predicted_risk_level: RiskLevel
    adherence_score: float = Field(
        ..., description="Adherence probability score between 0.0 and 1.0"
    )
    class_probabilities: dict[str, float] = Field(default_factory=dict)
    key_drivers: list[str] = Field(default_factory=list)


class AbandonmentPredictionInput(BaseModel):
    patient_id: str | None = None
    drug_id: str | None = None
    drug_name: str | None = None
    out_of_pocket_cost: float = Field(default=25.0, ge=0.0)
    estimated_patient_cost: float = Field(default=25.0, ge=0.0)
    formulary_tier: int = Field(default=1, ge=1, le=4)
    prior_auth_required: int = Field(default=0, ge=0, le=1)
    refill_gap_days_90: int = Field(default=5, ge=0)
    previous_pdc_180: float = Field(default=0.85, ge=0.0, le=1.0)
    access_friction_score: float = Field(default=0.2, ge=0.0)
    prior_abandonment_count: int = Field(default=0, ge=0)


class AbandonmentPredictionOutput(BaseModel):
    abandonment_risk_level: RiskLevel
    abandonment_probability: float = Field(
        ..., description="Predicted abandonment likelihood (0.0 to 1.0)"
    )
    optimal_threshold: float = Field(default=0.6949)
    will_abandon: bool
    risk_drivers: list[str] = Field(default_factory=list)


class CombinedMLRiskOutput(BaseModel):
    adherence: AdherencePredictionOutput
    abandonment: AbandonmentPredictionOutput
    overall_risk_status: RiskLevel
    access_barrier_flag: bool = Field(
        ...,
        description="True if high cost, prior auth, or high abandonment risk requires alternative discovery",
    )
    clinical_notes: list[str] = Field(default_factory=list)


__all__ = [
    "AbandonmentPredictionInput",
    "AbandonmentPredictionOutput",
    "AdherencePredictionInput",
    "AdherencePredictionOutput",
    "CombinedMLRiskOutput",
    "RiskLevel",
]
