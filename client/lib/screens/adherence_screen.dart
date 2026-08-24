import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class AdherenceScreen extends StatefulWidget {
  const AdherenceScreen({super.key});

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  String _selectedClassFilter = 'ALL';
  OutreachStatus? _selectedOutreachFilter;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final allFlags = appState.filteredAdherenceFlags;

    // Apply class & outreach filters
    final flags = allFlags.where((f) {
      if (_selectedClassFilter != 'ALL') {
        if (_selectedClassFilter == 'STATINS' && !f.drugClass.toLowerCase().contains('statin') && !f.drugClass.toLowerCase().contains('cholesterol')) return false;
        if (_selectedClassFilter == 'RASA' && !f.drugClass.toLowerCase().contains('rasa') && !f.drugClass.toLowerCase().contains('ace') && !f.drugClass.toLowerCase().contains('arni')) return false;
        if (_selectedClassFilter == 'DIABETES' && !f.drugClass.toLowerCase().contains('diabet') && !f.drugClass.toLowerCase().contains('dpp') && !f.drugClass.toLowerCase().contains('sglt')) return false;
        if (_selectedClassFilter == 'DOAC' && !f.drugClass.toLowerCase().contains('anticoag') && !f.drugClass.toLowerCase().contains('doac')) return false;
      }
      if (_selectedOutreachFilter != null && f.outreachStatus != _selectedOutreachFilter) {
        return false;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Hero Banner
          _buildHeroBanner(context, appState, flags.length),

          const SizedBox(height: 18),

          // 2. CMS 5-Star Triple Measure & ML Analytics KPI Grid
          _buildCmsTripleMeasureGrid(context, appState),

          const SizedBox(height: 18),

          // 3. Configurable PDC Threshold Controller & What-If Simulator
          _buildPdcThresholdControlCard(context, appState),

          const SizedBox(height: 18),

          // 4. Search & Multi-Dimensional Filter Bar
          _buildFilterBar(context, appState),

          const SizedBox(height: 18),

          // 5. Patient Risk Stratification Queue
          _buildPatientQueueCard(context, appState, flags),
        ],
      ),
    );
  }

  // 1. Enterprise Hero Banner
  Widget _buildHeroBanner(BuildContext context, AppState appState, int flaggedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2042), Color(0xFF0D3B66), Color(0xFF0A5C67)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2042).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.analytics_rounded, color: Color(0xFF38BDF8), size: 30),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Adherence Risk Core (PDC Engine)',
                      style: AppFonts.googleSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PDC Core Active',
                            style: AppFonts.googleSans(
                              color: const Color(0xFF6EE7B7),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        'AWS EC2 ML Inference: 94.2% AUC',
                        style: AppFonts.googleSans(
                          color: const Color(0xFFBAE6FD),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'CMS Proportion of Days Covered (PDC) compliance telemetry & proactive clinical pharmacist intervention queue.',
                  style: AppFonts.googleSans(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF87171)),
                    const SizedBox(width: 6),
                    Text(
                      '$flaggedCount Flagged Patients',
                      style: AppFonts.googleSans(
                        color: const Color(0xFFFCA5A5),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'CMS 5-Star Target: ≥80.0%',
                  style: AppFonts.googleSans(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. CMS 5-Star Triple Measure & ML Analytics KPI Grid
  Widget _buildCmsTripleMeasureGrid(BuildContext context, AppState appState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cardWidth = isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 1. Diabetes PDC
            _buildMeasureKpiCard(
              width: cardWidth,
              title: 'Diabetes Medication PDC',
              code: 'CMS D10 (SGLT2 / DPP-4 / GLP-1)',
              value: '84.2%',
              target: '80.0%',
              badgeText: '★ 5-Star Compliant (+4.2%)',
              badgeColor: const Color(0xFF10B981),
              badgeBg: const Color(0xFFECFDF5),
              progressValue: 0.842,
              progressColor: const Color(0xFF10B981),
              icon: Icons.water_drop_rounded,
              enrollees: '142 Patients Enrolled',
            ),
            // 2. Hypertension / RASA
            _buildMeasureKpiCard(
              width: cardWidth,
              title: 'Hypertension (RASA / ARB)',
              code: 'CMS H12 (ACE-I / ARBs / ARNI)',
              value: '74.8%',
              target: '80.0%',
              badgeText: '⚠️ -5.2% Below Target',
              badgeColor: const Color(0xFFEF4444),
              badgeBg: const Color(0xFFFEF2F2),
              progressValue: 0.748,
              progressColor: const Color(0xFFEF4444),
              icon: Icons.favorite_rounded,
              enrollees: '198 Patients Enrolled',
            ),
            // 3. Cholesterol / Statins
            _buildMeasureKpiCard(
              width: cardWidth,
              title: 'Cholesterol (Statins)',
              code: 'CMS C08 (High/Mod Intensity)',
              value: '79.1%',
              target: '80.0%',
              badgeText: '🟡 Near 5-Star (-0.9%)',
              badgeColor: const Color(0xFFF59E0B),
              badgeBg: const Color(0xFFFFFBEB),
              progressValue: 0.791,
              progressColor: const Color(0xFFF59E0B),
              icon: Icons.shield_rounded,
              enrollees: '264 Patients Enrolled',
            ),
            // 4. AWS ML Predictive Abandonment
            _buildMeasureKpiCard(
              width: cardWidth,
              title: 'AWS ML Abandonment Risk',
              code: 'EC2 XGBoost Inference Engine',
              value: '11.8%',
              target: '< 15.0%',
              badgeText: '🔥 6 Urgent Interventions',
              badgeColor: const Color(0xFF8B5CF6),
              badgeBg: const Color(0xFFF5F3FF),
              progressValue: 0.118,
              progressColor: const Color(0xFF8B5CF6),
              icon: Icons.psychology_rounded,
              enrollees: '50k Claims Baseline',
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeasureKpiCard({
    required double width,
    required String title,
    required String code,
    required String value,
    required String target,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required double progressValue,
    required Color progressColor,
    required IconData icon,
    required String enrollees,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.metallicBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: progressColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  badgeText,
                  style: AppFonts.googleSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppFonts.googleSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          Text(
            code,
            style: AppFonts.googleSans(fontSize: 10.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppFonts.googleSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: progressColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Target: $target',
                style: AppFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressValue.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.bgSlate,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            enrollees,
            style: AppFonts.googleSans(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // 3. Configurable PDC Threshold Controller & Simulation
  Widget _buildPdcThresholdControlCard(BuildContext context, AppState appState) {
    final currentTarget = (appState.pdcThreshold * 100).toInt();

    return BentoCard(
      title: 'Configurable CMS PDC Threshold & Simulation Core',
      subtitle: 'Dynamically recalculate adherence flags, risk stratification queues, and outreach prioritization.',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.tune_rounded, color: AppColors.primaryTeal, size: 18),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: appState.pdcThreshold >= 0.80 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: appState.pdcThreshold >= 0.80 ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          appState.pdcThreshold >= 0.80 ? 'CMS 5-Star Standard (≥80%)' : 'Sub-Optimal Benchmark (<80%)',
          style: AppFonts.googleSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: appState.pdcThreshold >= 0.80 ? const Color(0xFF059669) : const Color(0xFFD97706),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Active PDC Adherence Target: ',
                    style: AppFonts.googleSans(fontSize: 13.5, color: AppColors.textDark),
                  ),
                  Text(
                    '$currentTarget%',
                    style: AppFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildThresholdPresetButton(appState, 'Critical (65%)', 0.65),
                  const SizedBox(width: 8),
                  _buildThresholdPresetButton(appState, 'HEDIS (75%)', 0.75),
                  const SizedBox(width: 8),
                  _buildThresholdPresetButton(appState, 'CMS 5-Star (80%)', 0.80),
                  const SizedBox(width: 8),
                  _buildThresholdPresetButton(appState, 'Strict (85%)', 0.85),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primaryTeal,
              inactiveTrackColor: AppColors.borderLight,
              thumbColor: AppColors.primaryTeal,
              overlayColor: AppColors.primaryTeal.withValues(alpha: 0.12),
              trackHeight: 6,
              valueIndicatorTextStyle: AppFonts.googleSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: appState.pdcThreshold,
              min: 0.50,
              max: 0.95,
              divisions: 9,
              label: '$currentTarget%',
              onChanged: (val) => appState.setPdcThreshold(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdPresetButton(AppState appState, String label, double value) {
    final isSelected = (appState.pdcThreshold - value).abs() < 0.01;

    return InkWell(
      onTap: () => appState.setPdcThreshold(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.bgSlate,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.metallicBorder,
          ),
        ),
        child: Text(
          label,
          style: AppFonts.googleSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // 4. Search & Multi-Dimensional Filter Bar
  Widget _buildFilterBar(BuildContext context, AppState appState) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    style: AppFonts.googleSans(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by patient name, medication, NDC, or diagnosis...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primaryTeal),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
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
                  height: 42,
                  child: DropdownButtonFormField<RiskLevel?>(
                    value: appState.selectedRiskFilter,
                    isExpanded: true,
                    style: AppFonts.googleSans(fontSize: 12.5, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      labelText: 'Risk Stratification Level',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Risk Levels', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: RiskLevel.high, child: Text('🚨 High Risk (<65% PDC)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: RiskLevel.medium, child: Text('⚠️ Medium Risk (65–79% PDC)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: RiskLevel.low, child: Text('🟢 Low Risk (≥80% PDC)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => appState.setAdherenceRiskFilter(val),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 42,
                  child: DropdownButtonFormField<OutreachStatus?>(
                    value: _selectedOutreachFilter,
                    isExpanded: true,
                    style: AppFonts.googleSans(fontSize: 12.5, color: AppColors.textDark),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      labelText: 'Outreach Case Status',
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Case Statuses', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: OutreachStatus.pending, child: Text('🔴 Pending Outreach', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: OutreachStatus.contacted, child: Text('🟡 Contacted / Scheduled', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: OutreachStatus.syncScheduled, child: Text('🔵 90-Day Sync Active', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: OutreachStatus.resolved, child: Text('🟢 Resolved / Adherent', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedOutreachFilter = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category quick-filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildClassChip('ALL', 'All Therapeutic Classes', Icons.grid_view_rounded),
                const SizedBox(width: 8),
                _buildClassChip('STATINS', '🫀 Statins (Cholesterol)', Icons.shield_rounded),
                const SizedBox(width: 8),
                _buildClassChip('RASA', '🩺 RASA / ARB (Blood Pressure)', Icons.favorite_rounded),
                const SizedBox(width: 8),
                _buildClassChip('DIABETES', '🩸 Diabetes (SGLT2 / DPP-4)', Icons.water_drop_rounded),
                const SizedBox(width: 8),
                _buildClassChip('DOAC', '🛡️ Anticoagulants (DOACs)', Icons.health_and_safety_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassChip(String key, String label, IconData icon) {
    final isSelected = _selectedClassFilter == key;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedClassFilter = key;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentNavy : AppColors.bgSlate,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accentNavy : AppColors.metallicBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppFonts.googleSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Patient Risk Stratification Queue
  Widget _buildPatientQueueCard(BuildContext context, AppState appState, List<AdherenceFlag> flags) {
    return BentoCard(
      title: 'Patient Risk Stratification & Proactive Intervention Queue',
      subtitle: 'Real-time refill intervals, 180-day gap analysis, and 1-click clinical pharmacist outreach triggers.',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.bgSlate,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.metallicBorder),
        ),
        child: Text(
          'Showing ${flags.length} High-Impact Cases',
          style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (flags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    Text(
                      'No patients flagged under current filter criteria.',
                      style: AppFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All patients in this cohort meet or exceed the active CMS PDC adherence target.',
                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: flags.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final flag = flags[index];
                final rx = appState.dataService.prescriptions.firstWhere(
                  (p) => p.id == flag.prescriptionId,
                  orElse: () => Prescription(
                    id: flag.prescriptionId,
                    patientId: flag.patientId,
                    patientName: flag.patientName,
                    drugId: 'DRUG-01',
                    drugName: flag.drugName,
                    drugClass: flag.drugClass,
                    fillDates: const [],
                    fillRecords: const [],
                    pdcScore: flag.pdcScore,
                    status: 'Refill Overdue',
                    lastFillDate: DateTime.now().subtract(const Duration(days: 45)),
                    nextDueDate: DateTime.now().subtract(const Duration(days: 15)),
                    prescriberName: 'Dr. Sarah Jenkins, MD',
                  ),
                );
                final patient = appState.dataService.patients.firstWhere(
                  (p) => p.id == flag.patientId,
                  orElse: () => Patient(
                    id: flag.patientId,
                    name: flag.patientName,
                    age: 67,
                    gender: 'Female',
                    prescriberId: 'DOC-01',
                    prescriberName: 'Dr. Sarah Jenkins, MD',
                    planId: 'PLAN-MED-01',
                    riskScore: 0.75,
                    phone: '(555) 234-8901',
                    email: '',
                  ),
                );

                return _buildPatientAdherenceCard(context, flag, rx, patient, appState);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPatientAdherenceCard(
    BuildContext context,
    AdherenceFlag flag,
    Prescription rx,
    Patient patient,
    AppState appState,
  ) {
    final pdcPct = (flag.pdcScore * 100).toInt();
    final isCritical = flag.pdcScore < 0.65;
    final isModerate = flag.pdcScore >= 0.65 && flag.pdcScore < 0.80;

    final scoreColor = isCritical
        ? const Color(0xFFEF4444)
        : (isModerate ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    final scoreBg = isCritical
        ? const Color(0xFFFEF2F2)
        : (isModerate ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5));

    // Simulated Abandonment probability
    final mlAbandonment = ((1.0 - flag.pdcScore) * 1.15).clamp(0.10, 0.95);
    final mlPct = (mlAbandonment * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCritical
              ? const Color(0xFFFCA5A5)
              : AppColors.metallicBorder.withValues(alpha: 0.8),
          width: isCritical ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isCritical
                ? const Color(0xFFEF4444).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Patient Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scoreBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    patient.name.isNotEmpty ? patient.name[0] : 'P',
                    style: AppFonts.googleSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Patient Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patient.name,
                          style: AppFonts.googleSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.bgSlate,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ID: ${patient.id} • Age: ${patient.age} (${patient.gender})',
                            style: AppFonts.googleSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F2042).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            patient.planId,
                            style: AppFonts.googleSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F2042),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Diagnosis: ${rx.diagnosis ?? "Chronic condition management"} • Prescriber: ${patient.prescriberName}',
                      style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // PDC Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'PDC $pdcPct%',
                      style: AppFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      isCritical ? 'Critical Non-Adherence' : (isModerate ? 'At-Risk Gap' : 'Optimal'),
                      style: AppFonts.googleSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // AWS ML Abandonment Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFF8B5CF6)),
                        const SizedBox(width: 3),
                        Text(
                          '$mlPct% Risk',
                          style: AppFonts.googleSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF6D28D9),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'AWS Abandonment',
                      style: AppFonts.googleSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Medication & Refill Telemetry Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.metallicBorder.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.metallicBorder),
                  ),
                  child: const Icon(Icons.medication_rounded, size: 18, color: AppColors.primaryTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        flag.drugName,
                        style: AppFonts.googleSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Class: ${flag.drugClass} • Status: ${rx.status}',
                        style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                // Visual Fill Timeline (180 days simulation)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '180-Day Fill Adherence Pattern',
                      style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildFillDot(true, 'Fill 1 (Day 0)'),
                        const SizedBox(width: 4),
                        _buildFillDot(true, 'Fill 2 (Day 30)'),
                        const SizedBox(width: 4),
                        _buildFillDot(true, 'Fill 3 (Day 60)'),
                        const SizedBox(width: 4),
                        _buildFillDot(false, 'Fill 4 (Missed/Late)'),
                        const SizedBox(width: 4),
                        _buildFillDot(isModerate, 'Fill 5 (Delayed)'),
                        const SizedBox(width: 4),
                        _buildFillDot(false, 'Fill 6 (Current Gap)'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Clinical Reason & Cost Barrier Callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCritical
                    ? const Color(0xFFF87171).withValues(alpha: 0.3)
                    : const Color(0xFFFBBF24).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    flag.reason,
                    style: AppFonts.googleSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isCritical ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. Clinical Pharmacist Action Bar
          Row(
            children: [
              _buildOutreachStatusPill(flag.outreachStatus),
              const Spacer(),
              // 1. Proactive Outreach Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 15),
                label: Text(
                  'Proactive Outreach',
                  style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                onPressed: () => _showPatientOutreachModal(context, flag, rx, patient, appState),
              ),
              const SizedBox(width: 8),
              // 2. 90-Day Med Sync Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F2042),
                  side: const BorderSide(color: Color(0xFF0F2042), width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.sync_rounded, size: 15),
                label: Text(
                  '1-Click 90-Day Sync',
                  style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800),
                ),
                onPressed: () {
                  appState.updateOutreachStatus(
                    flag.id,
                    OutreachStatus.syncScheduled,
                    'Enrolled in 90-Day Mail Order Sync program to eliminate monthly refill friction.',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF10B981),
                      content: Text(
                        '✅ ${patient.name} enrolled in 90-Day Auto-Refill Synchronization!',
                        style: AppFonts.googleSans(fontWeight: FontWeight.w700),
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // 3. Clinical Case Notes Trigger
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.bgSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.metallicBorder),
                  ),
                ),
                icon: const Icon(Icons.notes_rounded, size: 18, color: AppColors.textDark),
                tooltip: 'Clinical Case Details',
                onPressed: () => _showPatientOutreachModal(context, flag, rx, patient, appState),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFillDot(bool filled, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: filled ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: (filled ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutreachStatusPill(OutreachStatus status) {
    String label;
    Color bg;
    Color text;
    IconData icon;

    switch (status) {
      case OutreachStatus.pending:
        label = 'Pending Pharmacist Action';
        bg = const Color(0xFFFEF2F2);
        text = const Color(0xFFDC2626);
        icon = Icons.pending_actions_rounded;
        break;
      case OutreachStatus.contacted:
        label = 'Contacted / Consultation Scheduled';
        bg = const Color(0xFFFFFBEB);
        text = const Color(0xFFD97706);
        icon = Icons.phone_callback_rounded;
        break;
      case OutreachStatus.syncScheduled:
        label = '90-Day Med Sync Active';
        bg = const Color(0xFFEFF6FF);
        text = const Color(0xFF2563EB);
        icon = Icons.sync_rounded;
        break;
      case OutreachStatus.resolved:
        label = 'Case Resolved & Adherent';
        bg = const Color(0xFFECFDF5);
        text = const Color(0xFF059669);
        icon = Icons.check_circle_rounded;
        break;
      case OutreachStatus.declined:
        label = 'Outreach Declined';
        bg = AppColors.bgSlate;
        text = AppColors.textMuted;
        icon = Icons.block_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: text.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: text),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppFonts.googleSans(
              color: text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // 6. Interactive Clinical Case Modal
  void _showPatientOutreachModal(
    BuildContext context,
    AdherenceFlag flag,
    Prescription rx,
    Patient patient,
    AppState appState,
  ) {
    final noteController = TextEditingController(text: flag.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.contact_phone_rounded, color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Adherence Case Review',
                    style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  Text(
                    '${patient.name} • ID: ${patient.id} • ${patient.phone}',
                    style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient telemetry box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSlate,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.metallicBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            flag.drugName,
                            style: AppFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: flag.pdcScore < 0.65 ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PDC: ${(flag.pdcScore * 100).toInt()}% (${flag.riskLevel.name.toUpperCase()} RISK)',
                              style: AppFonts.googleSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: flag.pdcScore < 0.65 ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Prescriber: ${patient.prescriberName} • Plan: ${patient.planId}',
                        style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Adherence Barrier Description:',
                        style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        flag.reason,
                        style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textDark),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Action Bar
                Text(
                  '1-Click Pharmacist Actions:',
                  style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.sms_rounded, size: 16),
                        label: Text('Send SMS Refill Alert', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          appState.updateOutreachStatus(
                            flag.id,
                            OutreachStatus.contacted,
                            'Automated SMS refill reminder and copay savings link sent to ${patient.phone}.',
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF10B981),
                              content: Text('📱 SMS sent to ${patient.name} (${patient.phone})'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F2042),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.sync_rounded, size: 16),
                        label: Text('Enroll in 90-Day Sync', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          appState.updateOutreachStatus(
                            flag.id,
                            OutreachStatus.syncScheduled,
                            'Enrolled in 90-Day Mail Order Sync program.',
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF0F2042),
                              content: Text('🔄 90-Day Auto-Refill Sync enabled for ${patient.name}!'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Clinical Case Notes Field
                Text(
                  'Pharmacist Clinical Notes & Follow-Up Log:',
                  style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: AppFonts.googleSans(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Enter clinical consultation summary, patient preferences, or physician follow-up...',
                    filled: true,
                    fillColor: AppColors.bgSlate,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.metallicBorder),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              appState.updateOutreachStatus(
                flag.id,
                OutreachStatus.resolved,
                noteController.text.trim(),
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: const Color(0xFF10B981),
                  content: Text('✅ Case for ${patient.name} marked as Resolved!'),
                ),
              );
            },
            child: Text('Save & Resolve Case', style: AppFonts.googleSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
