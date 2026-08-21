"""Integration functions used by the orchestrator or formulary agent."""

from .schemas import PrescriptionOutput
from .service import normalize_prescription


def process_prescription(
    patient_id: str,
    prescription_text: str,
    doctor_id: str,
    prescription_id: str | None = None,
) -> PrescriptionOutput:
    """Return a normalized prescription without an HTTP server."""
    return normalize_prescription(
        patient_id=patient_id,
        prescription_text=prescription_text,
        doctor_id=doctor_id,
        prescription_id=prescription_id,
    )


__all__ = ["process_prescription"]
