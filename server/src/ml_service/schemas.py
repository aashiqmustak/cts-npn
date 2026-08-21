from dataclasses import dataclass, field
from typing import Any


@dataclass
class AdherenceRequest:
    previous_pdc_180: float = 0.8
    previous_pdc_365: float = 0.8
    refill_gap_days_90: int = 0
    refill_gap_days_180: int = 0
    access_friction_score: float = 0.0
    out_of_pocket_cost: float = 0.0
    estimated_patient_cost: float = 0.0
    concurrent_medications_count: int = 1
    current_medication_count: int = 1
    prior_medication_count: int = 0
    active_chronic_count: int = 1
    formulary_tier: int = 1
    prior_auth_required: int = 0
    access_friction_level: str = "LOW"  # "LOW", "MEDIUM", "HIGH"


@dataclass
class AdherenceResponse:
    prediction: str
    risk_scores: dict[str, float]
    primary_risk_level: str


@dataclass
class AbandonmentRequest:
    out_of_pocket_cost: float = 0.0
    estimated_patient_cost: float = 0.0
    formulary_tier: int = 1
    prior_auth_required: int = 0
    refill_gap_days_90: int = 0
    previous_pdc_180: float = 0.8
    active_chronic_count: int = 1
    access_friction_score: float = 0.0
    features: dict[str, Any] | None = field(default_factory=dict)


@dataclass
class AbandonmentResponse:
    abandonment_probability: float
    is_abandonment_likely: bool
    risk_category: str


@dataclass
class HealthResponse:
    status: str
    models_loaded: dict[str, bool]
    version: str
