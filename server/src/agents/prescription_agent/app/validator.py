from typing import Any

from .config import CONFIDENCE_WEIGHTS, MIN_CONFIDENCE_THRESHOLD
from .models import DrugDetails


class PrescriptionValidator:
    @staticmethod
    def validate_and_score(
        drug_match: Any | None,
        strength: str | None,
        dose: str | None,
        frequency: str | None,
        route: str | None,
        duration_days: int | None,
        indication: str | None,
    ) -> tuple[float, str, DrugDetails]:
        """
        Validates extracted fields, computes an explainable confidence score,
        and assigns a standard processing status.
        """
        scores: dict[str, float] = {
            "drug_identification": 0.0,
            "rxnorm_mapping": 0.0,
            "strength_extraction": 0.0,
            "dose_extraction": 0.0,
            "frequency_extraction": 0.0,
            "route_extraction": 0.0,
            "duration_extraction": 0.0,
        }

        drug_name = None
        rxnorm_id = None

        if drug_match is not None:
            drug_name = drug_match.canonical_drug_name
            rxnorm_id = drug_match.rxnorm_id
            scores["drug_identification"] = float(drug_match.confidence)

            if rxnorm_id and rxnorm_id != "nan" and str(rxnorm_id).isdigit():
                scores["rxnorm_mapping"] = 1.0

        if strength:
            scores["strength_extraction"] = 1.0

        if dose:
            scores["dose_extraction"] = 1.0

        if frequency:
            scores["frequency_extraction"] = 1.0

        if route:
            scores["route_extraction"] = 1.0

        if duration_days and duration_days > 0:
            scores["duration_extraction"] = 1.0

        total = sum(scores[k] * CONFIDENCE_WEIGHTS[k] for k in CONFIDENCE_WEIGHTS)
        total_confidence = round(total, 2)

        drug_details = DrugDetails(
            name=drug_name,
            rxnorm_id=rxnorm_id,
            strength=strength,
            dose=dose,
            frequency=frequency,
            route=route,
            duration_days=duration_days,
        )

        if (
            drug_match is None
            or scores["drug_identification"] < MIN_CONFIDENCE_THRESHOLD
        ):
            status = "UNRECOGNIZED_DRUG"
        elif not strength or not frequency or not route:
            status = "INCOMPLETE"
        else:
            status = "NORMALIZED"

        return total_confidence, status, drug_details
