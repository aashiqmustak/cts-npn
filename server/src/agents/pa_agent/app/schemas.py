from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ClinicalInformation(BaseModel):
    model_config = ConfigDict(extra="allow")

    diagnosis: str | None = None
    lab_values: dict[str, Any] = Field(default_factory=dict)
    contraindications: list[str] = Field(default_factory=list)


class CriterionItem(BaseModel):
    criterion: str
    satisfied: bool


class EvidenceItem(BaseModel):
    source_id: str
    page: int


class PARequest(BaseModel):
    model_config = ConfigDict(extra="allow", populate_by_name=True)

    patient_id: str
    drug_id: str
    insurance_plan_id: str | None = None
    plan_id: str | None = None
    indication: str | None = None
    previous_medications: list[str] = Field(default_factory=list)
    clinical_information: ClinicalInformation = Field(default_factory=ClinicalInformation)

    @model_validator(mode="before")
    @classmethod
    def reconcile_plan_and_clinical_info(cls, values: Any) -> Any:
        if isinstance(values, dict):
            # Normalize insurance_plan_id / plan_id
            plan = values.get("insurance_plan_id") or values.get("plan_id") or ""
            values["insurance_plan_id"] = plan
            values["plan_id"] = plan

            # Normalize clinical_information
            ci = values.get("clinical_information")
            if ci is None:
                values["clinical_information"] = ClinicalInformation()
            elif isinstance(ci, dict):
                values["clinical_information"] = ClinicalInformation(**ci)
        return values


class PAResponse(BaseModel):
    drug_id: str
    pa_required: bool
    pa_status: str
    criteria: list[CriterionItem]
    missing_information: list[str]
    evidence: list[EvidenceItem]
