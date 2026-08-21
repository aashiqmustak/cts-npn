import csv
import pathlib
from typing import Any


class PatientHistoryRepository:

    def __init__(self, csv_path: str | None = None):
        if csv_path is None:
            current = pathlib.Path(__file__).resolve()

            for parent in [current] + list(current.parents):
                candidate = parent / "dataset" / "patient_history.csv"

                if candidate.exists():
                    csv_path = str(candidate)
                    break

        if csv_path is None:
            csv_path = "dataset/patient_history.csv"

        self.csv_path = csv_path
        self.records: list[dict[str, Any]] = []

        self._load_data()

    def _load_data(self) -> None:
        path = pathlib.Path(self.csv_path)

        if not path.exists():
            raise FileNotFoundError(
                f"Patient history dataset not found at {path.absolute()}"
            )

        print(f"Loading patient history dataset from: {path.absolute()}")

        with open(
            path,
            mode="r",
            encoding="utf-8-sig"
        ) as file:

            reader = csv.DictReader(file)

            for row in reader:
                self.records.append({
                    "patient_id": row.get("patient_id"),
                    "drug_id": row.get("drug_id"),
                    "fill_date": row.get("fill_date"),
                    "days_supply": row.get("days_supply"),
                    "status": row.get("status"),
                    "condition": row.get("condition"),
                })

        print(
            f"Loaded {len(self.records)} patient history records."
        )

    def get_patient_records(
        self,
        patient_id: str
    ) -> list[dict[str, Any]]:

        patient_id = (patient_id or "").strip().lower()

        return [
            record
            for record in self.records
            if str(record.get("patient_id") or "").strip().lower()
            == patient_id
        ]