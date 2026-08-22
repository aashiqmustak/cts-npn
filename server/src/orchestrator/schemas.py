from typing import Literal

from agents.alternative_discovery.app.schemas import Candidate
from agents.formulary_agent.app.schemas import FormularyResponse
from agents.pa_agent.app.schemas import PAResponse
from agents.patient_history_agent.app.schemas import PatientHistoryResponse
from agents.prescription_agent.app.schemas import PrescriptionOutput
from agents.ranking_agent.app.schemas import (
    PatientContext,
    RankedCandidate,
    RankingOutput,
    RejectedCandidate,
    ReviewCandidate,
)
from ml.schemas import CombinedMLRiskOutput
from pydantic import BaseModel, Field


class PrescriptionEvaluationRequest(BaseModel):
    patient_id: str
    prescription_text: str
    doctor_id: str = "DOC_001"
    insurance_plan_id: str = "PLAN_COMM_01"
    pharmacy_id: str = "PHARM_001"
    patient_context: PatientContext
    force_alternative_discovery: bool = False
    same_class_preferred: bool = True
    generic_only: bool = False


class TherapyEvaluationReport(BaseModel):
    patient_id: str
    action_decision: Literal[
        "DISPENSE_PRIMARY",
        "SWITCH_TO_TOP_ALTERNATIVE",
        "SUBMIT_PRIOR_AUTH",
        "PHYSICIAN_REVIEW_REQUIRED",
    ]
    summary_message: str
    top_recommended_drug: RankedCandidate | None = None
    normalized_prescription: PrescriptionOutput
    formulary_coverage: FormularyResponse
    patient_history: PatientHistoryResponse
    prior_authorization: PAResponse | None = None
    ml_risk_assessment: CombinedMLRiskOutput
    alternatives_discovered: list[Candidate] = Field(default_factory=list)
    ranking_result: RankingOutput
    rejected_alternatives: list[RejectedCandidate] = Field(default_factory=list)
    review_required_alternatives: list[ReviewCandidate] = Field(default_factory=list)


__all__ = [
    "PrescriptionEvaluationRequest",
    "TherapyEvaluationReport",
]
