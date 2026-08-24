import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/bento_card.dart';

// ============================================================================
// DATA MODELS FOR CLINICAL ANALYTICS
// ============================================================================

class _TabletFilterItem {
  final String name;
  final String originalBrand;
  final String alternativeGeneric;
  final String drugClass;
  final String fhirCode;
  final Color badgeColor;
  final IconData icon;

  const _TabletFilterItem({
    required this.name,
    required this.originalBrand,
    required this.alternativeGeneric,
    required this.drugClass,
    required this.fhirCode,
    required this.badgeColor,
    required this.icon,
  });
}

class _TabletChartData {
  final List<String> xLabels;
  final List<double> doctorPrescribedValues;
  final List<double> alternativeDispensedValues;
  final List<String> savingsByPeriod;
  final int totalDoctorPrescribed;
  final int totalAlternativeDispensed;
  final String substitutionRate;
  final String totalSavings;
  final double maxY;

  const _TabletChartData({
    required this.xLabels,
    required this.doctorPrescribedValues,
    required this.alternativeDispensedValues,
    required this.savingsByPeriod,
    required this.totalDoctorPrescribed,
    required this.totalAlternativeDispensed,
    required this.substitutionRate,
    required this.totalSavings,
    required this.maxY,
  });
}

class _TherapeuticClassItem {
  final String name;
  final double percentage;
  final int prescriptionCount;
  final Color color;
  final String subtext;

  const _TherapeuticClassItem({
    required this.name,
    required this.percentage,
    required this.prescriptionCount,
    required this.color,
    required this.subtext,
  });
}

// ============================================================================
// CLINICAL ANALYTICS DASHBOARD SCREEN
// ============================================================================

class DoctorOverviewDashboardScreen extends StatefulWidget {
  const DoctorOverviewDashboardScreen({super.key});

  @override
  State<DoctorOverviewDashboardScreen> createState() =>
      _DoctorOverviewDashboardScreenState();
}

class _DoctorOverviewDashboardScreenState
    extends State<DoctorOverviewDashboardScreen>
    with TickerProviderStateMixin {
  // Chart 1: Tablet Comparison State
  int _selectedTabletFilterIndex = 0;
  int _tabletChartTimeRangeIndex = 0; // 0: 7D, 1: 30D, 2: 90D
  bool _showPrescribedSeries = true;
  bool _showAlternativeSeries = true;
  int? _selectedBarGroupIndex;

  late AnimationController _tabletChartAnimController;
  late Animation<double> _tabletChartAnim;

  // Chart 2: Consultations & e-Rx Line Chart State
  int _consultationTimeRangeIndex = 0; // 0: 7D, 1: 30D, 2: 90D
  bool _showConsultationsSeries = true;
  bool _showEprescriptionsSeries = true;
  int? _selectedLinePointIndex;

  late AnimationController _lineChartAnimController;
  late Animation<double> _lineChartAnim;

  // Chart 3: Therapeutic Classes Donut State
  int _selectedDonutIndex = 0; // default to first class
  late AnimationController _donutChartAnimController;
  late Animation<double> _donutChartAnim;

  static const List<_TabletFilterItem> _tabletFilters = [
    _TabletFilterItem(
      name: 'All Tablets (Overview)',
      originalBrand: 'All Brand Prescriptions',
      alternativeGeneric: 'All Bioequivalent Generics',
      drugClass: 'Aggregated Therapeutic Formulary',
      fhirCode: 'FHIR-RX-AGGREGATE',
      badgeColor: Color(0xFF1244A2),
      icon: Icons.medication_rounded,
    ),
    _TabletFilterItem(
      name: 'Atorvastatin 20mg',
      originalBrand: 'Lipitor 20mg (Pfizer)',
      alternativeGeneric: 'Atorvastatin Calcium 20mg',
      drugClass: 'HMG-CoA Reductase Inhibitor (Cardiology)',
      fhirCode: 'RxNorm: 83367',
      badgeColor: Color(0xFF2563EB),
      icon: Icons.favorite_rounded,
    ),
    _TabletFilterItem(
      name: 'Metformin HCL 500mg',
      originalBrand: 'Glucophage 500mg (Bristol Myers)',
      alternativeGeneric: 'Metformin Hydrochloride 500mg',
      drugClass: 'Biguanide Antidiabetic (Endocrinology)',
      fhirCode: 'RxNorm: 860975',
      badgeColor: Color(0xFF10B981),
      icon: Icons.water_drop_rounded,
    ),
    _TabletFilterItem(
      name: 'Lisinopril 10mg',
      originalBrand: 'Zestril 10mg (AstraZeneca)',
      alternativeGeneric: 'Lisinopril USP 10mg',
      drugClass: 'ACE Inhibitor (Hypertension)',
      fhirCode: 'RxNorm: 314076',
      badgeColor: Color(0xFF8B5CF6),
      icon: Icons.speed_rounded,
    ),
    _TabletFilterItem(
      name: 'Omeprazole 20mg',
      originalBrand: 'Nexium 20mg (AstraZeneca)',
      alternativeGeneric: 'Omeprazole Delayed-Release 20mg',
      drugClass: 'Proton Pump Inhibitor (Gastroenterology)',
      fhirCode: 'RxNorm: 7646',
      badgeColor: Color(0xFFF59E0B),
      icon: Icons.shield_rounded,
    ),
    _TabletFilterItem(
      name: 'Amlodipine 5mg',
      originalBrand: 'Norvasc 5mg (Pfizer)',
      alternativeGeneric: 'Amlodipine Besylate 5mg',
      drugClass: 'Calcium Channel Blocker (Cardiology)',
      fhirCode: 'RxNorm: 197361',
      badgeColor: Color(0xFF06B6D4),
      icon: Icons.favorite_border_rounded,
    ),
    _TabletFilterItem(
      name: 'Losartan 50mg',
      originalBrand: 'Cozaar 50mg (Merck)',
      alternativeGeneric: 'Losartan Potassium 50mg',
      drugClass: 'Angiotensin II Receptor Antagonist (Nephrology)',
      fhirCode: 'RxNorm: 979467',
      badgeColor: Color(0xFFEC4899),
      icon: Icons.monitor_heart_rounded,
    ),
    _TabletFilterItem(
      name: 'Azithromycin 250mg',
      originalBrand: 'Zithromax 250mg (Pfizer)',
      alternativeGeneric: 'Azithromycin Monohydrate 250mg',
      drugClass: 'Macrolide Antibacterial (Infectious Disease)',
      fhirCode: 'RxNorm: 18631',
      badgeColor: Color(0xFF14B8A6),
      icon: Icons.biotech_rounded,
    ),
  ];

  static const List<_TherapeuticClassItem> _therapeuticClasses = [
    _TherapeuticClassItem(
      name: 'Cardiology',
      percentage: 38,
      prescriptionCount: 19000,
      color: Color(0xFF1244A2),
      subtext: 'Statins, Beta Blockers & ACEi',
    ),
    _TherapeuticClassItem(
      name: 'Endocrine / Diabetes',
      percentage: 26,
      prescriptionCount: 13000,
      color: Color(0xFF10B981),
      subtext: 'Metformin, SGLT2 & GLP-1',
    ),
    _TherapeuticClassItem(
      name: 'Antibiotics',
      percentage: 20,
      prescriptionCount: 10000,
      color: Color(0xFFF59E0B),
      subtext: 'Macrolides, Penicillins & Cephs',
    ),
    _TherapeuticClassItem(
      name: 'Psychiatric / CNS',
      percentage: 16,
      prescriptionCount: 8000,
      color: Color(0xFFEC4899),
      subtext: 'Antiepileptics & Anxiolytics',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabletChartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _tabletChartAnim = CurvedAnimation(
      parent: _tabletChartAnimController,
      curve: Curves.easeOutCubic,
    );

    _lineChartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _lineChartAnim = CurvedAnimation(
      parent: _lineChartAnimController,
      curve: Curves.easeOutCubic,
    );

    _donutChartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _donutChartAnim = CurvedAnimation(
      parent: _donutChartAnimController,
      curve: Curves.easeOutQuart,
    );

    _tabletChartAnimController.forward();
    _lineChartAnimController.forward();
    _donutChartAnimController.forward();
  }

  @override
  void dispose() {
    _tabletChartAnimController.dispose();
    _lineChartAnimController.dispose();
    _donutChartAnimController.dispose();
    super.dispose();
  }

  void _onTabletFilterSelected(int index) {
    if (_selectedTabletFilterIndex == index) return;
    setState(() {
      _selectedTabletFilterIndex = index;
      _selectedBarGroupIndex = null;
    });
    _tabletChartAnimController.reset();
    _tabletChartAnimController.forward();
  }

  void _onTabletTimeframeSelected(int index) {
    if (_tabletChartTimeRangeIndex == index) return;
    setState(() {
      _tabletChartTimeRangeIndex = index;
      _selectedBarGroupIndex = null;
    });
    _tabletChartAnimController.reset();
    _tabletChartAnimController.forward();
  }

  void _onConsultationTimeframeSelected(int index) {
    if (_consultationTimeRangeIndex == index) return;
    setState(() {
      _consultationTimeRangeIndex = index;
      _selectedLinePointIndex = null;
    });
    _lineChartAnimController.reset();
    _lineChartAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final doctorName = user.name.isNotEmpty ? user.name : 'Dr. Tariq Martin';
    final hospitalName = user.hospitalName ?? 'Wake Forest Baptist Medical Center';

    final totalPrescriptions = appState.prescriptions.length;
    final totalPatients = appState.patientRecords.length;
    final totalHospitals = appState.hospitals.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Executive Doctor Welcome Header Banner
          _buildExecutiveHeader(
            context,
            appState,
            doctorName: doctorName,
            hospitalName: hospitalName,
          ),

          const SizedBox(height: 18),

          // 1.5. Pharmacy Alternative Approval Requests (CDS Feed)
          _buildAlternativeApprovalRequestsSection(appState),

          // 2. Core Telemetry Bento Grid (4 Summary Cards)
          _buildTelemetryBentoGrid(
            totalPrescriptions: totalPrescriptions,
            totalPatients: totalPatients,
            totalHospitals: totalHospitals,
          ),

          const SizedBox(height: 18),

          // 3. FEATURED CHART 1: Doctor Prescriptions vs Alternative Tablet Dispensed
          _buildTabletComparisonChartSection(),

          const SizedBox(height: 18),

          // 4. CHARTS 2 & 3: Dual Interactive Chart Analytics Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 960;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildPatientVolumeLineChart()),
                    const SizedBox(width: 16),
                    Expanded(flex: 5, child: _buildDrugClassDistributionChart()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildPatientVolumeLineChart(),
                  const SizedBox(height: 16),
                  _buildDrugClassDistributionChart(),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          // 5. Clinical Appointments & Live e-Rx Transmission Queue
          _buildTodaysPatientQueue(appState),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. EXECUTIVE HEADER BANNER
  // =========================================================================
  Widget _buildExecutiveHeader(
    BuildContext context,
    AppState appState, {
    required String doctorName,
    required String hospitalName,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1244A2).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doctorName,
                        style: AppFonts.googleSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'DEA & NPI Active',
                            style: AppFonts.googleSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF34D399),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$hospitalName — Clinical Analytics Workspace',
                  style: AppFonts.googleSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              appState.setNavIndex(1); // Navigate to Issue Prescription
            },
            icon: const Icon(Icons.edit_note_rounded, size: 17, color: Colors.white),
            label: Text(
              '+ Issue Quick e-Rx',
              style: AppFonts.googleSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1244A2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1.5. PHARMACY ALTERNATIVE APPROVAL REQUESTS (CDS DECISIONS FEED)
  // =========================================================================
  Widget _buildAlternativeApprovalRequestsSection(AppState appState) {
    final pending = appState.pendingAlternativeApprovalRequests;
    if (pending.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFC084FC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
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
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pharmacy Alternative Regimen Approvals (CDS Feed)',
                        style: AppFonts.googleSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF4C1D95),
                        ),
                      ),
                      Text(
                        '${pending.length} Alternative medication change requests sent by Pharmacist awaiting physician sign-off',
                        style: AppFonts.googleSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_actions_rounded, size: 14, color: Colors.white),
                    const SizedBox(width: 5),
                    Text(
                      '${pending.length} PENDING REVIEW',
                      style: AppFonts.googleSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...pending.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9D5FF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Details Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${req.patientName} (${req.patientAge}y)',
                                style: AppFonts.googleSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Prescription ID: #${req.prescriptionId} • Indication: ${req.indication}',
                                style: AppFonts.googleSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Save \$${req.monthlySavings.toStringAsFixed(2)} / month',
                          style: AppFonts.googleSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: const Color(0xFFF3E8FF)),
                  const SizedBox(height: 14),

                  // Original vs Alternative Comparison
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ORIGINAL DRUG PRESCRIBED',
                                style: AppFonts.googleSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                req.originalDrug,
                                style: AppFonts.googleSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF7F1D1D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, color: Color(0xFF8B5CF6), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF6EE7B7)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RECOMMENDED ALTERNATIVE',
                                style: AppFonts.googleSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF065F46),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                req.recommendedAlternative,
                                style: AppFonts.googleSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF064E3B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Clinical Class & Rationale
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Clinical Class: ${req.clinicalClass}',
                          style: AppFonts.googleSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Clinical Rationale: ${req.clinicalRationale}',
                          style: AppFonts.googleSans(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFCA5A5)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 15),
                        label: Text('Deny Alternative',
                            style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                        onPressed: () {
                          appState.denyAlternativeDrug(requestId: req.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFEF4444),
                              content: Text('❌ Alternative denied for ${req.patientName}. Pharmacist notified.'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded, size: 16),
                        label: Text('Approve Alternative Medicine',
                            style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w900)),
                        onPressed: () {
                          appState.approveAlternativeDrug(requestId: req.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF10B981),
                              content: Text(
                                  '✅ Approved ${req.recommendedAlternative} for ${req.patientName}! Voice notification dispatched to Pharmacist.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. CORE TELEMETRY BENTO GRID
  // =========================================================================
  Widget _buildTelemetryBentoGrid({
    required int totalPrescriptions,
    required int totalPatients,
    required int totalHospitals,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);

        final items = [
          _telemetryCard(
            title: 'Consultations Today',
            value: '18 Patients',
            change: '+12.5% vs last week',
            isPositive: true,
            icon: Icons.people_alt_rounded,
            accentColor: const Color(0xFF1244A2),
          ),
          _telemetryCard(
            title: 'Active e-Prescriptions',
            value: '$totalPrescriptions Issued',
            change: '100% Synced to Pharmacy',
            isPositive: true,
            icon: Icons.receipt_long_rounded,
            accentColor: const Color(0xFF10B981),
          ),
          _telemetryCard(
            title: 'Patient Regimen Adherence',
            value: '96.4% PDC',
            change: '+3.2% Optimal Range',
            isPositive: true,
            icon: Icons.insights_rounded,
            accentColor: const Color(0xFF8B5CF6),
          ),
          _telemetryCard(
            title: 'Prior Auth Friction',
            value: '2 Pending Review',
            change: '0 Drug Interactions',
            isPositive: true,
            icon: Icons.security_rounded,
            accentColor: const Color(0xFFF59E0B),
          ),
        ];

        if (crossAxisCount == 4) {
          return Row(
            children: items
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        } else if (crossAxisCount == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 10),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: 10),
                  Expanded(child: items[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: items
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _telemetryCard({
    required String title,
    required String value,
    required String change,
    required bool isPositive,
    required IconData icon,
    required Color accentColor,
  }) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: AppFonts.googleSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppFonts.googleSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppFonts.googleSans(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 3. CHART 1: DOCTOR PRESCRIBED VS ALTERNATIVE TABLETS (HIGHLY INTERACTIVE)
  // =========================================================================
  Widget _buildTabletComparisonChartSection() {
    final activeTablet = _tabletFilters[_selectedTabletFilterIndex];
    final chartData = _getTabletChartData(_selectedTabletFilterIndex, _tabletChartTimeRangeIndex);

    return BentoCard(
      title: 'Doctor Prescriptions vs. Alternative Tablet Dispensed',
      subtitle: 'Comparative telemetry on doctor brand prescriptions & pharmacy generic substitutions',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1244A2), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.medication_liquid_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tabletTimeframeChip('7D', 0),
          const SizedBox(width: 4),
          _tabletTimeframeChip('30D', 1),
          const SizedBox(width: 4),
          _tabletTimeframeChip('90D', 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tablet List Filter Chips Carousel
          _buildTabletFilterSelector(),

          const SizedBox(height: 16),

          // 2. Dynamic 4-KPI Live Stat Strip (With animated counters)
          _buildTabletSummaryKpis(chartData, activeTablet),

          const SizedBox(height: 18),

          // 3. Animated Dual-Bar Chart Canvas with Clickable Highlight & Tooltips
          AnimatedBuilder(
            animation: _tabletChartAnim,
            builder: (context, child) {
              final animVal = _tabletChartAnim.value;
              return SizedBox(
                height: 270,
                child: _buildTabletBarChartCanvas(chartData, activeTablet, animVal),
              );
            },
          ),

          const SizedBox(height: 14),

          // 4. Interactive Legend Strip (Clickable to toggle series visibility)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _interactiveSeriesLegendToggle(
                color: const Color(0xFF2563EB),
                label: 'Prescribed by Doctor',
                sublabel: activeTablet.originalBrand,
                isActive: _showPrescribedSeries,
                onTap: () {
                  setState(() {
                    _showPrescribedSeries = !_showPrescribedSeries;
                    if (!_showPrescribedSeries && !_showAlternativeSeries) {
                      _showAlternativeSeries = true;
                    }
                  });
                },
              ),
              const SizedBox(width: 20),
              _interactiveSeriesLegendToggle(
                color: const Color(0xFF10B981),
                label: 'Alternative Dispensed',
                sublabel: activeTablet.alternativeGeneric,
                isActive: _showAlternativeSeries,
                onTap: () {
                  setState(() {
                    _showAlternativeSeries = !_showAlternativeSeries;
                    if (!_showPrescribedSeries && !_showAlternativeSeries) {
                      _showPrescribedSeries = true;
                    }
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5. Selected Tablet Clinical Bioequivalence & Equivalence Details Card
          _buildTabletDetailsFooter(activeTablet, chartData),
        ],
      ),
    );
  }

  Widget _tabletTimeframeChip(String label, int index) {
    final isSelected = _tabletChartTimeRangeIndex == index;
    return GestureDetector(
      onTap: () => _onTabletTimeframeSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1244A2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1244A2) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: AppFonts.googleSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletFilterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.filter_alt_rounded, size: 14, color: Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              'Select Tablet Formulary Filter:',
              style: AppFonts.googleSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(_tabletFilters.length, (index) {
              final tablet = _tabletFilters[index];
              final isSelected = _selectedTabletFilterIndex == index;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => _onTabletFilterSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? tablet.badgeColor.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? tablet.badgeColor : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tablet.icon,
                          size: 14,
                          color: isSelected ? tablet.badgeColor : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tablet.name,
                          style: AppFonts.googleSans(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? tablet.badgeColor : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // --- Dynamic 4-KPI Live Stat Strip with Animated Number Transitions ---
  Widget _buildTabletSummaryKpis(_TabletChartData data, _TabletFilterItem tablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        final cards = [
          _buildAnimatedTabletMetricCard(
            label: 'Doctor Prescribed',
            targetValue: data.totalDoctorPrescribed.toDouble(),
            formatPrefix: '',
            formatSuffix: '',
            unit: 'Rx Units',
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFF2563EB),
            trend: tablet.originalBrand,
          ),
          _buildAnimatedTabletMetricCard(
            label: 'Alternative Dispensed',
            targetValue: data.totalAlternativeDispensed.toDouble(),
            formatPrefix: '',
            formatSuffix: '',
            unit: 'Substituted',
            icon: Icons.change_circle_rounded,
            color: const Color(0xFF10B981),
            trend: tablet.alternativeGeneric,
          ),
          _buildTabletMetricCardStatic(
            label: 'Substitution Rate',
            value: data.substitutionRate,
            unit: 'Adoption',
            icon: Icons.percent_rounded,
            color: const Color(0xFF8B5CF6),
            trend: 'FDA Bioequivalent',
          ),
          _buildTabletMetricCardStatic(
            label: 'Patient Copay Savings',
            value: data.totalSavings,
            unit: 'Saved',
            icon: Icons.savings_rounded,
            color: const Color(0xFFF59E0B),
            trend: 'Est. Benefit',
          ),
        ];

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildAnimatedTabletMetricCard({
    required String label,
    required double targetValue,
    required String formatPrefix,
    required String formatSuffix,
    required String unit,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Flexible(
                child: Text(
                  trend,
                  style: AppFonts.googleSans(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetValue),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$formatPrefix${_formatNumber(val.round())}$formatSuffix',
                    style: AppFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: AppFonts.googleSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppFonts.googleSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabletMetricCardStatic({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              Flexible(
                child: Text(
                  trend,
                  style: AppFonts.googleSans(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppFonts.googleSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppFonts.googleSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: AppFonts.googleSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- Animated Dual-Bar Chart Canvas with Click Selection & Tooltips ---
  Widget _buildTabletBarChartCanvas(
    _TabletChartData data,
    _TabletFilterItem tablet,
    double animVal,
  ) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: Color(0xFFF1F5F9),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final step = data.maxY > 300
                    ? 300
                    : (data.maxY > 80 ? 50 : (data.maxY > 30 ? 10 : 5));
                if (value % step == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: AppFonts.googleSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < data.xLabels.length) {
                  final isSelected = _selectedBarGroupIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data.xLabels[idx],
                      style: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                        color: isSelected ? const Color(0xFF1244A2) : const Color(0xFF475569),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
              setState(() {
                final clickedIdx = barTouchResponse.spot!.touchedBarGroupIndex;
                _selectedBarGroupIndex = (_selectedBarGroupIndex == clickedIdx) ? null : clickedIdx;
              });
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF0F172A),
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = data.xLabels[group.x.toInt()];
              final prescribed = data.doctorPrescribedValues[group.x.toInt()].toInt();
              final alt = data.alternativeDispensedValues[group.x.toInt()].toInt();
              final rate = ((alt / (prescribed == 0 ? 1 : prescribed)) * 100).toStringAsFixed(1);
              final saving = data.savingsByPeriod[group.x.toInt()];

              return BarTooltipItem(
                '$label • ${tablet.name}\n',
                AppFonts.googleSans(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: '🩺 Doctor Prescribed: $prescribed\n',
                    style: AppFonts.googleSans(
                      color: const Color(0xFF93C5FD),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '💊 Alternative Dispensed: $alt ($rate%)\n',
                    style: AppFonts.googleSans(
                      color: const Color(0xFF34D399),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '💰 Est. Patient Savings: $saving',
                    style: AppFonts.googleSans(
                      color: const Color(0xFFFBBF24),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        barGroups: List.generate(data.xLabels.length, (i) {
          final barWidth = data.xLabels.length > 5 ? 13.0 : 19.0;
          final isGroupSelected = _selectedBarGroupIndex == i;

          final prescribedVal = _showPrescribedSeries ? (data.doctorPrescribedValues[i] * animVal) : 0.0;
          final altVal = _showAlternativeSeries ? (data.alternativeDispensedValues[i] * animVal) : 0.0;

          return BarChartGroupData(
            x: i,
            barsSpace: 6,
            showingTooltipIndicators: isGroupSelected ? [0, 1] : [],
            barRods: [
              // Bar 1: Prescribed by Doctor (Royal Blue Gradient)
              BarChartRodData(
                toY: prescribedVal,
                width: isGroupSelected ? (barWidth + 3) : barWidth,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: isGroupSelected
                      ? [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)]
                      : [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              // Bar 2: Alternative Tablet Dispensed (Emerald Mint Gradient)
              BarChartRodData(
                toY: altVal,
                width: isGroupSelected ? (barWidth + 3) : barWidth,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                gradient: LinearGradient(
                  colors: isGroupSelected
                      ? [const Color(0xFF059669), const Color(0xFF34D399)]
                      : [const Color(0xFF047857), const Color(0xFF10B981)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // --- Interactive Series Toggle Legend ---
  Widget _interactiveSeriesLegendToggle({
    required Color color,
    required String label,
    required String sublabel,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isActive ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppFonts.googleSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    sublabel,
                    style: AppFonts.googleSans(
                      fontSize: 9.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletDetailsFooter(_TabletFilterItem tablet, _TabletChartData data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tablet.badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tablet.icon, color: tablet.badgeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${tablet.drugClass} • ${tablet.fhirCode}',
                  style: AppFonts.googleSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: tablet.badgeColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Brand: ${tablet.originalBrand} ➔ Bioequivalent Generic: ${tablet.alternativeGeneric}',
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${data.substitutionRate} Substituted',
              style: AppFonts.googleSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. CHART 2: WEEKLY PATIENT CONSULTATIONS & E-RX VELOCITY (ANIMATED AREA)
  // =========================================================================
  Widget _buildPatientVolumeLineChart() {
    final timeRange = _consultationTimeRangeIndex; // 0: 7D, 1: 30D, 2: 90D

    List<String> labels;
    List<double> consultSpots;
    List<double> erxSpots;
    double maxY;

    if (timeRange == 0) {
      // 7 Days
      labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      consultSpots = [14, 19, 16, 24, 22, 12, 18];
      erxSpots = [10, 15, 12, 20, 18, 8, 15];
      maxY = 30;
    } else if (timeRange == 1) {
      // 30 Days (Weeks)
      labels = ['Wk 1', 'Wk 2', 'Wk 3', 'Wk 4'];
      consultSpots = [98, 124, 115, 142];
      erxSpots = [78, 102, 94, 118];
      maxY = 160;
    } else {
      // 90 Days (Months)
      labels = ['June', 'July', 'August'];
      consultSpots = [420, 485, 530];
      erxSpots = [345, 410, 460];
      maxY = 600;
    }

    return BentoCard(
      title: 'Weekly Patient Consultations & e-Rx Velocity',
      subtitle: 'Live volume trends, clinic consultations & digital transmission flow',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1244A2).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.show_chart_rounded, color: Color(0xFF1244A2), size: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _consultationTimeframeChip('7D', 0),
          const SizedBox(width: 4),
          _consultationTimeframeChip('30D', 1),
          const SizedBox(width: 4),
          _consultationTimeframeChip('90D', 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 14),
          AnimatedBuilder(
            animation: _lineChartAnim,
            builder: (context, child) {
              final anim = _lineChartAnim.value;

              return SizedBox(
                height: 230,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => const FlLine(
                        color: Color(0xFFF1F5F9),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            final step = maxY > 300 ? 150 : (maxY > 100 ? 40 : 10);
                            if (value % step == 0) {
                              return Text(
                                value.toInt().toString(),
                                style: AppFonts.googleSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < labels.length) {
                              final isSelected = _selectedLinePointIndex == idx;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  labels[idx],
                                  style: AppFonts.googleSans(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF1244A2) : const Color(0xFF64748B),
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (labels.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent && response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
                          setState(() {
                            final idx = response.lineBarSpots!.first.spotIndex;
                            _selectedLinePointIndex = (_selectedLinePointIndex == idx) ? null : idx;
                          });
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF0F172A),
                        tooltipRoundedRadius: 12,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final idx = spot.spotIndex;
                            final day = labels[idx];
                            final isConsult = spot.barIndex == 0;
                            final color = isConsult ? const Color(0xFF93C5FD) : const Color(0xFF34D399);
                            final labelText = isConsult ? 'Consultations' : 'e-Prescriptions';

                            return LineTooltipItem(
                              '$day • $labelText: ${spot.y.toInt()}',
                              AppFonts.googleSans(
                                color: color,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      // Series 1: Patient Consultations
                      if (_showConsultationsSeries)
                        LineChartBarData(
                          spots: List.generate(labels.length, (i) => FlSpot(i.toDouble(), consultSpots[i] * anim)),
                          isCurved: true,
                          color: const Color(0xFF1244A2),
                          barWidth: 3.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final isSelected = _selectedLinePointIndex == index;
                              return FlDotCirclePainter(
                                radius: isSelected ? 6 : 4,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1244A2),
                                strokeWidth: isSelected ? 3 : 1.5,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1244A2).withValues(alpha: 0.2),
                                const Color(0xFF1244A2).withValues(alpha: 0.02),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                      // Series 2: e-Prescriptions Broadcast
                      if (_showEprescriptionsSeries)
                        LineChartBarData(
                          spots: List.generate(labels.length, (i) => FlSpot(i.toDouble(), erxSpots[i] * anim)),
                          isCurved: true,
                          color: const Color(0xFF10B981),
                          barWidth: 2.8,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final isSelected = _selectedLinePointIndex == index;
                              return FlDotCirclePainter(
                                radius: isSelected ? 5.5 : 3.5,
                                color: isSelected ? const Color(0xFF059669) : const Color(0xFF10B981),
                                strokeWidth: isSelected ? 2.5 : 1,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF10B981).withValues(alpha: 0.15),
                                const Color(0xFF10B981).withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Interactive Legend with Series Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _interactiveLineLegend(
                color: const Color(0xFF1244A2),
                label: 'Patient Consultations',
                isActive: _showConsultationsSeries,
                onTap: () {
                  setState(() {
                    _showConsultationsSeries = !_showConsultationsSeries;
                    if (!_showConsultationsSeries && !_showEprescriptionsSeries) {
                      _showEprescriptionsSeries = true;
                    }
                  });
                },
              ),
              const SizedBox(width: 24),
              _interactiveLineLegend(
                color: const Color(0xFF10B981),
                label: 'e-Prescriptions Broadcast',
                isActive: _showEprescriptionsSeries,
                onTap: () {
                  setState(() {
                    _showEprescriptionsSeries = !_showEprescriptionsSeries;
                    if (!_showConsultationsSeries && !_showEprescriptionsSeries) {
                      _showConsultationsSeries = true;
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _consultationTimeframeChip(String label, int index) {
    final isSelected = _consultationTimeRangeIndex == index;
    return GestureDetector(
      onTap: () => _onConsultationTimeframeSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1244A2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1244A2) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: AppFonts.googleSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _interactiveLineLegend({
    required Color color,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isActive ? 1.0 : 0.35,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.googleSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 5. CHART 3: PRESCRIBED THERAPEUTIC CLASSES (INTERACTIVE DONUT WITH CENTER)
  // =========================================================================
  Widget _buildDrugClassDistributionChart() {
    final selectedClass = (_selectedDonutIndex >= 0 && _selectedDonutIndex < _therapeuticClasses.length)
        ? _therapeuticClasses[_selectedDonutIndex]
        : null;

    return BentoCard(
      title: 'Prescribed Therapeutic Classes',
      subtitle: 'Distribution of active clinical regimens across dataset',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.pie_chart_rounded, color: Color(0xFF8B5CF6), size: 18),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated PieChart Donut
                AnimatedBuilder(
                  animation: _donutChartAnim,
                  builder: (context, child) {
                    final anim = _donutChartAnim.value;

                    return PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            if (event is FlTapUpEvent && pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                              setState(() {
                                final idx = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                _selectedDonutIndex = (_selectedDonutIndex == idx) ? -1 : idx;
                              });
                            }
                          },
                        ),
                        sections: List.generate(_therapeuticClasses.length, (i) {
                          final item = _therapeuticClasses[i];
                          final isSelected = _selectedDonutIndex == i;
                          final radius = isSelected ? 52.0 : 44.0;

                          return PieChartSectionData(
                            color: item.color,
                            value: item.percentage * anim,
                            title: '${item.percentage.toInt()}%',
                            radius: radius,
                            titleStyle: AppFonts.googleSans(
                              fontSize: isSelected ? 12 : 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                            borderSide: isSelected
                                ? const BorderSide(color: Colors.white, width: 2.5)
                                : BorderSide.none,
                          );
                        }),
                      ),
                    );
                  },
                ),

                // Center Dynamic Readout Container
                GestureDetector(
                  onTap: () => setState(() => _selectedDonutIndex = -1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedClass != null ? selectedClass.name : 'Portfolio',
                        style: AppFonts.googleSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: selectedClass != null ? selectedClass.color : const Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        selectedClass != null
                            ? '${_formatNumber(selectedClass.prescriptionCount)} Rx'
                            : '50,000 Rx',
                        style: AppFonts.googleSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        selectedClass != null ? '${selectedClass.percentage.toInt()}% Share' : '100% Total',
                        style: AppFonts.googleSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Interactive Clickable Legend Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(_therapeuticClasses.length, (i) {
              final item = _therapeuticClasses[i];
              final isSelected = _selectedDonutIndex == i;

              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedDonutIndex = (_selectedDonutIndex == i) ? -1 : i;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? item.color.withValues(alpha: 0.12) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? item.color : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: item.color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item.name} (${item.percentage.toInt()}%)',
                        style: AppFonts.googleSans(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? item.color : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 6. TODAY'S PATIENT QUEUE
  // =========================================================================
  Widget _buildTodaysPatientQueue(AppState appState) {
    final patients = appState.patientRecords;

    return BentoCard(
      title: "Today's Patient Consultations Queue",
      subtitle: 'Registered clinical appointments & diagnosis logs',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person_search_rounded, color: Color(0xFF10B981), size: 18),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (patients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No registered patient consultations scheduled.',
                style: AppFonts.googleSans(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patients.length.clamp(0, 4),
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) {
                final p = patients[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1244A2).withValues(alpha: 0.1),
                    child: Text(
                      p.name.isNotEmpty ? p.name[0] : 'P',
                      style: AppFonts.googleSans(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1244A2),
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: AppFonts.googleSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Age: ${p.age} • ${p.currentProblem}',
                    style: AppFonts.googleSans(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: index == 0 ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      index == 0 ? 'Ready for e-Rx' : 'In Consultation',
                      style: AppFonts.googleSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: index == 0 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. DATA MATRIX & CALCULATIONS
  // =========================================================================
  _TabletChartData _getTabletChartData(int tabletIndex, int timeRangeIndex) {
    if (timeRangeIndex == 0) {
      // 7 Days
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      switch (tabletIndex) {
        case 1:
          return _calculateChartData(
            labels: labels,
            prescribed: [28.0, 32.0, 29.0, 35.0, 31.0, 18.0, 24.0],
            alternative: [24.0, 28.0, 26.0, 32.0, 28.0, 15.0, 21.0],
            unitSavings: 40,
            maxY: 45,
          );
        case 2:
          return _calculateChartData(
            labels: labels,
            prescribed: [34.0, 38.0, 35.0, 42.0, 39.0, 22.0, 30.0],
            alternative: [30.0, 34.0, 31.0, 38.0, 35.0, 19.0, 27.0],
            unitSavings: 20,
            maxY: 50,
          );
        case 3:
          return _calculateChartData(
            labels: labels,
            prescribed: [22.0, 25.0, 24.0, 29.0, 27.0, 15.0, 20.0],
            alternative: [19.0, 22.0, 21.0, 26.0, 24.0, 13.0, 18.0],
            unitSavings: 30,
            maxY: 35,
          );
        case 4:
          return _calculateChartData(
            labels: labels,
            prescribed: [18.0, 21.0, 19.0, 24.0, 22.0, 12.0, 16.0],
            alternative: [15.0, 18.0, 16.0, 21.0, 19.0, 10.0, 14.0],
            unitSavings: 55,
            maxY: 30,
          );
        case 5:
          return _calculateChartData(
            labels: labels,
            prescribed: [16.0, 19.0, 17.0, 22.0, 20.0, 11.0, 15.0],
            alternative: [13.0, 16.0, 14.0, 19.0, 17.0, 9.0, 13.0],
            unitSavings: 30,
            maxY: 28,
          );
        case 6:
          return _calculateChartData(
            labels: labels,
            prescribed: [14.0, 16.0, 15.0, 19.0, 17.0, 10.0, 13.0],
            alternative: [11.0, 13.0, 12.0, 16.0, 14.0, 8.0, 11.0],
            unitSavings: 40,
            maxY: 25,
          );
        case 7:
          return _calculateChartData(
            labels: labels,
            prescribed: [12.0, 14.0, 13.0, 17.0, 15.0, 8.0, 11.0],
            alternative: [10.0, 12.0, 11.0, 14.0, 13.0, 7.0, 9.0],
            unitSavings: 30,
            maxY: 22,
          );
        case 0:
        default:
          return _calculateChartData(
            labels: labels,
            prescribed: [88.0, 96.0, 92.0, 110.0, 102.0, 58.0, 78.0],
            alternative: [74.0, 82.0, 79.0, 95.0, 88.0, 50.0, 68.0],
            unitSavings: 40,
            maxY: 130,
          );
      }
    } else if (timeRangeIndex == 1) {
      // 30 Days (Weeks)
      const labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      switch (tabletIndex) {
        case 1:
          return _calculateChartData(
            labels: labels,
            prescribed: [115.0, 128.0, 122.0, 138.0],
            alternative: [102.0, 114.0, 109.0, 125.0],
            unitSavings: 40,
            maxY: 160,
          );
        case 2:
          return _calculateChartData(
            labels: labels,
            prescribed: [135.0, 148.0, 142.0, 158.0],
            alternative: [120.0, 133.0, 128.0, 144.0],
            unitSavings: 20,
            maxY: 180,
          );
        case 3:
          return _calculateChartData(
            labels: labels,
            prescribed: [95.0, 108.0, 102.0, 118.0],
            alternative: [82.0, 94.0, 89.0, 105.0],
            unitSavings: 30,
            maxY: 140,
          );
        case 4:
          return _calculateChartData(
            labels: labels,
            prescribed: [78.0, 88.0, 84.0, 96.0],
            alternative: [66.0, 76.0, 72.0, 84.0],
            unitSavings: 55,
            maxY: 120,
          );
        case 5:
          return _calculateChartData(
            labels: labels,
            prescribed: [72.0, 82.0, 78.0, 90.0],
            alternative: [60.0, 70.0, 66.0, 78.0],
            unitSavings: 30,
            maxY: 110,
          );
        case 6:
          return _calculateChartData(
            labels: labels,
            prescribed: [64.0, 72.0, 68.0, 78.0],
            alternative: [53.0, 61.0, 57.0, 67.0],
            unitSavings: 40,
            maxY: 100,
          );
        case 7:
          return _calculateChartData(
            labels: labels,
            prescribed: [55.0, 62.0, 58.0, 68.0],
            alternative: [45.0, 52.0, 48.0, 58.0],
            unitSavings: 30,
            maxY: 90,
          );
        case 0:
        default:
          return _calculateChartData(
            labels: labels,
            prescribed: [365.0, 395.0, 380.0, 425.0],
            alternative: [312.0, 342.0, 328.0, 372.0],
            unitSavings: 40,
            maxY: 500,
          );
      }
    }

    // 90 Days (3 Months View)
    const labels = ['June', 'July', 'August'];
    switch (tabletIndex) {
      case 1:
        return _calculateChartData(
          labels: labels,
          prescribed: [340.0, 385.0, 420.0],
          alternative: [305.0, 348.0, 382.0],
          unitSavings: 40,
          maxY: 500,
        );
      case 2:
        return _calculateChartData(
          labels: labels,
          prescribed: [390.0, 430.0, 475.0],
          alternative: [350.0, 392.0, 435.0],
          unitSavings: 20,
          maxY: 560,
        );
      case 3:
        return _calculateChartData(
          labels: labels,
          prescribed: [290.0, 325.0, 360.0],
          alternative: [255.0, 288.0, 320.0],
          unitSavings: 30,
          maxY: 430,
        );
      case 4:
        return _calculateChartData(
          labels: labels,
          prescribed: [245.0, 278.0, 310.0],
          alternative: [212.0, 242.0, 272.0],
          unitSavings: 55,
          maxY: 370,
        );
      case 5:
        return _calculateChartData(
          labels: labels,
          prescribed: [220.0, 248.0, 275.0],
          alternative: [188.0, 215.0, 242.0],
          unitSavings: 30,
          maxY: 330,
        );
      case 6:
        return _calculateChartData(
          labels: labels,
          prescribed: [195.0, 220.0, 245.0],
          alternative: [165.0, 188.0, 212.0],
          unitSavings: 40,
          maxY: 300,
        );
      case 7:
        return _calculateChartData(
          labels: labels,
          prescribed: [170.0, 192.0, 215.0],
          alternative: [142.0, 162.0, 185.0],
          unitSavings: 30,
          maxY: 260,
        );
      case 0:
      default:
        return _calculateChartData(
          labels: labels,
          prescribed: [1120.0, 1250.0, 1380.0],
          alternative: [965.0, 1080.0, 1195.0],
          unitSavings: 40,
          maxY: 1600,
        );
    }
  }

  _TabletChartData _calculateChartData({
    required List<String> labels,
    required List<double> prescribed,
    required List<double> alternative,
    required int unitSavings,
    required double maxY,
  }) {
    int totalPrescribed = 0;
    int totalAlt = 0;
    List<String> savingsByPeriod = [];

    for (int i = 0; i < labels.length; i++) {
      final p = prescribed[i].toInt();
      final a = alternative[i].toInt();
      totalPrescribed += p;
      totalAlt += a;
      final saving = a * unitSavings;
      savingsByPeriod.add('\$${_formatNumber(saving)}');
    }

    final double rate = totalPrescribed == 0 ? 0 : (totalAlt / totalPrescribed) * 100;
    final int grandSaving = totalAlt * unitSavings;

    return _TabletChartData(
      xLabels: labels,
      doctorPrescribedValues: prescribed,
      alternativeDispensedValues: alternative,
      savingsByPeriod: savingsByPeriod,
      totalDoctorPrescribed: totalPrescribed,
      totalAlternativeDispensed: totalAlt,
      substitutionRate: '${rate.toStringAsFixed(1)}%',
      totalSavings: '\$${_formatNumber(grandSaving)}',
      maxY: maxY,
    );
  }

  String _formatNumber(int n) {
    return n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
