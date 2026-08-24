import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/clinical_alerts_data.dart';
import '../data/doctor_clinical_data.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class DoctorClinicalDashboardScreen extends StatefulWidget {
  final bool showSidebar;

  const DoctorClinicalDashboardScreen({
    super.key,
    this.showSidebar = true,
  });

  @override
  State<DoctorClinicalDashboardScreen> createState() =>
      _DoctorClinicalDashboardScreenState();
}

class _DoctorClinicalDashboardScreenState
    extends State<DoctorClinicalDashboardScreen>
    with SingleTickerProviderStateMixin {
  ClinicalMedicineComparison? _selectedMedicine;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTimePeriod = 'Last 30 Days';
  final List<String> _timePeriods = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Year'
  ];

  late AnimationController _animController;
  late Animation<double> _chartAnim;

  int _selectedNavIndex = 3; // 3: Analytics (Active)
  int _approvalFeedTab = 0; // 0: Pending, 1: History
  int _historyFilterIndex = 0; // 0: All, 1: Dispensed, 2: Approved, 3: Denied
  final TextEditingController _historySearchController = TextEditingController();
  String _historySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _chartAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _historySearchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onMedicineSelected(ClinicalMedicineComparison med) {
    if (_selectedMedicine?.cleanName == med.cleanName) return;
    setState(() {
      _selectedMedicine = med;
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final doctorName = user.name.isNotEmpty ? user.name : 'Dr. Ananya Sharma';
    final doctorSpecialty = (user.title.isNotEmpty && user.title != 'Attending Physician')
        ? user.title
        : 'Cardiologist';

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1080;

    final dynamicMedicines = _getDynamicMedicines(appState);
    final currentMed = (_selectedMedicine != null &&
            dynamicMedicines.any((m) => m.cleanName.toLowerCase() == _selectedMedicine!.cleanName.toLowerCase()))
        ? dynamicMedicines.firstWhere((m) => m.cleanName.toLowerCase() == _selectedMedicine!.cleanName.toLowerCase())
        : (dynamicMedicines.isNotEmpty ? dynamicMedicines.first : DoctorClinicalData.defaultMedicine);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Dark Navy Sidebar
          if (widget.showSidebar && isDesktop)
            _buildDarkNavySidebar(context, appState),

          // 2. Main Dashboard Content Canvas
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header Bar
                  _buildTopHeaderBar(
                    doctorName: doctorName,
                    doctorSpecialty: doctorSpecialty,
                  ),

                  // Full-width 5 KPI Telemetry Cards Strip
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: _buildPrescriptionTelemetryStrip(appState),
                  ),

                  // Pharmacy Alternative Regimen Approvals (CDS Feed)
                  _buildAlternativeApprovalRequestsSection(appState),

                  // Main Body: Left Medicine Selector + Right Chart & Insights
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                    child: isDesktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column: Select Prescribed Medicine List
                              SizedBox(
                                width: 290,
                                height: 750,
                                child: _buildMedicineSelectionPanel(appState, currentMed),
                              ),
                              const SizedBox(width: 20),

                              // Right Column: Overview Card + Usage Chart + Insight
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Top Medicine Comparison Info Bar
                                    _buildMedicineComparisonInfoBar(currentMed),
                                    const SizedBox(height: 16),

                                    // 2. Dual-Bar Patient Usage Comparison Chart
                                    _buildPatientUsageChartCard(currentMed),
                                    const SizedBox(height: 16),

                                    // 3. Dynamic Insight Banner
                                    _buildDynamicInsightCard(currentMed),
                                    const SizedBox(height: 20),

                                    // 4. Interactive Clinical Alerts Section
                                    _buildClinicalAlertsSection(appState),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildMedicineComparisonInfoBar(currentMed),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 400,
                                child: _buildMedicineSelectionPanel(appState, currentMed),
                              ),
                              const SizedBox(height: 16),
                              _buildPatientUsageChartCard(currentMed),
                              const SizedBox(height: 16),
                              _buildDynamicInsightCard(currentMed),
                              const SizedBox(height: 20),
                              _buildClinicalAlertsSection(appState),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. DARK NAVY SIDEBAR
  // =========================================================================
  Widget _buildDarkNavySidebar(BuildContext context, AppState appState) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: Color(0xFF071228),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 16,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App Logo Emblem Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 28),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EDFD),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0062FF).withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0062FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alternea',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Doctor Clinical',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF7E8EA6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sidebar Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _buildSidebarNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  label: 'Dashboard',
                  onTap: () {
                    setState(() => _selectedNavIndex = 0);
                    appState.setNavIndex(0);
                  },
                ),
                _buildSidebarNavItem(
                  index: 1,
                  icon: Icons.people_outline_rounded,
                  label: 'Patients',
                  onTap: () => setState(() => _selectedNavIndex = 1),
                ),
                _buildSidebarNavItem(
                  index: 2,
                  icon: Icons.medication_outlined,
                  label: 'Prescriptions',
                  onTap: () {
                    setState(() => _selectedNavIndex = 2);
                    appState.setNavIndex(1); // Nav to issue prescription
                  },
                ),
                _buildSidebarNavItem(
                  index: 3,
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  isActive: _selectedNavIndex == 3,
                  onTap: () => setState(() => _selectedNavIndex = 3),
                ),
                _buildSidebarNavItem(
                  index: 4,
                  icon: Icons.notifications_none_rounded,
                  label: 'Alerts',
                  onTap: () => setState(() => _selectedNavIndex = 4),
                ),
                _buildSidebarNavItem(
                  index: 5,
                  icon: Icons.description_outlined,
                  label: 'Reports',
                  onTap: () => setState(() => _selectedNavIndex = 5),
                ),
                _buildSidebarNavItem(
                  index: 6,
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  onTap: () => setState(() => _selectedNavIndex = 6),
                ),
              ],
            ),
          ),

          // Logout Item at bottom
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            child: _buildSidebarNavItem(
              index: 7,
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: () => appState.logout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required int index,
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    final active = isActive || _selectedNavIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF0062FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Icon(
          icon,
          size: 20,
          color: active ? Colors.white : const Color(0xFF8A99AD),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF8A99AD),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // =========================================================================
  // 2. TOP HEADER BAR
  // =========================================================================
  Widget _buildTopHeaderBar({
    required String doctorName,
    required String doctorSpecialty,
  }) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE6EDF5), width: 1.2),
        ),
      ),
      child: Row(
        children: [
          // Dashboard Title & Subtitle
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Doctor Clinical Dashboard',
                style: GoogleFonts.inter(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Medicine Usage & Adherence Overview',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Date Range Dropdown Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE3EC), width: 1.2),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimePeriod,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF64748B),
                  size: 18,
                ),
                isDense: true,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
                items: _timePeriods.map((period) {
                  return DropdownMenuItem<String>(
                    value: period,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(period),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedTimePeriod = val);
                    _animController.reset();
                    _animController.forward();
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Doctor Profile Header Tile
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      doctorName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      doctorSpecialty,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EDFD),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF0062FF),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PRESCRIPTION PROCESS LIFECYCLE TELEMETRY STRIP (LIVE SUPABASE / DB METRICS)
  // =========================================================================
  Map<String, String> _getTelemetryMetrics(AppState appState) {
    final int totalRx = appState.prescriptions.length;
    final int totalApprovals = appState.allAlternativeHistory.length;
    final int pendingApprovals = appState.pendingAlternativeApprovalRequests.length;
    final int approvedAlternatives = appState.approvedAlternativeHistory.length;
    final int deniedAlternatives = appState.allAlternativeHistory.where((r) => r.status == 'denied').length;

    final int receivedCount = totalRx + totalApprovals;
    final int processedCount = appState.prescriptions.where((r) => r.status.toLowerCase() != 'draft').length + totalApprovals;
    final int approvedCount = approvedAlternatives + appState.prescriptions.where((r) => r.status.toLowerCase() == 'active' || r.status.toLowerCase() == 'dispensed' || r.status.toLowerCase() == 'approved').length;
    final int pendingCount = pendingApprovals;
    final int rejectedCount = deniedAlternatives;

    final procRate = receivedCount > 0 ? ((processedCount / receivedCount) * 100).toStringAsFixed(1) : '100.0';
    final appRate = processedCount > 0 ? ((approvedCount / processedCount) * 100).clamp(0.0, 100.0).toStringAsFixed(1) : '100.0';
    final pendRate = receivedCount > 0 ? ((pendingCount / receivedCount) * 100).clamp(0.0, 100.0).toStringAsFixed(1) : '0.0';
    final rejRate = receivedCount > 0 ? ((rejectedCount / receivedCount) * 100).clamp(0.0, 100.0).toStringAsFixed(1) : '0.0';

    return {
      'received': receivedCount.toString(),
      'processed': processedCount.toString(),
      'approved': approvedCount.toString(),
      'pending': pendingCount.toString(),
      'rejected': rejectedCount.toString(),
      'receivedSub': 'Live DB records',
      'processedSub': '$procRate% flow',
      'approvedSub': '$appRate% rate',
      'pendingSub': '$pendRate% queue',
      'rejectedSub': '$rejRate% friction',
    };
  }

  Widget _buildPrescriptionTelemetryStrip(AppState appState) {
    final telemetry = _getTelemetryMetrics(appState);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isVeryCompact = width < 820;

        final cards = [
          _buildTelemetryMetricCard(
            title: 'Prescriptions Received',
            value: telemetry['received']!,
            subtitle: telemetry['receivedSub']!,
            icon: Icons.receipt_long_rounded,
            accentColor: const Color(0xFF0062FF),
            badgeColor: const Color(0xFFEFF6FF),
          ),
          _buildTelemetryMetricCard(
            title: 'Total Processed',
            value: telemetry['processed']!,
            subtitle: telemetry['processedSub']!,
            icon: Icons.task_alt_rounded,
            accentColor: const Color(0xFF4F46E5),
            badgeColor: const Color(0xFFEEF2FF),
          ),
          _buildTelemetryMetricCard(
            title: 'Approved',
            value: telemetry['approved']!,
            subtitle: telemetry['approvedSub']!,
            icon: Icons.check_circle_outline_rounded,
            accentColor: const Color(0xFF10B981),
            badgeColor: const Color(0xFFECFDF5),
          ),
          _buildTelemetryMetricCard(
            title: 'Pending Review',
            value: telemetry['pending']!,
            subtitle: telemetry['pendingSub']!,
            icon: Icons.hourglass_top_rounded,
            accentColor: const Color(0xFFF59E0B),
            badgeColor: const Color(0xFFFEF3C7),
          ),
          _buildTelemetryMetricCard(
            title: 'Rejected',
            value: telemetry['rejected']!,
            subtitle: telemetry['rejectedSub']!,
            icon: Icons.highlight_off_rounded,
            accentColor: const Color(0xFFEF4444),
            badgeColor: const Color(0xFFFEF2F2),
          ),
        ];

        if (isVeryCompact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: cards
                  .map(
                    (card) => Container(
                      width: 175,
                      margin: const EdgeInsets.only(right: 12),
                      child: card,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        return Row(
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildTelemetryMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.025),
            blurRadius: 10,
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: accentColor, size: 17),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
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

  // =========================================================================
  // DYNAMIC MEDICINES GENERATOR (FROM SUPABASE & APPROVED ALTERNATIVES)
  // =========================================================================
  List<ClinicalMedicineComparison> _getDynamicMedicines(AppState appState) {
    final List<ClinicalMedicineComparison> dynamicList = [];

    // 1. Live Approved and historical Alternative Approvals from Supabase / AppState
    for (final req in appState.alternativeApprovalRequests) {
      final origParts = _splitDrugNameAndStrength(req.originalDrug);
      final altParts = _splitDrugNameAndStrength(req.recommendedAlternative);

      if (!dynamicList.any((m) => m.cleanName.toLowerCase() == origParts.$1.toLowerCase())) {
        final double prescribedPct = (req.isApproved || req.isDispensed) ? 66.0 : 72.0;
        final double altPct = (req.isApproved || req.isDispensed) ? 59.0 : 48.0;

        dynamicList.add(
          ClinicalMedicineComparison(
            cleanName: origParts.$1,
            strength: origParts.$2,
            altName: altParts.$1,
            altStrength: altParts.$2,
            therapeuticCategory: req.clinicalClass.isNotEmpty ? req.clinicalClass : 'Clinical Alternative Therapy',
            prescribedPct: prescribedPct,
            prescribedRangeMin: (prescribedPct - 8).clamp(0.0, 100.0),
            prescribedRangeMax: (prescribedPct + 7).clamp(0.0, 100.0),
            altPct: altPct,
            altRangeMin: (altPct - 8).clamp(0.0, 100.0),
            altRangeMax: (altPct + 7).clamp(0.0, 100.0),
            customInsight: req.clinicalRationale.isNotEmpty
                ? req.clinicalRationale
                : '${prescribedPct.toInt()}% of patients used ${origParts.$1} ${origParts.$2}, while ${altPct.toInt()}% switched to alternative ${altParts.$1} ${altParts.$2}.',
          ),
        );
      }
    }

    // 2. Add any prescription items from live patient records
    for (final rx in appState.prescriptions) {
      final drug = rx.drugName;
      if (drug.isNotEmpty && !drug.startsWith('RX-') && !dynamicList.any((m) => m.cleanName.toLowerCase() == drug.toLowerCase())) {
        final parts = _splitDrugNameAndStrength(drug);
        dynamicList.add(
          ClinicalMedicineComparison(
            cleanName: parts.$1,
            strength: parts.$2,
            altName: _inferAlternativeName(parts.$1),
            altStrength: parts.$2,
            therapeuticCategory: rx.drugClass.isNotEmpty ? rx.drugClass : 'General Formulary',
            prescribedPct: 68.0,
            prescribedRangeMin: 60.0,
            prescribedRangeMax: 76.0,
            altPct: 52.0,
            altRangeMin: 44.0,
            altRangeMax: 60.0,
          ),
        );
      }
    }

    // Filter by search query
    if (_searchQuery.isEmpty) return dynamicList;
    final q = _searchQuery.toLowerCase();
    return dynamicList.where((m) =>
        m.cleanName.toLowerCase().contains(q) ||
        m.altName.toLowerCase().contains(q) ||
        m.therapeuticCategory.toLowerCase().contains(q)).toList();
  }

  (String, String) _splitDrugNameAndStrength(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    final match = RegExp(r'^([A-Za-z\s]+)\s+(\d+\s*(?:mg|ml|mcg|g)?(?:\s*Oral\s*Tablet|\s*Tablet|\s*Capsule)?.*)$', caseSensitive: false).firstMatch(cleaned);
    if (match != null) {
      final name = match.group(1)?.trim() ?? cleaned;
      final strength = match.group(2)?.replaceAll('Oral Tablet', '')
          .replaceAll('Tablet', '')
          .replaceAll('Capsule', '')
          .trim() ?? '';
      return (name, strength.isNotEmpty ? strength : '5 mg');
    }
    return (cleaned, '5 mg');
  }

  String _inferAlternativeName(String drugName) {
    final lower = drugName.toLowerCase();
    if (lower.contains('levetiracetam') || lower.contains('keppra')) return 'Lamotrigine';
    if (lower.contains('lipitor') || lower.contains('atorvastatin')) return 'Rosuvastatin';
    if (lower.contains('metformin')) return 'Glimepiride';
    if (lower.contains('lisinopril') || lower.contains('prinivil')) return 'Telmisartan';
    if (lower.contains('levocetirizine')) return 'Cetirizine';
    if (lower.contains('cetirizine')) return 'Levocetirizine';
    if (lower.contains('omeprazole')) return 'Pantoprazole';
    if (lower.contains('paracetamol')) return 'Dolo';
    return 'Tier 1 Alternative';
  }

  // =========================================================================
  // 3. LEFT COLUMN: SELECT PRESCRIBED MEDICINE
  // =========================================================================
  Widget _buildMedicineSelectionPanel(AppState appState, ClinicalMedicineComparison selectedMed) {
    final filteredList = _getDynamicMedicines(appState);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Prescribed Medicine',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Click on a medicine to view usage comparison',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),

                // Search Input Field
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search medicine...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 17,
                        color: Color(0xFF94A3B8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 15),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Scrollable Medicine List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No clinical prescription records yet.\nApprove alternative medicines from pharmacy to populate.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    itemCount: filteredList.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final med = filteredList[index];
                      final isSelected =
                          selectedMed.cleanName.toLowerCase() == med.cleanName.toLowerCase();

                      final isApprovedAlt = appState.allAlternativeHistory.any((r) =>
                          r.originalDrug.toLowerCase().contains(med.cleanName.toLowerCase()) ||
                          r.recommendedAlternative.toLowerCase().contains(med.cleanName.toLowerCase()));

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: InkWell(
                          onTap: () => _onMedicineSelected(med),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEAF2FF)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0062FF)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isApprovedAlt ? Icons.auto_awesome_rounded : Icons.medication_liquid_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFF0062FF)
                                      : (isApprovedAlt ? const Color(0xFF8B5CF6) : const Color(0xFF94A3B8)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med.cleanName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? const Color(0xFF0062FF)
                                              : const Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isApprovedAlt)
                                        Text(
                                          'Approved Alternative',
                                          style: GoogleFonts.inter(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF7C3AED),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? const Color(0xFF0062FF)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Footer Total Medicines Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              'Total Medicines: ${filteredList.length}',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 4. RIGHT TOP INFO BAR: PRESCRIBED VS ALTERNATIVE + CATEGORY
  // =========================================================================
  Widget _buildMedicineComparisonInfoBar(ClinicalMedicineComparison selectedMed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Prescribed Medicine Box
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescribed Medicine',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0062FF),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        selectedMed.cleanName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedMed.strength,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0062FF),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Central Swap Icon Button
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Color(0xFF475569),
              size: 20,
            ),
          ),

          const SizedBox(width: 20),

          // 3. Recommended Alternative Box
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommended Alternative',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        selectedMed.altName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        selectedMed.altStrength,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Therapeutic Category Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD6E8FE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF0062FF),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Therapeutic Category',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0062FF),
                      ),
                    ),
                    Text(
                      selectedMed.therapeuticCategory,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
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

  // =========================================================================
  // 5. CENTER CARD: PATIENT USAGE COMPARISON DUAL-BAR CHART
  // =========================================================================
  Widget _buildPatientUsageChartCard(ClinicalMedicineComparison selectedMed) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patient Usage Comparison',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Percentage of patients using prescribed medicine vs alternative',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: Color(0xFF0062FF),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Data represents the selected time period',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Custom Dual-Bar Canvas with Whiskers
          AnimatedBuilder(
            animation: _chartAnim,
            builder: (context, child) {
              return SizedBox(
                height: 300,
                child: CustomPaint(
                  size: const Size(double.infinity, 300),
                  painter: _TwoBarWhiskerChartPainter(
                    animationProgress: _chartAnim.value,
                    prescribedName:
                        '${selectedMed.cleanName} ${selectedMed.strength}',
                    prescribedPct: selectedMed.prescribedPct,
                    prescribedMin: selectedMed.prescribedRangeMin,
                    prescribedMax: selectedMed.prescribedRangeMax,
                    altName:
                        '${selectedMed.altName} ${selectedMed.altStrength}',
                    altPct: selectedMed.altPct,
                    altMin: selectedMed.altRangeMin,
                    altMax: selectedMed.altRangeMax,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Range Badges Under Bars
          Row(
            children: [
              const SizedBox(width: 50), // Y-axis offset spacer
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Usage Range: ${selectedMed.prescribedRangeMin.toInt()}% - ${selectedMed.prescribedRangeMax.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      'Usage Range: ${selectedMed.altRangeMin.toInt()}% - ${selectedMed.altRangeMax.toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom Legend Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: const Color(0xFF0062FF),
                label: 'Prescribed Medicine',
              ),
              const SizedBox(width: 28),
              _buildLegendItem(
                color: const Color(0xFF16A34A),
                label: 'Alternative Medicine',
              ),
              const SizedBox(width: 28),
              _buildWhiskerLegendItem(label: 'Usage Range'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  Widget _buildWhiskerLegendItem({required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(18, 14),
          painter: _WhiskerIconPainter(),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 6. BOTTOM DYNAMIC INSIGHT BANNER
  // =========================================================================
  Widget _buildDynamicInsightCard(ClinicalMedicineComparison selectedMed) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E7FE), width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE1EFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Color(0xFF0062FF),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insight',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0062FF),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selectedMed.insightText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. INTERACTIVE CLINICAL ALERTS SECTION (DYNAMIC SUPABASE & APPSTATE RECORDS)
  // =========================================================================
  List<ClinicalAlertRecord> _getDynamicAlertRecords(AppState appState) {
    final List<ClinicalAlertRecord> records = [];

    // 1. Lower-Cost Alternatives (from live alternativeApprovalRequests)
    for (int i = 0; i < appState.alternativeApprovalRequests.length; i++) {
      final req = appState.alternativeApprovalRequests[i];
      records.add(
        ClinicalAlertRecord(
          id: 'ALT-REQ-${req.id}',
          patientId: req.patientId.isNotEmpty ? req.patientId : 'PAT_${1000 + i}',
          patientName: req.patientName.isNotEmpty ? req.patientName : 'Patient Record',
          prescriptionId: req.prescriptionId.isNotEmpty ? req.prescriptionId : 'RX_${2000 + i}',
          drugName: req.originalDrug,
          strength: 'Standard Dose',
          therapeuticClass: req.clinicalClass.isNotEmpty ? req.clinicalClass : 'Alternative Regimen',
          indication: req.clinicalRationale.isNotEmpty ? req.clinicalRationale : 'Therapeutic Switch Recommendation',
          alertType: ClinicalAlertType.lowerCostAlternative,
          severity: 'Medium',
          title: 'Lower-Cost Alternative Available: ${req.recommendedAlternative}',
          detailText: req.clinicalRationale.isNotEmpty
              ? req.clinicalRationale
              : 'Switch from ${req.originalDrug} to ${req.recommendedAlternative} saves patient money and improves formulary adherence.',
          alternativeDrug: req.recommendedAlternative,
          savingsEstimate: 'Save \$${req.patientSavings.toStringAsFixed(2)}/mo (\$${req.annualSavings.toStringAsFixed(2)}/yr)',
          timestampStr: req.createdAt.isNotEmpty ? req.createdAt : 'Just now',
        ),
      );
    }

    // 2. PA Pending / Prescriptions (from live prescriptions)
    for (int i = 0; i < appState.prescriptions.length; i++) {
      final rx = appState.prescriptions[i];
      final rxNotes = rx.notes ?? '';
      final rxDiag = rx.diagnosis ?? 'Chronic Condition';
      final isPa = rx.status.toLowerCase().contains('pa') || rx.status.toLowerCase().contains('pending');
      final isInteract = rxNotes.toLowerCase().contains('interaction') || rxNotes.toLowerCase().contains('warning');

      if (isPa) {
        records.add(
          ClinicalAlertRecord(
            id: 'PA-PEND-${rx.id}',
            patientId: rx.patientId.isNotEmpty ? rx.patientId : 'PAT_${1000 + i}',
            patientName: rx.patientName.isNotEmpty ? rx.patientName : 'Patient Record',
            prescriptionId: rx.id.isNotEmpty ? rx.id : 'RX_${2000 + i}',
            drugName: rx.drugName,
            strength: 'Standard Dose',
            therapeuticClass: rx.drugClass.isNotEmpty ? rx.drugClass : 'Clinical Category',
            indication: rxDiag,
            alertType: ClinicalAlertType.paPending,
            severity: 'High',
            title: 'Prior Authorization Review Required for ${rx.drugName}',
            detailText: 'Clinical PA documentation submitted to payer. Awaiting payer determination.',
            paStatus: 'Under Review',
            timestampStr: rx.prescribedDate?.toIso8601String() ?? rx.lastFillDate.toIso8601String(),
          ),
        );
      }

      if (isInteract) {
        records.add(
          ClinicalAlertRecord(
            id: 'INTERACT-${rx.id}',
            patientId: rx.patientId.isNotEmpty ? rx.patientId : 'PAT_${1000 + i}',
            patientName: rx.patientName.isNotEmpty ? rx.patientName : 'Patient Record',
            prescriptionId: rx.id.isNotEmpty ? rx.id : 'RX_${2000 + i}',
            drugName: rx.drugName,
            strength: 'Standard Dose',
            therapeuticClass: rx.drugClass.isNotEmpty ? rx.drugClass : 'Clinical Category',
            indication: rxDiag,
            alertType: ClinicalAlertType.drugInteraction,
            severity: 'High',
            title: 'Safety Warning / Interaction for ${rx.drugName}',
            detailText: rxNotes.isNotEmpty ? rxNotes : 'Potential drug-drug interaction or metabolic flag detected by CDS engine.',
            interactionWarning: 'Monitor metabolic & kidney labs',
            timestampStr: rx.prescribedDate?.toIso8601String() ?? rx.lastFillDate.toIso8601String(),
          ),
        );
      }

      if (rx.status.toLowerCase() == 'dispensed' || rx.status.toLowerCase() == 'active' || rx.status.toLowerCase() == 'approved') {
        records.add(
          ClinicalAlertRecord(
            id: 'PROC-${rx.id}',
            patientId: rx.patientId.isNotEmpty ? rx.patientId : 'PAT_${1000 + i}',
            patientName: rx.patientName.isNotEmpty ? rx.patientName : 'Patient Record',
            prescriptionId: rx.id.isNotEmpty ? rx.id : 'RX_${2000 + i}',
            drugName: rx.drugName,
            strength: 'Standard Dose',
            therapeuticClass: rx.drugClass.isNotEmpty ? rx.drugClass : 'Formulary Tier 1',
            indication: rxDiag,
            alertType: ClinicalAlertType.successfullyProcessed,
            severity: 'Info',
            title: 'Prescription Successfully Processed: ${rx.drugName}',
            detailText: 'Full claim adjudication passed. Copay collected and prescription dispensed to patient.',
            timestampStr: rx.prescribedDate?.toIso8601String() ?? rx.lastFillDate.toIso8601String(),
          ),
        );
      }
    }

    // 3. High Adherence Risk (from live patientRecords)
    for (int i = 0; i < appState.patientRecords.length; i++) {
      final p = appState.patientRecords[i];
      if (p.riskScore >= 0.70) {
        records.add(
          ClinicalAlertRecord(
            id: 'ADH-${p.id}',
            patientId: p.id,
            patientName: p.name,
            prescriptionId: 'RX_ADH_${1000 + i}',
            drugName: p.currentProblem.isNotEmpty ? p.currentProblem : 'Maintenance Regimen',
            strength: 'Standard',
            therapeuticClass: 'Adherence Monitoring',
            indication: p.currentProblem,
            alertType: ClinicalAlertType.highAdherenceRisk,
            severity: 'High',
            title: 'High Adherence Risk: ${p.name}',
            detailText: 'Proportion of Days Covered (PDC) below 80%. Automated refill reminders and consultation recommended.',
            pdcScore: '${(p.riskScore * 100).toInt()}%',
            timestampStr: p.visitDate.toIso8601String(),
          ),
        );
      }
    }

    return records;
  }

  Widget _buildClinicalAlertsSection(AppState appState) {
    final int highAdherenceCount = appState.patientRecords.where((p) => p.riskScore >= 0.70).length;
    final int paPendingCount = appState.prescriptions.where((p) => p.status.toLowerCase().contains('pa') || p.status.toLowerCase().contains('pending')).length;
    final int lowerCostAltCount = appState.alternativeApprovalRequests.length;
    final int drugInteractionCount = appState.prescriptions.where((p) => (p.notes ?? '').toLowerCase().contains('interaction') || (p.notes ?? '').toLowerCase().contains('warning')).length;
    final int processedCount = appState.prescriptions.where((p) => p.status.toLowerCase() == 'dispensed' || p.status.toLowerCase() == 'active' || p.status.toLowerCase() == 'approved').length + appState.approvedAlternativeHistory.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.notification_important_rounded,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Active Clinical Alerts',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Live Database Records',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dynamic patient safety, adherence, and alternative drug flags from live records',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // "View All Alerts" Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1931),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 16),
                label: Text(
                  'View All Alerts',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () => _showAllAlertsModal(context, appState),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Five Dynamic Alert Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;

              final cards = [
                // 1. High Adherence Risk
                _buildClinicalAlertCard(
                  appState: appState,
                  title: 'High Adherence Risk Patients',
                  count: '$highAdherenceCount',
                  subtitle: 'PDC < 80% • Refill Gaps',
                  icon: Icons.warning_rounded,
                  accentColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  borderColor: const Color(0xFFFECACA),
                  alertType: ClinicalAlertType.highAdherenceRisk,
                ),
                // 2. PA Pending
                _buildClinicalAlertCard(
                  appState: appState,
                  title: 'Prior Authorization Pending',
                  count: '$paPendingCount',
                  subtitle: 'Awaiting Payer Review',
                  icon: Icons.hourglass_top_rounded,
                  accentColor: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFDE68A),
                  alertType: ClinicalAlertType.paPending,
                ),
                // 3. Lower Cost Alternatives
                _buildClinicalAlertCard(
                  appState: appState,
                  title: 'Eligible for Lower-Cost Alt',
                  count: '$lowerCostAltCount',
                  subtitle: 'Tier 1 Generic Savings',
                  icon: Icons.savings_rounded,
                  accentColor: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFEFCE8),
                  borderColor: const Color(0xFFFEF08A),
                  alertType: ClinicalAlertType.lowerCostAlternative,
                ),
                // 4. Drug Interactions
                _buildClinicalAlertCard(
                  appState: appState,
                  title: 'Drug Interaction Alerts',
                  count: '$drugInteractionCount',
                  subtitle: 'Metabolic & Safety Flags',
                  icon: Icons.shield_outlined,
                  accentColor: const Color(0xFF0062FF),
                  bgColor: const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFFBFDBFE),
                  alertType: ClinicalAlertType.drugInteraction,
                ),
                // 5. Successfully Processed
                _buildClinicalAlertCard(
                  appState: appState,
                  title: 'Prescriptions Processed',
                  count: '$processedCount',
                  subtitle: 'Claim Paid • 100% Verified',
                  icon: Icons.check_circle_outline_rounded,
                  accentColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFBBF7D0),
                  alertType: ClinicalAlertType.successfullyProcessed,
                ),
              ];

              if (isWide) {
                return Row(
                  children: cards
                      .map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: c,
                            ),
                          ))
                      .toList(),
                );
              } else {
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
                        const SizedBox(width: 8),
                        Expanded(child: cards[4]),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalAlertCard({
    required AppState appState,
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required ClinicalAlertType alertType,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showAlertDetailModal(context, appState, alertType, count, title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: accentColor, size: 18),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: accentColor,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // MODAL 1: SINGLE ALERT CATEGORY DETAIL MODAL
  // =========================================================================
  void _showAlertDetailModal(
    BuildContext context,
    AppState appState,
    ClinicalAlertType alertType,
    String totalCount,
    String categoryTitle,
  ) {
    final allRecords = _getDynamicAlertRecords(appState)
        .where((r) => r.alertType == alertType)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Container(
            width: 760,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1931),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notification_important_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              categoryTitle,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$totalCount Total Patients In Cohort • ${allRecords.length} Active Records',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Body List
                Expanded(
                  child: allRecords.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No active alert records in this cohort.',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: allRecords.length,
                          separatorBuilder: (context, idx) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final rec = allRecords[idx];
                            return _buildAlertRecordItem(rec);
                          },
                        ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Adjudicated from live Supabase & physician records',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A1931),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // MODAL 2: UNIFIED "VIEW ALL ALERTS" MODAL (WITH CATEGORY TABS)
  // =========================================================================
  void _showAllAlertsModal(BuildContext context, AppState appState) {
    int activeTab = 0; // 0: All, 1: Adherence, 2: PA, 3: Alternatives, 4: Interactions, 5: Processed
    final allRecords = _getDynamicAlertRecords(appState);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            List<ClinicalAlertRecord> displayed = allRecords;
            if (activeTab == 1) {
              displayed = allRecords.where((r) => r.alertType == ClinicalAlertType.highAdherenceRisk).toList();
            } else if (activeTab == 2) {
              displayed = allRecords.where((r) => r.alertType == ClinicalAlertType.paPending).toList();
            } else if (activeTab == 3) {
              displayed = allRecords.where((r) => r.alertType == ClinicalAlertType.lowerCostAlternative).toList();
            } else if (activeTab == 4) {
              displayed = allRecords.where((r) => r.alertType == ClinicalAlertType.drugInteraction).toList();
            } else if (activeTab == 5) {
              displayed = allRecords.where((r) => r.alertType == ClinicalAlertType.successfullyProcessed).toList();
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Container(
                width: 820,
                constraints: const BoxConstraints(maxHeight: 740),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A1931),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.crisis_alert_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unified Clinical Alerts Center',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Cross-cohort safety warnings, PA friction queues, and adherence risks',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Filter Tabs
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildAlertFilterTab('All Alerts (${allRecords.length})', 0, activeTab, setModalState),
                            const SizedBox(width: 8),
                            _buildAlertFilterTab('🔴 High Adherence', 1, activeTab, setModalState),
                            const SizedBox(width: 8),
                            _buildAlertFilterTab('🟠 PA Pending', 2, activeTab, setModalState),
                            const SizedBox(width: 8),
                            _buildAlertFilterTab('🟡 Lower-Cost Alt', 3, activeTab, setModalState),
                            const SizedBox(width: 8),
                            _buildAlertFilterTab('🔵 Drug Interactions', 4, activeTab, setModalState),
                            const SizedBox(width: 8),
                            _buildAlertFilterTab('🟢 Processed', 5, activeTab, setModalState),
                          ],
                        ),
                      ),
                    ),

                    // Body
                    Expanded(
                      child: displayed.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No clinical alerts found for the selected tab.',
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: displayed.length,
                              separatorBuilder: (context, idx) => const SizedBox(height: 12),
                              itemBuilder: (context, idx) {
                                final rec = displayed[idx];
                                return _buildAlertRecordItem(rec);
                              },
                            ),
                    ),

                    // Footer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Showing ${displayed.length} matching clinical alerts',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A1931),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            ),
                            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlertFilterTab(
    String label,
    int index,
    int activeTab,
    void Function(void Function()) setModalState,
  ) {
    final isActive = activeTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setModalState(() {}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0A1931) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF0A1931) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertRecordItem(ClinicalAlertRecord rec) {
    Color badgeBg;
    Color badgeColor;

    switch (rec.alertType) {
      case ClinicalAlertType.highAdherenceRisk:
        badgeBg = const Color(0xFFFEE2E2);
        badgeColor = const Color(0xFFDC2626);
        break;
      case ClinicalAlertType.paPending:
        badgeBg = const Color(0xFFFEF3C7);
        badgeColor = const Color(0xFFD97706);
        break;
      case ClinicalAlertType.lowerCostAlternative:
        badgeBg = const Color(0xFFFEF9C3);
        badgeColor = const Color(0xFFB45309);
        break;
      case ClinicalAlertType.drugInteraction:
        badgeBg = const Color(0xFFEFF6FF);
        badgeColor = const Color(0xFF0062FF);
        break;
      case ClinicalAlertType.successfullyProcessed:
        badgeBg = const Color(0xFFDCFCE7);
        badgeColor = const Color(0xFF16A34A);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rec.severity.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${rec.patientName} (${rec.patientId})',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                rec.timestampStr,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          Text(
            rec.title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),

          Text(
            rec.detailText,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Metadata Chips Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rx: ${rec.drugName} ${rec.strength}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  rec.indication,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const Spacer(),

              // Quick Action Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0062FF),
                  side: const BorderSide(color: Color(0xFF93C5FD)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text('Review Details', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0A1931),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      content: Text('Opening clinical review for ${rec.drugName} (${rec.patientId})...'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // PHARMACY ALTERNATIVE REGIMEN APPROVALS & HISTORY (CDS AUDIT)
  // =========================================================================
  String _formatApprovalDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$min $ampm';
  }

  Widget _buildAlternativeApprovalRequestsSection(AppState appState) {
    final pending = appState.pendingAlternativeApprovalRequests;
    final allHistory = appState.allAlternativeHistory;

    // Filter history by search and sub-tab
    final filteredHistory = allHistory.where((req) {
      if (_historyFilterIndex == 1 && !req.isDispensed) return false;
      if (_historyFilterIndex == 2 && req.status != 'approved') return false;
      if (_historyFilterIndex == 3 && req.status != 'denied') return false;

      if (_historySearchQuery.isEmpty) return true;
      final q = _historySearchQuery.toLowerCase();
      return req.patientName.toLowerCase().contains(q) ||
          req.patientId.toLowerCase().contains(q) ||
          req.prescriptionId.toLowerCase().contains(q) ||
          req.originalDrug.toLowerCase().contains(q) ||
          req.recommendedAlternative.toLowerCase().contains(q) ||
          req.indication.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header with Tab Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pharmacy Alternative Regimen Approvals & Audit Feed',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4C1D95),
                          ),
                        ),
                        Text(
                          'Track live pharmacist alternative requests and historical physician approval records',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Tab Switcher: Pending vs History
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pending Tab Button
                      InkWell(
                        onTap: () => setState(() => _approvalFeedTab = 0),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _approvalFeedTab == 0 ? const Color(0xFF8B5CF6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pending_actions_rounded,
                                size: 14,
                                color: _approvalFeedTab == 0 ? Colors.white : const Color(0xFF6B21A8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pending Approvals (${pending.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _approvalFeedTab == 0 ? Colors.white : const Color(0xFF6B21A8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // History Tab Button
                      InkWell(
                        onTap: () => setState(() => _approvalFeedTab = 1),
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _approvalFeedTab == 1 ? const Color(0xFF8B5CF6) : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.history_edu_rounded,
                                size: 14,
                                color: _approvalFeedTab == 1 ? Colors.white : const Color(0xFF6B21A8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Approval History (${allHistory.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: _approvalFeedTab == 1 ? Colors.white : const Color(0xFF6B21A8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ===============================================================
            // TAB 0: PENDING APPROVALS LIST
            // ===============================================================
            if (_approvalFeedTab == 0) ...[
              if (pending.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF4FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE9D5FF)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 32, color: Color(0xFF10B981)),
                      const SizedBox(height: 8),
                      Text(
                        'No Pending Alternative Requests',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        'All pharmacy medication substitution recommendations have been reviewed and approved.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ...pending.map((req) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC084FC)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                          blurRadius: 8,
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
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3E8FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_rounded, size: 15, color: Color(0xFF7C3AED)),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${req.patientName} (${req.patientAge}y)',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Prescription ID: #${req.prescriptionId} • Indication: ${req.indication}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Save \$${req.monthlySavings.toStringAsFixed(2)} / mo',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFF3E8FF)),
                        const SizedBox(height: 12),

                        // Comparison Blocks
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ORIGINAL DRUG PRESCRIBED',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF991B1B),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      req.originalDrug,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF7F1D1D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF8B5CF6), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF6EE7B7)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RECOMMENDED ALTERNATIVE',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF065F46),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      req.recommendedAlternative,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
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

                        const SizedBox(height: 10),

                        // Rationale
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Class: ${req.clinicalClass}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Clinical Rationale: ${req.clinicalRationale}',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF64748B),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(color: Color(0xFFFCA5A5)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.close_rounded, size: 14),
                              label: Text('Deny Alternative',
                                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700)),
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
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.check_circle_rounded, size: 15),
                              label: Text('Approve Alternative Medicine',
                                  style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w900)),
                              onPressed: () {
                                appState.approveAlternativeDrug(requestId: req.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: const Color(0xFF10B981),
                                    content: Text(
                                        '✅ Approved ${req.recommendedAlternative} for ${req.patientName}! Logged in Alternative History and Voice alert sent to Pharmacist.'),
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

            // ===============================================================
            // TAB 1: ALTERNATIVE PRESCRIPTION APPROVAL HISTORY (NEW FEATURE)
            // ===============================================================
            if (_approvalFeedTab == 1) ...[
              // Search Bar & Filter Chips
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _historySearchController,
                        onChanged: (val) => setState(() => _historySearchQuery = val),
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
                        decoration: InputDecoration(
                          hintText: 'Search alternative history by patient, drug, or Rx ID...',
                          hintStyle: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                          suffixIcon: _historySearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () {
                                    _historySearchController.clear();
                                    setState(() => _historySearchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildHistoryFilterChip(0, 'All (${allHistory.length})'),
                        const SizedBox(width: 6),
                        _buildHistoryFilterChip(1, 'Dispensed (${allHistory.where((r) => r.isDispensed).length})'),
                        const SizedBox(width: 6),
                        _buildHistoryFilterChip(2, 'Approved (${allHistory.where((r) => r.status == 'approved').length})'),
                        const SizedBox(width: 6),
                        _buildHistoryFilterChip(3, 'Denied (${allHistory.where((r) => r.status == 'denied').length})'),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (filteredHistory.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.history_toggle_off_rounded, size: 32, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      Text(
                        'No Alternative Approval Records Found',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                      ),
                      Text(
                        'Alternative prescriptions approved by physicians will be archived here with full CDS clinical audit records.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ...filteredHistory.map((req) {
                  final isDispensed = req.isDispensed;
                  final isApproved = req.status == 'approved';
                  final isDenied = req.status == 'denied';

                  final badgeColor = isDispensed
                      ? const Color(0xFF10B981)
                      : (isApproved ? const Color(0xFF0062FF) : const Color(0xFFEF4444));
                  final badgeBg = isDispensed
                      ? const Color(0xFFECFDF5)
                      : (isApproved ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2));
                  final badgeText = isDispensed
                      ? '✨ DISPENSED & FULFILLED'
                      : (isApproved ? '🟢 APPROVED • PENDING DISPENSE' : '🔴 ALTERNATIVE DENIED');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // History Item Header: Status + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                badgeText,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Text(
                                  _formatApprovalDate(req.respondedAt ?? req.requestedAt),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Patient Info Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF475569)),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${req.patientName} (${req.patientAge}y)',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Prescription ID: #${req.prescriptionId} • Indication: ${req.indication}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (!isDenied)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'Patient Saved \$${req.monthlySavings.toStringAsFixed(2)} / mo (\$${req.annualSavings.toStringAsFixed(2)}/yr)',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 10),

                        // Comparison Display
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ORIGINAL PRESCRIBED',
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      req.originalDrug,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF334155),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isDenied ? Icons.close_rounded : Icons.arrow_forward_rounded,
                              color: isDenied ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDenied ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDenied ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isDenied ? 'DENIED SUBSTITUTION' : 'APPROVED ALTERNATIVE',
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDenied ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      req.recommendedAlternative,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDenied ? const Color(0xFF7F1D1D) : const Color(0xFF064E3B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Rationale & Doctor Decision Note
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clinical Class: ${req.clinicalClass}',
                                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rationale: ${req.clinicalRationale}',
                                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF64748B), fontStyle: FontStyle.italic),
                              ),
                              if (req.doctorNote != null && req.doctorNote!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Physician Sign-off Note: "${req.doctorNote}"',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryFilterChip(int index, String label) {
    final isSelected = _historyFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _historyFilterIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// CUSTOM DUAL-BAR CHART PAINTER WITH ERROR WHISKERS
// ===========================================================================
class _TwoBarWhiskerChartPainter extends CustomPainter {
  final double animationProgress;
  final String prescribedName;
  final double prescribedPct;
  final double prescribedMin;
  final double prescribedMax;
  final String altName;
  final double altPct;
  final double altMin;
  final double altMax;

  _TwoBarWhiskerChartPainter({
    required this.animationProgress,
    required this.prescribedName,
    required this.prescribedPct,
    required this.prescribedMin,
    required this.prescribedMax,
    required this.altName,
    required this.altPct,
    required this.altMin,
    required this.altMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double leftMargin = 52.0;
    const double bottomMargin = 54.0;
    const double topMargin = 28.0;
    final double rightMargin = 20.0;

    final double chartWidth = size.width - leftMargin - rightMargin;
    final double chartHeight = size.height - topMargin - bottomMargin;
    final double baselineY = topMargin + chartHeight;

    final Paint gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 1. Draw Y-Axis Horizontal Gridlines & Labels (0%, 20%, 40%, 60%, 80%, 100%)
    const List<int> yTicks = [0, 20, 40, 60, 80, 100];
    for (final tick in yTicks) {
      final double normalized = tick / 100.0;
      final double y = baselineY - (normalized * chartHeight);

      // Grid line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width - rightMargin, y),
        gridPaint,
      );

      // Y-axis tick label
      tp.text = TextSpan(
        text: '$tick%',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 10, y - (tp.height / 2)));
    }

    // Y-Axis Title on far left (rotated)
    canvas.save();
    canvas.translate(14, baselineY - (chartHeight / 2));
    canvas.rotate(-1.570796);
    tp.text = TextSpan(
      text: 'Percentage of Patients (%)',
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF475569),
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();

    // 2. Bar Dimensions & Centers
    final double sectionWidth = chartWidth / 2;
    final double barWidth = (chartWidth * 0.28).clamp(80.0, 150.0);

    final double bar1CenterX = leftMargin + (sectionWidth * 0.5);
    final double bar2CenterX = leftMargin + (sectionWidth * 1.5);

    // =======================================================================
    // BAR 1: PRESCRIBED MEDICINE (BLUE)
    // =======================================================================
    final double curPrescribedPct = prescribedPct * animationProgress;
    final double bar1Height = (curPrescribedPct / 100.0) * chartHeight;
    final double bar1Top = baselineY - bar1Height;

    final Rect bar1Rect = Rect.fromLTRB(
      bar1CenterX - (barWidth / 2),
      bar1Top,
      bar1CenterX + (barWidth / 2),
      baselineY,
    );

    final Paint bar1Paint = Paint()
      ..color = const Color(0xFF0062FF)
      ..style = PaintingStyle.fill;

    // Draw Bar 1
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bar1Rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      bar1Paint,
    );

    // Percentage text above Bar 1
    tp.text = TextSpan(
      text: '${prescribedPct.toInt()}%',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF0062FF),
      ),
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        bar1CenterX - (tp.width / 2),
        (baselineY - ((prescribedMax * animationProgress) / 100.0 * chartHeight)) - tp.height - 8,
      ),
    );

    // Error Whisker for Bar 1
    _drawErrorWhisker(
      canvas: canvas,
      centerX: bar1CenterX,
      baselineY: baselineY,
      chartHeight: chartHeight,
      minPct: prescribedMin * animationProgress,
      maxPct: prescribedMax * animationProgress,
      whiskerWidth: 24.0,
      color: const Color(0xFF1E293B),
    );

    // Label under Bar 1
    _drawXAxisMultiLineLabel(
      canvas: canvas,
      centerX: bar1CenterX,
      y: baselineY + 12,
      line1: prescribedName,
      line2: '(Prescribed Medicine)',
      line1Color: const Color(0xFF0F172A),
      line2Color: const Color(0xFF0062FF),
    );

    // =======================================================================
    // BAR 2: ALTERNATIVE MEDICINE (GREEN)
    // =======================================================================
    final double curAltPct = altPct * animationProgress;
    final double bar2Height = (curAltPct / 100.0) * chartHeight;
    final double bar2Top = baselineY - bar2Height;

    final Rect bar2Rect = Rect.fromLTRB(
      bar2CenterX - (barWidth / 2),
      bar2Top,
      bar2CenterX + (barWidth / 2),
      baselineY,
    );

    final Paint bar2Paint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    // Draw Bar 2
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        bar2Rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      ),
      bar2Paint,
    );

    // Percentage text above Bar 2
    tp.text = TextSpan(
      text: '${altPct.toInt()}%',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: const Color(0xFF16A34A),
      ),
    );
    tp.layout();
    tp.paint(
      canvas,
      Offset(
        bar2CenterX - (tp.width / 2),
        (baselineY - ((altMax * animationProgress) / 100.0 * chartHeight)) - tp.height - 8,
      ),
    );

    // Error Whisker for Bar 2
    _drawErrorWhisker(
      canvas: canvas,
      centerX: bar2CenterX,
      baselineY: baselineY,
      chartHeight: chartHeight,
      minPct: altMin * animationProgress,
      maxPct: altMax * animationProgress,
      whiskerWidth: 24.0,
      color: const Color(0xFF1E293B),
    );

    // Label under Bar 2
    _drawXAxisMultiLineLabel(
      canvas: canvas,
      centerX: bar2CenterX,
      y: baselineY + 12,
      line1: altName,
      line2: '(Alternative Medicine)',
      line1Color: const Color(0xFF0F172A),
      line2Color: const Color(0xFF16A34A),
    );
  }

  void _drawErrorWhisker({
    required Canvas canvas,
    required double centerX,
    required double baselineY,
    required double chartHeight,
    required double minPct,
    required double maxPct,
    required double whiskerWidth,
    required Color color,
  }) {
    final double minY = baselineY - ((minPct / 100.0) * chartHeight);
    final double maxY = baselineY - ((maxPct / 100.0) * chartHeight);

    final Paint whiskerPaint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Vertical line connecting min to max
    canvas.drawLine(
      Offset(centerX, minY),
      Offset(centerX, maxY),
      whiskerPaint,
    );

    // Top whisker horizontal tick
    canvas.drawLine(
      Offset(centerX - (whiskerWidth / 2), maxY),
      Offset(centerX + (whiskerWidth / 2), maxY),
      whiskerPaint,
    );

    // Bottom whisker horizontal tick
    canvas.drawLine(
      Offset(centerX - (whiskerWidth / 2), minY),
      Offset(centerX + (whiskerWidth / 2), minY),
      whiskerPaint,
    );
  }

  void _drawXAxisMultiLineLabel({
    required Canvas canvas,
    required double centerX,
    required double y,
    required String line1,
    required String line2,
    required Color line1Color,
    required Color line2Color,
  }) {
    final TextPainter tp1 = TextPainter(
      text: TextSpan(
        text: line1,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: line1Color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp1.layout();
    tp1.paint(canvas, Offset(centerX - (tp1.width / 2), y));

    final TextPainter tp2 = TextPainter(
      text: TextSpan(
        text: line2,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: line2Color,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp2.layout();
    tp2.paint(canvas, Offset(centerX - (tp2.width / 2), y + tp1.height + 2));
  }

  @override
  bool shouldRepaint(covariant _TwoBarWhiskerChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.prescribedName != prescribedName ||
        oldDelegate.prescribedPct != prescribedPct ||
        oldDelegate.altName != altName ||
        oldDelegate.altPct != altPct;
  }
}

class _WhiskerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = const Color(0xFF475569)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final double midY = size.height / 2;

    // Horizontal line
    canvas.drawLine(Offset(2, midY), Offset(size.width - 2, midY), p);
    // Left tick
    canvas.drawLine(Offset(2, 2), Offset(2, size.height - 2), p);
    // Right tick
    canvas.drawLine(
        Offset(size.width - 2, 2), Offset(size.width - 2, size.height - 2), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
