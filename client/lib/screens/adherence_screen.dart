import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class AdherenceScreen extends StatelessWidget {
  const AdherenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final flags = appState.filteredAdherenceFlags;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Adherence Risk Core (PDC Engine)',
            subtitle:
                'CMS Proportion of Days Covered (PDC) compliance telemetry & proactive pharmacist outreach.',
            icon: Icons.insights_rounded,
            statusLabel: 'PDC Core Active',
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${flags.length} Flagged Patients',
                style: AppFonts.googleSans(
                  color: AppColors.dangerText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 2. Configurable PDC Threshold Slider Bento Card
          _buildPdcThresholdControlCard(context, appState),

          const SizedBox(height: 18),

          // 3. Search & Filter Bento Card
          _buildFilterCard(context, appState),

          const SizedBox(height: 18),

          // 4. Patient Adherence Risk List Bento Card
          BentoCard(
            title: 'Patient Risk Stratification Queue',
            subtitle:
                'Real-time refill intervals calculated from pharmacy fill history',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (flags.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Center(
                      child: Text(
                        'No patients flagged at current PDC threshold and filter criteria.',
                        style: AppFonts.googleSans(
                            color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: flags.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final flag = flags[index];
                      final rx = appState.dataService.prescriptions.firstWhere(
                        (p) => p.id == flag.prescriptionId,
                        orElse: () => appState
                                .dataService.prescriptions.isNotEmpty
                            ? appState.dataService.prescriptions.first
                            : Prescription(
                                id: flag.prescriptionId,
                                patientId: flag.patientId,
                                patientName: flag.patientName,
                                drugId: 'DRUG-01',
                                drugName: flag.drugName,
                                drugClass: flag.drugClass,
                                fillDates: const [],
                                fillRecords: const [],
                                pdcScore: flag.pdcScore,
                                status: 'Active',
                                lastFillDate: DateTime.now(),
                                nextDueDate: DateTime.now()
                                    .add(const Duration(days: 30)),
                                prescriberName: 'Dr. Rahul Verma',
                              ),
                      );
                      final patient = appState.dataService.patients.firstWhere(
                        (p) => p.id == flag.patientId,
                        orElse: () => appState.dataService.patients.isNotEmpty
                            ? appState.dataService.patients.first
                            : Patient(
                                id: flag.patientId,
                                name: flag.patientName.isNotEmpty
                                    ? flag.patientName
                                    : 'Eleanor Vance',
                                age: 67,
                                gender: 'Female',
                                prescriberId: 'DOC-201',
                                prescriberName: 'Dr. Rahul Verma',
                                planId: 'PLAN-01',
                                riskScore: 0.35,
                                phone: '(555) 019-2834',
                                email: '',
                              ),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            _buildRiskAvatar(flag.riskLevel),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    flag.patientName,
                                    style: AppFonts.googleSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    '${flag.drugName} • Prescriber: ${patient.prescriberName}',
                                    style: AppFonts.googleSans(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.bgSlate,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.metallicBorder),
                              ),
                              child: Text(
                                'PDC ${(flag.pdcScore * 100).toInt()}%',
                                style: AppFonts.googleSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: flag.pdcScore < 0.65
                                      ? AppColors.jewelSoftCoral
                                      : AppColors.jewelWarmAmber,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildOutreachChip(flag.outreachStatus),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded,
                                  size: 20, color: AppColors.primaryTeal),
                              onPressed: () => _showPatientOutreachModal(
                                  context, flag, rx, patient, appState),
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
    return BentoCard(
      title: 'Configurable CMS PDC Threshold Control',
      subtitle:
          'Adjust threshold percentage to dynamically recalculate adherence flags across your patient panel',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.tune_rounded,
            color: AppColors.primaryTeal, size: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active PDC Adherence Target: ${(appState.pdcThreshold * 100).toInt()}%',
                style: AppFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: appState.pdcThreshold >= 0.80
                      ? AppColors.successBg
                      : AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  appState.pdcThreshold >= 0.80
                      ? 'CMS 5-Star Compliant'
                      : 'Sub-Optimal Benchmark',
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: appState.pdcThreshold >= 0.80
                        ? AppColors.successText
                        : AppColors.warningText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryTeal,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primaryTeal,
              overlayColor: AppColors.primaryTeal.withValues(alpha: 0.12),
              trackHeight: 6,
            ),
            child: Slider(
              value: appState.pdcThreshold,
              min: 0.50,
              max: 0.95,
              divisions: 9,
              label: '${(appState.pdcThreshold * 100).toInt()}%',
              onChanged: (val) => appState.setPdcThreshold(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, AppState appState) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                style: AppFonts.googleSans(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Search patient name or prescribed medication...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: AppColors.primaryTeal),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                  filled: true,
                  fillColor: AppColors.bgSlate,
                ),
                onChanged: (val) => appState.setAdherenceSearchQuery(val),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 40,
              child: DropdownButtonFormField<RiskLevel?>(
                initialValue: appState.selectedRiskFilter,
                isExpanded: true,
                style: AppFonts.googleSans(
                    fontSize: 12.5, color: AppColors.textDark),
                decoration: const InputDecoration(
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  labelText: 'Risk Filter',
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Risk Levels', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  DropdownMenuItem(
                      value: RiskLevel.high,
                      child: Text('High Risk (<65% PDC)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  DropdownMenuItem(
                      value: RiskLevel.medium,
                      child: Text('Medium Risk (65-79% PDC)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  DropdownMenuItem(
                      value: RiskLevel.low,
                      child: Text('Low Risk (>=80% PDC)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                ],
                onChanged: (val) => appState.setAdherenceRiskFilter(val),
              ),
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
        iconColor = AppColors.jewelSoftCoral;
        break;
      case RiskLevel.medium:
        bg = AppColors.warningBg;
        iconColor = AppColors.jewelWarmAmber;
        break;
      case RiskLevel.low:
        bg = AppColors.successBg;
        iconColor = AppColors.jewelEmerald;
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: iconColor.withValues(alpha: 0.25)),
      ),
      child: Icon(
        risk == RiskLevel.low
            ? Icons.check_circle_rounded
            : Icons.warning_amber_rounded,
        color: iconColor,
        size: 19,
      ),
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
        style: AppFonts.googleSans(
          color: text,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showPatientOutreachModal(BuildContext context, AdherenceFlag flag,
      Prescription rx, Patient patient, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Patient Adherence Timeline & Outreach',
          style: AppFonts.googleSans(
              fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${patient.name} (Age: ${patient.age})',
                style: AppFonts.googleSans(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Prescribed: ${flag.drugName} • Prescriber: ${patient.prescriberName}',
                style: AppFonts.googleSans(
                    fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgSlate,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current PDC: ${(flag.pdcScore * 100).toInt()}%',
                        style: AppFonts.googleSans(
                            fontWeight: FontWeight.w700)),
                    Text('Risk: ${flag.riskLevel.name.toUpperCase()}',
                        style: AppFonts.googleSans(
                            color: AppColors.textMuted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close',
                style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              appState.updateOutreachStatus(
                  flag.id,
                  OutreachStatus.contacted,
                  'Outreach initiated by clinical pharmacist');
              Navigator.pop(context);
            },
            child: Text('Mark Contacted',
                style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
