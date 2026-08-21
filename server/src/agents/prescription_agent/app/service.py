"""Service boundary for direct prescription normalization."""

from .agent import PrescriptionAgent
from .models import PrescriptionOutput


def normalize_prescription(
    patient_id: str,
    prescription_text: str,
    doctor_id: str,
    prescription_id: str | None = None,
) -> PrescriptionOutput:
    """Normalize prescription text for consumption by downstream agents."""
    return PrescriptionAgent().process(
        patient_id=patient_id,
        prescription_text=prescription_text,
        doctor_id=doctor_id,
        prescription_id=prescription_id,
    )


__all__ = ["normalize_prescription"]
