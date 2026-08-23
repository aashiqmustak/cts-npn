import logging
import os
from datetime import UTC, datetime, timedelta
from itertools import pairwise
from typing import Any

from .repository import PatientHistoryRepository
from .schemas import (
    BatchIngestRequest,
    BatchIngestResponse,
    MedicationHistory,
    PatientHistoryRequest,
    PatientHistoryResponse,
    PatientRecordIngestResponse,
    PatientRecordInput,
    RAGMatchItem,
    RAGQueryRequest,
    RAGQueryResponse,
)

logger = logging.getLogger("patient_history_agent.service")


class PatientHistoryService:
    def __init__(self, repository: PatientHistoryRepository):
        self.repository = repository
        self._groq_client = None
        self._init_llm()

    def _init_llm(self) -> None:
        groq_key = os.getenv("GROQ_API_KEY", "").strip()
        if groq_key:
            try:
                from groq import Groq

                self._groq_client = Groq(api_key=groq_key)
            except (ImportError, RuntimeError, ValueError) as exc:
                logger.warning(
                    "Could not initialize Groq client for RAG synthesis: %s", exc
                )

    def get_patient_history(
        self, request: PatientHistoryRequest
    ) -> PatientHistoryResponse:
        records = self.repository.get_patient_records(patient_id=request.patient_id)

        if not records:
            # Check if any records exist in Pinecone
            rag_matches = self.repository.query_rag(
                patient_id=request.patient_id,
                drug_id=request.drug_id,
                top_k=10,
            )
            if rag_matches:
                records = rag_matches

        if not records:
            return PatientHistoryResponse(
                patient_id=request.patient_id,
                medication_history=MedicationHistory(
                    previous_pdc_180=0.0,
                    refill_gap_days_90=0,
                    prior_abandonment_count_12m=0,
                    prior_switch_count_12m=0,
                    medication_count=0,
                    conditions_count=0,
                ),
                history_status="NOT_AVAILABLE",
                rag_context=[],
                rag_summary="No prior medication fill records found for this patient.",
            )

        parsed_records = []
        for record in records:
            fill_val = record.get("fill_date")
            fill_date = None
            if isinstance(fill_val, datetime):
                fill_date = (
                    fill_val.replace(tzinfo=UTC)
                    if fill_val.tzinfo is None
                    else fill_val
                )
            elif isinstance(fill_val, str):
                try:
                    fill_date = datetime.strptime(fill_val.strip(), "%Y-%m-%d").replace(
                        tzinfo=UTC
                    )
                except (ValueError, TypeError):
                    continue

            if fill_date is None:
                continue

            try:
                days_supply = int(float(record.get("days_supply") or 0))
            except (ValueError, TypeError):
                days_supply = 0

            parsed_records.append(
                {
                    **record,
                    "fill_date": fill_date,
                    "days_supply": days_supply,
                }
            )

        if not parsed_records:
            return PatientHistoryResponse(
                patient_id=request.patient_id,
                medication_history=MedicationHistory(
                    previous_pdc_180=0.0,
                    refill_gap_days_90=0,
                    prior_abandonment_count_12m=0,
                    prior_switch_count_12m=0,
                    medication_count=0,
                    conditions_count=0,
                ),
                history_status="NOT_AVAILABLE",
            )

        latest_date = max(record["fill_date"] for record in parsed_records)
        lookback_start = latest_date - timedelta(days=request.lookback_days)

        history = [
            record for record in parsed_records if record["fill_date"] >= lookback_start
        ]

        drug_history = [
            record
            for record in history
            if str(record.get("drug_id") or "").strip().lower()
            == request.drug_id.strip().lower()
        ]

        previous_pdc_180 = self._calculate_pdc(drug_history, latest_date)
        refill_gap_days_90 = self._calculate_refill_gap(drug_history, latest_date)
        prior_abandonment_count = sum(
            1
            for record in history
            if str(record.get("status") or "").strip().upper() == "ABANDONED"
        )
        medication_count = len(
            {record.get("drug_id") for record in history if record.get("drug_id")}
        )
        conditions_count = len(
            {record.get("condition") for record in history if record.get("condition")}
        )
        prior_switch_count = max(medication_count - 1, 0)

        med_history = MedicationHistory(
            previous_pdc_180=round(previous_pdc_180, 2),
            refill_gap_days_90=refill_gap_days_90,
            prior_abandonment_count_12m=prior_abandonment_count,
            prior_switch_count_12m=prior_switch_count,
            medication_count=medication_count,
            conditions_count=conditions_count,
        )

        rag_context: list[dict[str, Any]] = []
        rag_summary = None

        if request.include_rag:
            rag_context = self.repository.query_rag(
                patient_id=request.patient_id,
                drug_id=request.drug_id,
                top_k=5,
            )
            rag_summary = self._synthesize_rag_summary(
                patient_id=request.patient_id,
                matches=rag_context,
                adherence=med_history,
            )

        return PatientHistoryResponse(
            patient_id=request.patient_id,
            medication_history=med_history,
            history_status="AVAILABLE",
            rag_context=rag_context,
            rag_summary=rag_summary,
        )

    def ingest_patient_record(
        self, record_input: PatientRecordInput
    ) -> PatientRecordIngestResponse:
        """Process and index a newly received patient record from the client."""
        rec_dict = record_input.model_dump()
        vector_id = self.repository.add_record(rec_dict, sync_pinecone=True)

        return PatientRecordIngestResponse(
            success=True,
            record_id=vector_id
            or f"mem_{record_input.patient_id}_{record_input.drug_id}",
            patient_id=record_input.patient_id,
            message="Patient record successfully saved to history repository and Pinecone vector store.",
            vector_id=vector_id,
        )

    def ingest_batch(self, batch: BatchIngestRequest) -> BatchIngestResponse:
        """Batch ingest records from client or bulk import."""
        count = 0
        for item in batch.records:
            self.repository.add_record(item.model_dump(), sync_pinecone=True)
            count += 1

        return BatchIngestResponse(
            success=True,
            records_ingested=count,
            message=f"Successfully ingested {count} patient history records.",
        )

    def query_rag(self, request: RAGQueryRequest) -> RAGQueryResponse:
        """Perform semantic RAG query against Pinecone patient history."""
        matches_raw = self.repository.query_rag(
            patient_id=request.patient_id,
            query=request.query,
            top_k=request.top_k,
            condition=request.condition,
            drug_id=request.drug_id,
        )

        matches: list[RAGMatchItem] = []
        for m in matches_raw:
            matches.append(
                RAGMatchItem(
                    id=str(m.get("id") or ""),
                    score=float(m.get("score") or 0.0),
                    patient_id=str(m.get("patient_id") or request.patient_id),
                    drug_id=str(m.get("drug_id") or ""),
                    fill_date=str(m.get("fill_date") or ""),
                    days_supply=int(float(m.get("days_supply") or 0)),
                    status=str(m.get("status") or "FILLED"),
                    condition=str(m.get("condition") or "Unspecified"),
                    source=str(m.get("source") or "dataset"),
                    text=str(m.get("text") or ""),
                    notes=str(m.get("notes") or ""),
                )
            )

        # Calculate adherence metrics if records available
        hist_resp = self.get_patient_history(
            PatientHistoryRequest(
                patient_id=request.patient_id,
                drug_id=request.drug_id
                or (matches[0].drug_id if matches else "UNKNOWN"),
            )
        )

        summary = self._synthesize_rag_summary(
            patient_id=request.patient_id,
            matches=matches_raw,
            adherence=hist_resp.medication_history,
            query=request.query,
        )

        return RAGQueryResponse(
            patient_id=request.patient_id,
            total_matched=len(matches),
            matches=matches,
            summary=summary,
            adherence_metrics=hist_resp.medication_history,
        )

    def sync_dataset_to_pinecone(self) -> dict[str, Any]:
        """Bulk index dataset records to Pinecone."""
        upserted = self.repository.sync_dataset_to_pinecone()
        stats = self.repository.pinecone.get_stats()
        return {
            "success": upserted > 0,
            "upserted_count": upserted,
            "pinecone_stats": stats,
        }

    def _calculate_pdc(self, records: list[dict], latest_date: datetime) -> float:
        start_date = latest_date - timedelta(days=180)
        records = [record for record in records if record["fill_date"] >= start_date]
        if not records:
            return 0.0
        covered_days = sum(record["days_supply"] for record in records)
        return min(covered_days / 180, 1.0)

    def _calculate_refill_gap(self, records: list[dict], latest_date: datetime) -> int:
        start_date = latest_date - timedelta(days=90)
        records = sorted(
            [record for record in records if record["fill_date"] >= start_date],
            key=lambda x: x["fill_date"],
        )
        if len(records) < 2:
            return 0
        total_gap = 0
        for previous, current in pairwise(records):
            expected_date = previous["fill_date"] + timedelta(
                days=previous["days_supply"]
            )
            if current["fill_date"] > expected_date:
                gap = (current["fill_date"] - expected_date).days
                total_gap += gap
        return total_gap

    def _synthesize_rag_summary(
        self,
        patient_id: str,
        matches: list[dict[str, Any]],
        adherence: MedicationHistory,
        query: str | None = None,
    ) -> str:
        """Synthesize clinical observations using LLM or structured rule-based generator."""
        if not matches:
            return f"Patient {patient_id} has no historical treatment or fill records available in Pinecone vector index."

        # Attempt LLM synthesis if Groq is available
        if self._groq_client:
            try:
                context_str = "\n".join(
                    [
                        f"- Date: {m.get('fill_date')}, Drug: {m.get('drug_id')}, Condition: {m.get('condition')}, Status: {m.get('status')}, Days Supply: {m.get('days_supply')}, Source: {m.get('source', 'dataset')}, Notes: {m.get('notes', '')}"
                        for m in matches
                    ]
                )
                prompt = (
                    f"You are a clinical pharmacist AI analyzing patient medication history retrieved from Pinecone Vector RAG.\n"
                    f"Patient ID: {patient_id}\n"
                    f"Retrieved Records:\n{context_str}\n\n"
                    f"Adherence Stats: PDC-180: {adherence.previous_pdc_180 * 100:.1f}%, Refill Gap: {adherence.refill_gap_days_90} days, Prior Abandonments: {adherence.prior_abandonment_count_12m}.\n"
                    f"User Query: {query or 'General therapy history summary'}\n\n"
                    f"Provide a concise, 2-3 sentence clinical history summary focusing on treatment continuity, adherence patterns, and condition management."
                )
                model_name = os.getenv("GROQ_MODEL", "openai/gpt-oss-120b")
                # Fallback to llama-3.3-70b-versatile if gpt-oss is specified or fails
                for try_model in [
                    model_name,
                    "llama-3.3-70b-versatile",
                    "llama-3.1-8b-instant",
                ]:
                    try:
                        resp = self._groq_client.chat.completions.create(
                            model=try_model,
                            messages=[{"role": "user", "content": prompt}],
                            temperature=0.2,
                            max_tokens=150,
                        )
                        content = resp.choices[0].message.content
                        if content:
                            return content.strip()
                    except (
                        RuntimeError,
                        ValueError,
                        TimeoutError,
                        OSError,
                    ) as model_exc:
                        logger.debug(
                            "Model %s generation retry: %s", try_model, model_exc
                        )
                        continue
            except (RuntimeError, ValueError, TimeoutError, OSError) as exc:
                logger.warning("LLM RAG summary generation fallback: %s", exc)

        # High quality clinical fallback synthesis
        drugs = list({str(m.get("drug_id")) for m in matches if m.get("drug_id")})
        conditions = list(
            {str(m.get("condition")) for m in matches if m.get("condition")}
        )
        abandoned = sum(
            1 for m in matches if str(m.get("status")).upper() == "ABANDONED"
        )

        adherence_str = (
            "Optimal (>=80%)"
            if adherence.previous_pdc_180 >= 0.80
            else "Sub-optimal (<80%)"
        )
        return (
            f"Patient {patient_id} has {len(matches)} retrieved history records spanning conditions ({', '.join(conditions)}) "
            f"and medications ({', '.join(drugs)}). Proportion of Days Covered (PDC) is {adherence.previous_pdc_180 * 100:.1f}% ({adherence_str}), "
            f"with {abandoned} recorded abandonments and a 90-day refill gap of {adherence.refill_gap_days_90} days."
        )
