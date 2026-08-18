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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryTeal, AppColors.primaryTeal.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Pharmacist Dispensing Portal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Search patient name to inspect Doctor prescriptions, hospital origin, and dispense medicines.',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Search Bar Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lookup Patient Prescriptions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentNavy,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Enter Patient Name or Patient ID (e.g. Eleanor Vance)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Patient Prescriptions List
          if (matchingPatients.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: const [
                  Icon(Icons.search_off, size: 48, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No patients found matching your search',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Try entering a different patient name or ID above.',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
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

                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
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
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.primaryTeal.withOpacity(0.12),
                            child: const Icon(Icons.person,
                                color: AppColors.primaryTeal, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      patient.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.bgSlate,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'ID: ${patient.id}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Current Problem: ${patient.currentProblem}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.dangerRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Hospital & Doctor Mapping Grid
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bgSlate,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_hospital,
                                      color: AppColors.primaryTeal, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Hospital Origin',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                                fontWeight: FontWeight.bold)),
                                        Text(hospital.name,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                        Text(hospital.address,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.bgSlate,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.badge_outlined,
                                      color: AppColors.accentNavy, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Prescribing Doctor',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.textMuted,
                                                fontWeight: FontWeight.bold)),
                                        Text(doctor.name,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                        Text(doctor.specialty,
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Prescribed Medicines to Dispense:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Prescribed Medicines Table
                      Column(
                        children: items.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: item.isDispensed
                                  ? AppColors.primaryTeal.withOpacity(0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: item.isDispensed
                                    ? AppColors.primaryTeal.withOpacity(0.3)
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.isDispensed
                                      ? Icons.check_circle_rounded
                                      : Icons.pending_actions_rounded,
                                  color: item.isDispensed
                                      ? AppColors.primaryTeal
                                      : AppColors.warningOrange,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.medicineName} (${item.dosage})',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Frequency: ${item.frequency} | Duration: ${item.durationDays} Days',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                      if (item.instructions != null &&
                                          item.instructions!.isNotEmpty)
                                        Text(
                                          'Instructions: ${item.instructions}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontStyle: FontStyle.italic,
                                            color: AppColors.primaryTeal,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                if (item.isDispensed) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryTeal,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Dispensed ✓',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await appState.dispenseItem(item.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.primaryTeal,
                                            content: Text(
                                                '${item.medicineName} Dispensed to Patient!'),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.local_pharmacy, size: 16),
                                    label: const Text('Dispense Now'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryTeal,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
