import csv
import pathlib
from typing import Any


def parse_bool(val: str | None) -> bool:
    if not val:
        return False
    return str(val).strip().lower() in (
        "true",
        "1",
        "yes",
        "t",
        "y",
        "pass",
    )


def parse_int(val: str | None) -> int | None:
    if not val or str(val).strip().lower() == "nan":
        return None
    try:
        return int(float(val))
    except ValueError:
        return None


class PARepository:
    """
    Repository for Prior Authorization (PA) and clinical criteria dataset.
    Loads and caches records from pharmaassist_full_50000.csv.
    """

    def __init__(self, csv_path: str | None = None):
        if csv_path is None:
            current = pathlib.Path(__file__).resolve()
            for parent in [current] + list(current.parents):
                candidate = parent / "dataset" / "pharmaassist_full_50000.csv"
                if candidate.exists():
                    csv_path = str(candidate)
                    break

        if csv_path is None:
            csv_path = "dataset/pharmaassist_full_50000.csv"

        self.csv_path = csv_path
        self.records: list[dict[str, Any]] = []
        self._load_data()

    def _load_data(self) -> None:
        path = pathlib.Path(self.csv_path)
        if not path.exists():
            raise FileNotFoundError(f"Dataset not found at {path.absolute()}")

        print(f"Loading PA dataset from: {path.absolute()}")
        with open(path, mode="r", encoding="utf-8-sig") as file:
            reader = csv.DictReader(file)
            for row in reader:
                pa_req = parse_bool(
                    row.get("pa_required") or row.get("prior_auth_required")
                )
                self.records.append(
                    {
                        "patient_id": row.get("patient_id"),
                        "drug_id": row.get("drug_id"),
                        "drug_name": row.get("drug_name"),
                        "insurance_plan_id": row.get("insurance_plan_id"),
                        "payer_id": row.get("payer_id"),
                        "indication": row.get("indication"),
                        "pa_required": pa_req,
                        "prior_auth_required": pa_req,
                        "pa_criteria_type": row.get("pa_criteria_type") or "NONE",
                        "pa_previous_therapy_required": parse_bool(
                            row.get("pa_previous_therapy_required")
                        ),
                        "pa_diagnosis_required": parse_bool(
                            row.get("pa_diagnosis_required")
                        ),
                        "pa_lab_required": parse_bool(row.get("pa_lab_required")),
                        "pa_specialist_required": parse_bool(
                            row.get("pa_specialist_required")
                        ),
                        "pa_documentation_required": parse_bool(
                            row.get("pa_documentation_required")
                        ),
                        "pa_submission_ready": parse_bool(
                            row.get("pa_submission_ready")
                        ),
                        "pa_missing_information": parse_bool(
                            row.get("pa_missing_information")
                        ),
                        "pa_status": row.get("pa_status") or "NOT_REQUIRED",
                        "step_therapy_steps": parse_int(row.get("step_therapy_steps")),
                        "previous_therapies_required": parse_bool(
                            row.get("previous_therapies_required")
                        ),
                        "previous_therapy_completed": parse_bool(
                            row.get("previous_therapy_completed")
                        ),
                        "step_therapy_status": row.get("step_therapy_status"),
                        "previous_failed_therapy": parse_bool(
                            row.get("previous_failed_therapy")
                        ),
                        "previous_same_class_medication": parse_bool(
                            row.get("previous_same_class_medication")
                        ),
                        "contraindication_flag": parse_bool(
                            row.get("contraindication_flag")
                        ),
                        "evidence_available": row.get("evidence_available") or "PASS",
                    }
                )
        print(f"Loaded {len(self.records)} PA records.")

    def find_record(
        self,
        drug_id: str,
        plan_id: str | None = None,
        patient_id: str | None = None,
    ) -> dict[str, Any] | None:
        d_id = (drug_id or "").strip().lower()
        p_id = (plan_id or "").strip().lower() if plan_id else None
        pat_id = (patient_id or "").strip().lower() if patient_id else None

        # 1. Exact match with patient_id + drug_id + plan_id
        if pat_id and p_id:
            for record in self.records:
                if (
                    str(record.get("drug_id") or "").strip().lower() == d_id
                    and str(record.get("insurance_plan_id") or "").strip().lower()
                    == p_id
                    and str(record.get("patient_id") or "").strip().lower() == pat_id
                ):
                    return record

        # 2. Match patient_id + drug_id
        if pat_id:
            for record in self.records:
                if (
                    str(record.get("drug_id") or "").strip().lower() == d_id
                    and str(record.get("patient_id") or "").strip().lower() == pat_id
                ):
                    return record

        # 3. Match plan_id + drug_id
        if p_id:
            for record in self.records:
                if (
                    str(record.get("drug_id") or "").strip().lower() == d_id
                    and str(record.get("insurance_plan_id") or "").strip().lower()
                    == p_id
                ):
                    return record

        # 4. Fallback: match drug_id only
        for record in self.records:
            if str(record.get("drug_id") or "").strip().lower() == d_id:
                return record

        return None

    def get_patient_records(self, patient_id: str) -> list[dict[str, Any]]:
        pat_id = (patient_id or "").strip().lower()
        return [
            r
            for r in self.records
            if str(r.get("patient_id") or "").strip().lower() == pat_id
        ]

    def get_pa_policy(
        self, drug_id: str, plan_id: str | None = None
    ) -> dict[str, Any] | None:
        return self.find_record(drug_id=drug_id, plan_id=plan_id)
