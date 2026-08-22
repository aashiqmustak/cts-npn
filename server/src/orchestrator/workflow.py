import datetime
import logging

from agents.alternative_discovery.app.agent import AlternativeDiscoveryAgent
from agents.alternative_discovery.app.repository import AlternativeDiscoveryRepository
from agents.alternative_discovery.app.schemas import (
    AlternativeDiscoveryInput,
    Constraints,
    OriginalDrug,
)
from agents.alternative_discovery.app.service import AlternativeDiscoveryService
from agents.formulary_agent.app.agent import FormularyAgent
from agents.formulary_agent.app.repository import FormularyRepository
from agents.formulary_agent.app.schemas import FormularyRequest, FormularyResponse
from agents.formulary_agent.app.service import FormularyService
from agents.pa_agent.app.agent import PAAgent
from agents.pa_agent.app.repository import PARepository
from agents.pa_agent.app.schemas import ClinicalInformation, PARequest, PAResponse
from agents.pa_agent.app.service import PAService
from agents.patient_history_agent.app.agent import PatientHistoryAgent
from agents.patient_history_agent.app.repository import PatientHistoryRepository
from agents.patient_history_agent.app.schemas import (
    PatientHistoryRequest,
    PatientHistoryResponse,
)
from agents.patient_history_agent.app.service import PatientHistoryService
from agents.prescription_agent.app.agent import PrescriptionAgent
from agents.prescription_agent.app.schemas import PrescriptionOutput
from agents.ranking_agent.app.agent import RankingAgent
from agents.ranking_agent.app.schemas import (
    CandidateDrug,
    RankingInput,
    RankingOutput,
)
from agents.ranking_agent.app.service import RankingService
from ml.service import MLPredictorService

from .schemas import PrescriptionEvaluationRequest, TherapyEvaluationReport

logger = logging.getLogger(__name__)


def infer_clinical_class_and_indication(drug_text: str) -> tuple[str, str]:
    d = (drug_text or "").lower()
    if any(
        k in d
        for k in [
            "entresto",
            "sacubitril",
            "valsartan",
            "lisinopril",
            "losartan",
            "amlodipine",
            "telmisartan",
            "enalapril",
            "ramipril",
            "hydrochlorothiazide",
            "metoprolol",
            "atenolol",
            "carvedilol",
            "blood pressure",
            "hypertens",
            "heart failure",
        ]
    ):
        return "Antihypertensive", "Hypertension"
    elif any(
        k in d
        for k in [
            "metformin",
            "januvia",
            "jardiance",
            "glipizide",
            "glimepiride",
            "sitagliptin",
            "empagliflozin",
            "dapagliflozin",
            "insulin",
            "pioglitazone",
            "diabet",
            "glycemic",
        ]
    ):
        return "Antidiabetic", "Type 2 Diabetes Mellitus"
    elif any(
        k in d
        for k in [
            "atorvastatin",
            "rosuvastatin",
            "simvastatin",
            "crestor",
            "lipitor",
            "pravastatin",
            "ezetimibe",
            "statin",
            "cholesterol",
            "lipid",
        ]
    ):
        return "Lipid_lowering", "Hyperlipidemia"
    elif any(
        k in d
        for k in [
            "advair",
            "albuterol",
            "fluticasone",
            "salmeterol",
            "symbicort",
            "budesonide",
            "montelukast",
            "ipratropium",
            "inhaler",
            "asthma",
            "copd",
        ]
    ):
        return "Respiratory", "Asthma / COPD Maintenance"
    elif any(
        k in d
        for k in [
            "plavix",
            "clopidogrel",
            "brilinta",
            "ticagrelor",
            "warfarin",
            "eliquis",
            "apixaban",
            "xarelto",
            "thrombo",
        ]
    ):
        return "Cardiovascular", "Atrial Fibrillation / DVT Prevention"
    elif any(
        k in d
        for k in [
            "omeprazole",
            "pantoprazole",
            "famotidine",
            "ondansetron",
            "esomeprazole",
            "gerd",
            "acid",
        ]
    ):
        return "Gastrointestinal", "GERD / Peptic Ulcer Disease"
    elif any(
        k in d
        for k in [
            "amoxicillin",
            "azithromycin",
            "ciprofloxacin",
            "doxycycline",
            "cephalexin",
            "antibiotic",
        ]
    ):
        return "Antibiotic", "Bacterial Infection"
    return "Antihypertensive", "Hypertension"


class MultiAgentOrchestrator:
    """Coordinates the 7-stage Clinical Decision Support multi-agent workflow."""

    def __init__(self):
        # 1. Prescription Normalizer
        self.prescription_agent = PrescriptionAgent()

        # 2. Formulary Lookup
        self.formulary_repo = FormularyRepository()
        self.formulary_agent = FormularyAgent(FormularyService(self.formulary_repo))

        # 3. Prior Authorization Evaluator
        self.pa_repo = PARepository()
        self.pa_agent = PAAgent(PAService(self.pa_repo))

        # 4. Patient History Claims & Adherence Analyzer
        self.history_repo = PatientHistoryRepository()
        self.history_agent = PatientHistoryAgent(
            PatientHistoryService(self.history_repo)
        )

        # 5. Machine Learning Predictor (Adherence + Abandonment)
        self.ml_service = MLPredictorService()

        # 6. Alternative Discovery Agent
        self.alt_repo = AlternativeDiscoveryRepository()
        self.alt_agent = AlternativeDiscoveryAgent(
            AlternativeDiscoveryService(self.alt_repo)
        )

        # 7. Ranking Agent (Multi-factor scoring + Top 1 selection + Rejection explanations)
        self.ranking_agent = RankingAgent(RankingService())

    def evaluate_prescription(
        self, request: PrescriptionEvaluationRequest
    ) -> TherapyEvaluationReport:
        patient_id = request.patient_id

        # -------------------------------------------------------------
        # STEP 1: Prescription Normalization
        # -------------------------------------------------------------
        norm_rx: PrescriptionOutput = self.prescription_agent.process(
            patient_id=patient_id,
            prescription_text=request.prescription_text,
            doctor_id=request.doctor_id,
        )
        canonical_drug_name = norm_rx.drug.name or request.prescription_text
        _rxnorm_id = norm_rx.drug.rxnorm_id or "RX_NORM_UNKNOWN"

        inferred_class, inferred_ind = infer_clinical_class_and_indication(
            canonical_drug_name + " " + request.prescription_text
        )

        # Attempt to map to a dataset drug_id
        matched_drug_id = None
        matched_therapeutic_class = None
        matched_indication = None

        for rec in self.formulary_repo.records:
            d_name = (rec.get("drug_name") or "").lower()
            c_name = canonical_drug_name.lower()
            if d_name and (c_name in d_name or d_name in c_name):
                matched_drug_id = rec.get("drug_id")
                matched_therapeutic_class = rec.get("therapeutic_class")
                matched_indication = rec.get("indication")
                break

        if not matched_drug_id:
            for rec in self.formulary_repo.records:
                if rec.get("therapeutic_class") == inferred_class:
                    matched_drug_id = rec.get("drug_id")
                    matched_therapeutic_class = rec.get("therapeutic_class")
                    matched_indication = rec.get("indication")
                    break

        matched_drug_id = matched_drug_id or "DRUG_HYP_01"
        final_class = matched_therapeutic_class or inferred_class
        final_ind = (
            request.patient_context.indication.name
            if request.patient_context.indication
            else (
                request.patient_context.conditions[0].name
                if request.patient_context.conditions
                and request.patient_context.conditions[0].name
                not in ("Hyperlipidemia", "Diagnosed Indication")
                else (matched_indication or inferred_ind)
            )
        )

        # -------------------------------------------------------------
        # STEP 2: Formulary Coverage Check
        # -------------------------------------------------------------
        form_req = FormularyRequest(
            patient_id=patient_id,
            drug_id=matched_drug_id,
            insurance_plan_id=request.insurance_plan_id,
            pharmacy_id=request.pharmacy_id,
            date=datetime.datetime.now(datetime.UTC).date().isoformat(),
        )
        form_res: FormularyResponse = self.formulary_agent.process_request(form_req)

        # -------------------------------------------------------------
        # STEP 3: Patient History Retrieval
        # -------------------------------------------------------------
        hist_req = PatientHistoryRequest(
            patient_id=patient_id,
            drug_id=matched_drug_id,
            lookback_days=365,
        )
        hist_res: PatientHistoryResponse = self.history_agent.process_request(hist_req)

        # -------------------------------------------------------------
        # STEP 4: Prior Authorization Evaluation
        # -------------------------------------------------------------
        pa_required = form_res.coverage.pa_required
        pa_res: PAResponse | None = None
        if pa_required:
            pa_req = PARequest(
                patient_id=patient_id,
                drug_id=matched_drug_id,
                insurance_plan_id=request.insurance_plan_id,
                indication=request.patient_context.indication.name
                if request.patient_context.indication
                else "Hyperlipidemia",
                clinical_information=ClinicalInformation(
                    diagnosis=request.patient_context.conditions[0].name
                    if request.patient_context.conditions
                    else "Diagnosed Indication"
                ),
            )
            pa_res = self.pa_agent.process_request(pa_req)

        # -------------------------------------------------------------
        # STEP 5: ML Risk Predictions (Adherence + Abandonment)
        # -------------------------------------------------------------
        ml_res = self.ml_service.predict_combined(
            patient_history_dict=hist_res.model_dump(),
            formulary_dict=form_res.model_dump(),
            pa_required=pa_required,
        )

        # -------------------------------------------------------------
        # STEP 6: Decision Branch & Alternative Discovery
        # -------------------------------------------------------------
        # Check if alternative discovery is needed
        trigger_alternatives = (
            request.force_alternative_discovery
            or ml_res.access_barrier_flag
            or not form_res.coverage.covered
            or form_res.coverage.tier > 2
            or (pa_res is not None and pa_res.pa_status == "DENIED")
        )

        candidates_for_ranking: list[CandidateDrug] = []
        discovered_alternatives = []

        # Add the original drug as Candidate 1
        candidates_for_ranking.append(
            CandidateDrug(
                drug_id=matched_drug_id,
                drug_name=canonical_drug_name,
                dosage_form=norm_rx.drug.route or "Oral Tablet",
                strength=norm_rx.drug.strength or "Standard Dose",
                formulary_tier=form_res.coverage.tier or 1,
                estimated_cost=float(form_res.coverage.patient_cost or 15.0),
                relationship="ORIGINAL_PRESCRIBED",
            )
        )

        if trigger_alternatives:
            alt_input = AlternativeDiscoveryInput(
                patient_id=patient_id,
                original_drug=OriginalDrug(
                    drug_id=matched_drug_id,
                    drug_name=canonical_drug_name,
                    therapeutic_class=final_class,
                    indication=final_ind,
                ),
                constraints=Constraints(
                    generic_only=request.generic_only,
                    same_class_preferred=request.same_class_preferred,
                ),
            )
            alt_output = self.alt_agent.process_request(alt_input)
            discovered_alternatives = alt_output.candidates

            for alt in discovered_alternatives:
                candidates_for_ranking.append(
                    CandidateDrug(
                        drug_id=alt.drug_id,
                        drug_name=alt.drug_name,
                        dosage_form="Oral Tablet",
                        formulary_tier=1,
                        estimated_cost=10.0,
                        relationship=alt.relationship,
                    )
                )

        # -------------------------------------------------------------
        # STEP 7: Ranking Agent (Safety Evaluation + Multi-Factor Ranking)
        # -------------------------------------------------------------
        ranking_inp = RankingInput(
            patient_id=patient_id,
            candidate_drugs=candidates_for_ranking,
            patient_context=request.patient_context,
            original_drug_id=matched_drug_id,
            original_drug_name=canonical_drug_name,
        )
        ranking_res: RankingOutput = self.ranking_agent.process_request(ranking_inp)

        # -------------------------------------------------------------
        # Final Decision Synthesis
        # -------------------------------------------------------------
        top_drug = ranking_res.top_recommended_drug

        if (
            top_drug
            and top_drug.drug_id == matched_drug_id
            and not trigger_alternatives
        ):
            decision = "DISPENSE_PRIMARY"
            msg = f"Primary medication '{canonical_drug_name}' passed all safety checks, is covered under formulary (Tier {form_res.coverage.tier}), and shows low abandonment risk."
        elif top_drug and top_drug.drug_id != matched_drug_id:
            decision = "SWITCH_TO_TOP_ALTERNATIVE"
            msg = f"Recommended switching to top alternative '{top_drug.drug_name}' (Rank 1, Score: {top_drug.total_score}/100) due to superior safety, lower cost, or improved access profile."
        elif pa_required and (pa_res is None or pa_res.pa_status != "APPROVED"):
            decision = "SUBMIT_PRIOR_AUTH"
            msg = f"Prior authorization is required for '{canonical_drug_name}'. Clinical documentation should be submitted."
        else:
            decision = "PHYSICIAN_REVIEW_REQUIRED"
            msg = "Prescription evaluation requires physician/pharmacist clinical review before dispensing."

        return TherapyEvaluationReport(
            patient_id=patient_id,
            action_decision=decision,
            summary_message=msg,
            top_recommended_drug=top_drug,
            normalized_prescription=norm_rx,
            formulary_coverage=form_res,
            patient_history=hist_res,
            prior_authorization=pa_res,
            ml_risk_assessment=ml_res,
            alternatives_discovered=discovered_alternatives,
            ranking_result=ranking_res,
            rejected_alternatives=ranking_res.rejected_candidates,
            review_required_alternatives=ranking_res.review_required,
        )
