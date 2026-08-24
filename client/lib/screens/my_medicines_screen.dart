import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class MyMedicinesScreen extends StatefulWidget {
  const MyMedicinesScreen({super.key});

  @override
  State<MyMedicinesScreen> createState() => _MyMedicinesScreenState();
}

class _MyMedicinesScreenState extends State<MyMedicinesScreen> {
  int _activeFilterTab = 0; // 0: All, 1: Active, 2: Completed, 3: On Hold

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
            title: 'My Medication Cabinet',
            subtitle: 'Track active dosages, refill countdowns, and adherence compliance.',
            icon: Icons.medication_rounded,
            statusLabel: 'Cabinet Active',
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
                onPressed: () => _showAddMedicineModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: Text(
                  '+ Add Medicine',
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
          Builder(
            builder: (context) {
              final activePatientId = (appState.currentUser.patientId ?? appState.currentUser.id).toLowerCase();
              final activePatientName = appState.currentUser.name.toLowerCase();

              final userRxList = appState.prescriptions.reversed.where((r) {
                final pid = r.patientId.toLowerCase();
                final pName = r.patientName.toLowerCase();
                if (appState.currentUser.role == UserRole.patient) {
                  return pid == activePatientId ||
                      (activePatientId.isNotEmpty && (pid.contains(activePatientId) || activePatientId.contains(pid))) ||
                      (activePatientName.isNotEmpty && pName.isNotEmpty && pName.contains(activePatientName));
                }
                return pid == activePatientId ||
                    pid == 'pat_00001' ||
                    (activePatientId.isNotEmpty && (pid.contains(activePatientId) || activePatientId.contains(pid)));
              }).toList();

              final userRxCount = userRxList.length;
              final totalMedsCount = 4 + userRxCount;
              final activeMedsCount = 3 + userRxCount;

              return BentoCard(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSubTabButton(0, 'All Medications ($totalMedsCount)'),
                      const SizedBox(width: 8),
                      _buildSubTabButton(1, 'Active Daily ($activeMedsCount)'),
                      const SizedBox(width: 8),
                      _buildSubTabButton(2, 'Completed (1)'),
                      const SizedBox(width: 8),
                      _buildSubTabButton(3, 'As Needed / PRN (0)'),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 3. Asymmetric Bento 2-Column Workspace
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 920;
              final activePatientId = (appState.currentUser.patientId ?? appState.currentUser.id).toLowerCase();
              final activePatientName = appState.currentUser.name.toLowerCase();

              final dynamicCards = <Widget>[];

              final userRxList = appState.prescriptions.reversed.where((r) {
                final pid = r.patientId.toLowerCase();
                final pName = r.patientName.toLowerCase();
                if (appState.currentUser.role == UserRole.patient) {
                  return pid == activePatientId ||
                      (activePatientId.isNotEmpty && (pid.contains(activePatientId) || activePatientId.contains(pid))) ||
                      (activePatientName.isNotEmpty && pName.isNotEmpty && pName.contains(activePatientName));
                }
                return pid == activePatientId ||
                    pid == 'pat_00001' ||
                    (activePatientId.isNotEmpty && (pid.contains(activePatientId) || activePatientId.contains(pid)));
              }).toList();

              for (final rx in userRxList) {
                var items = appState.prescriptionItems.where((i) => i.prescriptionId == rx.id).toList();

                dynamicCards.add(
                  _buildPrescriptionContainerCard(
                    rx: rx,
                    items: items,
                  ),
                );
                dynamicCards.add(const SizedBox(height: 14));
              }

              final medsColumn = Column(
                children: [
                  ...dynamicCards,
                  _buildMedicineCabinetCard(
                    title: 'Metformin Hydrochloride (Glucophage)',
                    dosage: '500 mg • 1 Tablet Twice Daily',
                    purpose: 'Type 2 Diabetes Blood Glucose Regulation',
                    prescriber: 'Dr. Tariq Martin, MD',
                    prescribeDate: 'Aug 10, 2026',
                    pharmacyLocation: 'MetroHealth Pharmacy Hub (#402)',
                    pharmacistName: 'Sarah Lin, PharmD',
                    dispenseDate: 'Aug 12, 2026 at 14:30 PM',
                    daysLeft: 18,
                    complianceScore: 0.94,
                    icon: Icons.medication_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMedicineCabinetCard(
                    title: 'Lisinopril (Zestril)',
                    dosage: '10 mg • 1 Tablet Once Daily (Morning)',
                    purpose: 'Hypertension & Blood Pressure Support',
                    prescriber: 'Dr. Neha Kapoor, MD',
                    prescribeDate: 'Aug 02, 2026',
                    pharmacyLocation: 'CVS Pharmacy #108 (Winston-Salem, NC)',
                    pharmacistName: 'Mark Stevens, RPh',
                    dispenseDate: 'Aug 04, 2026 at 09:15 AM',
                    daysLeft: 6,
                    complianceScore: 0.88,
                    icon: Icons.favorite_border_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMedicineCabinetCard(
                    title: 'Atorvastatin Calcium (Lipitor)',
                    dosage: '20 mg • 1 Tablet Bedtime',
                    purpose: 'Cholesterol & Lipid Management',
                    prescriber: 'Dr. Neha Kapoor, MD',
                    prescribeDate: 'Jul 28, 2026',
                    pharmacyLocation: 'Walgreens Pharmacy #305 (Main St)',
                    pharmacistName: 'Sarah Lin, PharmD',
                    dispenseDate: 'Jul 29, 2026 at 16:45 PM',
                    daysLeft: 24,
                    complianceScore: 0.96,
                    icon: Icons.monitor_heart_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMedicineCabinetCard(
                    title: 'Amoxicillin Trihydrate',
                    dosage: '500 mg • 1 Capsule Every 8h (10 Days)',
                    purpose: 'Bacterial Infection (Completed Course)',
                    prescriber: 'Dr. Tariq Martin, MD',
                    prescribeDate: 'Jun 10, 2026',
                    pharmacyLocation: 'MetroHealth Pharmacy Hub (#402)',
                    pharmacistName: 'Mark Stevens, RPh',
                    dispenseDate: 'Jun 10, 2026 at 11:00 AM',
                    daysLeft: 0,
                    complianceScore: 1.0,
                    isCompleted: true,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              );

              final sideColumn = Column(
                children: [
                  _buildRefillAlertBento(),
                  const SizedBox(height: 16),
                  _buildAdherenceSummaryCard(appState),
                ],
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: medsColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: sideColumn),
                  ],
                );
              }

              return Column(
                children: [
                  sideColumn,
                  const SizedBox(height: 20),
                  medsColumn,
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

  Widget _buildPrescriptionContainerCard({
    required Prescription rx,
    required List<PrescriptionItem> items,
  }) {
    final prescriberName = rx.prescriberName.isNotEmpty ? rx.prescriberName : 'Dr. Tariq Martin, MD';
    final diagnosis = (rx.diagnosis != null && rx.diagnosis!.isNotEmpty)
        ? rx.diagnosis!
        : 'Clinical Regimen Evaluation';
    final hospital = rx.hospitalName ?? 'MetroHealth Medical Facility';

    return BentoCard(
      enableHover: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Container Prescription Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF1244A2),
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
                        Expanded(
                          child: Text(
                            'e-Prescription #${rx.id}',
                            style: AppFonts.googleSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (rx.prescribedDate != null &&
                            rx.prescribedDate!.year == DateTime.now().year &&
                            rx.prescribedDate!.month == DateTime.now().month &&
                            rx.prescribedDate!.day == DateTime.now().day)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1244A2).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF1244A2)),
                                const SizedBox(width: 4),
                                Text(
                                  'PRESCRIBED TODAY',
                                  style: AppFonts.googleSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1244A2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Prescribed By: $prescriberName • $hospital',
                      style: AppFonts.googleSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Prescribed Diagnosis Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.medical_information_outlined, size: 15, color: Color(0xFF475569)),
                const SizedBox(width: 8),
                Text(
                  'Diagnosis / Purpose: ',
                  style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF334155)),
                ),
                Expanded(
                  child: Text(
                    diagnosis,
                    style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF1244A2)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Prescribed Medicine Items (${items.length}):',
            style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),

          // 2. Inside Container Medicine Items List
          if (items.isEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication_rounded, color: Color(0xFF1244A2), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rx.drugName.isNotEmpty ? rx.drugName : 'Prescribed Clinical Therapy',
                      style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  Text(
                    '1 Tablet • 30 Days',
                    style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            Column(
              children: items.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1244A2).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication_rounded, color: Color(0xFF1244A2), size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.medicineName,
                              style: AppFonts.googleSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.dosage} • ${item.frequency}',
                              style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.durationDays} Days Supply',
                          style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 14),

          // 3. Bottom Action Footer inside Container Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    'Signed & Transmitted Live',
                    style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF10B981)),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<AppState>(context, listen: false).requestPrescriptionRefill(rx.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF10B981),
                          content: Text(
                            '🔄 Refill requested for Rx #${rx.id}! Sent to Pharmacist queue.',
                            style: AppFonts.googleSans(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.autorenew_rounded, size: 14),
                    label: Text('Request Refill', style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1244A2),
                      side: const BorderSide(color: Color(0xFF1244A2)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showDownloadPdfModal(context, rx: rx, items: items),
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: Text('Download e-Rx PDF', style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1244A2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDownloadPdfModal(BuildContext context, {required Prescription rx, required List<PrescriptionItem> items}) {
    final prescriberName = rx.prescriberName.isNotEmpty ? rx.prescriberName : 'Dr. Tariq Martin, MD';
    final hospital = rx.hospitalName ?? 'MetroHealth Medical Facility';
    final diagnosis = (rx.diagnosis != null && rx.diagnosis!.isNotEmpty) ? rx.diagnosis! : 'General Clinical Regimen';

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
                    Text('$prescriberName ($hospital)', style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    Text('Diagnosis / Purpose:', style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted)),
                    Text(diagnosis, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text('Prescribed Medication Items:', style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1244A2))),
                    const SizedBox(height: 4),
                    if (items.isEmpty)
                      Text('1. ${rx.drugName.isNotEmpty ? rx.drugName : "Prescribed Medication Payload"} — 1 Tab Oral QD (30 Days)', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600))
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.asMap().entries.map((e) {
                          final item = e.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '${e.key + 1}. ${item.medicineName} — ${item.dosage} • ${item.frequency} (${item.durationDays} Days)',
                              style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                          );
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
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 16, color: Colors.white),
                    label: Text('Share / Print', style: AppFonts.googleSans(fontWeight: FontWeight.w800, color: Colors.white)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await PdfExportService.instance.printPdf(rx: rx, items: items);
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
                    label: Text('Save / Download PDF', style: AppFonts.googleSans(fontWeight: FontWeight.w800, color: Colors.white)),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await PdfExportService.instance.downloadOrSharePdf(rx: rx, items: items);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('e-Prescription PDF (${rx.id}) generated & exported!'),
                            backgroundColor: const Color(0xFF1244A2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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

  Widget _buildMedicineCabinetCard({
    required String title,
    required String dosage,
    required String purpose,
    required String prescriber,
    required String prescribeDate,
    required String pharmacyLocation,
    required String pharmacistName,
    required String dispenseDate,
    required int daysLeft,
    required double complianceScore,
    required IconData icon,
    bool isCompleted = false,
    bool isNewToday = false,
  }) {
    return BentoCard(
      enableHover: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isNewToday
                      ? const Color(0xFF1244A2).withValues(alpha: 0.12)
                      : (isCompleted ? AppColors.bgSlate : AppColors.primaryLight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isNewToday
                      ? const Color(0xFF1244A2)
                      : (isCompleted ? AppColors.textMuted : AppColors.primaryTeal),
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
                        Expanded(
                          child: Text(
                            title,
                            style: AppFonts.googleSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (isNewToday)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF1244A2).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF1244A2)),
                                const SizedBox(width: 4),
                                Text(
                                  'PRESCRIBED TODAY',
                                  style: AppFonts.googleSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1244A2),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Completed Course',
                              style: AppFonts.googleSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purpleText,
                              ),
                            ),
                          )
                        else if (daysLeft <= 7)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Refill in $daysLeft Days',
                              style: AppFonts.googleSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dangerText,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dosage,
                      style: AppFonts.googleSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Indication: $purpose',
            style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),

          // Prescribing Doctor & Pharmacy Purchase Provenance Block
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.metallicBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 15, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prescribed By: $prescriber • Prescribed $prescribeDate',
                        style: AppFonts.googleSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Purchased & Dispensed At: $pharmacyLocation (Pharm. $pharmacistName) • $dispenseDate',
                        style: AppFonts.googleSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adherence Score: ${(complianceScore * 100).toInt()}%',
                          style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isCompleted ? 'Course Finished' : '$daysLeft Days Remaining',
                          style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: complianceScore,
                        minHeight: 6,
                        backgroundColor: AppColors.bgSlate,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          complianceScore >= 0.8 ? AppColors.successGreen : AppColors.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refill Request Sent to Pharmacist!'),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    );
                  },
                  child: Text('Request Refill', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefillAlertBento() {
    return BentoCard(
      title: 'Upcoming Refill Countdown',
      subtitle: 'Action needed within 7 days',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.warningOrange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lisinopril 10mg (6 Days Left)',
                    style: AppFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warningText,
                    ),
                  ),
                  Text(
                    'Tap Request Refill to notify your clinical pharmacy before supply runs out.',
                    style: AppFonts.googleSans(fontSize: 11, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceSummaryCard(AppState appState) {
    return BentoCard(
      title: 'Overall Compliance Rating',
      subtitle: 'Based on 30-day continuous logging',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly PDC Score', style: AppFonts.googleSans(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('94.2% (Optimal)', style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.successText)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.942,
              minHeight: 8,
              backgroundColor: AppColors.bgSlate,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Keep up the great work! Consistent adherence protects you from cardiovascular and metabolic complications.',
            style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Medication to Cabinet',
          style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: AppFonts.googleSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Medication Name', hintText: 'e.g. CoQ10 200mg'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                style: AppFonts.googleSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Dosage & Frequency', hintText: 'e.g. 1 Softgel with lunch'),
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
                  content: Text('Medication Added to Cabinet!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: Text('Add Medication', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
