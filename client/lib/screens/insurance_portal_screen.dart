import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class InsurancePortalScreen extends StatefulWidget {
  const InsurancePortalScreen({super.key});

  @override
  State<InsurancePortalScreen> createState() => _InsurancePortalScreenState();
}

class _InsurancePortalScreenState extends State<InsurancePortalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Map<String, List<String>> _companyPlansMap = {
    'Blue Cross Blue Shield': [
      'Blue Cross PPO Premier',
      'Blue Cross Advantage Plus',
      'Blue Cross Rx Comprehensive',
      'Blue Care HMO Gold',
    ],
    'UnitedHealthcare (UHC)': [
      'UHC Choice Plus Comprehensive',
      'UHC Medicare Part D Standard',
      'UHC Dual Complete (HMO-POS)',
      'Optum Rx Preferred',
    ],
    'Medicare Part D (CMS)': [
      'SilverScript Choice (PDP)',
      'Medicare Advantage Part D Gold',
      'WellCare Value Script (PDP)',
      'Humana Premier Rx (PDP)',
    ],
    'Aetna Health': [
      'Aetna Medicare Part D Value',
      'Aetna Open Access PPO',
      'Aetna Premier Rx Tier 1-5',
    ],
    'Cigna Healthcare': [
      'Cigna Secure Rx (PDP)',
      'Cigna Total Care Plus',
      'Cigna Essential Rx Plan',
    ],
    'Humana Rx': [
      'Humana Walmart Value Rx',
      'Humana Gold Plus (HMO)',
      'Humana Premier Part D',
    ],
    'Kaiser Permanente': [
      'Kaiser Senior Advantage',
      'Kaiser Permanente Deductible Plan',
      'Kaiser Specialty Rx',
    ],
  };

  static const List<String> _availableMedicinesList = [
    'Atorvastatin (Lipitor) 20mg',
    'Metformin HCl 500mg',
    'Lisinopril 10mg',
    'Ozempic (Semaglutide) 2mg/3mL',
    'Eliquis (Apixaban) 5mg',
    'Levothyroxine 50mcg',
    'Amlodipine Besylate 5mg',
    'Omeprazole 20mg',
    'Losartan Potassium 50mg',
    'Jardiance (Empagliflozin) 10mg',
    'Gabapentin 300mg',
    'Hydrochlorothiazide 25mg',
    'Montelukast Sodium 10mg',
    'Rosuvastatin (Crestor) 10mg',
    'Pantoprazole Sodium 40mg',
    'Duloxetine (Cymbalta) 30mg',
    'Sertraline HCl 50mg',
  ];

  static const List<String> _availableHospitalsList = [
    'MetroHealth Medical Center (Cleveland, OH)',
    'St. Jude Memorial Hospital (Fullerton, CA)',
    'Johns Hopkins Hospital (Baltimore, MD)',
    'Cleveland Clinic Main Campus (Cleveland, OH)',
    'Duke University Hospital (Durham, NC)',
    'Mayo Clinic Hospital (Rochester, MN)',
    'Massachusetts General Hospital (Boston, MA)',
    'Northwestern Memorial Hospital (Chicago, IL)',
    'Mount Sinai Hospital (New York, NY)',
    'Stanford Health Care (Stanford, CA)',
  ];

  String? _selectedCompany;
  final Set<String> _selectedPlans = {};
  final Set<String> _selectedMedicines = {};
  final Set<String> _selectedHospitals = {};
  bool _isInitialized = false;
  bool _isSaving = false;

  // Search & Filter States
  String _formularySearchQuery = '';
  int _selectedTierFilter = 0; // 0 = All Tiers, 1-5
  String _paSearchQuery = '';
  String _paFilterStatus = 'all'; // all, blocked, inReview, resolved
  String _hospitalSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initFromAppState(AppState appState) {
    if (_isInitialized) return;
    _isInitialized = true;

    final user = appState.currentUser;
    _selectedCompany = (user.insuranceCompany != null && user.insuranceCompany!.isNotEmpty)
        ? user.insuranceCompany!
        : 'Blue Cross Blue Shield';

    if (user.insurancePlans.isNotEmpty) {
      _selectedPlans.addAll(user.insurancePlans);
    } else {
      _selectedPlans.addAll(_companyPlansMap[_selectedCompany]?.take(2) ?? ['Blue Cross PPO Premier']);
    }

    if (user.insuranceMedicines.isNotEmpty) {
      _selectedMedicines.addAll(user.insuranceMedicines);
    } else {
      _selectedMedicines.addAll([
        'Atorvastatin (Lipitor) 20mg',
        'Metformin HCl 500mg',
        'Eliquis (Apixaban) 5mg',
        'Lisinopril 10mg',
        'Amlodipine Besylate 5mg',
      ]);
    }

    if (user.insuranceHospitals.isNotEmpty) {
      _selectedHospitals.addAll(user.insuranceHospitals);
    } else {
      _selectedHospitals.addAll([
        'MetroHealth Medical Center (Cleveland, OH)',
        'Cleveland Clinic Main Campus (Cleveland, OH)',
        'Johns Hopkins Hospital (Baltimore, MD)',
      ]);
    }
  }

  Future<void> _handleSaveConfiguration(AppState appState) async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 350));

    final company = _selectedCompany ?? 'Blue Cross Blue Shield';
    final plans = _selectedPlans.isNotEmpty
        ? _selectedPlans.toList()
        : (_companyPlansMap[company]?.take(1).toList() ?? ['Standard Benefit Plan']);

    await appState.updateInsuranceAgentDetails(
      company: company,
      plans: plans,
      medicines: _selectedMedicines.toList(),
      hospitals: _selectedHospitals.toList(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Formulary, Benefit Plans, and In-Network Hospital settings updated successfully!',
                  style: AppFonts.googleSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showResolvePADialog(BuildContext context, PAFrictionEvent event, AppState appState) {
    final noteController = TextEditingController(
      text: 'Prior authorization exception verified against ${event.drugName} formulary guidelines. Clinical necessity established.',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.verified_rounded, color: Color(0xFF047857), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prior Authorization Decision',
                    style: AppFonts.googleSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Case ID: ${event.id} • ${event.patientName}',
                    style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildDialogRow('Prescribed Drug:', event.drugName, isBold: true),
                      const SizedBox(height: 6),
                      _buildDialogRow('Friction Reason:', event.barrierType == BarrierType.paRequired
                          ? 'Prior Authorization Mandatory'
                          : (event.barrierType == BarrierType.stepTherapyFailed
                              ? 'Step Therapy Protocol Required'
                              : 'Quantity Limit Exceeded')),
                      const SizedBox(height: 6),
                      _buildDialogRow('Est. Annual Cost Impact:', '\$${event.estAnnualSavings.toStringAsFixed(0)}', color: const Color(0xFF047857)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Clinical Approval & Adjudication Notes',
                  style: AppFonts.googleSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: AppFonts.googleSans(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Enter clinical justification...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: AppFonts.googleSans(color: AppColors.textMuted)),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              appState.updateFrictionStatus(event.id, FrictionStatus.appealed);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Claim case ${event.id} marked as Under Appeal / Clinical Review'),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            },
            child: Text('Require Appeal', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              appState.updateFrictionStatus(event.id, FrictionStatus.resolved);
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Prior authorization approved for ${event.patientName} (${event.drugName})'),
                  backgroundColor: const Color(0xFF047857),
                ),
              );
            },
            child: Text('Approve & Overturn', style: AppFonts.googleSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showComplianceReportModal(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_rounded, color: Color(0xFF1D4ED8), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CMS Part D Compliance Audit Report',
                    style: AppFonts.googleSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Generated on ${DateFormat.yMMMd().format(DateTime.now())} • Real-time Telemetry',
                    style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAuditMetricCard('Formulary Negative Change Notice Compliance', '100% (Compliant)', Icons.check_circle_rounded, const Color(0xFF10B981)),
              const SizedBox(height: 10),
              _buildAuditMetricCard('Prior Authorization Turnaround Time', '1.4 Hours (Standard: <24h)', Icons.timer_rounded, const Color(0xFF2563EB)),
              const SizedBox(height: 10),
              _buildAuditMetricCard('Medicare Star Rating Adherence Index', '4.85 / 5.0 Stars', Icons.star_rounded, const Color(0xFFF59E0B)),
              const SizedBox(height: 10),
              _buildAuditMetricCard('Generic Substitution Savings Yield', '\$${(appState.dataService.totalEstimatedAnnualSavingsOpportunity + 248500).toStringAsFixed(0)}', Icons.savings_rounded, const Color(0xFF10B981)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: AppFonts.googleSans(color: AppColors.textMuted)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.download_rounded, size: 16),
            label: Text('Export Official PDF Audit', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('CMS Part D Telemetry Audit exported successfully to Downloads folder.'),
                  backgroundColor: Color(0xFF0F172A),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppFonts.googleSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
            ),
          ),
          Text(
            value,
            style: AppFonts.googleSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted)),
        Text(
          value,
          style: AppFonts.googleSans(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    _initFromAppState(appState);

    final user = appState.currentUser;
    final plans = appState.dataService.plans;
    final drugs = appState.dataService.drugs;
    final paEvents = appState.dataService.paFrictionEvents;
    final hospitals = appState.dataService.hospitals;

    final resolvedPaCount = paEvents.where((e) => e.status == FrictionStatus.resolved).length;
    final pendingPaCount = paEvents.where((e) => e.status != FrictionStatus.resolved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner & Quick Actions
          BentoHeroBanner(
            title: 'Insurance Payer & Formulary Suite',
            subtitle: 'Real-time CMS Part D claims telemetry, automated prior authorization workflows, and multi-tier drug cost optimization.',
            icon: Icons.verified_user_rounded,
            statusLabel: 'CMS Certified Payer Network',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.assessment_rounded, size: 16),
                  label: Text(
                    'CMS Audit Report',
                    style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _showComplianceReportModal(context, appState),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 2. High-Density Executive Payer Metric HUD
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final isMedium = constraints.maxWidth >= 600;

              final metricTiles = [
                BentoMetricTile(
                  label: 'Covered Benefit Plans',
                  value: '${_selectedPlans.length} Active Plans',
                  trendText: '142.8k Enrolled Lives',
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: const Color(0xFF1D4ED8),
                  iconBgColor: const Color(0xFFEFF6FF),
                ),
                BentoMetricTile(
                  label: 'Formulary Drug Catalog',
                  value: '${_selectedMedicines.length} Covered Rx',
                  trendText: 'Tier 1-5 Tiered',
                  icon: Icons.medication_liquid_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFE0F2FE),
                ),
                BentoMetricTile(
                  label: 'Prior Auth Review Queue',
                  value: '$pendingPaCount Pending PA',
                  trendText: '$resolvedPaCount Resolved',
                  icon: Icons.fact_check_rounded,
                  iconColor: pendingPaCount > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
                  iconBgColor: pendingPaCount > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                ),
                BentoMetricTile(
                  label: 'Annual Cost Containment',
                  value: '\$${(appState.dataService.totalEstimatedAnnualSavingsOpportunity + 248500).toStringAsFixed(0)}',
                  trendText: '+16.8% YoY Yield',
                  icon: Icons.savings_rounded,
                  iconColor: const Color(0xFF047857),
                  iconBgColor: const Color(0xFFECFDF5),
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: metricTiles[0]),
                    const SizedBox(width: 12),
                    Expanded(child: metricTiles[1]),
                    const SizedBox(width: 12),
                    Expanded(child: metricTiles[2]),
                    const SizedBox(width: 12),
                    Expanded(child: metricTiles[3]),
                  ],
                );
              } else if (isMedium) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: metricTiles[0]),
                        const SizedBox(width: 12),
                        Expanded(child: metricTiles[1]),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: metricTiles[2]),
                        const SizedBox(width: 12),
                        Expanded(child: metricTiles[3]),
                      ],
                    ),
                  ],
                );
              } else {
                return Column(
                  children: metricTiles
                      .map((tile) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: tile,
                          ))
                      .toList(),
                );
              }
            },
          ),

          const SizedBox(height: 18),

          // 3. Multi-View Interactive Workspace Tabs
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.metallicBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentNavy.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppFonts.googleSans(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
              unselectedLabelStyle: AppFonts.googleSans(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.dashboard_customize_rounded, size: 16),
                  text: 'Overview & Telemetry',
                ),
                Tab(
                  icon: Icon(Icons.medication_rounded, size: 16),
                  text: 'Formulary Matrix',
                ),
                Tab(
                  icon: Icon(Icons.fact_check_rounded, size: 16),
                  text: 'Prior Auth Review',
                ),
                Tab(
                  icon: Icon(Icons.local_hospital_rounded, size: 16),
                  text: 'In-Network Hospitals',
                ),
                Tab(
                  icon: Icon(Icons.tune_rounded, size: 16),
                  text: 'Policy Manager',
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 4. Dynamic Tab View Content
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              switch (_tabController.index) {
                case 0:
                  return _buildOverviewTelemetryTab(appState, user, plans, paEvents, hospitals);
                case 1:
                  return _buildFormularyMatrixTab(appState, drugs);
                case 2:
                  return _buildPriorAuthQueueTab(appState, paEvents);
                case 3:
                  return _buildInNetworkHospitalsTab(appState, hospitals);
                case 4:
                  return _buildPolicyManagerTab(appState, user);
                default:
                  return _buildOverviewTelemetryTab(appState, user, plans, paEvents, hospitals);
              }
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW & REAL-TIME TELEMETRY
  // ==========================================
  Widget _buildOverviewTelemetryTab(
    AppState appState,
    User user,
    List<Plan> plans,
    List<PAFrictionEvent> paEvents,
    List<Hospital> hospitals,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carrier Banner with Live Badges
        BentoCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.business_center_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user.insuranceCompany != null && user.insuranceCompany!.isNotEmpty
                                  ? user.insuranceCompany!
                                  : (_selectedCompany ?? 'Blue Cross Blue Shield'),
                              style: AppFonts.googleSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
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
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live Telemetry',
                                    style: AppFonts.googleSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Authorized Specialist Account • ${user.name.isNotEmpty ? user.name : "Active Specialist"} • CMS Part D Tier 1-5 Compliance Active',
                          style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: Text(
                      'Configure Policy',
                      style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _tabController.animateTo(4),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // Active Benefit Plans Chips
              Text(
                'MANAGED BENEFIT PLANS (${_selectedPlans.length}):',
                style: AppFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedPlans.map((plan) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 6),
                        Text(
                          plan,
                          style: AppFonts.googleSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Visual Tier Distribution & Star Rating Breakdown Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

            final chartCard = BentoCard(
              title: 'Formulary Tier Distribution & Copay Model',
              subtitle: 'Relative proportion of prescription volume by cost-sharing tier',
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 60,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (group) => const Color(0xFF0F172A),
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final tierNames = ['Tier 1\nPref. Generic', 'Tier 2\nGeneric', 'Tier 3\nPref. Brand', 'Tier 4\nNon-Pref', 'Tier 5\nSpecialty'];
                              return BarTooltipItem(
                                '${tierNames[group.x]}\n${rod.toY.toInt()}% Volume',
                                AppFonts.googleSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget: (val, meta) => Text(
                                '${val.toInt()}%',
                                style: AppFonts.googleSans(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return Text('T1 Pref', style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700));
                                  case 1:
                                    return Text('T2 Gen', style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700));
                                  case 2:
                                    return Text('T3 Brand', style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700));
                                  case 3:
                                    return Text('T4 Non-P', style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700));
                                  case 4:
                                    return Text('T5 Spec', style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 15,
                          getDrawingHorizontalLine: (val) => FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 42, color: const Color(0xFF10B981), width: 22, borderRadius: BorderRadius.circular(6))]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 28, color: const Color(0xFF0284C7), width: 22, borderRadius: BorderRadius.circular(6))]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 18, color: const Color(0xFF3B82F6), width: 22, borderRadius: BorderRadius.circular(6))]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 8, color: const Color(0xFFF59E0B), width: 22, borderRadius: BorderRadius.circular(6))]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 4, color: const Color(0xFF8B5CF6), width: 22, borderRadius: BorderRadius.circular(6))]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTierLegend('T1: \$10', const Color(0xFF10B981)),
                      _buildTierLegend('T2: \$20', const Color(0xFF0284C7)),
                      _buildTierLegend('T3: \$45', const Color(0xFF3B82F6)),
                      _buildTierLegend('T4: \$90', const Color(0xFFF59E0B)),
                      _buildTierLegend('T5: 33%', const Color(0xFF8B5CF6)),
                    ],
                  ),
                ],
              ),
            );

            final starRatingCard = BentoCard(
              title: 'Medicare 5-Star Quality Scorecard',
              subtitle: 'CMS adherence standards and clinical quality measures',
              child: Column(
                children: [
                  _buildQualityProgressBar('Statin Therapy for Diabetes (SUPD)', 0.88, '88.4% (5 Stars)', const Color(0xFF10B981)),
                  const SizedBox(height: 14),
                  _buildQualityProgressBar('Medication Adherence for RAS Antagonists', 0.91, '91.0% (5 Stars)', const Color(0xFF10B981)),
                  const SizedBox(height: 14),
                  _buildQualityProgressBar('Generic Drug Dispensing Ratio', 0.89, '89.2% (4.5 Stars)', const Color(0xFF0284C7)),
                  const SizedBox(height: 14),
                  _buildQualityProgressBar('Prior Authorization SLA (<24h)', 0.98, '98.0% (5 Stars)', const Color(0xFF3B82F6)),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: chartCard),
                  const SizedBox(width: 14),
                  Expanded(flex: 4, child: starRatingCard),
                ],
              );
            } else {
              return Column(
                children: [
                  chartCard,
                  const SizedBox(height: 14),
                  starRatingCard,
                ],
              );
            }
          },
        ),

        const SizedBox(height: 18),

        // Live Prior Auth & Friction Quick Action Stream
        BentoCard(
          title: 'Live Prior Authorization & Claim Exceptions Stream',
          subtitle: 'Active member requests requiring medical review or step therapy verification',
          trailing: TextButton.icon(
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text('Full PA Desk', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
            onPressed: () => _tabController.animateTo(2),
          ),
          child: paEvents.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No active prior authorization exceptions.', style: AppFonts.googleSans(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paEvents.take(4).length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  itemBuilder: (context, index) {
                    final event = paEvents[index];
                    final isResolved = event.status == FrictionStatus.resolved;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isResolved ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                              color: isResolved ? const Color(0xFF047857) : const Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${event.patientName} • ${event.drugName}',
                                  style: AppFonts.googleSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.barrierType == BarrierType.paRequired
                                      ? 'Prior Authorization Required • Delayed ${event.daysDelayed}d'
                                      : 'Step Therapy Protocol • Est. \$${event.estAnnualSavings.toStringAsFixed(0)} Savings',
                                  style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (!isResolved)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () => _showResolvePADialog(context, event, appState),
                              child: Text('Review & Decide', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Approved',
                                style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF047857)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTierLegend(String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(text, style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildQualityProgressBar(String label, double value, String ratingText, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(label, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            ),
            Text(ratingText, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: FORMULARY MATRIX & COST EXPLORER
  // ==========================================
  Widget _buildFormularyMatrixTab(AppState appState, List<Drug> drugs) {
    final filteredDrugs = drugs.where((d) {
      if (_selectedTierFilter > 0 && d.tier != _selectedTierFilter) return false;
      if (_formularySearchQuery.isNotEmpty) {
        final query = _formularySearchQuery.toLowerCase();
        final match = d.name.toLowerCase().contains(query) ||
            d.drugClass.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_liquid_rounded, color: Color(0xFF1D4ED8), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interactive Formulary Drug Matrix & Coverage Rules',
                      style: AppFonts.googleSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse tiered prescription lines, copay brackets, and prior auth restrictions',
                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar & Tier Filter Chips
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _formularySearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by medication name or drug class...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1D4ED8), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tier Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTierFilterChip(0, 'All Tiers (${drugs.length})'),
                const SizedBox(width: 8),
                _buildTierFilterChip(1, 'Tier 1 - Pref Generic'),
                const SizedBox(width: 8),
                _buildTierFilterChip(2, 'Tier 2 - Generic'),
                const SizedBox(width: 8),
                _buildTierFilterChip(3, 'Tier 3 - Pref Brand'),
                const SizedBox(width: 8),
                _buildTierFilterChip(4, 'Tier 4 - Non-Preferred'),
                const SizedBox(width: 8),
                _buildTierFilterChip(5, 'Tier 5 - Specialty'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Drugs Table / List
          filteredDrugs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('No medications match your filter criteria.', style: AppFonts.googleSans(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDrugs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final drug = filteredDrugs[index];
                    final isCovered = _selectedMedicines.any((m) => m.toLowerCase().contains(drug.name.toLowerCase()));

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getTierColor(drug.tier).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _getTierColor(drug.tier).withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Tier ${drug.tier}',
                              style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: _getTierColor(drug.tier)),
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
                                      drug.name,
                                      style: AppFonts.googleSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      drug.tierLabel,
                                      style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Class: ${drug.drugClass} • Cost Share: \$${drug.costShare.toStringAsFixed(0)} • Est. Monthly: \$${drug.estMonthlyCost.toStringAsFixed(0)}',
                                  style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (drug.requiresPa)
                            Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'PA Req',
                                style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFB45309)),
                              ),
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isCovered ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                              backgroundColor: isCovered ? const Color(0xFFECFDF5) : Colors.white,
                              side: BorderSide(color: isCovered ? const Color(0xFF6EE7B7) : const Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: Icon(isCovered ? Icons.check_circle_rounded : Icons.add_rounded, size: 15),
                            label: Text(
                              isCovered ? 'Covered' : 'Add to Plan',
                              style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              setState(() {
                                final label = drug.name;
                                if (isCovered) {
                                  _selectedMedicines.removeWhere((m) => m.toLowerCase().contains(drug.name.toLowerCase()));
                                } else {
                                  _selectedMedicines.add(label);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildTierFilterChip(int tier, String label) {
    final isSelected = _selectedTierFilter == tier;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF1D4ED8),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: AppFonts.googleSans(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      onSelected: (_) => setState(() => _selectedTierFilter = tier),
    );
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 1:
        return const Color(0xFF10B981);
      case 2:
        return const Color(0xFF0284C7);
      case 3:
        return const Color(0xFF3B82F6);
      case 4:
        return const Color(0xFFF59E0B);
      case 5:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  // ==========================================
  // TAB 3: PRIOR AUTH REVIEW DESK
  // ==========================================
  Widget _buildPriorAuthQueueTab(AppState appState, List<PAFrictionEvent> paEvents) {
    final filteredEvents = paEvents.where((e) {
      if (_paFilterStatus == 'blocked' && e.status != FrictionStatus.blocked) return false;
      if (_paFilterStatus == 'inReview' && e.status != FrictionStatus.inReview && e.status != FrictionStatus.appealed) return false;
      if (_paFilterStatus == 'resolved' && e.status != FrictionStatus.resolved) return false;

      if (_paSearchQuery.isNotEmpty) {
        final q = _paSearchQuery.toLowerCase();
        final match = e.patientName.toLowerCase().contains(q) ||
            e.drugName.toLowerCase().contains(q) ||
            e.id.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fact_check_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prior Authorization & Exception Adjudication Desk',
                      style: AppFonts.googleSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Evaluate medical necessity criteria, step-therapy overrides, and fast-track approvals',
                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search & Filter
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _paSearchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search by case ID, patient name, or prescribed medication...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD97706), size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filter Tabs
          Row(
            children: [
              _buildPaFilterChip('all', 'All Cases (${paEvents.length})'),
              const SizedBox(width: 8),
              _buildPaFilterChip('blocked', 'Action Required'),
              const SizedBox(width: 8),
              _buildPaFilterChip('inReview', 'In Review / Appeal'),
              const SizedBox(width: 8),
              _buildPaFilterChip('resolved', 'Approved / Resolved'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          filteredEvents.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('No prior authorization cases match the selected filter.', style: AppFonts.googleSans(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    final isResolved = event.status == FrictionStatus.resolved;

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isResolved ? const Color(0xFFF8FAFC) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isResolved ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isResolved ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isResolved ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                              color: isResolved ? const Color(0xFF047857) : const Color(0xFFD97706),
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
                                      event.patientName,
                                      style: AppFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Case #${event.id}',
                                        style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1D4ED8)),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prescribed: ${event.drugName} • Barrier: ${event.barrierType == BarrierType.paRequired ? "Prior Auth Required" : "Step Therapy Protocol"}',
                                  style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Estimated Plan Cost Impact: \$${event.estAnnualSavings.toStringAsFixed(0)}/yr • Delayed: ${event.daysDelayed} Days',
                                  style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (!isResolved)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1D4ED8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              icon: const Icon(Icons.rule_folder_rounded, size: 16),
                              label: Text('Adjudicate', style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700)),
                              onPressed: () => _showResolvePADialog(context, event, appState),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF6EE7B7)),
                              ),
                              child: Text(
                                'Approved / Resolved',
                                style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF047857)),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPaFilterChip(String statusKey, String label) {
    final isSelected = _paFilterStatus == statusKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFD97706),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: AppFonts.googleSans(
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      onSelected: (_) => setState(() => _paFilterStatus = statusKey),
    );
  }

  // ==========================================
  // TAB 4: IN-NETWORK HOSPITALS DIRECTORY
  // ==========================================
  Widget _buildInNetworkHospitalsTab(AppState appState, List<Hospital> hospitals) {
    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF1D4ED8), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'In-Network Hospital & Care Facility Network',
                      style: AppFonts.googleSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Contracted medical centers, trauma facilities, and regional provider nodes',
                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Bar
          TextField(
            onChanged: (val) => setState(() => _hospitalSearchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search by hospital facility name or location...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1D4ED8), size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 14),

          // Hospital List Grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _availableHospitalsList.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final hosp = _availableHospitalsList[index];
              if (_hospitalSearchQuery.isNotEmpty && !hosp.toLowerCase().contains(_hospitalSearchQuery.toLowerCase())) {
                return const SizedBox.shrink();
              }
              final isInNetwork = _selectedHospitals.contains(hosp);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isInNetwork ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.apartment_rounded,
                        color: isInNetwork ? const Color(0xFF047857) : const Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hosp,
                            style: AppFonts.googleSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isInNetwork ? 'Tier 1 Preferred Facility • Direct e-Rx Electronic Link' : 'Out-of-Network Facility',
                            style: AppFonts.googleSans(
                              fontSize: 11.5,
                              color: isInNetwork ? const Color(0xFF047857) : AppColors.textMuted,
                              fontWeight: isInNetwork ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isInNetwork ? const Color(0xFF047857) : const Color(0xFF1D4ED8),
                        backgroundColor: isInNetwork ? const Color(0xFFECFDF5) : Colors.white,
                        side: BorderSide(color: isInNetwork ? const Color(0xFF6EE7B7) : const Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(isInNetwork ? Icons.check_circle_rounded : Icons.add_rounded, size: 16),
                      label: Text(
                        isInNetwork ? 'Contracted' : 'Add to Network',
                        style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        setState(() {
                          if (isInNetwork) {
                            _selectedHospitals.remove(hosp);
                          } else {
                            _selectedHospitals.add(hosp);
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: POLICY & FORMULARY MANAGER
  // ==========================================
  Widget _buildPolicyManagerTab(AppState appState, User user) {
    final availablePlansForCurrentCompany = _companyPlansMap[_selectedCompany] ?? _companyPlansMap['Blue Cross Blue Shield']!;

    return BentoCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formulary & In-Network Directory Configuration',
                      style: AppFonts.googleSans(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure covered medicines, contracted hospitals, and benefit plans managed by your payer account.',
                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 18),

          // 1. SELECT INSURANCE PAYER COMPANY
          Text(
            '1. SELECT INSURANCE PAYER COMPANY',
            style: AppFonts.googleSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCompany,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1D4ED8)),
                style: AppFonts.googleSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                items: _companyPlansMap.keys.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Row(
                      children: [
                        const Icon(Icons.business_rounded, size: 16, color: Color(0xFF1D4ED8)),
                        const SizedBox(width: 8),
                        Text(c),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCompany = val;
                      _selectedPlans.clear();
                      final defaults = _companyPlansMap[val];
                      if (defaults != null && defaults.isNotEmpty) {
                        _selectedPlans.addAll(defaults.take(2));
                      }
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 2. BENEFIT PLANS MANAGED
          Text(
            '2. BENEFIT PLANS MANAGED (${_selectedPlans.length} Selected)',
            style: AppFonts.googleSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(
                  'Select plan to toggle on/off...',
                  style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
                icon: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF1D4ED8), size: 18),
                items: availablePlansForCurrentCompany.map((plan) {
                  final isSelected = _selectedPlans.contains(plan);
                  return DropdownMenuItem<String>(
                    value: plan,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(plan, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                          size: 16,
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (_selectedPlans.contains(val)) {
                        _selectedPlans.remove(val);
                      } else {
                        _selectedPlans.add(val);
                      }
                    });
                  }
                },
              ),
            ),
          ),
          if (_selectedPlans.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedPlans.map((plan) {
                return Chip(
                  label: Text(plan),
                  backgroundColor: const Color(0xFFDBEAFE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                  ),
                  labelStyle: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E40AF),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF1E40AF)),
                  onDeleted: () => setState(() => _selectedPlans.remove(plan)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 18),

          // 3. COVERED MEDICINES
          Text(
            '3. COVERED MEDICINES (${_selectedMedicines.length} Selected)',
            style: AppFonts.googleSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(
                  'Select medicine to add to covered formulary...',
                  style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
                icon: const Icon(Icons.medication_rounded, color: Color(0xFF1D4ED8), size: 18),
                items: _availableMedicinesList.map((med) {
                  final isSelected = _selectedMedicines.contains(med);
                  return DropdownMenuItem<String>(
                    value: med,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(med, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                          size: 16,
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (_selectedMedicines.contains(val)) {
                        _selectedMedicines.remove(val);
                      } else {
                        _selectedMedicines.add(val);
                      }
                    });
                  }
                },
              ),
            ),
          ),
          if (_selectedMedicines.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedMedicines.map((med) {
                return Chip(
                  label: Text(med),
                  backgroundColor: const Color(0xFFE0F2FE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF38BDF8)),
                  ),
                  labelStyle: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0369A1),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0369A1)),
                  onDeleted: () => setState(() => _selectedMedicines.remove(med)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 18),

          // 4. IN-NETWORK HOSPITALS
          Text(
            '4. IN-NETWORK HOSPITALS (${_selectedHospitals.length} Selected)',
            style: AppFonts.googleSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text(
                  'Select in-network hospital facility...',
                  style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                ),
                icon: const Icon(Icons.local_hospital_rounded, color: Color(0xFF1D4ED8), size: 18),
                items: _availableHospitalsList.map((hosp) {
                  final isSelected = _selectedHospitals.contains(hosp);
                  return DropdownMenuItem<String>(
                    value: hosp,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            hosp,
                            style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                          size: 16,
                          color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (_selectedHospitals.contains(val)) {
                        _selectedHospitals.remove(val);
                      } else {
                        _selectedHospitals.add(val);
                      }
                    });
                  }
                },
              ),
            ),
          ),
          if (_selectedHospitals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedHospitals.map((hosp) {
                return Chip(
                  label: Text(hosp),
                  backgroundColor: const Color(0xFFECFDF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Color(0xFF34D399)),
                  ),
                  labelStyle: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF047857),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF047857)),
                  onDeleted: () => setState(() => _selectedHospitals.remove(hosp)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 22),

          // Save Action Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _handleSaveConfiguration(appState),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 18, color: Colors.white),
              label: Text(
                _isSaving ? 'SAVING CHANGES...' : 'SAVE FORMULARY & NETWORK CONFIGURATION',
                style: AppFonts.googleSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
