import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class PharmacistDispenseScreen extends StatefulWidget {
  const PharmacistDispenseScreen({super.key});

  @override
  State<PharmacistDispenseScreen> createState() =>
      _PharmacistDispenseScreenState();
}

class _PharmacistDispenseScreenState extends State<PharmacistDispenseScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final query = _searchController.text.trim().toLowerCase();

    // Filter patients by search query
    final matchingPatients = appState.patientRecords.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.currentProblem.toLowerCase().contains(query);
    }).toList();

    final pendingCount = appState.prescriptionItems.where((i) => !i.isDispensed).length;
    final dispensedCount = appState.prescriptionItems.where((i) => i.isDispensed).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Clinical Dispense Engine',
            subtitle: 'Inspect verified e-prescriptions, validate clinical origin, and securely dispense medications.',
            icon: Icons.local_pharmacy_rounded,
            statusLabel: 'FHIR v4.0 Active',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeaderStatPill('$pendingCount Pending', AppColors.warningBg, AppColors.warningText),
                const SizedBox(width: 10),
                _buildHeaderStatPill('$dispensedCount Fulfilled', AppColors.successBg, AppColors.successText),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Command Search Bar
          BentoCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search prescription queue by patient name, Rx ID, or clinical indication...',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: AppColors.primaryTeal,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Patient Prescriptions Queue
          if (matchingPatients.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            Column(
              children: matchingPatients.map((patient) {
                // Find hospital info
                final hospital = appState.hospitals.firstWhere(
                  (h) => h.id == patient.hospitalId,
                  orElse: () => appState.hospitals.isNotEmpty
                      ? appState.hospitals.first
                      : Hospital(
                          id: patient.hospitalId ?? 'HOSP-101',
                          name: 'MetroHealth Medical Center',
                          address: '100 Hospital Way, Medical Plaza',
                          city: 'New York',
                          state: 'NY',
                          zip: '10001',
                          phone: '(212) 555-0100',
                        ),
                );

                // Find doctor info
                final doctor = appState.doctors.firstWhere(
                  (d) => d.id == patient.assignedDoctorId,
                  orElse: () => appState.doctors.isNotEmpty
                      ? appState.doctors.first
                      : Doctor(
                          id: patient.assignedDoctorId ?? 'DOC-201',
                          name: 'Dr. Rahul Verma',
                          specialty: 'Internal Medicine / Cardiology',
                          email: 'doctor@alternea.org',
                          phone: '(555) 019-2834',
                          hospitalId: patient.hospitalId ?? 'HOSP-101',
                        ),
                );

                final items = appState.prescriptionItems;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: _buildPatientBentoCard(
                    context: context,
                    appState: appState,
                    patient: patient,
                    hospital: hospital,
                    doctor: doctor,
                    items: items,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderStatPill(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
    );
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
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No active patients match your search filter. Try entering a different patient name or Rx identifier.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientBentoCard({
    required BuildContext context,
    required AppState appState,
    required dynamic patient,
    required dynamic hospital,
    required dynamic doctor,
    required List<dynamic> items,
  }) {
    return BentoCard(
      enableHover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.gradientPill,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  patient.name.isNotEmpty ? patient.name[0] : 'P',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
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
                          patient.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.bgSlate,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.metallicBorder),
                          ),
                          child: Text(
                            'ID: ${patient.id}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monitor_heart_rounded, size: 13, color: AppColors.dangerRed),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              patient.currentProblem,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dangerRed,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: AppColors.metallicBorder, height: 1),
          ),

          // Clinical Origin Grid (Hospital & Doctor)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final tiles = [
                _buildInfoTile(
                  icon: Icons.local_hospital_rounded,
                  iconColor: AppColors.primaryTeal,
                  label: 'Hospital Origin',
                  title: hospital.name,
                  subtitle: hospital.address,
                ),
                _buildInfoTile(
                  icon: Icons.badge_rounded,
                  iconColor: AppColors.accentNavy,
                  label: 'Prescribing Physician',
                  title: doctor.name,
                  subtitle: doctor.specialty,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: 14),
                    Expanded(child: tiles[1]),
                  ],
                );
              }
              return Column(
                children: [
                  tiles[0],
                  const SizedBox(height: 10),
                  tiles[1],
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Icon(Icons.medication_rounded, size: 16, color: AppColors.primaryTeal),
              const SizedBox(width: 8),
              Text(
                'Prescription Items Ready to Dispense',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prescribed Item Cards
          Column(
            children: items.map((item) {
              return _buildMedicineItem(
                context: context,
                appState: appState,
                item: item,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.metallicBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem({
    required BuildContext context,
    required AppState appState,
    required dynamic item,
  }) {
    final dispensed = item.isDispensed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: dispensed ? AppColors.bgSlate : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dispensed
              ? AppColors.metallicBorder
              : AppColors.primaryTeal.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: dispensed
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: dispensed ? AppColors.primaryTeal : AppColors.warningOrange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    dispensed
                        ? Icons.check_circle_rounded
                        : Icons.pending_actions_rounded,
                    color: dispensed ? AppColors.primaryTeal : AppColors.warningOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.medicineName} (${item.dosage})',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Frequency: ${item.frequency} • Duration: ${item.durationDays} Days Supply',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (item.instructions != null && item.instructions!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Instructions: ${item.instructions}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (dispensed) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, size: 13, color: AppColors.successText),
                          const SizedBox(width: 4),
                          Text(
                            'Dispensed',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.successText,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: AppColors.gradientPill),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await appState.dispenseItem(item.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: AppColors.primaryTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                content: Text(
                                  '${item.medicineName} Dispensed to Patient!',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.local_pharmacy_rounded, size: 15, color: Colors.white),
                        label: Text(
                          'Dispense Now',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}