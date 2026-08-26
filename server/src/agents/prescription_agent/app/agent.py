import logging
import uuid

from .config import REFERENCE_DATA_PATH
from .drug_mapper import DrugMapper
from .llm_extractor import LLMExtractor
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
        self.llm_extractor = LLMExtractor()

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

        if not patient_id or not patient_id.strip():
            raise ValueError("patient_id must not be empty")

        if not prescription_text or not prescription_text.strip():
            raise ValueError("prescription_text must not be empty")

        if not doctor_id or not doctor_id.strip():
            raise ValueError("doctor_id must not be empty")

        patient_id = patient_id.strip()
        doctor_id = doctor_id.strip()
        prescription_text = prescription_text.strip()

        llm_data = {}

        try:
            llm_data = self.llm_extractor.extract(prescription_text)
            logger.info("LLM extraction result: %s", llm_data)
        except (OSError, RuntimeError, TypeError, ValueError) as exc:
            logger.warning("LLM extraction failed: %s", exc)

        llm_drug_name = llm_data.get("drug_name")
        llm_strength = llm_data.get("strength")
        llm_dose = llm_data.get("dose")
        llm_frequency = llm_data.get("frequency")
        llm_route = llm_data.get("route")
        llm_duration = llm_data.get("duration_days")
        llm_indication = llm_data.get("indication")

        clean_text = TextPreprocessor.preprocess(prescription_text)

        drug_search_text = llm_drug_name if llm_drug_name else clean_text

        drug_match = self.drug_mapper.find_match(drug_search_text)

        if drug_match:
            logger.info(
                "Identified drug: %s (RxNorm: %s, confidence: %.2f)",
                drug_match.canonical_drug_name,
                drug_match.rxnorm_id,
                drug_match.confidence,
            )
        else:
            logger.warning(
                "Unrecognized drug: '%s'",
                llm_drug_name or prescription_text,
            )

        def_strength = drug_match.default_strength if drug_match else None
        def_dose = drug_match.default_dose if drug_match else None
        def_freq = drug_match.default_frequency if drug_match else None
        def_route = drug_match.default_route if drug_match else None
        def_dur = drug_match.default_duration if drug_match else None

        strength = (
            llm_strength
            if llm_strength
            else StrengthExtractor.extract(
                clean_text,
                default_strength=def_strength,
            )
        )

        dose = (
            llm_dose
            if llm_dose
            else DoseExtractor.extract(
                clean_text,
                extracted_strength=strength,
                default_dose=def_dose,
            )
        )

        frequency = (
            llm_frequency
            if llm_frequency
            else FrequencyNormalizer.normalize(
                clean_text,
                default_frequency=def_freq,
            )
        )

        route = (
            llm_route
            if llm_route
            else RouteNormalizer.normalize(
                clean_text,
                default_route=def_route,
            )
        )

        duration_days = (
            llm_duration
            if llm_duration is not None
            else DurationExtractor.extract(
                clean_text,
                default_duration=def_dur,
            )
        )

        indication = (
            llm_indication
            if llm_indication
            else IndicationExtractor.extract(
                clean_text,
                default_indication=None,
            )
        )

        confidence, status, drug_details = PrescriptionValidator.validate_and_score(
            drug_match=drug_match,
            strength=strength,
            dose=dose,
            frequency=frequency,
            route=route,
            duration_days=duration_days,
            indication=indication,
        )

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
