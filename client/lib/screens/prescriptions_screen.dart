import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  int _activeFilterTab = 0; // 0: All, 1: Active, 2: Completed, 3: Expired, 4: Drafts

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

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
                  style: GoogleFonts.plusJakartaSans(
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
                  _buildSubTabButton(1, 'Active (3)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(2, 'Completed (1)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(3, 'Expired (1)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(4, 'Drafts (0)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Asymmetric Bento 2-Column Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              final listColumn = Column(
                children: [
                  _buildPrescriptionBentoCard(
                    id: 'Prescription #RX58921',
                    doctor: 'Dr. Rahul Verma • General Physician',
                    dateDetails: 'May 15, 2025 • 3 Medicines Prescribed',
                    status: 'Active',
                    bgStatus: AppColors.successBg,
                    textStatus: AppColors.successText,
                    onView: () => appState.setSelectedPrescriptionId('RX58921'),
                  ),
                  const SizedBox(height: 14),
                  _buildPrescriptionBentoCard(
                    id: 'Prescription #RX58711',
                    doctor: 'Dr. Neha Kapoor • Cardiologist',
                    dateDetails: 'Apr 28, 2025 • 2 Medicines Prescribed',
                    status: 'Active',
                    bgStatus: AppColors.successBg,
                    textStatus: AppColors.successText,
                    onView: () => appState.setSelectedPrescriptionId('RX58711'),
                  ),
                  const SizedBox(height: 14),
                  _buildPrescriptionBentoCard(
                    id: 'Prescription #RX58432',
                    doctor: 'Dr. Rahul Verma • General Physician',
                    dateDetails: 'Mar 20, 2025 • 4 Medicines Prescribed',
                    status: 'Completed',
                    bgStatus: AppColors.purpleBg,
                    textStatus: AppColors.purpleText,
                    onView: () => appState.setSelectedPrescriptionId('RX58432'),
                  ),
                  const SizedBox(height: 14),
                  _buildPrescriptionBentoCard(
                    id: 'Prescription #RX58109',
                    doctor: 'Dr. Neha Kapoor • Cardiologist',
                    dateDetails: 'Feb 18, 2025 • 3 Medicines Prescribed',
                    status: 'Expired',
                    bgStatus: AppColors.dangerBg,
                    textStatus: AppColors.dangerText,
                    onView: () => appState.setSelectedPrescriptionId('RX58109'),
                  ),
                  const SizedBox(height: 14),
                  _buildPrescriptionBentoCard(
                    id: 'Prescription #RX57902',
                    doctor: 'Dr. Amit Singh • Orthopedic',
                    dateDetails: 'Jan 10, 2025 • 2 Medicines Prescribed',
                    status: 'Active',
                    bgStatus: AppColors.successBg,
                    textStatus: AppColors.successText,
                    onView: () => appState.setSelectedPrescriptionId('RX57902'),
                  ),
                ],
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildPrescriptionBentoCard({
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
                      id,
                      style: GoogleFonts.plusJakartaSans(
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textStatus,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  doctor,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
                Text(
                  dateDetails,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showDownloadPdfModal(context, id, doctor, dateDetails),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1244A2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(color: const Color(0xFF1244A2).withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 15, color: Color(0xFF1244A2)),
                label: Text(
                  'Download PDF',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800),
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
                  style: GoogleFonts.plusJakartaSans(
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

  void _showDownloadPdfModal(BuildContext context, String id, String doctor, String dateDetails) {
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
                          'Official Clinical e-Prescription Document',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textDark),
                        ),
                        Text(
                          'FHIR v4.0 Certified • DEA & NPI Signed',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
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
                        Text('ALTERNEA HEALTH CLINICAL NETWORK', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF1244A2))),
                        Text('Rx ID: $id', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('Prescribing Physician:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    Text(doctor, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Patient & Date Details:', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    Text(dateDetails, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text('Rx Regimen Payload:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1244A2))),
                    const SizedBox(height: 4),
                    Text('1. Amantadine 100mg Capsule — 1 Cap Oral QD (30 Days)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    Text('2. Lipitor (Atorvastatin) 20mg Tablet — 1 Tab QHS (90 Days)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600)),
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
                          Text('SHA-256 Signature Stamp: Verified & Encrypted', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFF10B981))),
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
                    child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1244A2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                    label: Text('Save / Download PDF', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: Colors.white)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('e-Prescription PDF ($id) downloaded successfully!'),
                          backgroundColor: const Color(0xFF1244A2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
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
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
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
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
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
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
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
            child: Text('Process e-Rx', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}