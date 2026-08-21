from datetime import datetime, timedelta

from .repository import PatientHistoryRepository
from .schemas import (
    MedicationHistory,
    PatientHistoryRequest,
    PatientHistoryResponse,
)


class PatientHistoryService:

    def __init__(
        self,
        repository: PatientHistoryRepository
    ):
        self.repository = repository

    def get_patient_history(
        self,
        request: PatientHistoryRequest
    ) -> PatientHistoryResponse:

        records = self.repository.get_patient_records(
            patient_id=request.patient_id
        )

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
            )

        parsed_records = []

        for record in records:

            try:
                fill_date = datetime.strptime(
                    str(record.get("fill_date")),
                    "%Y-%m-%d"
                )
            except (ValueError, TypeError):
                continue

            try:
                days_supply = int(
                    float(record.get("days_supply") or 0)
                )
            except (ValueError, TypeError):
                days_supply = 0

            parsed_records.append({
                **record,
                "fill_date": fill_date,
                "days_supply": days_supply,
            })

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

        latest_date = max(
            record["fill_date"]
            for record in parsed_records
        )

        lookback_start = (
            latest_date -
            timedelta(days=request.lookback_days)
        )

        history = [
            record
            for record in parsed_records
            if record["fill_date"] >= lookback_start
        ]

        drug_history = [
            record
            for record in history
            if str(record.get("drug_id") or "").strip().lower()
            == request.drug_id.strip().lower()
        ]

        previous_pdc_180 = self._calculate_pdc(
            drug_history,
            latest_date
        )

        refill_gap_days_90 = self._calculate_refill_gap(
            drug_history,
            latest_date
        )

        prior_abandonment_count = sum(
            1
            for record in history
            if str(record.get("status") or "").strip().upper()
            == "ABANDONED"
        )

        medication_count = len({
            record.get("drug_id")
            for record in history
            if record.get("drug_id")
        })

        conditions_count = len({
            record.get("condition")
            for record in history
            if record.get("condition")
        })

        prior_switch_count = max(
            medication_count - 1,
            0
        )

        return PatientHistoryResponse(
            patient_id=request.patient_id,
            medication_history=MedicationHistory(
                previous_pdc_180=round(
                    previous_pdc_180,
                    2
                ),
                refill_gap_days_90=refill_gap_days_90,
                prior_abandonment_count_12m=prior_abandonment_count,
                prior_switch_count_12m=prior_switch_count,
                medication_count=medication_count,
                conditions_count=conditions_count,
            ),
            history_status="AVAILABLE",
        )

    def _calculate_pdc(
        self,
        records: list[dict],
        latest_date: datetime
    ) -> float:

        start_date = latest_date - timedelta(days=180)

        records = [
            record
            for record in records
            if record["fill_date"] >= start_date
        ]

        if not records:
            return 0.0

        covered_days = sum(
            record["days_supply"]
            for record in records
        )

        return min(
            covered_days / 180,
            1.0
        )

    def _calculate_refill_gap(
        self,
        records: list[dict],
        latest_date: datetime
    ) -> int:

        start_date = latest_date - timedelta(days=90)

        records = sorted(
            [
                record
                for record in records
                if record["fill_date"] >= start_date
            ],
            key=lambda x: x["fill_date"]
        )

        if len(records) < 2:
            return 0

        total_gap = 0

        for previous, current in zip(
            records,
            records[1:]
        ):
            expected_date = (
                previous["fill_date"] +
                timedelta(days=previous["days_supply"])
            )

            if current["fill_date"] > expected_date:

                gap = (
                    current["fill_date"] -
                    expected_date
                ).days

                total_gap += gap

        return total_gap