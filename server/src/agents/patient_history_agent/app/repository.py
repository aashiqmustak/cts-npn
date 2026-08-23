import csv
import logging
import pathlib
from typing import Any

from .pinecone_client import PineconePatientHistoryClient

logger = logging.getLogger("patient_history_agent.repository")


class PatientHistoryRepository:
    def __init__(
        self,
        csv_path: str | None = None,
        pinecone_client: PineconePatientHistoryClient | None = None,
    ):
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
        self.pinecone = pinecone_client or PineconePatientHistoryClient()

        self._load_data()

    def _load_data(self) -> None:
        path = pathlib.Path(self.csv_path)
        if not path.exists():
            logger.warning("Patient history dataset not found at %s", path.absolute())
            return

        logger.info("Loading patient history dataset from: %s", path.absolute())

        with open(path, mode="r", encoding="utf-8-sig") as file:
            reader = csv.DictReader(file)
            for row in reader:
                self.records.append(
                    {
                        "patient_id": str(row.get("patient_id") or "").strip(),
                        "drug_id": str(row.get("drug_id") or "").strip(),
                        "fill_date": str(row.get("fill_date") or "").strip(),
                        "days_supply": row.get("days_supply"),
                        "status": str(row.get("status") or "FILLED").strip().upper(),
                        "condition": str(row.get("condition") or "Unspecified").strip(),
                        "source": "historical_dataset",
                        "notes": "",
                    }
                )

        logger.info("Loaded %d patient history records into in-memory store.", len(self.records))

    def get_patient_records(self, patient_id: str) -> list[dict[str, Any]]:
        clean_patient_id = (patient_id or "").strip().lower()
        return [
            record
            for record in self.records
            if str(record.get("patient_id") or "").strip().lower() == clean_patient_id
        ]

    def add_record(self, record: dict[str, Any], sync_pinecone: bool = True) -> str | None:
        """Add a new patient record (from client) to local cache and upsert to Pinecone."""
        formatted_record = {
            "patient_id": str(record.get("patient_id") or "").strip(),
            "drug_id": str(record.get("drug_id") or "").strip(),
            "fill_date": str(record.get("fill_date") or "").strip(),
            "days_supply": record.get("days_supply", 30),
            "status": str(record.get("status") or "FILLED").strip().upper(),
            "condition": str(record.get("condition") or "Unspecified").strip(),
            "source": str(record.get("source") or "client_submission").strip(),
            "notes": str(record.get("notes") or "").strip(),
        }

        self.records.append(formatted_record)

        vec_id = None
        if sync_pinecone and self.pinecone.is_available:
            try:
                vec_id = self.pinecone.upsert_single_record(formatted_record)
                logger.info("Synced new patient record to Pinecone (vector_id: %s)", vec_id)
            except Exception as exc:
                logger.error("Failed to sync record to Pinecone: %s", exc)

        return vec_id

    def sync_dataset_to_pinecone(self, batch_size: int = 40) -> int:
        """Upsert all in-memory / dataset records into Pinecone."""
        if not self.pinecone.is_available:
            logger.warning("Pinecone is not available for bulk sync.")
            return 0

        logger.info("Syncing %d records to Pinecone...", len(self.records))
        return self.pinecone.upsert_records(self.records, batch_size=batch_size)

    def query_rag(
        self,
        patient_id: str,
        query: str | None = None,
        top_k: int = 5,
        condition: str | None = None,
        drug_id: str | None = None,
    ) -> list[dict[str, Any]]:
        """Query Pinecone for semantic records; fallback to local records if Pinecone unavailable."""
        if self.pinecone.is_available:
            matches = self.pinecone.query_patient_records(
                patient_id=patient_id,
                query_text=query,
                top_k=top_k,
                condition=condition,
                drug_id=drug_id,
            )
            if matches:
                return matches

        # Local fallback if Pinecone offline or has no vector matches
        records = self.get_patient_records(patient_id)
        fallback_results = []
        for i, rec in enumerate(records[:top_k]):
            fallback_results.append(
                {
                    "id": f"local_{rec.get('patient_id')}_{i}",
                    "score": 1.0,
                    "patient_id": rec.get("patient_id"),
                    "drug_id": rec.get("drug_id"),
                    "fill_date": rec.get("fill_date"),
                    "days_supply": int(float(rec.get("days_supply") or 0)),
                    "status": rec.get("status"),
                    "condition": rec.get("condition"),
                    "source": rec.get("source", "local_dataset"),
                    "notes": rec.get("notes", ""),
                    "text": self.pinecone.format_record_text(rec),
                }
            )
        return fallback_results
