import logging
import uuid

from .config import REFERENCE_DATA_PATH
from .drug_mapper import DrugMapper
from .models import PrescriptionOutput
from .normalizer import (
    DoseExtractor,
    DurationExtractor,
    FrequencyNormalizer,
    IndicationExtractor,
    RouteNormalizer,
    StrengthExtractor,
    TextPreprocessor,
)
from .validator import PrescriptionValidator

logger = logging.getLogger("prescription_agent")


class PrescriptionAgent:
    def __init__(self, reference_path: str = REFERENCE_DATA_PATH):
        self.drug_mapper = DrugMapper(reference_path=reference_path)
        logger.info(
            "PrescriptionAgent initialized with %d reference drugs.",
            self.drug_mapper.count(),
        )

    def process(
        self,
        patient_id: str,
        prescription_text: str,
        doctor_id: str,
        prescription_id: str | None = None,
    ) -> PrescriptionOutput:
        logger.info(
            "Processing prescription for patient_id: %s, doctor_id: %s",
            patient_id,
            doctor_id,
        )

        # 1. Input Validation
        if not patient_id or not patient_id.strip():
            raise ValueError("patient_id must not be empty")
        if not prescription_text or not prescription_text.strip():
            raise ValueError("prescription_text must not be empty")
        if not doctor_id or not doctor_id.strip():
            raise ValueError("doctor_id must not be empty")

        patient_id = patient_id.strip()
        doctor_id = doctor_id.strip()

        # 2. Text Preprocessing
        clean_text = TextPreprocessor.preprocess(prescription_text)

        # 3. Drug Matching & Identification
        drug_match = self.drug_mapper.find_match(clean_text)
        if drug_match:
            logger.info(
                "Identified drug: %s (RxNorm: %s, confidence: %.2f)",
                drug_match.canonical_drug_name,
                drug_match.rxnorm_id,
                drug_match.confidence,
            )
        else:
            logger.warning(
                "Unrecognized drug in prescription text: '%s'", prescription_text
            )

        def_strength = drug_match.default_strength if drug_match else None
        def_dose = drug_match.default_dose if drug_match else None
        def_freq = drug_match.default_frequency if drug_match else None
        def_route = drug_match.default_route if drug_match else None
        def_dur = drug_match.default_duration if drug_match else None

        # 4. Strength Extraction
        strength = StrengthExtractor.extract(clean_text, default_strength=def_strength)

        # 5. Dose Extraction
        dose = DoseExtractor.extract(
            clean_text, extracted_strength=strength, default_dose=def_dose
        )

        # 6. Frequency Normalization
        frequency = FrequencyNormalizer.normalize(
            clean_text, default_frequency=def_freq
        )

        # 7. Route Normalization
        route = RouteNormalizer.normalize(clean_text, default_route=def_route)

        # 8. Duration Extraction
        duration_days = DurationExtractor.extract(clean_text, default_duration=def_dur)

        # 9. Explicit Indication Extraction
        indication = IndicationExtractor.extract(clean_text, default_indication=None)

        # 10. Validation & Confidence Scoring
        confidence, status, drug_details = PrescriptionValidator.validate_and_score(
            drug_match=drug_match,
            strength=strength,
            dose=dose,
            frequency=frequency,
            route=route,
            duration_days=duration_days,
            indication=indication,
        )

        # 11. Prescription ID generation
        if not prescription_id or not prescription_id.strip():
            rx_suffix = uuid.uuid4().hex[:8].upper()
            prescription_id = f"RX_{rx_suffix}"
        else:
            prescription_id = prescription_id.strip()

        logger.info(
            "Prescription %s normalized with status: %s, confidence: %.2f",
            prescription_id,
            status,
            confidence,
        )

        return PrescriptionOutput(
            patient_id=patient_id,
            prescription_id=prescription_id,
            drug=drug_details,
            indication=indication,
            confidence=confidence,
            status=status,
        )
