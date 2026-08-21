from pydantic import BaseModel, Field


class DrugDetails(BaseModel):
    name: str | None = Field(
        None, description="Canonical drug name or active ingredient"
    )
    rxnorm_id: str | None = Field(
        None, description="RxNorm Concept Unique Identifier (RxCUI)"
    )
    strength: str | None = Field(
        None, description="Normalized medication strength (e.g. 20 mg, 100 units/mL)"
    )
    dose: str | None = Field(
        None, description="Prescribed dosage quantity (e.g. 20 mg, 1 tablet, 2 puffs)"
    )
    frequency: str | None = Field(
        None, description="Normalized frequency code (e.g. once_daily, twice_daily)"
    )
    route: str | None = Field(
        None, description="Normalized route of administration (e.g. oral, subcutaneous)"
    )
    duration_days: int | None = Field(
        None, description="Duration of prescription therapy in integer days"
    )


class PrescriptionOutput(BaseModel):
    patient_id: str = Field(..., description="Patient identifier preserved from input")
    prescription_id: str = Field(..., description="Unique prescription identifier")
    drug: DrugDetails = Field(
        default_factory=DrugDetails,
        description="Structured drug and regimen information",
    )
    indication: str | None = Field(
        None, description="Explicit clinical indication if present, else null"
    )
    confidence: float = Field(
        ..., description="Explainable extraction confidence score between 0.0 and 1.0"
    )
    status: str = Field(
        ...,
        description="Processing status: NORMALIZED, INCOMPLETE, UNRECOGNIZED_DRUG, VALIDATION_FAILED",
    )
