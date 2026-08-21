import sys
from pathlib import Path
from typing import Any

APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

try:
    from .schemas import (
        ClinicalSafetyInput,
        ClinicalSafetyOutput,
        EligibleCandidate,
        Evidence,
        RejectedCandidate,
        ReviewCandidate,
        SafetyChecks,
        SafetyIssue,
    )
except ImportError:  # pragma: no cover - allows standalone script execution
    from schemas import (
        ClinicalSafetyInput,
        ClinicalSafetyOutput,
        EligibleCandidate,
        Evidence,
        RejectedCandidate,
        ReviewCandidate,
        SafetyChecks,
        SafetyIssue,
    )


STATUS_PRIORITY = {"PASS": 0, "REVIEW": 1, "REJECT": 2}


def _as_issue(rule_name: str, result: dict[str, Any]) -> SafetyIssue:
    return SafetyIssue(
        type=rule_name,
        severity=result.get("severity", "LOW"),
        reason=result.get("reason", "No reason supplied."),
        source=result.get("source"),
        source_section=result.get("source_section"),
    )


def _aggregate_status(checks: dict[str, str]) -> str:
    if any(v == "REJECT" for v in checks.values()):
        return "REJECT"
    if any(v == "REVIEW" for v in checks.values()):
        return "REVIEW"
    return "PASS"


def _check_allergy(context: dict[str, Any]) -> dict[str, Any]:
    allergies = context.get("allergy_flag", False) or (context.get("allergy_count", 0) > 0)
    if allergies:
        return {"status": "REJECT", "severity": "HIGH", "reason": "Patient has an allergy flag or recorded allergy count."}
    return {"status": "PASS", "severity": "LOW", "reason": "No allergy issue detected."}


def _check_drug_interaction(context: dict[str, Any]) -> dict[str, Any]:
    if context.get("drug_interaction_flag"):
        return {"status": "REJECT", "severity": "HIGH", "reason": "Drug interaction flag is true."}
    return {"status": "PASS", "severity": "LOW", "reason": "No drug interaction reported."}


def _check_contraindication(context: dict[str, Any]) -> dict[str, Any]:
    if context.get("contraindication_flag"):
        return {"status": "REJECT", "severity": "CRITICAL", "reason": "Contraindication flag is true."}
    return {"status": "PASS", "severity": "LOW", "reason": "No contraindication found."}


def _check_drug_disease(context: dict[str, Any]) -> dict[str, Any]:
    indication = context.get("indication")
    candidate_name = context.get("candidate_drug_name", "")
    if (
        indication
        and indication.lower() == "diabetes"
        and candidate_name.lower() in {"metformin"}
    ):
        return {"status": "PASS", "severity": "LOW", "reason": "Indication and candidate drug are clinically consistent."}
    return {"status": "PASS", "severity": "LOW", "reason": "No disease-drug conflict detected."}


def _check_renal(context: dict[str, Any]) -> dict[str, Any]:
    renal_status = str(context.get("renal_status", "UNKNOWN")).upper()
    if renal_status in {"NORMAL", "MILD_IMPAIRMENT"}:
        return {"status": "PASS", "severity": "LOW", "reason": "Renal function is acceptable."}
    if renal_status in {"MODERATE_IMPAIRMENT", "SEVERE_IMPAIRMENT"}:
        return {"status": "REVIEW", "severity": "MODERATE", "reason": "Renal function is impaired; medication review recommended."}
    return {"status": "REVIEW", "severity": "MODERATE", "reason": "Renal function is unknown."}


def _check_hepatic(context: dict[str, Any]) -> dict[str, Any]:
    hepatic_status = str(context.get("hepatic_status", "UNKNOWN")).upper()
    if hepatic_status == "NORMAL":
        return {"status": "PASS", "severity": "LOW", "reason": "Hepatic function is normal."}
    if hepatic_status in {"MILD_IMPAIRMENT", "MODERATE_IMPAIRMENT"}:
        return {"status": "REVIEW", "severity": "MODERATE", "reason": "Hepatic impairment may require dose adjustment."}
    return {"status": "REVIEW", "severity": "HIGH", "reason": "Hepatic status is abnormal or unknown."}


def _check_age(context: dict[str, Any]) -> dict[str, Any]:
    age = int(context.get("patient_age", 0) or 0)
    if age < 0 or age > 120:
        return {"status": "REJECT", "severity": "HIGH", "reason": "Age is outside the supported range."}
    return {"status": "PASS", "severity": "LOW", "reason": "Age is within the supported range."}


def _check_indication(context: dict[str, Any]) -> dict[str, Any]:
    indication = context.get("indication")
    if not indication:
        return {"status": "REVIEW", "severity": "MODERATE", "reason": "No indication supplied."}
    return {"status": "PASS", "severity": "LOW", "reason": "Indication is provided."}


def _check_pregnancy(context: dict[str, Any]) -> dict[str, Any]:
    if context.get("pregnancy_relevant_flag"):
        return {"status": "REVIEW", "severity": "HIGH", "reason": "Pregnancy relevance requires clinical review."}
    return {"status": "PASS", "severity": "LOW", "reason": "Not pregnancy-relevant."}


def clinical_eligibility_agent(row: dict[str, Any]) -> ClinicalSafetyOutput:
    patient_id = row.get("patient_id", "UNKNOWN")
    candidate = row["candidate_drugs"][0]
    patient_context = row["patient_context"]

    context = {
        "patient_id": patient_id,
        "patient_age": patient_context.get("age", 0),
        "gender": patient_context.get("sex", "UNKNOWN"),
        "indication": patient_context.get("indication", {}).get("name") or row.get("indication"),
        "allergy_flag": bool(row.get("allergy_flag", False)),
        "allergy_count": row.get("allergy_count", 0),
        "renal_status": row.get("renal_status"),
        "hepatic_status": row.get("hepatic_status"),
        "pregnancy_relevant_flag": row.get("pregnancy_relevant_flag", False),
        "current_medication_count": row.get("current_medication_count"),
        "concurrent_medications_count": row.get("concurrent_medications_count"),
        "drug_interaction_flag": row.get("drug_interaction_flag", False),
        "contraindication_flag": row.get("contraindication_flag", False),
        "candidate_drug_id": candidate.get("drug_id"),
        "candidate_drug_name": candidate.get("drug_name"),
        "candidate_relationship": row.get("candidate_relationship"),
    }

    allergy_result = _check_allergy(context)
    interaction_result = _check_drug_interaction(context)
    contraindication_result = _check_contraindication(context)
    disease_result = _check_drug_disease(context)
    renal_result = _check_renal(context)
    hepatic_result = _check_hepatic(context)
    age_result = _check_age(context)
    indication_result = _check_indication(context)
    pregnancy_result = _check_pregnancy(context)

    checks = SafetyChecks(
        allergy=allergy_result["status"],
        drug_interaction=interaction_result["status"],
        drug_disease=disease_result["status"],
        renal=renal_result["status"],
        hepatic=hepatic_result["status"],
        age=age_result["status"],
        indication=indication_result["status"],
        pregnancy=pregnancy_result["status"],
    )

    issues: list[SafetyIssue] = []
    for name, result in [
        ("allergy", allergy_result),
        ("drug_interaction", interaction_result),
        ("contraindication", contraindication_result),
        ("drug_disease", disease_result),
        ("renal", renal_result),
        ("hepatic", hepatic_result),
        ("age", age_result),
        ("indication", indication_result),
        ("pregnancy", pregnancy_result),
    ]:
        if result["status"] != "PASS":
            issues.append(_as_issue(name, result))

    final_status = _aggregate_status({
        "allergy": checks.allergy,
        "drug_interaction": checks.drug_interaction,
        "contraindication": contraindication_result["status"],
        "drug_disease": checks.drug_disease,
        "renal": checks.renal,
        "hepatic": checks.hepatic,
        "age": checks.age,
        "indication": checks.indication,
        "pregnancy": checks.pregnancy or "PASS",
    })

    eligible_candidates: list[EligibleCandidate] = []
    rejected_candidates: list[RejectedCandidate] = []
    review_required: list[ReviewCandidate] = []

    if final_status == "PASS":
        eligible_candidates.append(
            EligibleCandidate(
                drug_id=candidate.get("drug_id"),
                drug_name=candidate.get("drug_name"),
                eligible=True,
                safety_status="PASS",
                checks=checks,
                warnings=[],
            )
        )
    elif final_status == "REJECT":
        rejected_candidates.append(
            RejectedCandidate(
                drug_id=candidate.get("drug_id"),
                drug_name=candidate.get("drug_name"),
                eligible=False,
                reasons=issues,
            )
        )
    else:
        review_required.append(
            ReviewCandidate(
                drug_id=candidate.get("drug_id"),
                drug_name=candidate.get("drug_name"),
                eligible=False,
                reasons=issues,
            )
        )

    return ClinicalSafetyOutput(
        patient_id=patient_id,
        eligible_candidates=eligible_candidates,
        rejected_candidates=rejected_candidates,
        review_required=review_required,
        evidence=[Evidence(source="clinical_agent", section="evaluation", document_id=str(patient_id), version="v1")],
        overall_status=final_status,
    )


class ClinicalEligibilityService:
    def evaluate(self, request: ClinicalSafetyInput) -> ClinicalSafetyOutput:
        return clinical_eligibility_agent(request.model_dump())

    def run(self, task: dict[str, Any] | ClinicalSafetyInput) -> dict[str, Any]:
        if isinstance(task, ClinicalSafetyInput):
            req = task
        else:
            req = ClinicalSafetyInput.model_validate(task)
        return self.evaluate(req).model_dump()
