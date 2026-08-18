import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AdherenceScreen extends StatelessWidget {
  const AdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final flags = appState.filteredAdherenceFlags;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Screen Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Adherence Risk Monitoring (PDC Engine)',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Synthea-backed fill histories & CMS Proportion of Days Covered (PDC) compliance benchmarks.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${flags.length} Patients Flagged At-Risk',
                  style: const TextStyle(
                    color: AppColors.dangerText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Configurable PDC Threshold Slider Card
          _buildPdcThresholdControlCard(context, appState),

          const SizedBox(height: 20),

          // Filter Controls Card
          _buildFilterCard(context, appState),

          const SizedBox(height: 20),

          // Patient Adherence Risk List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (flags.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No patients flagged at current PDC threshold and filter criteria.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: flags.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final flag = flags[index];
                      final rx = appState.dataService.prescriptions.firstWhere(
                        (p) => p.id == flag.prescriptionId,
                        orElse: () => appState.dataService.prescriptions.first,
                      );
                      final patient = appState.dataService.patients.firstWhere(
                        (p) => p.id == flag.patientId,
                        orElse: () => appState.dataService.patients.first,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Risk Indicator Avatar
                            _buildRiskAvatar(flag.riskLevel),

                            const SizedBox(width: 14),

                            // Patient & Prescriber Info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${patient.age} yrs • ${patient.gender} • Prescriber: ${patient.prescriberName}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Drug & Class
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flag.drugName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    flag.drugClass,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // PDC Score Gauge Bar
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'PDC: ${(flag.pdcScore * 100).toInt()}%',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: flag.pdcScore < appState.pdcThreshold
                                              ? AppColors.dangerText
                                              : AppColors.successText,
                                        ),
                                      ),
                                      Text(
                                        flag.pdcScore < appState.pdcThreshold ? 'Below Target' : 'Compliant',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: flag.pdcScore,
                                      minHeight: 6,
                                      backgroundColor: AppColors.borderLight,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        flag.pdcScore < appState.pdcThreshold
                                            ? AppColors.dangerText
                                            : AppColors.successText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 12),

                            // Outreach Status Badge
                            Expanded(
                              flex: 2,
                              child: _buildOutreachChip(flag.outreachStatus),
                            ),

                            // Action Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () {
                                _showPatientOutreachModal(context, flag, rx, patient, appState);
                              },
                              child: const Text('View Timeline & Outreach', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdcThresholdControlCard(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.tune_rounded, color: AppColors.primaryTeal),
                  const SizedBox(width: 10),
                  Text(
                    'CMS Adherence Benchmark PDC Threshold: ${(appState.pdcThreshold * 100).toInt()}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Configurable Rule',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Adjust the PDC (Proportion of Days Covered) cutoff threshold to dynamically filter patients with gaps in refill adherence.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('50%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: appState.pdcThreshold,
                  min: 0.50,
                  max: 0.95,
                  divisions: 9,
                  label: '${(appState.pdcThreshold * 100).toInt()}% PDC',
                  activeColor: AppColors.primaryTeal,
                  onChanged: (val) => appState.setPdcThreshold(val),
                ),
              ),
              const Text('95%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search patient name or drug...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (val) => appState.setAdherenceSearchQuery(val),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<RiskLevel?>(
              value: appState.selectedRiskFilter,
              decoration: const InputDecoration(
                labelText: 'Risk Level',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Risk Levels')),
                DropdownMenuItem(value: RiskLevel.high, child: Text('High Risk (<65% PDC)')),
                DropdownMenuItem(value: RiskLevel.medium, child: Text('Medium Risk (65-79% PDC)')),
                DropdownMenuItem(value: RiskLevel.low, child: Text('Low Risk (>=80% PDC)')),
              ],
              onChanged: (val) => appState.setAdherenceRiskFilter(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskAvatar(RiskLevel risk) {
    Color bg;
    Color iconColor;

    switch (risk) {
      case RiskLevel.high:
        bg = AppColors.dangerBg;
        iconColor = AppColors.dangerText;
        break;
      case RiskLevel.medium:
        bg = AppColors.warningBg;
        iconColor = AppColors.warningText;
        break;
      case RiskLevel.low:
        bg = AppColors.successBg;
        iconColor = AppColors.successText;
        break;
    }

    return CircleAvatar(
      radius: 18,
      backgroundColor: bg,
      child: Icon(Icons.warning_amber_rounded, color: iconColor, size: 20),
    );
  }

  Widget _buildOutreachChip(OutreachStatus status) {
    String label;
    Color bg;
    Color text;

    switch (status) {
      case OutreachStatus.pending:
        label = 'Pending Outreach';
        bg = AppColors.dangerBg;
        text = AppColors.dangerText;
        break;
      case OutreachStatus.contacted:
        label = 'Contacted';
        bg = AppColors.warningBg;
        text = AppColors.warningText;
        break;
      case OutreachStatus.resolved:
        label = 'Resolved';
        bg = AppColors.successBg;
        text = AppColors.successText;
        break;
      case OutreachStatus.declined:
        label = 'Declined';
        bg = AppColors.bgSlate;
        text = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPatientOutreachModal(BuildContext context, AdherenceFlag flag,
      Prescription rx, Patient patient, AppState appState) {
    final fmtDate = DateFormat('MMM d, yyyy');
    final noteController = TextEditingController(text: flag.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Adherence Detail & Outreach: ${patient.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSlate,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medication: ${flag.drugName}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('Prescriber: ${rx.prescriberName} • Phone: ${patient.phone}'),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PDC Score: ${(flag.pdcScore * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Adherence Gap Rationale', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(flag.reason, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),

                const SizedBox(height: 20),

                const Text('Synthea Refill History Timeline', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // Timeline List
                Column(
                  children: rx.fillRecords.map((fill) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: fill.wasOnTime ? AppColors.borderLight : AppColors.dangerBg),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            fill.wasOnTime ? Icons.check_circle : Icons.error,
                            color: fill.wasOnTime ? AppColors.successText : AppColors.dangerText,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fill Date: ${fmtDate.format(fill.date)} (${fill.daysSupply} Days Supply)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            fill.wasOnTime ? 'On Time' : 'Refill Delayed',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: fill.wasOnTime ? AppColors.successText : AppColors.dangerText,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),

                const Text('Pharmacist Outreach Action & Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Enter clinical outreach notes (e.g. Spoke with patient, offered copay assistance, contacted prescriber)...',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.updateOutreachStatus(
                flag.id,
                OutreachStatus.contacted,
                noteController.text,
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Patient outreach logged successfully!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: const Text('Log Outreach & Update'),
          ),
        ],
      ),
    );
  }
}
