import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          _buildHeaderBanner(),

          const SizedBox(height: 28),

          // Search Bar Section
          _buildSearchCard(),

          const SizedBox(height: 28),

          // Patient Prescriptions List
          if (matchingPatients.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            Column(
              children: matchingPatients.map((patient) {
                // Find hospital info
                final hospital = appState.hospitals.firstWhere(
                  (h) => h.id == patient.hospitalId,
                  orElse: () => appState.hospitals.first,
                );

                // Find doctor info
                final doctor = appState.doctors.firstWhere(
                  (d) => d.id == patient.assignedDoctorId,
                  orElse: () => appState.doctors.first,
                );

                // Items for this patient
                final items = appState.prescriptionItems;

                return _buildPatientCard(
                  context: context,
                  appState: appState,
                  patient: patient,
                  hospital: hospital,
                  doctor: doctor,
                  items: items,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------
  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTeal,
            AppColors.primaryTeal.withOpacity(0.85),
            AppColors.accentNavy.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Decorative soft glow circles for a premium feel
            Positioned(
              right: -30,
              top: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -60,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pharmacist Dispensing Portal',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Search patient name to inspect Doctor prescriptions, hospital origin, and dispense medicines.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------------------
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  size: 18,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lookup Patient Prescriptions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentNavy,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter Patient Name or Patient ID (e.g. Eleanor Vance)...',
                hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // EMPTY STATE
  // ------------------------------------------------------------------
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off_rounded,
                size: 40, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Text(
            'No patients found matching your search',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try entering a different patient name or ID above.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // PATIENT CARD
  // ------------------------------------------------------------------
  Widget _buildPatientCard({
    required BuildContext context,
    required AppState appState,
    required dynamic patient,
    required dynamic hospital,
    required dynamic doctor,
    required List<dynamic> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryTeal.withOpacity(0.25),
                      AppColors.primaryTeal.withOpacity(0.05),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryTeal.withOpacity(0.12),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primaryTeal, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        Text(
                          patient.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                            letterSpacing: 0.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgSlate,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(
                            'ID: ${patient.id}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.dangerRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monitor_heart_rounded,
                              size: 13, color: AppColors.dangerRed),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              patient.currentProblem,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
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

          const SizedBox(height: 20),
          Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),

          // Hospital & Doctor Mapping Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.local_hospital_rounded,
                  iconColor: AppColors.primaryTeal,
                  label: 'Hospital Origin',
                  title: hospital.name,
                  subtitle: hospital.address,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildInfoTile(
                  icon: Icons.badge_rounded,
                  iconColor: AppColors.accentNavy,
                  label: 'Prescribing Doctor',
                  title: doctor.name,
                  subtitle: doctor.specialty,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Icon(Icons.medication_rounded,
                  size: 16, color: AppColors.accentNavy),
              const SizedBox(width: 8),
              const Text(
                'Prescribed Medicines to Dispense',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentNavy,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Prescribed Medicines Table
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

  // ------------------------------------------------------------------
  // INFO TILE (Hospital / Doctor)
  // ------------------------------------------------------------------
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // MEDICINE ITEM
  // ------------------------------------------------------------------
  Widget _buildMedicineItem({
    required BuildContext context,
    required AppState appState,
    required dynamic item,
  }) {
    final bool dispensed = item.isDispensed;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: dispensed
            ? AppColors.primaryTeal.withOpacity(0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dispensed
              ? AppColors.primaryTeal.withOpacity(0.3)
              : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 64,
            decoration: BoxDecoration(
              color: dispensed
                  ? AppColors.primaryTeal
                  : AppColors.warningOrange,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
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
                    color: dispensed
                        ? AppColors.primaryTeal
                        : AppColors.warningOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.medicineName} (${item.dosage})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Frequency: ${item.frequency}  •  Duration: ${item.durationDays} Days',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (item.instructions != null &&
                            item.instructions!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text(
                              'Instructions: ${item.instructions}',
                              style: const TextStyle(
                                fontSize: 11,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryTeal,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Dispensed',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        await appState.dispenseItem(item.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.primaryTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${item.medicineName} Dispensed to Patient!'),
                                ],
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.local_pharmacy_rounded, size: 16),
                      label: const Text(
                        'Dispense Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
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