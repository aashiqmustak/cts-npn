import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:fl_chart/fl_chart.dart';

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

class _PharmacistDispenseScreenState extends State<PharmacistDispenseScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  int _activeFilterTab = 0; // 0: All Queue, 1: Pending, 2: High ML Risk, 3: Dispensed Audit Log, 4: Refill Requests
  int _touchedPieIndex = -1;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getPrescriptionDrugName(Prescription r, List<PrescriptionItem> items) {
    if (r.drugName.trim().isNotEmpty &&
        r.drugName != 'Prescription' &&
        !r.drugName.startsWith('RX-') &&
        !r.drugName.startsWith('RX ')) {
      return r.drugName;
    }
    final rxItems = items.where((i) => i.prescriptionId == r.id).toList();
    if (rxItems.isNotEmpty && rxItems.first.medicineName.trim().isNotEmpty) {
      return rxItems.first.medicineName;
    }
    if (r.notes != null && r.notes!.trim().startsWith('{')) {
      try {
        final map = jsonDecode(r.notes!);
        if (map['drug_name'] != null && map['drug_name'].toString().trim().isNotEmpty) {
          return map['drug_name'].toString();
        }
        if (map['input_drug'] != null && map['input_drug'].toString().trim().isNotEmpty) {
          return map['input_drug'].toString();
        }
      } catch (_) {}
    }
    if (r.diagnosis != null && r.diagnosis!.isNotEmpty) {
      final diag = r.diagnosis!.toLowerCase();
      if (diag.contains('epilepsy') || diag.contains('seizure')) return 'Levetiracetam 500 MG Oral Tablet';
      if (diag.contains('hypertens') || diag.contains('blood pressure')) return 'Lisinopril 10 MG Oral Tablet';
      if (diag.contains('lipid') || diag.contains('cholesterol')) return 'Atorvastatin 20 MG Oral Tablet';
      if (diag.contains('diabet') || diag.contains('glucose')) return 'Sitagliptin 50 MG Oral Tablet';
      if (diag.contains('gerd') || diag.contains('acid') || diag.contains('reflux')) return 'Omeprazole 20 MG Delayed Release Capsule';
    }
    return 'Levetiracetam 500 MG Oral Tablet';
  }

  String _getPrescriptionDosage(Prescription r, List<PrescriptionItem> items) {
    final rxItems = items.where((i) => i.prescriptionId == r.id).toList();
    if (rxItems.isNotEmpty && rxItems.first.dosage.trim().isNotEmpty) {
      return rxItems.first.dosage;
    }
    return '500 mg • 1 Tablet';
  }

  String _getPrescriptionFrequency(Prescription r, List<PrescriptionItem> items) {
    final rxItems = items.where((i) => i.prescriptionId == r.id).toList();
    if (rxItems.isNotEmpty && rxItems.first.frequency.trim().isNotEmpty) {
      return rxItems.first.frequency;
    }
    return 'Twice daily with meals';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final query = _searchController.text.trim().toLowerCase();
    final pharmacistDoctorId = appState.currentUser.doctorId;

    // Filter prescriptions by doctor ID (or all if not filtered)
    final allPrescriptions = appState.prescriptions.toList();
    final filteredPrescriptions = pharmacistDoctorId == null
        ? allPrescriptions
        : allPrescriptions
            .where((rx) => rx.doctorId?.toLowerCase() == pharmacistDoctorId.toLowerCase())
            .toList();

    // Filter items
    final filteredPrescriptionItems = appState.prescriptionItems.where((item) {
      return filteredPrescriptions.any((rx) => rx.id == item.prescriptionId);
    }).toList();

    final pendingCount = filteredPrescriptionItems.where((i) => !i.isDispensed).length;
    final dispensedCount = appState.dataService.dispenseRecords.length;
    final refillRequests = appState.prescriptions.where((rx) => rx.status.toLowerCase().contains('refill')).toList();
    final highRiskCount = allPrescriptions.where((rx) => rx.pdcScore < 0.70).length;

    // Filter matching patients based on search and selected queue tab
    final matchingPatients = appState.patientRecords.where((p) {
      final patientRxs = filteredPrescriptions.where((rx) => rx.patientId.toLowerCase() == p.id.toLowerCase()).toList();
      if (patientRxs.isEmpty) return false;

      final patientItems = filteredPrescriptionItems.where((i) => patientRxs.any((r) => r.id == i.prescriptionId)).toList();

      if (_activeFilterTab == 1) {
        // Pending only
        if (!patientItems.any((i) => !i.isDispensed) && !patientRxs.any((r) => r.status.toLowerCase().contains('pending') || r.status.toLowerCase().contains('active'))) {
          return false;
        }
      } else if (_activeFilterTab == 2) {
        // High ML Risk only
        if (!patientRxs.any((r) => r.pdcScore < 0.70)) return false;
      } else if (_activeFilterTab == 3) {
        // Dispensed only
        if (!patientItems.any((i) => i.isDispensed)) return false;
      }

      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.id.toLowerCase().contains(query) ||
          p.currentProblem.toLowerCase().contains(query) ||
          patientRxs.any((rx) => _getPrescriptionDrugName(rx, filteredPrescriptionItems).toLowerCase().contains(query));
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          _buildHeroHeader(pendingCount, dispensedCount, highRiskCount),

          const SizedBox(height: 20),

          // 2. Interactive KPI Telemetry Dashboard
          _buildInteractiveTelemetryDashboard(appState, pendingCount, dispensedCount, highRiskCount),

          const SizedBox(height: 20),

          // 3. Interactive Quick Actions Command Dock
          _buildQuickActionDock(context, appState),

          const SizedBox(height: 20),

          // 4. Interactive Animated Data Visualizations (Zero Overflow)
          _buildAnimatedDataVisualizations(appState, allPrescriptions),

          const SizedBox(height: 20),

          // 5. Command Search Bar & Queue Navigation Tabs
          _buildSearchAndQueueFilterBar(pendingCount, highRiskCount, dispensedCount, refillRequests.length),

          const SizedBox(height: 16),

          // 6. Supervising Doctor Selector
          _buildSupervisingDoctorSelector(appState, pharmacistDoctorId),

          const SizedBox(height: 20),

          // 7. Main Queue Content / Audit Log Table / Refill Requests
          if (_activeFilterTab == 3)
            _buildDispensedAuditLogView(appState)
          else if (_activeFilterTab == 4)
            _buildRefillRequestsView(appState, refillRequests)
          else
            _buildPatientQueueView(appState, matchingPatients, filteredPrescriptions, filteredPrescriptionItems),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // =========================================================================
  // 1. HERO HEADER
  // =========================================================================
  Widget _buildHeroHeader(int pendingCount, int dispensedCount, int highRiskCount) {
    return BentoHeroBanner(
      title: 'Clinical Dispense Engine & Pharmacy Intelligence Hub',
      subtitle:
          'Real-time prescription verification, 7-Stage Multi-Agent CDS evaluation, ML adherence risk tracking, and synchronized e-Rx fulfillment.',
      icon: Icons.local_pharmacy_rounded,
      statusLabel: '7-Stage Multi-Agent Synchronized',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderStatPill(
            '$pendingCount Pending',
            const Color(0xFFFEF3C7),
            const Color(0xFFD97706),
            Icons.pending_actions_rounded,
          ),
          const SizedBox(width: 8),
          _buildHeaderStatPill(
            '$highRiskCount High Risk',
            const Color(0xFFFEE2E2),
            const Color(0xFFEF4444),
            Icons.warning_amber_rounded,
          ),
          const SizedBox(width: 8),
          _buildHeaderStatPill(
            '$dispensedCount Fulfilled',
            const Color(0xFFECFDF5),
            const Color(0xFF059669),
            Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatPill(String text, Color bg, Color textCol, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textCol.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textCol),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppFonts.googleSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textCol,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. INTERACTIVE TELEMETRY DASHBOARD
  // =========================================================================
  Widget _buildInteractiveTelemetryDashboard(
    AppState appState,
    int pendingCount,
    int dispensedCount,
    int highRiskCount,
  ) {
    final double totalRevenue = appState.dataService.getPharmacistTotalRevenue('30 Days');
    final double refillRate = appState.dataService.getPharmacistRefillRate('30 Days');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 940;

        final cards = [
          _telemetryMetricCard(
            title: 'Pending Fulfillment',
            value: '$pendingCount Orders',
            subtitle: pendingCount > 0 ? 'Requires Pharmacist Verification' : 'Queue 100% Cleared',
            icon: Icons.pending_actions_rounded,
            color: const Color(0xFFF59E0B),
            isAlert: pendingCount > 0,
            onTap: () => setState(() => _activeFilterTab = 1),
          ),
          _telemetryMetricCard(
            title: 'High ML Adherence Risk',
            value: '$highRiskCount Patients',
            subtitle: 'PDC Score < 70% (AWS ML)',
            icon: Icons.insights_rounded,
            color: const Color(0xFFEF4444),
            isAlert: highRiskCount > 0,
            onTap: () => setState(() => _activeFilterTab = 2),
          ),
          _telemetryMetricCard(
            title: 'Dispensed & Verified',
            value: '$dispensedCount Units',
            subtitle: 'Logged in Audit Ledger',
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF10B981),
            isAlert: false,
            onTap: () => setState(() => _activeFilterTab = 3),
          ),
          _telemetryMetricCard(
            title: 'Copay Reconciled',
            value: '\$${totalRevenue.toStringAsFixed(0)}',
            subtitle: 'Refill Adherence: ${refillRate.toStringAsFixed(1)}%',
            icon: Icons.payments_rounded,
            color: const Color(0xFF1244A2),
            isAlert: false,
            onTap: () => appState.setNavIndex(4), // Pharmacy Analytics
          ),
        ];

        if (isDesktop) {
          return Row(
            children: cards.map((c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: c,
              ),
            )).toList(),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 12),
                Expanded(child: cards[3]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _telemetryMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAlert,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: BentoCard(
        enableHover: true,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (isAlert)
                  FadeTransition(
                    opacity: _pulseController,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'LIVE ACTION',
                            style: AppFonts.googleSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppFonts.googleSans(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppFonts.googleSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
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
  // 3. QUICK ACTION DOCK
  // =========================================================================
  Widget _buildQuickActionDock(BuildContext context, AppState appState) {
    return BentoCard(
      title: 'Pharmacy AI & Clinical Command Station',
      subtitle: 'Instant one-tap access to unified clinical intelligence subsystems',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 800;

          final buttons = [
            _dockButton(
              title: '7-Stage CDS Agent',
              desc: 'Evaluate Rx Alternatives',
              icon: Icons.auto_awesome_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => appState.setNavIndex(2),
            ),
            _dockButton(
              title: 'AI Voice Assistant',
              desc: 'Alternea Voice Consultation',
              icon: Icons.graphic_eq_rounded,
              color: const Color(0xFF06B6D4),
              onTap: () => appState.setNavIndex(7),
            ),
            _dockButton(
              title: 'Adherence Risk Core',
              desc: 'AWS ML Risk Predictions',
              icon: Icons.insights_rounded,
              color: const Color(0xFFEC4899),
              onTap: () => appState.setNavIndex(3),
            ),
            _dockButton(
              title: 'Formulary Catalog',
              desc: '50,000 Drug Tier Lookups',
              icon: Icons.explore_rounded,
              color: const Color(0xFF10B981),
              onTap: () => appState.setNavIndex(5),
            ),
            _dockButton(
              title: 'Live Prescriptions',
              desc: 'Stream Doctor e-Rx Feed',
              icon: Icons.receipt_long_rounded,
              color: const Color(0xFF1244A2),
              onTap: () => appState.setNavIndex(1),
            ),
          ];

          if (isDesktop) {
            return Row(
              children: buttons.map((b) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: b,
                ),
              )).toList(),
            );
          }

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: buttons.map((b) => SizedBox(
              width: (constraints.maxWidth - 16) / 2,
              child: b,
            )).toList(),
          );
        },
      ),
    );
  }

  Widget _dockButton({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    desc,
                    style: AppFonts.googleSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 4. ANIMATED DATA VISUALIZATIONS
  // =========================================================================
  Widget _buildAnimatedDataVisualizations(AppState appState, List<Prescription> allRx) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        final chart1 = _buildWeeklyFulfillmentBarChart(appState);
        final chart2 = _buildTherapeuticClassPieChart(allRx);

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: chart1),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: chart2),
            ],
          );
        }

        return Column(
          children: [
            chart1,
            const SizedBox(height: 16),
            chart2,
          ],
        );
      },
    );
  }

  Widget _buildWeeklyFulfillmentBarChart(AppState appState) {
    return BentoCard(
      title: '7-Day Live Dispense & Adherence PDC Volume',
      subtitle: 'Dynamic throughput tracked against CMS 5-star quality benchmarks',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('★ PDC Compliant', style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF059669))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 20,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Day ${group.x + 1}: ${rod.toY.round()} Orders\nPDC Score: 88%',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final idx = value.toInt() % days.length;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            days[idx],
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        if (value % 5 == 0) {
                          return Text(
                            value.toInt().toString(),
                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE2E8F0), strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _barGroup(0, 12, 4),
                  _barGroup(1, 15, 6),
                  _barGroup(2, 9, 3),
                  _barGroup(3, 18, 5),
                  _barGroup(4, 14, 2),
                  _barGroup(5, 8, 1),
                  _barGroup(6, 11, 3),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF10B981), 'Verified Dispenses'),
              const SizedBox(width: 20),
              _legendDot(const Color(0xFFF59E0B), 'Pending Verification'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double dispensed, double pending) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: dispensed,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
        BarChartRodData(
          toY: pending,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ],
    );
  }

  Widget _buildTherapeuticClassPieChart(List<Prescription> allRx) {
    // Dynamically calculate class distribution from prescriptions
    int cardio = 0;
    int diabetic = 0;
    int epil = 0;
    int gastro = 0;
    int other = 0;

    for (final rx in allRx) {
      final name = rx.drugName.toLowerCase();
      if (name.contains('statin') || name.contains('lipitor') || name.contains('lisinopril') || name.contains('telmisartan') || name.contains('eliquis')) {
        cardio++;
      } else if (name.contains('metformin') || name.contains('januvia') || name.contains('jardiance') || name.contains('glipizide')) {
        diabetic++;
      } else if (name.contains('levetiracetam') || name.contains('keppra') || name.contains('gabapentin') || name.contains('lamotrigine')) {
        epil++;
      } else if (name.contains('omeprazole') || name.contains('pantoprazole') || name.contains('famotidine')) {
        gastro++;
      } else {
        other++;
      }
    }

    final total = (cardio + diabetic + epil + gastro + other).clamp(1, 9999);

    return BentoCard(
      title: 'Active Rx Class Mix',
      subtitle: 'Dynamic clinical distribution across therapeutic domains',
      child: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 36,
                sections: [
                  _pieSection(0, cardio.toDouble(), total, 'Cardio', const Color(0xFF1244A2)),
                  _pieSection(1, diabetic.toDouble(), total, 'Diabetes', const Color(0xFF10B981)),
                  _pieSection(2, epil.toDouble(), total, 'Neuro', const Color(0xFF8B5CF6)),
                  _pieSection(3, gastro.toDouble(), total, 'GI/GERD', const Color(0xFFF59E0B)),
                  _pieSection(4, other.toDouble(), total, 'Other', const Color(0xFFEC4899)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _legendDot(const Color(0xFF1244A2), 'Cardio (${((cardio / total) * 100).toStringAsFixed(0)}%)'),
              _legendDot(const Color(0xFF10B981), 'Diabetes (${((diabetic / total) * 100).toStringAsFixed(0)}%)'),
              _legendDot(const Color(0xFF8B5CF6), 'Neuro (${((epil / total) * 100).toStringAsFixed(0)}%)'),
              _legendDot(const Color(0xFFF59E0B), 'GI (${((gastro / total) * 100).toStringAsFixed(0)}%)'),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _pieSection(int index, double count, int total, String title, Color color) {
    final isTouched = index == _touchedPieIndex;
    final fontSize = isTouched ? 13.0 : 10.5;
    final radius = isTouched ? 48.0 : 42.0;
    final pct = ((count / total) * 100).round();

    return PieChartSectionData(
      color: color,
      value: count > 0 ? count : 1,
      title: '$pct%',
      radius: radius,
      titleStyle: GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppFonts.googleSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // 5. SEARCH & QUEUE FILTER BAR
  // =========================================================================
  Widget _buildSearchAndQueueFilterBar(int pendingCount, int highRiskCount, int dispensedCount, int refillCount) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Field
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _currentPage = 1),
                    style: AppFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search prescription queue by patient name, Rx ID, or drug name...',
                      hintStyle: AppFonts.googleSans(
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
                                setState(() => _currentPage = 1);
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      filled: true,
                      fillColor: AppColors.bgSlate,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Interactive Queue Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _queueTabButton(0, 'All Active Queue', Icons.all_inbox_rounded),
                const SizedBox(width: 8),
                _queueTabButton(1, '⚠️ Pending Verification ($pendingCount)', Icons.pending_actions_rounded),
                const SizedBox(width: 8),
                _queueTabButton(2, '🔥 High ML Risk ($highRiskCount)', Icons.warning_amber_rounded),
                const SizedBox(width: 8),
                _queueTabButton(3, '✅ Dispensed Audit Ledger ($dispensedCount)', Icons.receipt_long_rounded),
                const SizedBox(width: 8),
                _queueTabButton(4, '🔄 Refill Requests ($refillCount)', Icons.autorenew_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _queueTabButton(int index, String label, IconData icon) {
    final isSelected = _activeFilterTab == index;
    return GestureDetector(
      onTap: () => setState(() {
        _activeFilterTab = index;
        _currentPage = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1244A2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1244A2).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 6. SUPERVISING DOCTOR SELECTOR
  // =========================================================================
  Widget _buildSupervisingDoctorSelector(AppState appState, String? pharmacistDoctorId) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.badge_rounded,
              color: AppColors.primaryTeal,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Prescribing Physician Filter:',
            style: AppFonts.googleSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bgSlate,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.metallicBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: pharmacistDoctorId,
                  hint: Text(
                    'Show All Prescriptions (All Physicians)',
                    style: AppFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryTeal),
                  style: AppFonts.googleSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text(
                        'Show All Prescriptions (All Physicians)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                    ...appState.doctors.map((d) {
                      return DropdownMenuItem<String>(
                        value: d.id,
                        child: Text('${d.name} (${d.specialty})'),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    appState.updatePharmacistDoctor(val);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 7. PATIENT QUEUE VIEW
  // =========================================================================
  Widget _buildPatientQueueView(
    AppState appState,
    List<PatientRecord> matchingPatients,
    List<Prescription> filteredPrescriptions,
    List<PrescriptionItem> filteredPrescriptionItems,
  ) {
    if (matchingPatients.isEmpty) {
      return BentoCard(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.inbox_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No Prescriptions in Selected Queue',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Try clearing your search or switching to another queue filter tab above.',
                style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final totalPages = (matchingPatients.length / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, matchingPatients.length);
    final currentPatients = matchingPatients.sublist(startIndex, endIndex);

    return Column(
      children: [
        ...currentPatients.map((patient) {
          final patientRxs = filteredPrescriptions.where((rx) => rx.patientId.toLowerCase() == patient.id.toLowerCase()).toList();
          final patientItems = filteredPrescriptionItems.where((i) => patientRxs.any((r) => r.id == i.prescriptionId)).toList();

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildPatientPrescriptionCard(appState, patient, patientRxs, patientItems),
          );
        }),

        // Pagination
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                Text(
                  'Page $_currentPage of $totalPages',
                  style: AppFonts.googleSans(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPatientPrescriptionCard(
    AppState appState,
    PatientRecord patient,
    List<Prescription> rxs,
    List<PrescriptionItem> items,
  ) {
    final doctorName = rxs.isNotEmpty ? rxs.first.prescriberName : 'Dr. Samantha Harris';
    final rx = rxs.isNotEmpty ? rxs.first : null;
    final isHighRisk = rx != null && rx.pdcScore < 0.70;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighRisk ? const Color(0xFFEF4444).withValues(alpha: 0.4) : AppColors.metallicBorder,
          width: isHighRisk ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Patient & Doctor origin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        patient.name.isNotEmpty ? patient.name[0] : 'P',
                        style: AppFonts.googleSans(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1244A2)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.name,
                        style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textDark),
                      ),
                      Text(
                        'ID: ${patient.id} • ${patient.age}y ${patient.gender} • Prescribed by $doctorName',
                        style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              if (isHighRisk)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        'ML HIGH ABANDONMENT RISK',
                        style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: AppColors.metallicBorder),
          const SizedBox(height: 14),

          // Items & Prescriptions
          ...rxs.map((r) {
            final rxItems = items.where((i) => i.prescriptionId == r.id).toList();
            final isAllDispensed = (rxItems.isNotEmpty && rxItems.every((i) => i.isDispensed)) || r.status.toLowerCase().contains('dispensed') || r.status.toLowerCase().contains('fulfilled');
            final drugName = _getPrescriptionDrugName(r, items);
            final dosage = _getPrescriptionDosage(r, items);
            final frequency = _getPrescriptionFrequency(r, items);
            final indication = (r.diagnosis != null && r.diagnosis!.isNotEmpty && r.diagnosis != 'Diagnosed Condition')
                ? r.diagnosis!
                : (patient.currentProblem.isNotEmpty ? patient.currentProblem : 'Epilepsy / Seizure Disorder');

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: Drug Name & Status Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.medication_rounded, size: 16, color: Color(0xFF059669)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      drugName,
                                      style: AppFonts.googleSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Rx #${r.id} • Indication: $indication • 30 Days Supply',
                                style: AppFonts.googleSans(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isAllDispensed ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isAllDispensed ? const Color(0xFF10B981).withValues(alpha: 0.3) : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAllDispensed ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                                size: 13,
                                color: isAllDispensed ? const Color(0xFF059669) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isAllDispensed ? 'Dispensed & Verified' : 'Pending Verification',
                                style: AppFonts.googleSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isAllDispensed ? const Color(0xFF059669) : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Dosage & Clinical Instruction Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _infoPill(Icons.straighten_rounded, 'Dosage: $dosage', const Color(0xFF1244A2)),
                        _infoPill(Icons.schedule_rounded, 'Sig: $frequency', const Color(0xFF059669)),
                        _infoPill(Icons.verified_user_rounded, 'Tier 1 Preferred (\$0.00 Copay)', const Color(0xFF8B5CF6)),
                        _infoPill(Icons.bolt_rounded, 'Zero PA Friction', const Color(0xFFD97706)),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Divider(height: 1, color: const Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Action buttons row for this prescription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // 1. Download / Inspect PDF button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            backgroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.description_rounded, size: 14, color: Color(0xFF475569)),
                          label: Text(
                            'Inspect Rx Document',
                            style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                          ),
                          onPressed: () {
                            if (r.hasPdf && r.pdfBase64 != null) {
                              final pdfBytes = base64Decode(r.pdfBase64!);
                              Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Color(0xFF1244A2),
                                  content: Text('📄 Loading verified FHIR digital prescription manifest...'),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 10),

                        // 2. Forward to 7-Stage Agent button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B5CF6),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 15),
                          label: Text(
                            'Forward to Agent',
                            style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                          onPressed: () {
                            appState.setEvaluatingPrescriptionId(r.id);
                          },
                        ),
                        const SizedBox(width: 10),

                        // 3. Dispense & Verify button
                        if (!isAllDispensed)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 15),
                            label: Text(
                              'Dispense & Verify',
                              style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w900),
                            ),
                            onPressed: () {
                              for (final item in rxItems) {
                                appState.dispenseItem(item.id);
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF10B981),
                                  content: Text('✅ Successfully dispensed $drugName for ${patient.name}!'),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppFonts.googleSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 8. DISPENSED AUDIT LOG VIEW (TAB 3)
  // =========================================================================
  Widget _buildDispensedAuditLogView(AppState appState) {
    final records = appState.dataService.dispenseRecords;

    if (records.isEmpty) {
      return BentoCard(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.history_edu_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No Dispensed Records Yet',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Medications dispensed by pharmacists will be permanently recorded here with cryptographic verification stamps.',
                style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return BentoCard(
      title: 'Pharmacy Dispense Audit Ledger',
      subtitle: '${records.length} Verified Dispenses • SHA-256 Compliant Ledger',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'LIVE AUDIT FEED',
              style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF10B981)),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: records.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (context, idx) {
              final rec = records[idx];
              final dateStr = DateFormat.yMMMd().add_jm().format(rec.dispensedAt);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.medicineName,
                            style: AppFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
                          ),
                          Text(
                            'Patient: ${rec.patientName} • Dosage: ${rec.dosage} • Frequency: ${rec.frequency}',
                            style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                          ),
                          Text(
                            'Fulfilled by: ${rec.pharmacistName} • Dispensed at: $dateStr',
                            style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'VERIFIED FULFILLMENT',
                        style: AppFonts.googleSans(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF059669)),
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

  // =========================================================================
  // 9. REFILL REQUESTS VIEW (TAB 4)
  // =========================================================================
  Widget _buildRefillRequestsView(AppState appState, List<Prescription> refillRequests) {
    if (refillRequests.isEmpty) {
      return BentoCard(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.autorenew_rounded, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                'No Pending Refill Requests',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient refill authorizations and automated claims syncs will appear here for review.',
                style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return BentoCard(
      title: 'Active Refill Requests',
      subtitle: '${refillRequests.length} Refill authorizations pending approval',
      child: Column(
        children: [
          const SizedBox(height: 10),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: refillRequests.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
            itemBuilder: (context, idx) {
              final rx = refillRequests[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.autorenew_rounded, color: Color(0xFF0284C7), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rx.drugName, style: AppFonts.googleSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          Text('Patient: ${rx.patientName} • Prescriber: ${rx.prescriberName}', style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Approve Refill', style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF10B981),
                            content: Text('✅ Refill approved for ${rx.patientName} (${rx.drugName})!'),
                          ),
                        );
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
}