import csv
import pathlib
from typing import Any


def parse_bool(val: str | None) -> bool:
    if not val:
        return False
    return val.strip().lower() in (
        "true",
        "1",
        "yes",
        "t",
        "y",
    )


def parse_float(val: str | None) -> float | None:
    if not val or val.strip().lower() == "nan":
        return None
    try:
        return float(val)
    except ValueError:
        return None


def parse_int(val: str | None) -> int | None:
    if not val or val.strip().lower() == "nan":
        return None
    try:
        return int(float(val))
    except ValueError:
        return None


class FormularyRepository:
    """
    Repository for formulary/insurance data.
    Primary lookup: insurance_plan_id + drug_id + pharmacy_id
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

        print(f"Loading formulary dataset from: {path.absolute()}")
        with open(path, mode="r", encoding="utf-8-sig") as file:
            reader = csv.DictReader(file)
            for row in reader:
                self.records.append(
                    {
                        "patient_id": row.get("patient_id"),
                        "drug_id": row.get("drug_id"),
                        "drug_name": row.get("drug_name"),
                        "therapeutic_class": row.get("therapeutic_class"),
                        "indication": row.get("indication"),
                        "insurance_plan_id": row.get("insurance_plan_id"),
                        "payer_id": row.get("payer_id"),
                        "pharmacy_id": row.get("pharmacy_id"),
                        "coverage_start_date": row.get("coverage_start_date"),
                        "coverage_end_date": row.get("coverage_end_date"),
                        "formulary_tier": parse_int(row.get("formulary_tier")),
                        "covered": parse_bool(row.get("covered")),
                        "patient_copay": parse_float(row.get("patient_copay")),
                        "patient_coinsurance": parse_float(
                            row.get("patient_coinsurance")
                        ),
                        "estimated_patient_cost": parse_float(
                            row.get("estimated_patient_cost")
                        ),
                        "prior_auth_required": parse_bool(
                            row.get("prior_auth_required") or row.get("pa_required")
                        ),
                        "step_therapy_required": parse_bool(
                            row.get("step_therapy_required")
                        ),
                        "quantity_limit": parse_bool(row.get("quantity_limit")),
                        "in_network": parse_bool(row.get("in_network")),
                        "preferred_pharmacy": parse_bool(row.get("preferred_pharmacy")),
                        "formulary_status": row.get("formulary_status") or "UNKNOWN",
                    }
                )
        print(f"Loaded {len(self.records)} formulary records.")

    def find_record(
        self,
        drug_id: str,
        plan_id: str,
        pharmacy_id: str,
        patient_id: str | None = None,
    ) -> dict[str, Any] | None:
        d_id = (drug_id or "").strip().lower()
        p_id = (plan_id or "").strip().lower()
        ph_id = (pharmacy_id or "").strip().lower()
        pat_id = (patient_id or "").strip().lower() if patient_id else None

        # 1. Exact match with patient_id if given
        if pat_id:
            for record in self.records:
                if (
                    str(record.get("drug_id") or "").strip().lower() == d_id
                    and str(record.get("insurance_plan_id") or "").strip().lower()
                    == p_id
                    and str(record.get("pharmacy_id") or "").strip().lower() == ph_id
                    and str(record.get("patient_id") or "").strip().lower() == pat_id
                ):
                    return record

        # 2. Match plan + drug + pharmacy
        for record in self.records:
            if (
                str(record.get("drug_id") or "").strip().lower() == d_id
                and str(record.get("insurance_plan_id") or "").strip().lower() == p_id
                and str(record.get("pharmacy_id") or "").strip().lower() == ph_id
            ):
                return record

        # 3. Fallback: match plan + drug
        for record in self.records:
            if (
                str(record.get("drug_id") or "").strip().lower() == d_id
                and str(record.get("insurance_plan_id") or "").strip().lower() == p_id
            ):
                return record

        # 4. Fallback: match drug only
        for record in self.records:
            if str(record.get("drug_id") or "").strip().lower() == d_id:
                return record

        return None

    def search_drugs(self, query: str, limit: int = 10) -> list[dict[str, Any]]:
        q = (query or "").strip().lower()
        results: list[dict[str, Any]] = []
        seen = set()
        for record in self.records:
            d_id = record.get("drug_id") or ""
            d_name = record.get("drug_name") or ""
            if q in d_id.lower() or q in d_name.lower():
                if d_id not in seen:
                    seen.add(d_id)
                    results.append(
                        {
                            "drug_id": d_id,
                            "drug_name": d_name,
                            "formulary_tier": record.get("formulary_tier"),
                            "covered": record.get("covered"),
                        }
                    )
                if len(results) >= limit:
                    break
        return results

    def get_drug_details(self, drug_id: str) -> dict[str, Any] | None:
        d_id = (drug_id or "").strip().lower()
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
