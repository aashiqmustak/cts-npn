import '../theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../widgets/bento_card.dart';

class DoctorOverviewDashboardScreen extends StatefulWidget {
  const DoctorOverviewDashboardScreen({super.key});

  @override
  State<DoctorOverviewDashboardScreen> createState() =>
      _DoctorOverviewDashboardScreenState();
}

class _DoctorOverviewDashboardScreenState
    extends State<DoctorOverviewDashboardScreen> {
  int _selectedTimeRangeIndex = 0; // 0: 7 Days, 1: 30 Days, 2: 90 Days

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

          const SizedBox(height: 20),

          // 2. Core Telemetry Bento Grid (4 Summary Cards)
          _buildTelemetryBentoGrid(appState),

          const SizedBox(height: 20),

          // 3. Dual Interactive Chart Analytics Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 940;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildPatientVolumeLineChart(appState)),
                    const SizedBox(width: 18),
                    Expanded(flex: 5, child: _buildDrugClassDistributionChart(appState)),
                  ],
                );
              }
              return Column(
                children: [
                  _buildPatientVolumeLineChart(appState),
                  const SizedBox(height: 18),
                  _buildDrugClassDistributionChart(appState),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 4. Clinical Appointments & Live e-Rx Transmission Queue
          _buildTodaysPatientQueue(appState),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- Executive Header Banner ---
  Widget _buildExecutiveHeader(
    BuildContext context,
    AppState appState, {
    required String doctorName,
    required String hospitalName,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Doctor Avatar Icon
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
                  size: 28,
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
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF10B981), size: 13),
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
                    const SizedBox(height: 4),
                    Text(
                      '$hospitalName — Cardiology & Internal Medicine',
                      style: AppFonts.googleSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Quick e-Rx Action Button
              ElevatedButton.icon(
                onPressed: () {
                  appState.setNavIndex(1); // Navigate to Issue Prescription
                },
                icon: const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                label: Text(
                  '+ Issue Quick e-Rx',
                  style: AppFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1244A2),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Core Telemetry Bento Grid ---
  Widget _buildTelemetryBentoGrid(AppState appState) {
    final user = appState.currentUser;
    final consultationsToday = appState.dataService.getDoctorConsultationsToday(user.doctorId);
    final totalPrescriptions = appState.prescriptions.length;
    final avgPdc = appState.dataService.getDoctorAveragePdc(user.doctorId);
    final pendingPa = appState.dataService.getDoctorPendingPaCount(user.doctorId);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);

        final items = [
          _telemetryCard(
            title: 'Consultations Today',
            value: '$consultationsToday Patients',
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
            value: '${(avgPdc * 100).toStringAsFixed(1)}% PDC',
            change: avgPdc >= 0.80 ? '★ 5-Star Compliant' : '⚠️ Action Required',
            isPositive: avgPdc >= 0.80,
            icon: Icons.insights_rounded,
            accentColor: const Color(0xFF8B5CF6),
          ),
          _telemetryCard(
            title: 'Prior Auth Friction',
            value: '$pendingPa Pending Review',
            change: pendingPa == 0 ? '0 Bottlenecks' : '$pendingPa In Queue',
            isPositive: pendingPa == 0,
            icon: Icons.security_rounded,
            accentColor: const Color(0xFFF59E0B),
          ),
        ];

        if (crossAxisCount == 4) {
          return Row(
            children: items.map((card) => Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: card,
            ))).toList(),
          );
        } else if (crossAxisCount == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 12),
                  Expanded(child: items[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: items[2]),
                  const SizedBox(width: 12),
                  Expanded(child: items[3]),
                ],
              ),
            ],
          );
        }

        return Column(
          children: items
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  change,
                  style: AppFonts.googleSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
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
          ),
        ],
      ),
    );
  }

  // --- Chart 1: Dynamic Patient Volume & e-Rx Line Chart ---
  Widget _buildPatientVolumeLineChart(AppState appState) {
    final days = _selectedTimeRangeIndex == 0 ? 7 : (_selectedTimeRangeIndex == 1 ? 14 : 30);
    final velocityData = appState.dataService.getDoctorPrescriptionVelocity(appState.currentUser.doctorId, 7);

    final spots1 = List.generate(
      velocityData.length,
      (i) => FlSpot(i.toDouble(), velocityData[i] + 4.0),
    );

    final spots2 = List.generate(
      velocityData.length,
      (i) => FlSpot(i.toDouble(), velocityData[i]),
    );

    return BentoCard(
      title: 'Patient Consultations & e-Rx Velocity',
      subtitle: 'Live volume trends over the past ${_selectedTimeRangeIndex == 0 ? "7 Days" : (_selectedTimeRangeIndex == 1 ? "30 Days" : "90 Days")}',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1244A2).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.show_chart_rounded,
            color: Color(0xFF1244A2), size: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _rangeFilterChip('7D', 0),
          const SizedBox(width: 4),
          _rangeFilterChip('30D', 1),
          const SizedBox(width: 4),
          _rangeFilterChip('90D', 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: AppFonts.googleSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const daysLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < daysLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              daysLabels[value.toInt()],
                              style: AppFonts.googleSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
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
                maxX: 6,
                minY: 0,
                maxY: 30,
                lineBarsData: [
                  // Line 1: Consultations (Sapphire Blue)
                  LineChartBarData(
                    spots: spots1,
                    isCurved: true,
                    color: const Color(0xFF1244A2),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                    ),
                  ),
                  // Line 2: e-Prescriptions Broadcast (Electric Mint)
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF1244A2), 'Patient Consultations'),
              const SizedBox(width: 24),
              _legendDot(const Color(0xFF10B981), 'e-Prescriptions Broadcast'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeFilterChip(String label, int index) {
    final isSelected = _selectedTimeRangeIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeRangeIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1244A2) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
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

  // --- Chart 2: Dynamic Drug Class Distribution ---
  Widget _buildDrugClassDistributionChart(AppState appState) {
    final classDist = appState.dataService.getDoctorDrugClassDistribution(appState.currentUser.doctorId);
    final colors = [
      const Color(0xFF1244A2),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
    ];

    final sections = <PieChartSectionData>[];
    final legendEntries = <Widget>[];

    int colorIdx = 0;
    classDist.forEach((className, pct) {
      final color = colors[colorIdx % colors.length];
      sections.add(
        PieChartSectionData(
          color: color,
          value: pct,
          title: '${pct.toStringAsFixed(0)}%',
          radius: 45,
          titleStyle: AppFonts.googleSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
      legendEntries.add(
        _legendDot(color, '$className (${pct.toStringAsFixed(0)}%)'),
      );
      colorIdx++;
    });

    return BentoCard(
      title: 'Prescribed Therapeutic Classes',
      subtitle: 'Distribution of active clinical regimens',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.pie_chart_rounded,
            color: Color(0xFF8B5CF6), size: 18),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: sections,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: legendEntries,
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
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

  // --- Today's Patient Queue Widget ---
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
        child: const Icon(Icons.person_search_rounded,
            color: Color(0xFF10B981), size: 18),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          if (patients.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No registered patient consultations scheduled.',
                style: AppFonts.googleSans(
                    fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: patients.length.clamp(0, 4),
              separatorBuilder: (context, index) =>
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) {
                final p = patients[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: index == 0
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      index == 0 ? 'Ready for e-Rx' : 'In Consultation',
                      style: AppFonts.googleSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: index == 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFF64748B),
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
}
