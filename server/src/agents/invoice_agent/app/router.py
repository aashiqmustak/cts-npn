from fastapi import APIRouter, Query
from fastapi.responses import HTMLResponse

from .agent import InvoiceAgent
from .invoice_template import generate_invoice_html
from .schemas import InvoiceRequest, InvoiceResponse

router = APIRouter(prefix="/invoice", tags=["Invoice Agent"])

agent = InvoiceAgent()


@router.get("/health")
def health():
    return {"status": "ok", "agent": "invoice_agent"}


@router.post("/generate", response_model=InvoiceResponse)
def generate_invoice(request: InvoiceRequest):
    return agent.generate_invoice(
        patient_id=request.patient_id,
        original_drug=request.original_drug,
        alternative_drug=request.alternative_drug,
        tablet_cost=request.tablet_cost,
        insurance_coverage=request.insurance_coverage,
        approval_status=request.approval_status,
        prescribing_physician=request.prescribing_physician,
        medical_facility=request.medical_facility,
        diagnosis=request.diagnosis,
        dosage_regimen=request.dosage_regimen,
        days_supply=request.days_supply or 30,
        original_drug_cost=request.original_drug_cost,
        copay_discount=request.copay_discount or 0.0,
        prescription_id=request.prescription_id,
        pharmacy_name=request.pharmacy_name,
        include_html=True,
    )


@router.get("/view", response_class=HTMLResponse)
def view_invoice(
    patient_id: str = Query("PAT-00181", description="Patient identifier"),
    original_drug: str = Query(
        "Keppra 500mg (Brand)", description="Original prescribed brand name"
    ),
    alternative_drug: str = Query(
        "Levetiracetam 500mg (Antiepileptic Therapy)",
        description="Substituted alternative drug",
    ),
    tablet_cost: float = Query(35.0, description="Alternative drug retail cost"),
    insurance_coverage: float = Query(
        30.0, description="Payer / insurance formulary coverage"
    ),
    approval_status: str = Query("APPROVED", description="Adjudication / PA status"),
    prescribing_physician: str | None = Query(
        "Dr. Lauren Sharma, MD", description="Doctor name"
    ),
    medical_facility: str | None = Query(
        "Ohio State University Wexner Medical Center", description="Hospital / Facility"
    ),
    diagnosis: str | None = Query(
        "Epilepsy / Seizure Disorder", description="Clinical diagnosis"
    ),
    dosage_regimen: str | None = Query(
        "1 Tablet Oral - Twice Daily (Take as directed by physician)",
        description="Dosage instructions",
    ),
    days_supply: int = Query(30, description="Supply duration in days"),
    original_drug_cost: float | None = Query(
        240.0, description="Original brand reference retail cost"
    ),
    copay_discount: float = Query(0.0, description="Copay assistance discount"),
    prescription_id: str | None = Query(
        "RX_00181", description="Associated prescription ID"
    ),
):
    invoice_data = agent.generate_invoice(
        patient_id=patient_id,
        original_drug=original_drug,
        alternative_drug=alternative_drug,
        tablet_cost=tablet_cost,
        insurance_coverage=insurance_coverage,
        approval_status=approval_status,
        prescribing_physician=prescribing_physician,
        medical_facility=medical_facility,
        diagnosis=diagnosis,
        dosage_regimen=dosage_regimen,
        days_supply=days_supply,
        original_drug_cost=original_drug_cost,
        copay_discount=copay_discount,
        prescription_id=prescription_id,
    )

    return generate_invoice_html(invoice_data)


@router.post("/view", response_class=HTMLResponse)
def render_invoice_post(request: InvoiceRequest):
    invoice_data = agent.generate_invoice(
        patient_id=request.patient_id,
        original_drug=request.original_drug,
        alternative_drug=request.alternative_drug,
        tablet_cost=request.tablet_cost,
        insurance_coverage=request.insurance_coverage,
        approval_status=request.approval_status,
        prescribing_physician=request.prescribing_physician,
        medical_facility=request.medical_facility,
        diagnosis=request.diagnosis,
        dosage_regimen=request.dosage_regimen,
        days_supply=request.days_supply or 30,
        original_drug_cost=request.original_drug_cost,
        copay_discount=request.copay_discount or 0.0,
        prescription_id=request.prescription_id,
        pharmacy_name=request.pharmacy_name,
    )

    return generate_invoice_html(invoice_data)
