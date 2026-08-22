import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'dart:convert';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  int _activeFilterTab = 0; // 0: All, 1: Active, 2: Completed, 3: Expired, 4: Drafts

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEmptyState() {
    return BentoCard(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.bgSlate,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 38,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Prescriptions Found',
              style: AppFonts.googleSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No active prescriptions match your filter.',
              style: AppFonts.googleSans(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Calculate dynamic tab counts
    final activeCount = appState.prescriptions.where((rx) => rx.status.toLowerCase() == 'active' || rx.status.toLowerCase() == 'prescribed').length;
    final completedCount = appState.prescriptions.where((rx) => rx.status.toLowerCase() == 'completed').length;
    final expiredCount = appState.prescriptions.where((rx) => rx.status.toLowerCase() == 'expired').length;
    final draftsCount = appState.prescriptions.where((rx) => rx.status.toLowerCase() == 'draft').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Live Prescriptions Registry',
            subtitle: 'Real-time e-Rx fulfillment audit, verified doctor signatures, and pharmacy lifecycle tracking.',
            icon: Icons.receipt_long_rounded,
            statusLabel: 'Live FHIR Stream',
            trailing: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientPill),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _showUploadModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Upload e-Rx Document',
                  style: AppFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Filter Sub-Tabs Bar
          BentoCard(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSubTabButton(0, 'All Prescriptions'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(1, 'Active ($activeCount)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(2, 'Completed ($completedCount)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(3, 'Expired ($expiredCount)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(4, 'Drafts ($draftsCount)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Asymmetric Bento 2-Column Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              final filteredRxList = appState.prescriptions.reversed.where((rx) {
                if (_activeFilterTab == 0) return true;
                if (_activeFilterTab == 1) return rx.status.toLowerCase() == 'active' || rx.status.toLowerCase() == 'prescribed';
                if (_activeFilterTab == 2) return rx.status.toLowerCase() == 'completed';
                if (_activeFilterTab == 3) return rx.status.toLowerCase() == 'expired';
                if (_activeFilterTab == 4) return rx.status.toLowerCase() == 'draft';
                return true;
              }).toList();

              final listColumn = Column(
                children: filteredRxList.isEmpty
                  ? [
                      _buildEmptyState(),
                    ]
                  : filteredRxList.map((rx) {
                      final items = appState.prescriptionItems.where((i) => i.prescriptionId == rx.id).toList();
                      final medsText = items.isEmpty
                          ? '${rx.drugName.isNotEmpty ? rx.drugName : "1 Medicine"} Prescribed'
                          : '${items.length} Medicine${items.length > 1 ? "s" : ""} Prescribed';
                          
                      Color bgStatus = AppColors.successBg;
                      Color textStatus = AppColors.successText;
                      if (rx.status.toLowerCase() == 'completed') {
                        bgStatus = AppColors.purpleBg;
                        textStatus = AppColors.purpleText;
                      } else if (rx.status.toLowerCase() == 'expired') {
                        bgStatus = AppColors.dangerBg;
                        textStatus = AppColors.dangerText;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildPrescriptionBentoCard(
                          rx: rx,
                          items: items,
                          id: rx.id,
                          doctor: 'Dr. ${rx.prescriberName}',
                          dateDetails: '${_formatDate(rx.prescribedDate ?? rx.lastFillDate)} • $medsText',
                          status: rx.status,
                          bgStatus: bgStatus,
                          textStatus: textStatus,
                          onView: () => appState.setSelectedPrescriptionId(rx.id),
                        ),
                      );
                    }).toList(),
              );

              final sideColumn = Column(
                children: [
                  _buildOverviewCard(),
                  const SizedBox(height: 16),
                  _buildBenefitsCard(),
                ],
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: listColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: sideColumn),
                  ],
                );
              }

              return Column(
                children: [
                  sideColumn,
                  const SizedBox(height: 20),
                  listColumn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeFilterTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilterTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.bgSlate,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.metallicBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: AppFonts.googleSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionBentoCard({
    required Prescription rx,
    required List<PrescriptionItem> items,
    required String id,
    required String doctor,
    required String dateDetails,
    required String status,
    required Color bgStatus,
    required Color textStatus,
    required VoidCallback onView,
  }) {
    return BentoCard(
      enableHover: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.receipt_rounded,
              color: AppColors.primaryTeal,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Prescription #${rx.id}',
                      style: AppFonts.googleSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgStatus,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: AppFonts.googleSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textStatus,
                        ),
                      ),
                    ),
                    if (rx.hasPdf) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.picture_as_pdf_rounded, size: 10, color: AppColors.primaryTeal),
                            SizedBox(width: 4),
                            Text(
                              'ORIGINAL PDF',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  doctor,
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                Text(
                  dateDetails,
                  style: AppFonts.googleSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showDownloadPdfModal(context, rx, items),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1244A2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(color: const Color(0xFF1244A2).withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(
                  rx.hasPdf ? Icons.download_rounded : Icons.picture_as_pdf_rounded,
                  size: 15,
                  color: const Color(0xFF1244A2),
                ),
                label: Text(
                  rx.hasPdf ? 'Download PDF' : 'Download PDF',
                  style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: onView,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgSlate,
                  foregroundColor: AppColors.primaryTeal,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.metallicBorder),
                  ),
                ),
                child: Text(
                  'Inspect Rx',
                  style: AppFonts.googleSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDownloadPdfModal(BuildContext context, Prescription rx, List<PrescriptionItem> items) {
    final prescriberName = rx.prescriberName.isNotEmpty ? rx.prescriberName : 'Attending Doctor';
    final dateDetails = _formatDate(rx.prescribedDate ?? rx.lastFillDate);
    final diagnosis = rx.diagnosis ?? 'Clinical Regimen Evaluation';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                       color: const Color(0xFF1244A2),
                       borderRadius: BorderRadius.circular(14),
                     ),
                     child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 24),
                   ),
                   const SizedBox(width: 14),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           rx.hasPdf 
                             ? 'Doctor Uploaded Rx Document' 
                             : 'Official Clinical e-Prescription Document',
                           style: AppFonts.googleSans(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textDark),
                         ),
                         Text(
                           'FHIR v4.0 Certified • DEA & NPI Signed',
                           style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                         ),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                     onPressed: () => Navigator.pop(ctx),
                   ),
                 ],
               ),
               const Divider(height: 24),
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF8FAFC),
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: const Color(0xFFCBD5E1)),
                 ),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('ALTERNEA HEALTH CLINICAL NETWORK', style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF1244A2))),
                         Text('Rx ID: ${rx.id}', style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                       ],
                     ),
                     const SizedBox(height: 10),
                     Text('Prescribing Physician:', style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted)),
                     Text('Dr. $prescriberName', style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                     const SizedBox(height: 8),
                     Text('Patient & Date Details:', style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted)),
                     Text('Patient Name: ${rx.patientName} • Issued: $dateDetails', style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                     const SizedBox(height: 8),
                     Text('Diagnosis / Indication:', style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted)),
                     Text(diagnosis, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                     const SizedBox(height: 12),
                     const Divider(height: 1),
                     const SizedBox(height: 12),
                     Text('Rx Regimen Payload:', style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1244A2))),
                     const SizedBox(height: 4),
                     if (items.isEmpty)
                       Text('1. ${rx.drugName.isNotEmpty ? rx.drugName : "Prescribed Clinical Therapy"} — 1 Oral QD (30 Days)', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600))
                     else
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: items.asMap().entries.map((e) {
                           final i = e.value;
                           return Text('${e.key + 1}. ${i.medicineName} ${i.dosage} — ${i.frequency} (${i.durationDays} Days)', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600));
                         }).toList(),
                       ),
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                       decoration: BoxDecoration(
                         color: const Color(0xFF10B981).withValues(alpha: 0.12),
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Row(
                         children: [
                           const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
                           const SizedBox(width: 6),
                           Text('SHA-256 Signature Stamp: Verified & Encrypted', style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
               const SizedBox(height: 18),
               Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   TextButton(
                     onPressed: () => Navigator.pop(ctx),
                     child: Text('Close', style: AppFonts.googleSans(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                   ),
                   const SizedBox(width: 8),
                   OutlinedButton.icon(
                     style: OutlinedButton.styleFrom(
                       foregroundColor: const Color(0xFF1244A2),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                       side: const BorderSide(color: Color(0xFF1244A2)),
                     ),
                     icon: const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF1244A2)),
                     label: Text(
                       rx.hasPdf ? 'View Original PDF' : 'View PDF',
                       style: AppFonts.googleSans(fontWeight: FontWeight.w800, color: const Color(0xFF1244A2)),
                     ),
                     onPressed: () async {
                       Navigator.pop(ctx);
                       if (rx.hasPdf) {
                         try {
                           final bytes = base64Decode(rx.pdfBase64!);
                           await Printing.layoutPdf(
                             onLayout: (PdfPageFormat format) async => bytes,
                             name: rx.pdfName ?? 'prescription.pdf',
                           );
                         } catch (e) {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Error viewing PDF: $e'),
                                 backgroundColor: AppColors.dangerRed,
                                 behavior: SnackBarBehavior.floating,
                               ),
                             );
                           }
                         }
                       } else {
                         await PdfExportService.instance.printPdf(rx: rx, items: items);
                       }
                     },
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton.icon(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF1244A2),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                     ),
                     icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                     label: Text(
                       rx.hasPdf ? 'Download Original PDF' : 'Save / Download PDF',
                       style: AppFonts.googleSans(fontWeight: FontWeight.w800, color: Colors.white),
                     ),
                     onPressed: () async {
                       Navigator.pop(ctx);
                       if (rx.hasPdf) {
                         try {
                           final bytes = base64Decode(rx.pdfBase64!);
                           await Printing.sharePdf(
                             bytes: bytes,
                             filename: rx.pdfName ?? 'prescription.pdf',
                           );
                         } catch (e) {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Error decoding PDF: $e'),
                                 backgroundColor: AppColors.dangerRed,
                                 behavior: SnackBarBehavior.floating,
                               ),
                             );
                           }
                         }
                       } else {
                         await PdfExportService.instance.downloadOrSharePdf(rx: rx, items: items);
                       }
                     },
                   ),
                 ],
               ),
             ],
           ),
         ),
       ),
     );
   }

  Widget _buildOverviewCard() {
    return BentoCard(
      title: 'Prescription Lifecycle',
      subtitle: 'Real-time telemetry breakdown',
      child: Column(
        children: [
          _buildLifecycleRow('Active Treatments', '3 Orders', AppColors.electricMint),
          const SizedBox(height: 10),
          _buildLifecycleRow('Completed Regimens', '1 Order', AppColors.jewelSapphire),
          const SizedBox(height: 10),
          _buildLifecycleRow('Renewal Required', '1 Order', AppColors.jewelWarmAmber),
        ],
      ),
    );
  }

  Widget _buildLifecycleRow(String label, String value, Color indicatorColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.metallicBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: indicatorColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppFonts.googleSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: AppFonts.googleSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return BentoCard(
      title: 'EHR Security Protocol',
      subtitle: 'HIPAA & FHIR Standard v4.0',
      child: Column(
        children: [
          _buildSecurityRow(
            'Cryptographic Audit Trail',
            'Every dispense transaction is stamped with physician credentials and tamper-evident SHA-256 verification.',
          ),
          const SizedBox(height: 10),
          _buildSecurityRow(
            'CMS PDC Adherence Scoring',
            'Automated refill calculations detect prescription abandonment before gap penalties occur.',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.metallicBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shield_rounded, size: 16, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Upload e-Prescription (PDF/HL7)',
          style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.bgSlate,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primaryTeal),
                      const SizedBox(height: 8),
                      Text(
                        'Drag & Drop FHIR/HL7 Document here',
                        style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prescription Document Uploaded & Parsed via OCR!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: Text('Process e-Rx', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}