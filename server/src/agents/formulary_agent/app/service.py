from datetime import date
from typing import Any

from .repository import FormularyRepository
from .schemas import (
    Coverage,
    FormularyRequest,
    FormularyResponse,
)


class FormularyService:
    def __init__(self, repository: FormularyRepository):
        self.repository = repository

    def check_formulary(
        self,
        request: FormularyRequest,
    ) -> FormularyResponse:
        drug_id = request.drug_id
        plan_id = request.insurance_plan_id
        pharmacy_id = request.pharmacy_id
        patient_id = request.patient_id

        # Derive source string from date
        source_str = "FORMULARY_2026_08"
        if request.date:
            if isinstance(request.date, str):
                try:
                    dt = date.fromisoformat(request.date)
                    source_str = f"FORMULARY_{dt.strftime('%Y_%m')}"
                except (ValueError, TypeError, AttributeError):
                    parts = request.date.split("-")
                    if len(parts) >= 2:
                        source_str = f"FORMULARY_{parts[0]}_{parts[1]}"
            elif isinstance(request.date, date):
                source_str = f"FORMULARY_{request.date.strftime('%Y_%m')}"

        record = self.repository.find_record(
            drug_id=drug_id,
            plan_id=plan_id,
            pharmacy_id=pharmacy_id,
            patient_id=patient_id,
        )

        if record is None:
            return FormularyResponse(
                drug_id=drug_id,
                plan_id=plan_id,
                coverage=Coverage(
                    covered=False,
                    tier=None,
                    patient_cost=None,
                    pa_required=False,
                    step_therapy_required=False,
                    quantity_limit=False,
                    in_network=False,
                ),
                decision="NOT_FOUND",
                source=source_str,
            )

        covered = bool(record.get("covered", False))
        tier = record.get("formulary_tier")

        copay = record.get("patient_copay") or 0.0
        coinsurance = record.get("patient_coinsurance") or 0.0
        estimated_cost = record.get("estimated_patient_cost")
        if estimated_cost is not None:
            raw_cost = float(estimated_cost)
        elif copay or coinsurance:
            raw_cost = float(copay) + float(coinsurance)
        else:
            raw_cost = 0.0

        patient_cost = int(raw_cost) if raw_cost.is_integer() else raw_cost

        pa_required = bool(record.get("prior_auth_required") or record.get("pa_required", False))
        step_therapy_required = bool(record.get("step_therapy_required", False))
        quantity_limit = bool(record.get("quantity_limit", False))
        in_network = bool(record.get("in_network", False))

        # Decision hierarchy
        if not covered:
            decision = "NOT_COVERED"
        elif not in_network:
            decision = "OUT_OF_NETWORK"
        elif pa_required:
            decision = "PA_REQUIRED"
        elif step_therapy_required:
            decision = "STEP_THERAPY_REQUIRED"
        elif quantity_limit:
            decision = "QUANTITY_LIMIT"
        elif tier == 1:
            decision = "COVERED_PREFERRED"
        else:
            decision = "COVERED"

        return FormularyResponse(
            drug_id=drug_id,
            plan_id=plan_id,
            coverage=Coverage(
                covered=covered,
                tier=tier,
                patient_cost=patient_cost,
                pa_required=pa_required,
                step_therapy_required=step_therapy_required,
                quantity_limit=quantity_limit,
                in_network=in_network,
            ),
            decision=decision,
            source=source_str,
        )

    def search_drugs(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        return self.repository.search_drugs(query=query, limit=limit)

    def get_drug_details(self, drug_id: str) -> dict[str, Any] | None:
        return self.repository.get_drug_details(drug_id=drug_id)

    def get_patient_history(self, patient_id: str) -> list[dict[str, Any]]:
        return self.repository.get_patient_records(patient_id=patient_id)
