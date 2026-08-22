from pydantic import BaseModel


class InvoiceRequest(BaseModel):
    patient_id: str
    original_drug: str
    alternative_drug: str
    tablet_cost: float
    insurance_coverage: float = 0.0
    approval_status: str = "PENDING"
    prescribing_physician: str | None = "Dr. Lauren Sharma, MD"
    medical_facility: str | None = "Ohio State University Wexner Medical Center"
    diagnosis: str | None = "Epilepsy / Seizure Disorder"
    dosage_regimen: str | None = (
        "1 Tablet Oral - Twice Daily (Take as directed by physician)"
    )
    days_supply: int | None = 30
    original_drug_cost: float | None = None
    copay_discount: float | None = 0.0
    prescription_id: str | None = None
    pharmacy_name: str | None = "Alternea Central Clinical Pharmacy"


class InvoiceResponse(BaseModel):
    invoice_id: str
    prescription_id: str
    patient_id: str
    prescribing_physician: str
    medical_facility: str
    diagnosis: str
    original_drug: str
    alternative_drug: str
    dosage_regimen: str
    days_supply: int
    original_drug_cost: float
    tablet_cost: float
    insurance_coverage: float
    copay_discount: float
    patient_payable: float
    savings: float
    savings_percentage: float
    payment_status: str
    approval_status: str
    digital_stamp: str
    html_invoice: str | None = None
