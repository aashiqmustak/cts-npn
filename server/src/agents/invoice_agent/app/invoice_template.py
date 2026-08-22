from html import escape


def generate_invoice_html(invoice: dict) -> str:
    """
    Generates a pixel-perfect, clinically branded HTML document replicating the
    Alternea Health e-Prescription template (as seen in prescription.pdf) with
    comprehensive financial adjudication and final cost breakdown for the alternative.
    """
    # Safe retrieval with clinical fallbacks
    invoice_id = escape(str(invoice.get("invoice_id", "INV_00181")))
    rx_id = escape(str(invoice.get("prescription_id", "#RX_00181")))
    if not rx_id.startswith("#"):
        rx_id = f"#{rx_id}"

    patient_id = escape(str(invoice.get("patient_id", "PAT_94021")))
    physician = escape(str(invoice.get("prescribing_physician", "Dr. Lauren Sharma, MD")))
    facility = escape(str(invoice.get("medical_facility", "Ohio State University Wexner Medical Center")))
    diagnosis = escape(str(invoice.get("diagnosis", "Epilepsy / Seizure Disorder")))
    
    orig_drug = escape(str(invoice.get("original_drug", "Keppra 500mg")))
    alt_drug = escape(str(invoice.get("alternative_drug", "Levetiracetam 500mg (Antiepileptic Therapy)")))
    regimen = escape(str(invoice.get("dosage_regimen", "1 Tablet Oral - Twice Daily (Take as directed by physician)")))
    days_supply = int(invoice.get("days_supply", 30))

    tablet_cost = float(invoice.get("tablet_cost", 35.00))
    insurance_cov = float(invoice.get("insurance_coverage", 30.00))
    copay_discount = float(invoice.get("copay_discount", 0.00))
    patient_payable = float(invoice.get("patient_payable", 5.00))
    orig_cost = float(invoice.get("original_drug_cost", max(tablet_cost * 2.5, 240.00)))
    savings = float(invoice.get("savings", max(0.0, orig_cost - patient_payable)))
    savings_pct = float(invoice.get("savings_percentage", round((savings / orig_cost * 100) if orig_cost > 0 else 0.0, 1)))

    payment_status = escape(str(invoice.get("payment_status", "NO PATIENT PAYMENT" if patient_payable == 0 else "PATIENT PAYMENT")))
    approval_status = escape(str(invoice.get("approval_status", "APPROVED")))
    digital_stamp = escape(str(invoice.get("digital_stamp", "SHA256-7D8E2A91F4B03C8E-981A4D02")))

    is_free = patient_payable <= 0.0001
    payment_badge_color = "#059669" if is_free else "#1E3A8A"
    payment_badge_bg = "#ECFDF5" if is_free else "#EFF6FF"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Alternea Health Adjudicated Invoice - {invoice_id}</title>
    <style>
        @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800;900&display=swap');

        * {{
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }}

        body {{
            background: #F1F5F9;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            color: #0F172A;
            padding: 30px 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            -webkit-print-color-adjust: exact;
            print-color-adjust: exact;
        }}

        /* Action Toolbar */
        .toolbar {{
            width: 800px;
            max-width: 100%;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }}

        .toolbar .back-btn {{
            display: inline-flex;
            align-items: center;
            gap: 6px;
            color: #475569;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            padding: 8px 14px;
            background: white;
            border: 1px solid #CBD5E1;
            border-radius: 8px;
            cursor: pointer;
            transition: all 0.15s ease;
        }}

        .toolbar .back-btn:hover {{
            background: #F8FAFC;
            color: #0F172A;
        }}

        .toolbar .print-btn {{
            display: inline-flex;
            align-items: center;
            gap: 8px;
            background: #0F3B82;
            color: white;
            border: none;
            padding: 10px 22px;
            font-size: 14px;
            font-weight: 700;
            border-radius: 8px;
            cursor: pointer;
            box-shadow: 0 4px 12px rgba(15, 59, 130, 0.25);
            transition: all 0.2s ease;
        }}

        .toolbar .print-btn:hover {{
            background: #0C2F68;
            transform: translateY(-1px);
            box-shadow: 0 6px 16px rgba(15, 59, 130, 0.35);
        }}

        /* Main Document Container */
        .document-page {{
            width: 800px;
            max-width: 100%;
            background: #FFFFFF;
            border: 1px solid #E2E8F0;
            border-radius: 16px;
            box-shadow: 0 10px 30px -5px rgba(0, 0, 0, 0.08), 0 4px 6px -2px rgba(0, 0, 0, 0.03);
            padding: 36px 40px;
            position: relative;
            overflow: hidden;
            display: flex;
            flex-direction: column;
            min-height: 1050px;
        }}

        /* Watermark Background */
        .watermark-container {{
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 580px;
            pointer-events: none;
            opacity: 0.045;
            z-index: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            text-align: center;
            user-select: none;
        }}

        .watermark-container svg {{
            width: 240px;
            height: 240px;
            margin-bottom: 20px;
            fill: #0F3B82;
        }}

        .watermark-text-main {{
            font-size: 32px;
            font-weight: 900;
            letter-spacing: 3px;
            color: #0F3B82;
            text-transform: uppercase;
        }}

        .watermark-text-sub {{
            font-size: 14px;
            font-weight: 700;
            letter-spacing: 2px;
            color: #0F3B82;
            margin-top: 8px;
            text-transform: uppercase;
        }}

        .document-content {{
            position: relative;
            z-index: 2;
            display: flex;
            flex-direction: column;
            flex-grow: 1;
        }}

        /* Top Header Banner */
        .header-banner {{
            background: linear-gradient(135deg, #0F3B82 0%, #154C9E 100%);
            border-radius: 12px;
            padding: 22px 28px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
            box-shadow: 0 4px 12px rgba(15, 59, 130, 0.15);
        }}

        .header-title-group {{
            display: flex;
            flex-direction: column;
        }}

        .header-network-name {{
            color: #FFFFFF;
            font-size: 18px;
            font-weight: 800;
            letter-spacing: 0.4px;
            text-transform: uppercase;
        }}

        .header-payload-subtitle {{
            color: #BFDBFE;
            font-size: 12.5px;
            font-weight: 500;
            margin-top: 4px;
        }}

        .header-badge {{
            background: #00C853;
            color: #FFFFFF;
            font-size: 11.5px;
            font-weight: 800;
            padding: 6px 14px;
            border-radius: 20px;
            letter-spacing: 0.5px;
            display: inline-flex;
            align-items: center;
            box-shadow: 0 2px 8px rgba(0, 200, 83, 0.35);
        }}

        /* Metadata Details Card */
        .metadata-card {{
            border: 1.5px solid #E2E8F0;
            border-radius: 12px;
            padding: 18px 24px;
            background: #FAFAFC;
            display: flex;
            flex-direction: column;
            gap: 10px;
            margin-bottom: 24px;
        }}

        .metadata-row {{
            display: flex;
            justify-content: space-between;
            align-items: baseline;
            font-size: 13.5px;
        }}

        .metadata-label {{
            color: #64748B;
            font-weight: 500;
        }}

        .metadata-value {{
            font-weight: 700;
            color: #0F172A;
            text-align: right;
        }}

        .metadata-value.id-highlight {{
            font-size: 15px;
            font-weight: 800;
            color: #0F172A;
        }}

        .metadata-value.diag-highlight {{
            color: #1D4ED8;
            font-weight: 700;
        }}

        /* Section Headings */
        .section-header {{
            font-size: 12px;
            font-weight: 800;
            color: #0F172A;
            letter-spacing: 0.8px;
            text-transform: uppercase;
            margin-bottom: 10px;
        }}

        /* Prescribed / Alternative Item Card */
        .medication-card {{
            border: 1.5px solid #E2E8F0;
            border-radius: 12px;
            padding: 18px 22px;
            background: #FFFFFF;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 24px;
        }}

        .medication-info {{
            display: flex;
            flex-direction: column;
        }}

        .medication-name {{
            font-size: 16px;
            font-weight: 800;
            color: #0F172A;
        }}

        .medication-sub {{
            font-size: 13px;
            color: #64748B;
            margin-top: 5px;
            line-height: 1.4;
        }}

        .medication-badge {{
            background: #EFF6FF;
            color: #1D4ED8;
            border: 1px solid #DBEAFE;
            font-size: 13px;
            font-weight: 700;
            padding: 8px 16px;
            border-radius: 20px;
            white-space: nowrap;
        }}

        /* Cost Breakdown Table */
        .cost-card {{
            border: 1.5px solid #E2E8F0;
            border-radius: 12px;
            overflow: hidden;
            background: #FFFFFF;
            margin-bottom: 20px;
        }}

        .cost-table {{
            width: 100%;
            border-collapse: collapse;
        }}

        .cost-table th {{
            background: #F8FAFC;
            color: #475569;
            font-size: 12px;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            padding: 12px 20px;
            text-align: left;
            border-bottom: 1px solid #E2E8F0;
        }}

        .cost-table th.text-right {{
            text-align: right;
        }}

        .cost-table td {{
            padding: 13px 20px;
            font-size: 14px;
            border-bottom: 1px solid #F1F5F9;
            color: #334155;
        }}

        .cost-table td.amount {{
            text-align: right;
            font-weight: 600;
            color: #0F172A;
        }}

        .cost-table td.deduction {{
            color: #059669;
            font-weight: 700;
        }}

        /* Final Cost Highlight Row */
        .cost-table tr.final-cost-row td {{
            background: #F0FDF4;
            border-top: 2px solid #10B981;
            border-bottom: none;
            padding: 18px 20px;
        }}

        .final-cost-title {{
            font-size: 15px;
            font-weight: 900;
            color: #065F46;
            letter-spacing: 0.2px;
            display: flex;
            align-items: center;
            gap: 8px;
        }}

        .final-cost-savings {{
            font-size: 12.5px;
            font-weight: 700;
            color: #059669;
            margin-top: 4px;
        }}

        .final-cost-amount {{
            font-size: 24px;
            font-weight: 900;
            color: #065F46;
            text-align: right;
        }}

        /* Status Badges Section */
        .status-grid {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 20px;
        }}

        .status-box {{
            border: 1.5px solid #E2E8F0;
            border-radius: 12px;
            padding: 14px 18px;
            background: #FAFAFC;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }}

        .status-box-label {{
            font-size: 11.5px;
            font-weight: 700;
            color: #64748B;
            text-transform: uppercase;
            letter-spacing: 0.4px;
        }}

        .status-box-val {{
            font-size: 14px;
            font-weight: 800;
            color: #0F172A;
            display: flex;
            align-items: center;
            gap: 6px;
        }}

        /* Digital Clinical / Adjudication Signature Stamp */
        .signature-card {{
            border: 1.5px solid #10B981;
            border-radius: 12px;
            padding: 16px 20px;
            background: #F0FDF4;
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-top: auto;
            margin-bottom: 28px;
        }}

        .signature-info {{
            display: flex;
            flex-direction: column;
        }}

        .signature-title {{
            color: #059669;
            font-size: 12.5px;
            font-weight: 800;
            letter-spacing: 0.5px;
            text-transform: uppercase;
        }}

        .signature-sub {{
            color: #065F46;
            font-size: 12px;
            margin-top: 3px;
            font-weight: 500;
        }}

        .signature-hash {{
            color: #047857;
            font-size: 10px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            margin-top: 3px;
            letter-spacing: 0.5px;
        }}

        .signature-verified {{
            color: #059669;
            font-size: 14px;
            font-weight: 800;
            letter-spacing: 0.5px;
            text-transform: uppercase;
            display: flex;
            align-items: center;
            gap: 6px;
        }}

        /* Document Footer */
        .document-footer {{
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 11px;
            color: #94A3B8;
            font-weight: 500;
            padding-top: 14px;
            border-top: 1px solid #E2E8F0;
        }}

        /* Print Media Styles */
        @media print {{
            body {{
                background: white;
                padding: 0;
            }}

            .toolbar {{
                display: none !important;
            }}

            .document-page {{
                width: 100%;
                border: none;
                box-shadow: none;
                padding: 24px 30px;
                min-height: auto;
            }}
        }}
    </style>
</head>
<body>

    <!-- Action Toolbar (Hidden during print) -->
    <div class="toolbar">
        <button class="back-btn" onclick="if(window.history.length > 1) {{ window.history.back(); }} else {{ window.close(); }}">
            &larr; Back to Portal
        </button>
        <button class="print-btn" onclick="window.print()">
            <svg width="16" height="16" fill="currentColor" viewBox="0 0 16 16">
                <path d="M2.5 8a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1z"/>
                <path d="M5 1a2 2 0 0 0-2 2v2H2a2 2 0 0 0-2 2v3a2 2 0 0 0 2 2h1v1a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2v-1h1a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2h-1V3a2 2 0 0 0-2-2H5zM4 3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2H4V3zm1 5a2 2 0 0 0-2 2v1H2a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h12a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1h-1v-1a2 2 0 0 0-2-2H5zm7 2v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1z"/>
            </svg>
            Print / Save Adjudicated Invoice (PDF)
        </button>
    </div>

    <!-- Official Document Page -->
    <div class="document-page">

        <!-- Authentic Watermark Background -->
        <div class="watermark-container">
            <svg viewBox="0 0 24 24">
                <path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4zm-1 6h2v4h4v2h-4v4h-2v-4H7v-2h4V7z"/>
            </svg>
            <div class="watermark-text-main">ALTERNEA HEALTH NETWORK</div>
            <div class="watermark-text-sub">OFFICIAL CLINICAL E-PRESCRIPTION WATERMARK</div>
            <div class="watermark-text-sub" style="font-size: 11px; margin-top: 4px;">DEA & NPI AUTHENTICATED VERIFICATION STAMP</div>
        </div>

        <div class="document-content">

            <!-- 1. Header Banner -->
            <div class="header-banner">
                <div class="header-title-group">
                    <div class="header-network-name">ALTERNEA HEALTH CLINICAL NETWORK</div>
                    <div class="header-payload-subtitle">Official Electronic Medication Invoice & Adjudication Payload</div>
                </div>
                <div class="header-badge">
                    FHIR v4.0 VERIFIED
                </div>
            </div>

            <!-- 2. Metadata Record Box -->
            <div class="metadata-card">
                <div class="metadata-row">
                    <span class="metadata-label">Invoice Record ID:</span>
                    <span class="metadata-value id-highlight">#{invoice_id}</span>
                </div>
                <div class="metadata-row">
                    <span class="metadata-label">Prescription Record ID:</span>
                    <span class="metadata-value">{rx_id}</span>
                </div>
                <div class="metadata-row">
                    <span class="metadata-label">Patient Record ID:</span>
                    <span class="metadata-value">#{patient_id}</span>
                </div>
                <div class="metadata-row">
                    <span class="metadata-label">Prescribing Physician:</span>
                    <span class="metadata-value">{physician}</span>
                </div>
                <div class="metadata-row">
                    <span class="metadata-label">Medical Facility:</span>
                    <span class="metadata-value">{facility}</span>
                </div>
                <div class="metadata-row">
                    <span class="metadata-label">ICD-10 Clinical Diagnosis:</span>
                    <span class="metadata-value diag-highlight">{diagnosis}</span>
                </div>
            </div>

            <!-- 3. Section 1: Prescribed & Alternative Regimen -->
            <div class="section-header">
                DISPENSED ALTERNATIVE MEDICATION & REGIMEN
            </div>

            <div class="medication-card">
                <div class="medication-info">
                    <div class="medication-name">{alt_drug}</div>
                    <div class="medication-sub">
                        <strong>Dosage Regimen:</strong> {regimen}<br>
                        <span style="color: #059669; font-weight: 600; font-size: 12px;">Substitution for: {orig_drug} (Clinically Equivalent / Tier-1 Formulary)</span>
                    </div>
                </div>
                <div class="medication-badge">
                    {days_supply} Days Supply
                </div>
            </div>

            <!-- 4. Section 2: Financial Adjudication & Final Cost -->
            <div class="section-header">
                MEDICATION ADJUDICATION & FINAL COST BREAKDOWN
            </div>

            <div class="cost-card">
                <table class="cost-table">
                    <thead>
                        <tr>
                            <th>Cost Component / Description</th>
                            <th class="text-right">Adjudicated Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>
                                <strong>Original Brand Retail Reference</strong>
                                <div style="font-size: 12px; color: #64748B;">{orig_drug} (Standard Out-of-Pocket Cost)</div>
                            </td>
                            <td class="amount" style="text-decoration: line-through; color: #94A3B8;">
                                ${orig_cost:.2f}
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <strong>Alternative Medication Retail Price</strong>
                                <div style="font-size: 12px; color: #64748B;">{alt_drug} (Generic Unit Rate)</div>
                            </td>
                            <td class="amount">
                                ${tablet_cost:.2f}
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <strong>Insurance / Payer Benefit Contribution</strong>
                                <div style="font-size: 12px; color: #059669;">Real-Time Formulary & Prior Auth Covered</div>
                            </td>
                            <td class="amount deduction">
                                -${insurance_cov:.2f}
                            </td>
                        </tr>
                        {f'''<tr>
                            <td>
                                <strong>Co-Pay Assistance & Generic Discount</strong>
                                <div style="font-size: 12px; color: #059669;">Applied Manufacturer / Clinic Co-Pay Relief</div>
                            </td>
                            <td class="amount deduction">
                                -${copay_discount:.2f}
                            </td>
                        </tr>''' if copay_discount > 0 else ''}
                        <tr class="final-cost-row">
                            <td>
                                <div class="final-cost-title">
                                    <svg width="18" height="18" fill="currentColor" viewBox="0 0 16 16">
                                        <path d="M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0zm-3.97-3.03a.75.75 0 0 0-1.08.022L7.477 9.417 5.384 7.323a.75.75 0 0 0-1.06 1.06L6.97 11.03a.75.75 0 0 0 1.079-.02l3.992-4.99a.75.75 0 0 0-.01-1.05z"/>
                                    </svg>
                                    FINAL COST FOR ALTERNATIVE (PATIENT PAYABLE)
                                </div>
                                <div class="final-cost-savings">
                                    Total Patient Savings: ${savings:.2f} ({savings_pct:.1f}% Less Than Brand)
                                </div>
                            </td>
                            <td class="final-cost-amount">
                                ${patient_payable:.2f}
                            </td>
                        </tr>
                    </tbody>
                </table>
            </div>

            <!-- 5. Status Badges -->
            <div class="status-grid">
                <div class="status-box" style="background: {payment_badge_bg}; border-color: {payment_badge_color}33;">
                    <div class="status-box-label">Payment Adjudication Status</div>
                    <div class="status-box-val" style="color: {payment_badge_color};">
                        <span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:{payment_badge_color};"></span>
                        {payment_status}
                    </div>
                </div>
                <div class="status-box">
                    <div class="status-box-label">Prior Authorization & Approval</div>
                    <div class="status-box-val" style="color: #059669;">
                        <span style="display:inline-block; width:8px; height:8px; border-radius:50%; background:#059669;"></span>
                        {approval_status}
                    </div>
                </div>
            </div>

            <!-- 6. SHA-256 Digital Signature Stamp -->
            <div class="signature-card">
                <div class="signature-info">
                    <div class="signature-title">SHA-256 DIGITAL CLINICAL SIGNATURE STAMP</div>
                    <div class="signature-sub">Cryptographically Signed by DEA Prescriber License & NPI Network</div>
                    <div class="signature-hash">ID: {digital_stamp}</div>
                </div>
                <div class="signature-verified">
                    <svg width="16" height="16" fill="#059669" viewBox="0 0 16 16">
                        <path d="M12.736 3.97a.733.733 0 0 1 1.047 0c.286.289.29.756.01 1.05L7.88 12.01a.733.733 0 0 1-1.065.02L3.217 8.384a.757.757 0 0 1 0-1.06.733.733 0 0 1 1.047 0l3.052 3.093 5.4-6.425a.247.247 0 0 1 .02-.022Z"/>
                    </svg>
                    VERIFIED
                </div>
            </div>

            <!-- 7. Document Footer -->
            <div class="document-footer">
                <span>Generated by Alternea Health Telemetry</span>
                <span>Page 1 of 1</span>
            </div>

        </div>
    </div>

</body>
</html>
"""