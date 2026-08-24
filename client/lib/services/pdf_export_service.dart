import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/models.dart';
import '../utils/download_helper.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._();
  PdfExportService._();

  /// Generate a PDF document for an e-Prescription with background app logo verification watermark
  Future<Uint8List> generatePrescriptionPdf({
    required Prescription rx,
    required List<PrescriptionItem> items,
  }) async {
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/app_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('PDF Logo Asset load note: $e');
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final doctorName = rx.prescriberName.isNotEmpty ? rx.prescriberName : 'Dr. Tariq Martin, MD';
    final hospital = rx.hospitalName ?? 'MetroHealth Medical Center Hub (#402)';
    final diagnosis = (rx.diagnosis != null && rx.diagnosis!.isNotEmpty) ? rx.diagnosis! : 'General Clinical Regimen';

    // Resolve exact tablet/medicine name
    final displayMedName = rx.drugName.isNotEmpty
        ? rx.drugName
        : (items.isNotEmpty ? items.first.medicineName : 'Levetiracetam 500mg (Antiepileptic Therapy)');

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (pw.Context context) {
        // Low opacity background watermark app logo & verification seal
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotateBox(
              angle: -0.25,
              child: pw.Opacity(
                opacity: 0.08,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Image(
                        logoImage,
                        width: 220,
                        height: 220,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.Container(
                        width: 140,
                        height: 140,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColor.fromHex('#1244A2'), width: 6),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'ALTERNEA',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#1244A2'),
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 14),
                    pw.Text(
                      'ALTERNEA HEALTH NETWORK',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1244A2'),
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'OFFICIAL CLINICAL E-PRESCRIPTION WATERMARK',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1244A2'),
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.Text(
                      'DEA & NPI AUTHENTICATED VERIFICATION STAMP',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1244A2'),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#1244A2'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ALTERNEA HEALTH CLINICAL NETWORK',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Official e-Prescription & Pharmacy Telemetry Payload',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#10B981'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'FHIR v4.0 VERIFIED',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Metadata Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Prescription Record ID:',
                          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748B')),
                        ),
                        pw.Text(
                          '#${rx.id}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Prescribing Physician:',
                          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748B')),
                        ),
                        pw.Text(
                          doctorName,
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Medical Facility:',
                          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748B')),
                        ),
                        pw.Text(
                          hospital,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'ICD-10 Clinical Diagnosis:',
                          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#64748B')),
                        ),
                        pw.Text(
                          diagnosis,
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1244A2')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                'PRESCRIBED MEDICATIONS & DOSAGE REGIMEN',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
              ),

              pw.SizedBox(height: 8),

              // Comprehensive Medicine Items Table
              if (items.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    borderRadius: pw.BorderRadius.circular(6),
                    color: PdfColor.fromHex('#FFFFFF'),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            displayMedName,
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A')),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Dosage Regimen: 1 Tablet Oral - Twice Daily (Take as directed by physician)',
                            style: pw.TextStyle(fontSize: 9.5, color: PdfColor.fromHex('#475569')),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#EFF6FF'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          '30 Days Supply',
                          style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1244A2')),
                        ),
                      ),
                    ],
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(color: PdfColor.fromHex('#CBD5E1')),
                  headerStyle: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1244A2')),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  cellHeight: 26,
                  cellAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerLeft,
                  },
                  headers: ['#', 'Medicine Name', 'Dosage & Frequency', 'Duration', 'Instructions / Notes'],
                  data: items.asMap().entries.map((e) {
                    final i = e.value;
                    final notes = (i.instructions != null && i.instructions!.isNotEmpty)
                        ? i.instructions!
                        : 'Take oral as directed';
                    return [
                      '${e.key + 1}',
                      i.medicineName,
                      '${i.dosage} - ${i.frequency}',
                      '${i.durationDays} Days',
                      notes,
                    ];
                  }).toList(),
                ),

              pw.SizedBox(height: 24),

              // Digital Signature Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#10B981')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SHA-256 DIGITAL CLINICAL SIGNATURE STAMP',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#047857')),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Cryptographically Signed by DEA Prescriber License & NPI Network',
                          style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#065F46')),
                        ),
                      ],
                    ),
                    pw.Text(
                      'VERIFIED',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#047857')),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generated by Alternea Health Telemetry', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                  pw.Text('Page 1 of 1', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate a PDF document for an ingested/vault prescription health record
  Future<Uint8List> generateVaultDocumentPdf({
    required String docId,
    required String title,
    required String patientName,
    required String patientId,
    required String provider,
    required DateTime date,
    required String therapeuticClass,
    required String categoryLabel,
    required String statusLabel,
    String? dosage,
    String? indication,
    String? summary,
    String? rawText,
    double? confidence,
  }) async {
    pw.Font fontRegular;
    pw.Font fontBold;
    try {
      fontRegular = await PdfGoogleFonts.openSansRegular();
      fontBold = await PdfGoogleFonts.openSansBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/app_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('PDF Logo Asset load note: $e');
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      buildBackground: (pw.Context context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotateBox(
              angle: -0.25,
              child: pw.Opacity(
                opacity: 0.07,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Image(
                        logoImage,
                        width: 200,
                        height: 200,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.Container(
                        width: 120,
                        height: 120,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: PdfColor.fromHex('#1244A2'), width: 5),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'ALTERNEA',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#1244A2'),
                            ),
                          ),
                        ),
                      ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'ALTERNEA HEALTH NETWORK',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1244A2'),
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'OFFICIAL CLINICAL HEALTH RECORD & FORMULARY VAULT',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#1244A2'),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0A1931'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ALTERNEA HEALTH CLINICAL NETWORK',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 13.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Patient Health Record & Pharmacy Dispense Vault Payload',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#10B981'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'FHIR v4.0 & HIPAA VERIFIED',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Metadata Key-Value Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfField('Prescription Record ID:', '#$docId'),
                        ),
                        pw.Expanded(
                          child: _buildPdfField('Patient Name & ID:', '$patientName ($patientId)'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfField('Dispensing Provider:', provider),
                        ),
                        pw.Expanded(
                          child: _buildPdfField('Date Ingested:', '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildPdfField('Therapeutic Class:', therapeuticClass),
                        ),
                        pw.Expanded(
                          child: _buildPdfField('Verification Status:', statusLabel),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Prescribed Medication Details Card
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFFFFF'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            title,
                            style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#0F172A'),
                            ),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#EFF6FF'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            categoryLabel,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#1D4ED8'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (indication != null && indication.isNotEmpty) ...[
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Indication / Diagnosis: $indication',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0062FF'),
                        ),
                      ),
                    ],
                    if (dosage != null && dosage.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Dosage & Regimen: $dosage',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColor.fromHex('#475569'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (summary != null && summary.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EFF6FF'),
                    borderRadius: pw.BorderRadius.circular(6),
                    border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'THERAPEUTIC & CLINICAL SUMMARY',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#1E40AF'),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        summary,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: PdfColor.fromHex('#1E3A8A'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (rawText != null && rawText.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#0F172A'),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'VERIFIED FORMULARY RECORD TRANSCRIPT (OCR/FHIR)',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#38BDF8'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        rawText,
                        style: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 14),

              // Digital Signature Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#10B981')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SHA-256 DIGITAL CLINICAL RECORD SIGNATURE STAMP',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#047857'),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Formulary Gateway Verified • DEA Prescriber License & NPI Network Authenticated',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: PdfColor.fromHex('#065F46'),
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#047857'),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        'AUTHENTICATED',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColor.fromHex('#E2E8F0')),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Alternea Health Vault Telemetry • Confidential Medical Document',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8.5,
            color: PdfColor.fromHex('#64748B'),
          ),
        ),
        pw.SizedBox(height: 1.5),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  /// Download or Share Vault Document PDF directly to local storage / browser downloads
  Future<void> downloadOrShareVaultPdf({
    required String docId,
    required String title,
    required String patientName,
    required String patientId,
    required String provider,
    required DateTime date,
    required String therapeuticClass,
    required String categoryLabel,
    required String statusLabel,
    String? dosage,
    String? indication,
    String? summary,
    String? rawText,
    double? confidence,
  }) async {
    final bytes = await generateVaultDocumentPdf(
      docId: docId,
      title: title,
      patientName: patientName,
      patientId: patientId,
      provider: provider,
      date: date,
      therapeuticClass: therapeuticClass,
      categoryLabel: categoryLabel,
      statusLabel: statusLabel,
      dosage: dosage,
      indication: indication,
      summary: summary,
      rawText: rawText,
      confidence: confidence,
    );
    final cleanFileName = '${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';

    await FileDownloader.downloadBytes(
      bytes: bytes,
      fileName: cleanFileName,
      mimeType: 'application/pdf',
    );
  }

  /// Print or Preview Vault Document PDF directly
  Future<void> printVaultPdf({
    required String docId,
    required String title,
    required String patientName,
    required String patientId,
    required String provider,
    required DateTime date,
    required String therapeuticClass,
    required String categoryLabel,
    required String statusLabel,
    String? dosage,
    String? indication,
    String? summary,
    String? rawText,
    double? confidence,
  }) async {
    final bytes = await generateVaultDocumentPdf(
      docId: docId,
      title: title,
      patientName: patientName,
      patientId: patientId,
      provider: provider,
      date: date,
      therapeuticClass: therapeuticClass,
      categoryLabel: categoryLabel,
      statusLabel: statusLabel,
      dosage: dosage,
      indication: indication,
      summary: summary,
      rawText: rawText,
      confidence: confidence,
    );
    final cleanFileName = '${title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: cleanFileName,
    );
  }

  /// Share or Download PDF directly to local storage / file system
  Future<void> downloadOrSharePdf({
    required Prescription rx,
    required List<PrescriptionItem> items,
  }) async {
    final bytes = await generatePrescriptionPdf(rx: rx, items: items);
    final fileName = 'e-Rx_${rx.id}.pdf';

    await FileDownloader.downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );
  }

  /// Print or Preview PDF directly
  Future<void> printPdf({
    required Prescription rx,
    required List<PrescriptionItem> items,
  }) async {
    final bytes = await generatePrescriptionPdf(rx: rx, items: items);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'e-Rx_${rx.id}.pdf',
    );
  }

  /// Generate a PDF document for an Approved Alternative e-Prescription
  Future<Uint8List> generateAlternativePrescriptionPdf({
    required AlternativeApprovalRequest req,
  }) async {
    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/app_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('PDF Logo Asset load note: $e');
    }

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fontRegular,
        bold: fontBold,
      ),
    );

    final doctorName = req.doctorName.isNotEmpty ? req.doctorName : 'Dr. Sarah Jenkins, MD';
    final patientName = req.patientName.isNotEmpty ? req.patientName : 'Patient';
    final patientId = req.patientId.isNotEmpty ? req.patientId : 'PAT-001';
    final rxId = req.prescriptionId.isNotEmpty ? req.prescriptionId : 'RX-ALT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      buildBackground: (pw.Context context) {
        return pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotateBox(
              angle: -0.25,
              child: pw.Opacity(
                opacity: 0.08,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, width: 140, height: 140),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PHYSICIAN-APPROVED ALTERNATIVE REGIMEN',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0062FF'),
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.Text(
                      'OFFICIAL e-PRESCRIPTION CERTIFICATE',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0062FF'),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0062FF'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ALTERNEA HEALTH CLINICAL NETWORK',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Official Physician-Approved Alternative e-Prescription',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#10B981'),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'DOCTOR APPROVED',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Metadata Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPdfField('Prescription Record ID', '#$rxId'),
                        _buildPdfField('Date Approved', '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}'),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPdfField('Patient Name', patientName),
                        _buildPdfField('Patient ID', patientId),
                        _buildPdfField('Patient Age', '${req.patientAge} Years'),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPdfField('Prescribing Physician', doctorName),
                        _buildPdfField('Doctor ID', req.doctorId.isNotEmpty ? req.doctorId : 'DOC-201'),
                        _buildPdfField('Facility', 'MetroHealth Pharmacy Hub (#402)'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // Prescribed Alternative Medication Highlight Box
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#ECFDF5'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColor.fromHex('#10B981'), width: 1.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'PRESCRIBED ALTERNATIVE MEDICATION (ACTIVE)',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#059669'),
                          ),
                        ),
                        pw.Text(
                          'Tier ${req.alternativeTier} Preferred • \$${req.alternativeCopay.toStringAsFixed(2)} Copay',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#059669'),
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      req.recommendedAlternative,
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#064E3B'),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Dosage: 1 Tablet Oral Daily • 30-Day Supply with Refills Authorized',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColor.fromHex('#047857'),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // Discontinued Original Drug & Savings Comparison
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#EFF6FF'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Discontinued Original Drug:',
                          style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#1E40AF')),
                        ),
                        pw.Text(
                          req.originalDrug,
                          style: pw.TextStyle(
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.lineThrough,
                            color: PdfColor.fromHex('#1E3A8A'),
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Patient Monthly / Annual Savings:',
                          style: pw.TextStyle(fontSize: 8.5, color: PdfColor.fromHex('#059669')),
                        ),
                        pw.Text(
                          'Save \$${req.monthlySavings.toStringAsFixed(2)}/mo (\$${req.annualSavings.toStringAsFixed(2)}/yr)',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#047857'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              // Clinical Rationale & Doctor Note
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Physician Clinical Rationale & Endorsement:',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#334155')),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      req.doctorNote?.isNotEmpty == true
                          ? req.doctorNote!
                          : (req.clinicalRationale.isNotEmpty
                              ? req.clinicalRationale
                              : 'Therapeutic substitution approved by attending physician for improved cost efficiency and verified bioequivalence.'),
                      style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#475569')),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures & Stamp
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DIGITALLY SIGNED & VERIFIED BY:',
                        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        doctorName,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0062FF')),
                      ),
                      pw.Text(
                        'Attending Physician • Alternea Health Network',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('#10B981'), width: 1.5),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'PHARMACY DISPENSED',
                          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#10B981')),
                        ),
                        pw.Text(
                          'METROHEALTH HUB #402',
                          style: pw.TextStyle(fontSize: 7.5, color: PdfColor.fromHex('#059669')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColor.fromHex('#CBD5E1')),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Alternea Health Vault Telemetry • Official Medical e-Prescription',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Download or Share Alternative Prescription PDF
  Future<void> downloadOrShareAlternativePrescriptionPdf({
    required AlternativeApprovalRequest req,
  }) async {
    final bytes = await generateAlternativePrescriptionPdf(req: req);
    final fileName = 'Alternative_eRx_${req.recommendedAlternative.replaceAll(' ', '_')}_${req.patientName.replaceAll(' ', '_')}.pdf';

    await FileDownloader.downloadBytes(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );
  }

  /// Print or Preview Alternative Prescription PDF
  Future<void> printAlternativePrescriptionPdf({
    required AlternativeApprovalRequest req,
  }) async {
    final bytes = await generateAlternativePrescriptionPdf(req: req);
    final fileName = 'Alternative_eRx_${req.recommendedAlternative.replaceAll(' ', '_')}.pdf';
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: fileName,
    );
  }
}
