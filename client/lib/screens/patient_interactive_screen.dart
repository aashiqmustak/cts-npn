import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PatientInteractiveScreen extends StatefulWidget {
  const PatientInteractiveScreen({super.key});

  @override
  State<PatientInteractiveScreen> createState() =>
      _PatientInteractiveScreenState();
}

class _PatientInteractiveScreenState extends State<PatientInteractiveScreen> {
  final _customMedController = TextEditingController();
  final _timeController = TextEditingController(text: '08:00 AM');

  @override
  void dispose() {
    _customMedController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _addCustomMedicine(AppState appState) {
    if (_customMedController.text.trim().isEmpty) return;
    appState.dataService.patientLogs; // Ensures list is mutable in state
    final newLog = PatientMedicineLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      patientId: appState.currentUser.patientId ?? 'PT-301',
      medicineName: _customMedController.text.trim(),
      scheduledTime: _timeController.text.trim(),
      isTaken: false,
      logDate: DateTime.now(),
      notes: 'Added by patient',
    );
    appState.patientLogs.add(newLog);
    _customMedController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primaryTeal,
        content: Text('Medicine added to your daily schedule!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final logs = appState.patientLogs;
    final takenCount = logs.where((l) => l.isTaken).length;
    final progress = logs.isEmpty ? 0.0 : takenCount / logs.length;


    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalized Greeting Banner
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D9488).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DAILY HEALTH HUB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.local_fire_department,
                              color: Colors.orangeAccent, size: 20),
                          const Text(
                            '7 Day Adherence Streak!',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome Back, ${appState.currentUser.name}! 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Keep up your great health habits. Check off your daily medicines below!',
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Circular Progress Indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Medical Diagnosis Summary Widget
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.health_and_safety_outlined,
                      color: AppColors.primaryTeal, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Medical Issue / Diagnosis',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        appState.patientRecords.isNotEmpty
                            ? appState.patientRecords.first.currentProblem
                            : 'No active medical diagnosis logged yet.',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentNavy),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.hospitals.isNotEmpty && appState.doctors.isNotEmpty
                            ? 'Care Team: ${appState.doctors.first.name} at ${appState.hospitals.first.name}'
                            : 'Care Team: Add Doctor & Hospital in Portal',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Interactive Medicine Checklist Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Medication Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentNavy,
                ),
              ),
              Text(
                '$takenCount of ${logs.length} Completed',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryTeal,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Medicine Check List
          Column(
            children: logs.map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: log.isTaken
                      ? AppColors.primaryTeal.withOpacity(0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: log.isTaken
                        ? AppColors.primaryTeal.withOpacity(0.4)
                        : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: log.isTaken,
                      activeColor: AppColors.primaryTeal,
                      onChanged: (val) async {
                        await appState.togglePatientLog(log.id, val ?? false);
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.medicineName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              decoration: log.isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: log.isTaken
                                  ? AppColors.textMuted
                                  : AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                'Scheduled: ${log.scheduledTime}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                              if (log.notes != null) ...[
                                const SizedBox(width: 12),
                                Text(
                                  '• ${log.notes}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryTeal,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (log.isTaken)
                      const Chip(
                        label: Text('Taken ✓', style: TextStyle(color: Colors.white, fontSize: 11)),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Add Custom Medicine Form
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Extra Medicine or Supplement',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentNavy,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _customMedController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Vitamin D3 1000 IU',
                          labelText: 'Medicine Name',
                          prefixIcon: Icon(Icons.medication_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _timeController,
                        decoration: const InputDecoration(
                          hintText: '08:00 AM',
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.schedule, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _addCustomMedicine(appState),
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Schedule'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
