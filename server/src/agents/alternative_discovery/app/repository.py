import csv
import pathlib
from typing import Any


def parse_bool(val: str | None) -> bool:
    if not val:
        return False
    return val.strip().lower() in ("true", "1", "yes", "t", "y")


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


class AlternativeDiscoveryRepository:
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

        print(f"Loading alternative discovery dataset from: {path.absolute()}")
        with open(path, mode="r", encoding="utf-8-sig") as file:
            reader = csv.DictReader(file)
            for row in reader:
                self.records.append(
                    {
                        "drug_id": row.get("drug_id"),
                        "drug_name": row.get("drug_name"),
                        "therapeutic_class": row.get("therapeutic_class"),
                        "indication": row.get("indication"),
                        # include the others just in case we need them
                        "formulary_tier": parse_int(row.get("formulary_tier")),
                        "covered": parse_bool(row.get("covered")),
                        "in_network": parse_bool(row.get("in_network")),
                    }
                )
        print(f"Loaded {len(self.records)} alternative discovery records.")

    def find_candidate_drugs(
        self,
        therapeutic_class: str,
        indication: str,
        exclude_drug_id: str,
        limit: int = 15,
    ) -> list[dict[str, Any]]:
        results: list[dict[str, Any]] = []
        t_class = (therapeutic_class or "").strip().lower()
        ind = (indication or "").strip().lower()
        exclude_id = (exclude_drug_id or "").strip().lower()

        seen = set()

        for record in self.records:
            r_id = (record.get("drug_id") or "").strip().lower()
            if r_id == exclude_id or not r_id:
                continue

            r_class = (record.get("therapeutic_class") or "").strip().lower()
            r_ind = (record.get("indication") or "").strip().lower()

            # Find drugs where the record's therapeutic class OR indication loosely matches
            if (
                (t_class and t_class in r_class)
                or (ind and ind in r_ind)
                or (r_class and r_class in t_class)
                or (r_ind and r_ind in ind)
            ) and r_id not in seen:
                seen.add(r_id)
                results.append(record)
                if len(results) >= limit:
                    break

        return results
