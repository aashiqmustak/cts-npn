import hashlib
import logging
import os
import time
from typing import Any

from dotenv import load_dotenv

load_dotenv()

logger = logging.getLogger("patient_history_agent.pinecone")


class PineconePatientHistoryClient:
    """Client for Pinecone Vector DB operations in the Patient History Agent."""

    def __init__(
        self,
        api_key: str | None = None,
        index_name: str | None = None,
        namespace: str | None = None,
        embedding_model: str | None = None,
    ):
        self.api_key = api_key or os.getenv("PINECONE_API_KEY", "").strip()
        self.index_name = index_name or os.getenv("PINECONE_INDEX_NAME", "cts-npn").strip()
        self.namespace = namespace or os.getenv("PINECONE_NAMESPACE", "patient-history").strip()
        self.embedding_model = embedding_model or os.getenv("EMBEDDING_PROVIDER", "llama-text-embed-v2").strip()

        self._pc = None
        self._index = None
        self._available = False

        self._init_client()

    def _init_client(self) -> None:
        if not self.api_key:
            logger.warning("PINECONE_API_KEY is missing. Pinecone RAG features will run in mock/offline mode.")
            self._available = False
            return

        try:
            from pinecone import Pinecone

            self._pc = Pinecone(api_key=self.api_key)
            self._index = self._pc.Index(self.index_name)
            self._available = True
            logger.info("Connected to Pinecone index '%s' (namespace: '%s')", self.index_name, self.namespace)
        except (ImportError, RuntimeError, ValueError, OSError) as exc:
            logger.error("Failed to connect to Pinecone: %s", exc)
            self._available = False

    @property
    def is_available(self) -> bool:
        return self._available and self._index is not None

    def format_record_text(self, record: dict[str, Any]) -> str:
        """Construct a dense semantic document representation of a patient history entry."""
        patient_id = str(record.get("patient_id") or "").strip()
        drug_id = str(record.get("drug_id") or "").strip()
        condition = str(record.get("condition") or "Unspecified").strip()
        status = str(record.get("status") or "FILLED").strip().upper()
        fill_date = str(record.get("fill_date") or "").strip()
        days_supply = record.get("days_supply", 30)
        source = str(record.get("source") or "historical_dataset").strip()
        notes = str(record.get("notes") or "").strip()

        text = (
            f"Patient {patient_id} record: Condition {condition}. "
            f"Medication {drug_id} was {status} on {fill_date} for a {days_supply}-day supply. "
            f"Source: {source}."
        )
        if notes:
            text += f" Clinical Notes: {notes}."
        return text

    def generate_record_id(self, record: dict[str, Any], index_idx: int = 0) -> str:
        """Generate deterministic or unique ID for the vector record."""
        p_id = str(record.get("patient_id") or "").strip().lower()
        d_id = str(record.get("drug_id") or "").strip().lower()
        f_date = str(record.get("fill_date") or "").strip()
        cond = str(record.get("condition") or "").strip().lower()
        raw = f"{p_id}_{d_id}_{f_date}_{cond}_{index_idx}"
        hash_suffix = hashlib.md5(raw.encode("utf-8")).hexdigest()[:8]
        return f"{p_id}_{d_id}_{f_date}_{hash_suffix}"

    def embed_texts(self, texts: list[str], input_type: str = "passage", max_retries: int = 3) -> list[list[float]]:
        """Generate embeddings using Pinecone Inference API with automatic retry."""
        if not self.is_available or not self._pc:
            raise RuntimeError("Pinecone client is not initialized or offline.")

        last_exc: BaseException | None = None
        for attempt in range(max_retries):
            try:
                embeddings_response = self._pc.inference.embed(
                    model=self.embedding_model,
                    inputs=texts,
                    parameters={"input_type": input_type, "truncate": "END"},
                )
                return [record.values for record in embeddings_response]
            except (TimeoutError, OSError, RuntimeError, ValueError) as exc:
                last_exc = exc
                logger.warning("Embedding attempt %d/%d failed: %s. Retrying in %ds...", attempt + 1, max_retries, exc, attempt + 1)
                time.sleep(attempt + 1)

        logger.error("Error generating embeddings with Pinecone inference (%s): %s", self.embedding_model, last_exc)
        if last_exc:
            raise last_exc
        raise RuntimeError("Failed to generate embeddings.")

    def upsert_records(
        self,
        records: list[dict[str, Any]],
        namespace: str | None = None,
        batch_size: int = 40,
    ) -> int:
        """Vectorize and upsert a batch of patient history records with rich metadata."""
        if not self.is_available or not self._index:
            logger.warning("Pinecone index not available; skipping vector upsert.")
            return 0

        ns = namespace or self.namespace
        total_upserted = 0

        for i in range(0, len(records), batch_size):
            chunk = records[i : i + batch_size]
            texts = [self.format_record_text(r) for r in chunk]

            try:
                embeddings = self.embed_texts(texts, input_type="passage")
            except (TimeoutError, OSError, RuntimeError, ValueError) as exc:
                logger.error("Failed to generate embeddings for batch %d: %s", i, exc)
                continue

            vectors = []
            for j, (rec, text, emb) in enumerate(zip(chunk, texts, embeddings, strict=False)):
                vec_id = self.generate_record_id(rec, index_idx=i + j)
                metadata = {
                    "patient_id": str(rec.get("patient_id") or "").strip().lower(),
                    "drug_id": str(rec.get("drug_id") or "").strip().upper(),
                    "fill_date": str(rec.get("fill_date") or "").strip(),
                    "days_supply": int(float(rec.get("days_supply") or 0)),
                    "status": str(rec.get("status") or "FILLED").strip().upper(),
                    "condition": str(rec.get("condition") or "Unspecified").strip(),
                    "source": str(rec.get("source") or "dataset").strip(),
                    "notes": str(rec.get("notes") or "").strip(),
                    "text": text,
                }
                vectors.append({"id": vec_id, "values": emb, "metadata": metadata})

            try:
                self._index.upsert(vectors=vectors, namespace=ns)
                total_upserted += len(vectors)
                logger.info("Upserted %d records to Pinecone namespace '%s'", len(vectors), ns)
            except (TimeoutError, OSError, RuntimeError, ValueError) as exc:
                logger.error("Failed to upsert vectors to Pinecone: %s", exc)

        return total_upserted

    def upsert_single_record(
        self,
        record: dict[str, Any],
        namespace: str | None = None,
    ) -> str:
        """Vectorize and upsert a single patient record (e.g. from client)."""
        ns = namespace or self.namespace
        text = self.format_record_text(record)
        embeddings = self.embed_texts([text], input_type="passage")
        if not embeddings:
            raise RuntimeError("Failed to generate embedding for record.")

        vec_id = self.generate_record_id(record)
        metadata = {
            "patient_id": str(record.get("patient_id") or "").strip().lower(),
            "drug_id": str(record.get("drug_id") or "").strip().upper(),
            "fill_date": str(record.get("fill_date") or "").strip(),
            "days_supply": int(float(record.get("days_supply") or 0)),
            "status": str(record.get("status") or "FILLED").strip().upper(),
            "condition": str(record.get("condition") or "Unspecified").strip(),
            "source": str(record.get("source") or "client_submission").strip(),
            "notes": str(record.get("notes") or "").strip(),
            "text": text,
        }

        if self._index:
            self._index.upsert(
                vectors=[{"id": vec_id, "values": embeddings[0], "metadata": metadata}],
                namespace=ns,
            )
        return vec_id

    def query_patient_records(
        self,
        patient_id: str,
        query_text: str | None = None,
        top_k: int = 5,
        condition: str | None = None,
        drug_id: str | None = None,
        namespace: str | None = None,
    ) -> list[dict[str, Any]]:
        """Retrieve semantically relevant records for a patient from Pinecone."""
        if not self.is_available or not self._index:
            logger.warning("Pinecone is not available; unable to perform vector search.")
            return []

        ns = namespace or self.namespace
        clean_patient_id = (patient_id or "").strip().lower()

        # Construct query text
        if not query_text or not query_text.strip():
            query_text = f"Medication adherence history, past fills, conditions, and therapy outcomes for patient {clean_patient_id}"
            if condition:
                query_text += f" regarding {condition}"
            if drug_id:
                query_text += f" for medication {drug_id}"

        # Build filter dictionary
        filter_dict: dict[str, Any] = {"patient_id": {"$eq": clean_patient_id}}
        if condition:
            filter_dict["condition"] = {"$eq": condition.strip()}
        if drug_id:
            filter_dict["drug_id"] = {"$eq": drug_id.strip().upper()}

        try:
            query_embedding = self.embed_texts([query_text], input_type="query")[0]
            response = self._index.query(
                vector=query_embedding,
                top_k=top_k,
                include_metadata=True,
                filter=filter_dict,
                namespace=ns,
            )

            results = []
            for match in response.get("matches", []):
                meta = match.get("metadata", {})
                results.append(
                    {
                        "id": match.get("id"),
                        "score": round(match.get("score", 0.0), 4),
                        "patient_id": meta.get("patient_id"),
                        "drug_id": meta.get("drug_id"),
                        "fill_date": meta.get("fill_date"),
                        "days_supply": meta.get("days_supply"),
                        "status": meta.get("status"),
                        "condition": meta.get("condition"),
                        "source": meta.get("source"),
                        "notes": meta.get("notes"),
                        "text": meta.get("text"),
                    }
                )
            return results
        except (TimeoutError, OSError, RuntimeError, ValueError) as exc:
            logger.error("Error executing Pinecone query for patient '%s': %s", patient_id, exc)
            return []

    def get_stats(self) -> dict[str, Any]:
        """Return index statistics and status."""
        if not self.is_available or not self._index:
            return {"status": "offline", "index_name": self.index_name, "total_vector_count": 0}

        try:
            stats = self._index.describe_index_stats()
            return {
                "status": "online",
                "index_name": self.index_name,
                "dimension": stats.dimension,
                "total_vector_count": stats.total_vector_count,
                "namespaces": stats.namespaces,
                "metric": stats.metric,
            }
        except (TimeoutError, OSError, RuntimeError, ValueError) as exc:
            return {"status": "error", "error": str(exc)}
