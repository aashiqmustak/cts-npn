import hashlib
import uuid


class InvoiceAgent:
    def generate_invoice(
        self,
        patient_id: str,
        original_drug: str,
        alternative_drug: str,
        tablet_cost: float,
        insurance_coverage: float = 0.0,
        approval_status: str = "PENDING",
        prescribing_physician: str | None = None,
        medical_facility: str | None = None,
        diagnosis: str | None = None,
        dosage_regimen: str | None = None,
        days_supply: int = 30,
        original_drug_cost: float | None = None,
        copay_discount: float = 0.0,
        prescription_id: str | None = None,
        pharmacy_name: str | None = None,
        include_html: bool = False,
    ) -> dict:

        if tablet_cost < 0:
            raise ValueError("tablet_cost cannot be negative")

        if insurance_coverage < 0:
            raise ValueError("insurance_coverage cannot be negative")

        if copay_discount < 0:
            raise ValueError("copay_discount cannot be negative")

        effective_insurance = min(insurance_coverage, tablet_cost)
        remaining_after_insurance = max(0.0, tablet_cost - effective_insurance)
        effective_copay = min(copay_discount, remaining_after_insurance)
        patient_payable = round(
            max(0.0, remaining_after_insurance - effective_copay), 2
        )

        # Baseline original brand cost if not provided (typical 2.5x to 4x of generic)
        if original_drug_cost is not None:
            if original_drug_cost < 0:
                raise ValueError("original_drug_cost cannot be negative")
            orig_cost = round(original_drug_cost, 2)
        else:
            orig_cost = round(max(tablet_cost * 2.5, tablet_cost + 45.0), 2)

        savings = round(max(0.0, orig_cost - patient_payable), 2)
        savings_percentage = (
            round((savings / orig_cost * 100), 1) if orig_cost > 0 else 0.0
        )

        inv_suffix = uuid.uuid4().hex[:5].upper()
        invoice_id = f"INV_{inv_suffix}"

        rx_id = (
            prescription_id if prescription_id else f"RX_{uuid.uuid4().hex[:5].upper()}"
        )
        if (
            not rx_id.startswith("#")
            and not rx_id.startswith("RX_")
            and not rx_id.startswith("RX-")
        ):
            rx_id = f"RX_{rx_id}"

        doc_name = prescribing_physician or "Dr. Lauren Sharma, MD"
        facility = medical_facility or "Ohio State University Wexner Medical Center"
        diag = diagnosis or "Epilepsy / Seizure Disorder"
        regimen = (
            dosage_regimen
            or "1 Tablet Oral - Twice Daily (Take as directed by physician)"
        )

        # Generate cryptographic signature stamp
        stamp_raw = f"{invoice_id}:{rx_id}:{patient_id}:{alternative_drug}:{patient_payable}:{approval_status}"
        stamp_hash = hashlib.sha256(stamp_raw.encode("utf-8")).hexdigest().upper()
        digital_stamp = f"SHA256-{stamp_hash[:16]}-{stamp_hash[-8:]}"

        result = {
            "invoice_id": invoice_id,
            "prescription_id": rx_id,
            "patient_id": patient_id,
            "prescribing_physician": doc_name,
            "medical_facility": facility,
            "diagnosis": diag,
            "original_drug": original_drug,
            "alternative_drug": alternative_drug,
            "dosage_regimen": regimen,
            "days_supply": int(days_supply),
            "original_drug_cost": orig_cost,
            "tablet_cost": round(tablet_cost, 2),
            "insurance_coverage": round(effective_insurance, 2),
            "copay_discount": round(effective_copay, 2),
            "patient_payable": patient_payable,
            "savings": savings,
            "savings_percentage": savings_percentage,
            "payment_status": (
                "NO PATIENT PAYMENT" if patient_payable == 0 else "PATIENT PAYMENT"
            ),
            "approval_status": approval_status,
            "digital_stamp": digital_stamp,
        }

        if include_html:
            from .invoice_template import generate_invoice_html

            result["html_invoice"] = generate_invoice_html(result)

        return result
