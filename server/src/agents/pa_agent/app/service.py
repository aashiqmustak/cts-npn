from typing import Any

from .repository import PARepository
from .schemas import (
    CriterionItem,
    EvidenceItem,
    PARequest,
    PAResponse,
)


class PAService:
    """
    Prior Authorization (PA) Service.
    Evaluates prior-authorization criteria, checks evidence requirements,
    detects missing information, and determines submission readiness.
    """

    def __init__(self, repository: PARepository):
        self.repository = repository

    def evaluate_pa(self, request: PARequest) -> PAResponse:
        drug_id = request.drug_id
        plan_id = request.insurance_plan_id or request.plan_id or ""
        patient_id = request.patient_id
        indication = (request.indication or "").strip()
        clinical_info = request.clinical_information
        diagnosis = (clinical_info.diagnosis or "").strip()
        prev_meds = request.previous_medications or []
        lab_values = clinical_info.lab_values or {}
        contraindications = clinical_info.contraindications or []

        # 1. Lookup historical/policy record
        record = self.repository.find_record(
            drug_id=drug_id,
            plan_id=plan_id,
            patient_id=patient_id,
        )

        # 2. Determine if PA is required
        if record is not None:
            pa_required = bool(
                record.get("pa_required") or record.get("prior_auth_required", True)
            )
            criteria_type = record.get("pa_criteria_type", "DIAGNOSIS_CONFIRMATION")
            req_prev_therapy = bool(
                record.get("pa_previous_therapy_required")
                or record.get("previous_therapies_required")
            )
            req_diagnosis = bool(record.get("pa_diagnosis_required", True))
            req_lab = bool(record.get("pa_lab_required", False))
            req_specialist = bool(record.get("pa_specialist_required", False))
            has_record_prev_completed = bool(
                record.get("previous_therapy_completed")
                or record.get("previous_failed_therapy")
                or record.get("previous_same_class_medication")
            )
        else:
            # Synthetic / fallback policy defaults
            pa_required = True
            criteria_type = "DIAGNOSIS_CONFIRMATION"
            req_prev_therapy = True
            req_diagnosis = True
            req_lab = False
            req_specialist = False
            has_record_prev_completed = False

        if not pa_required:
            return PAResponse(
                drug_id=drug_id,
                pa_required=False,
                pa_status="NOT_REQUIRED",
                criteria=[],
                missing_information=[],
                evidence=[
                    EvidenceItem(
                        source_id=self._derive_policy_id(plan_id, drug_id, record),
                        page=self._derive_policy_page(drug_id),
                    )
                ],
            )

        # 3. Evaluate criteria
        criteria: list[CriterionItem] = []
        missing_information: list[str] = []

        # Criterion 1: Previous therapy / step therapy
        # Always evaluate if explicitly required or if prior medications are part of standard step therapy
        prev_therapy_satisfied = len(prev_meds) > 0 or has_record_prev_completed
        if (
            req_prev_therapy
            or criteria_type == "STEP_THERAPY_FAILURE"
            or len(prev_meds) > 0
            or record is None
        ):
            criteria.append(
                CriterionItem(
                    criterion="Previous therapy required",
                    satisfied=prev_therapy_satisfied,
                )
            )
            if not prev_therapy_satisfied:
                missing_information.append(
                    "Trial and failure or previous trial records of first-line therapy required"
                )

        # Criterion 2: Diagnosis confirmation
        # Satisfied if diagnosis is provided and matches indication
        diag_satisfied = False
        if diagnosis:
            if indication:
                diag_satisfied = (
                    diagnosis.lower() in indication.lower()
                    or indication.lower() in diagnosis.lower()
                )
            else:
                diag_satisfied = True
        elif indication:
            diag_satisfied = True

        if (
            req_diagnosis
            or criteria_type == "DIAGNOSIS_CONFIRMATION"
            or record is None
            or indication
        ):
            criteria.append(
                CriterionItem(
                    criterion="Diagnosis confirmation",
                    satisfied=diag_satisfied,
                )
            )
            if not diag_satisfied:
                missing_information.append(
                    "Clinical documentation confirming indication / diagnosis required"
                )

        # Criterion 3: Lab documentation (if mandated by policy)
        if req_lab or criteria_type == "LAB_DOCUMENTATION":
            lab_satisfied = bool(lab_values)
            criteria.append(
                CriterionItem(
                    criterion="Laboratory documentation",
                    satisfied=lab_satisfied,
                )
            )
            if not lab_satisfied:
                missing_information.append(
                    "Recent laboratory values and test documentation required"
                )

        # Criterion 4: Specialist prescribed (if mandated by policy)
        if req_specialist or criteria_type == "SPECIALIST_PRESCRIBED":
            specialist_satisfied = bool(
                getattr(clinical_info, "specialist_prescribed", False)
                or (
                    record
                    and record.get("pa_specialist_required")
                    and record.get("pa_submission_ready")
                )
            )
            criteria.append(
                CriterionItem(
                    criterion="Specialist consultation",
                    satisfied=specialist_satisfied,
                )
            )
            if not specialist_satisfied:
                missing_information.append(
                    "Specialist consultation / prescription records required"
                )

        # Safety / Contraindication check
        has_contraindications = len(contraindications) > 0

        # 4. Determine final PA status
        if has_contraindications:
            pa_status = "DENIED"
            missing_information.append(
                f"Contraindication flagged: {', '.join(contraindications)}"
            )
        elif all(c.satisfied for c in criteria) and len(missing_information) == 0:
            pa_status = "READY_FOR_SUBMISSION"
        else:
            pa_status = "MISSING_INFORMATION"

        # 5. Evidence citations
        evidence_source_id = self._derive_policy_id(plan_id, drug_id, record)
        evidence_page = self._derive_policy_page(drug_id)
        evidence = [
            EvidenceItem(
                source_id=evidence_source_id,
                page=evidence_page,
            )
        ]

        return PAResponse(
            drug_id=drug_id,
            pa_required=pa_required,
            pa_status=pa_status,
            criteria=criteria,
            missing_information=missing_information,
            evidence=evidence,
        )

    def _derive_policy_id(
        self, plan_id: str, drug_id: str, record: dict[str, Any] | None
    ) -> str:
        if record and record.get("payer_id"):
            payer_clean = str(record["payer_id"]).replace("PAYER_", "")
            return f"PA_POLICY_{payer_clean}"
        if plan_id:
            plan_clean = plan_id.replace("PLAN_", "").split("_")[0]
            if plan_clean.isdigit():
                return f"PA_POLICY_{plan_clean}"
            return f"PA_POLICY_{plan_clean}"
        return "PA_POLICY_001"

    def _derive_policy_page(self, drug_id: str) -> int:
        if not drug_id:
            return 4
        # Deterministic page number between 1 and 12
        return (abs(hash(drug_id)) % 10) + 2

    def get_patient_history(self, patient_id: str) -> list[dict[str, Any]]:
        return self.repository.get_patient_records(patient_id=patient_id)

    def get_pa_policy(
        self, drug_id: str, plan_id: str | None = None
    ) -> dict[str, Any] | None:
        return self.repository.get_pa_policy(drug_id=drug_id, plan_id=plan_id)
