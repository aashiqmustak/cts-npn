import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class DashboardOverviewScreen extends StatefulWidget {
  const DashboardOverviewScreen({super.key});

  @override
  State<DashboardOverviewScreen> createState() =>
      _DashboardOverviewScreenState();
}

class _DashboardOverviewScreenState extends State<DashboardOverviewScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _entranceController;
  late final AnimationController _idleWaveController;
  late final AnimationController _chartAnimationController;
  late final AnimationController _lineProgressController;

  double _scrollOffset = 0.0;
  String _selectedTimeframe = '30 Days';

  final List<String> _timeframeOptions = [
    '24 Hours',
    '7 Days',
    '30 Days',
    '90 Days',
    'YTD',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _idleWaveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _lineProgressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _entranceController.dispose();
    _idleWaveController.dispose();
    _chartAnimationController.dispose();
    _lineProgressController.dispose();
    super.dispose();
  }

  void _replayAnimations() {
    _entranceController.reset();
    _chartAnimationController.reset();
    _lineProgressController.reset();

    _entranceController.forward();
    _chartAnimationController.forward();
    _lineProgressController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final totalRx = appState.prescriptions.length * 120 + 480;
    final totalPatients = appState.patientRecords.length * 45 + 180;

    return Stack(
      children: [
        // -----------------------------------------------------------------
        // Kinetic Background Vector Mesh Layer (Scroll & Wave Driven)
        // -----------------------------------------------------------------
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _idleWaveController,
            builder: (context, child) {
              return CustomPaint(
                painter: _DoctorMeshBackgroundPainter(
                  scrollOffset: _scrollOffset,
                  wavePhase: _idleWaveController.value * 2 * math.pi,
                ),
              );
            },
          ),
        ),

        // -----------------------------------------------------------------
        // Main Scroll-Linked Clinical Reports Viewport
        // -----------------------------------------------------------------
        SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------------------------------------------------------------
              // Header Bento Banner with Timeframe Filter Bar
              // -------------------------------------------------------------
              _DoctorScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 0,
                child: BentoHeroBanner(
                  title: 'Physician Clinical Intelligence & Diagnostics Matrix',
                  subtitle:
                      'Advanced clinical telemetry: Dual-axis prescribing trends, 6-axis competency radar, referral node mesh, and PDC scatter dispersion heatmap.',
                  icon: Icons.medical_services_rounded,
                  statusLabel: 'Clinical Engine Synchronized',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _timeframeOptions.map((tf) {
                            final isSel = _selectedTimeframe == tf;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedTimeframe = tf);
                                _replayAnimations();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Text(
                                  tf,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: isSel
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isSel
                                        ? AppColors.primaryDark
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 10),

                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded,
                            size: 14, color: Colors.white),
                        label: Text(
                          'Replay',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                        ),
                        onPressed: _replayAnimations,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // Top Clinical Counting Metric Cards Grid (TweenAnimationBuilder)
              // -------------------------------------------------------------
              _DoctorScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 40,
                child: _buildClinicalStatsCounterGrid(totalRx, totalPatients),
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------------------
              // FIRST ROW: DUAL-AXIS LINE GRAPH & 6-AXIS RADAR CHART
              // -------------------------------------------------------------
              _DoctorScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 90,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final dualAxisCard = _buildDoctorDualAxisGraph();
                    final radarCard = _buildDoctorRadarChart();

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: dualAxisCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: radarCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        dualAxisCard,
                        const SizedBox(height: 16),
                        radarCard,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // SECOND ROW (SCROLL DOWN): CLINICAL REFERRAL NETWORK NODE GRAPH
              // -------------------------------------------------------------
              _DoctorScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 200,
                child: _buildDoctorNetworkNodeGraphCard(),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // THIRD ROW (SCROLL FURTHER): PATIENT RISK SCATTER HEATMAP MATRIX
              // -------------------------------------------------------------
              _DoctorScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 340,
                child: _buildDoctorScatterPlotMatrixCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 1. TOP STATS COUNTER ROW (TweenAnimationBuilder)
  // ---------------------------------------------------------------------
  Widget _buildClinicalStatsCounterGrid(int totalRx, int totalPatients) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final tiles = [
          _buildDoctorMetricTile(
            label: 'e-Prescriptions Issued',
            targetValue: totalRx.toDouble(),
            prefix: '',
            suffix: ' e-Rx',
            isCurrency: false,
            trendText: '+18.4% MoM',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF00B4D8),
            iconBg: const Color(0xFFE0F7FA),
          ),
          _buildDoctorMetricTile(
            label: 'Clinical Registry Panel',
            targetValue: totalPatients.toDouble(),
            prefix: '',
            suffix: ' Patients',
            isCurrency: false,
            trendText: 'Active Caseload',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF00E676),
            iconBg: const Color(0xFFE8F5E9),
          ),
          _buildDoctorMetricTile(
            label: 'Mean PDC Adherence',
            targetValue: 89.2,
            prefix: '',
            suffix: '%',
            isCurrency: false,
            trendText: 'Optimal Tier',
            icon: Icons.favorite_rounded,
            iconColor: AppColors.primaryTeal,
            iconBg: AppColors.primaryLight,
          ),
          _buildDoctorMetricTile(
            label: 'Clinical Network Nodes',
            targetValue: 14.0,
            prefix: '',
            suffix: ' Connected',
            isCurrency: false,
            trendText: '99.9% Telemetry',
            icon: Icons.hub_rounded,
            iconColor: const Color(0xFF7209B7),
            iconBg: const Color(0xFFF3E5F5),
          ),
        ];

        if (isDesktop) {
          return Row(
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 12),
              Expanded(child: tiles[1]),
              const SizedBox(width: 12),
              Expanded(child: tiles[2]),
              const SizedBox(width: 12),
              Expanded(child: tiles[3]),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 12),
                Expanded(child: tiles[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: tiles[2]),
                const SizedBox(width: 12),
                Expanded(child: tiles[3]),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorMetricTile({
    required String label,
    required double targetValue,
    required String prefix,
    required String suffix,
    required bool isCurrency,
    required String trendText,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enableHover: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bgSlate,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.metallicBorder),
                ),
                child: Text(
                  trendText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: targetValue),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              String displayVal;
              if (suffix == '%') {
                displayVal = '${val.toStringAsFixed(1)}%';
              } else {
                displayVal = '${NumberFormat('#,###').format(val.toInt())}$suffix';
              }
              return Text(
                displayVal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FIRST ROW (LEFT): DUAL-AXIS LINE GRAPH (e-Rx Volume vs PA Days)
  // ---------------------------------------------------------------------
  Widget _buildDoctorDualAxisGraph() {
    return BentoCard(
      title: 'Dual-Axis: e-Rx Volume (Left) vs. PA Latency Days (Right)',
      subtitle: 'Correlation between monthly prescription volume and prior-authorization resolution speed',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.show_chart_rounded,
            color: Color(0xFF00B4D8), size: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendDot(
            label: 'e-Rx Volume (0-300)',
            color: const Color(0xFF00E676),
          ),
          const SizedBox(width: 10),
          _buildLegendDot(
            label: 'PA Days (0-15)',
            color: const Color(0xFF00B4D8),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _lineProgressController,
        builder: (context, child) {
          final progress = _lineProgressController.value.clamp(0.01, 1.0);

          final volumeSpots = [
            FlSpot(0, 85 * progress),
            FlSpot(1, 120 * progress),
            FlSpot(2, 155 * progress),
            FlSpot(3, 190 * progress),
            FlSpot(4, 225 * progress),
            FlSpot(5, 270 * progress),
          ];

          final paDaysSpots = [
            FlSpot(0, (14.2 * 20) * progress),
            FlSpot(1, (11.5 * 20) * progress),
            FlSpot(2, (8.8 * 20) * progress),
            FlSpot(3, (6.2 * 20) * progress),
            FlSpot(4, (4.1 * 20) * progress),
            FlSpot(5, (2.2 * 20) * progress),
          ];

          return SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 300,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 60,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderLight.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.accentNavy,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        if (spot.barIndex == 0) {
                          return LineTooltipItem(
                            'Volume: ${spot.y.toInt()} e-Rx\n',
                            GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00E676),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        } else {
                          final days = spot.y / 20.0;
                          return LineTooltipItem(
                            'PA Speed: ${days.toStringAsFixed(1)} Days\n',
                            GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00E5FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          );
                        }
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    axisNameWidget: Text(
                      'PA Days',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00B4D8)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 60,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        '${(val / 20).toInt()}d',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF00B4D8),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'e-Rx Count',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00E676)),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 60,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (val, meta) {
                        final months = [
                          'Jan',
                          'Feb',
                          'Mar',
                          'Apr',
                          'May',
                          'Jun'
                        ];
                        final idx = val.toInt();
                        if (idx >= 0 &&
                            idx < months.length &&
                            val == idx.toDouble()) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              months[idx],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: volumeSpots,
                    isCurved: true,
                    color: const Color(0xFF00E676),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00E676).withValues(alpha: 0.12),
                    ),
                  ),
                  LineChartBarData(
                    spots: paDaysSpots,
                    isCurved: true,
                    color: const Color(0xFF00B4D8),
                    barWidth: 3.5,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF00B4D8).withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeInOutCubic,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendDot({required String label, required Color color}) {
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // FIRST ROW (RIGHT): 6-AXIS CLINICAL COMPETENCY RADAR CHART
  // ---------------------------------------------------------------------
  Widget _buildDoctorRadarChart() {
    return BentoCard(
      title: '6-Axis Clinical Efficacy & Compliance Radar',
      subtitle: 'Multivariate score matrix across key clinical benchmarks',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.radar_rounded,
            color: Color(0xFF00E676), size: 18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: AnimatedBuilder(
              animation: _chartAnimationController,
              builder: (context, child) {
                final anim = CurvedAnimation(
                  parent: _chartAnimationController,
                  curve: Curves.easeOutCubic,
                ).value;

                final rawScores = [92.0, 96.0, 88.0, 94.0, 90.0, 95.0];
                final titles = [
                  'PDC Adherence',
                  'PA Velocity',
                  'Generic Adopt',
                  'Care Continuity',
                  'DDI Safety',
                  'Patient Trust'
                ];

                return RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    radarBorderData: const BorderSide(
                        color: AppColors.borderLight, width: 1.2),
                    gridBorderData: BorderSide(
                        color: AppColors.borderLight.withValues(alpha: 0.6),
                        width: 1),
                    tickBorderData: BorderSide(
                        color: AppColors.borderLight.withValues(alpha: 0.4),
                        width: 0.8),
                    tickCount: 3,
                    ticksTextStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 8, color: AppColors.textMuted),
                    getTitle: (index, angle) {
                      return RadarChartTitle(
                        text: titles[index % titles.length],
                        angle: angle,
                        positionPercentageOffset: 0.15,
                      );
                    },
                    titleTextStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    dataSets: [
                      RadarDataSet(
                        fillColor: const Color(0xFF00E676).withValues(alpha: 0.25 * anim),
                        borderColor: const Color(0xFF00E676),
                        entryRadius: 3.5,
                        dataEntries: rawScores
                            .map((s) => RadarEntry(value: s * anim))
                            .toList(),
                        borderWidth: 2.5,
                      ),
                      RadarDataSet(
                        fillColor: const Color(0xFF00B4D8).withValues(alpha: 0.15 * anim),
                        borderColor: const Color(0xFF00B4D8),
                        entryRadius: 3.0,
                        dataEntries: [80.0, 82.0, 78.0, 84.0, 85.0, 80.0]
                            .map((s) => RadarEntry(value: s * anim))
                            .toList(),
                        borderWidth: 1.8,
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeInOutCubic,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendDot(
                label: 'Dr. Rahul Verma (92.5 Avg)',
                color: const Color(0xFF00E676),
              ),
              const SizedBox(width: 14),
              _buildLegendDot(
                label: 'Regional Peer Benchmark (81.5 Avg)',
                color: const Color(0xFF00B4D8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECOND ROW (SCROLL DOWN): CLINICAL REFERRAL NETWORK NODE GRAPH
  // ---------------------------------------------------------------------
  Widget _buildDoctorNetworkNodeGraphCard() {
    return BentoCard(
      title: 'Physician Clinical Referral & Dispensing Network Mesh',
      subtitle:
          'Real-time interconnected topology: Prescribing Physician ↔ Clinical Diagnostic Cohorts ↔ Pharmacy Hubs • Interactive Node Tap & Pulse',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.hub_rounded,
            color: Color(0xFF7209B7), size: 18),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.metallicBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sensors_rounded,
                size: 13, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              '14 Mesh Nodes Synchronized',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _idleWaveController,
        builder: (context, child) {
          return _DoctorNetworkNodeMeshWidget(
            wavePhase: _idleWaveController.value * 2 * math.pi,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // THIRD ROW (SCROLL FURTHER): PATIENT RISK SCATTER HEATMAP MATRIX
  // ---------------------------------------------------------------------
  Widget _buildDoctorScatterPlotMatrixCard() {
    return BentoCard(
      title: 'Patient Cohort PDC Adherence vs. Age Scatter Heatmap Dispersion',
      subtitle:
          '4-Quadrant Risk Matrix: X-Axis Patient Age (30-85) vs. Y-Axis PDC Adherence Score (40%-100%) • Hover on clusters for patient telemetry',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bubble_chart_rounded,
            color: Color(0xFFFF5252), size: 18),
      ),
      child: const SizedBox(
        height: 250,
        child: _DoctorScatterMatrixWidget(),
      ),
    );
  }
}

// =========================================================================
// CUSTOM INTERACTIVE SCATTER PLOT MATRIX WIDGET (CustomPainter)
// =========================================================================
class _DoctorScatterMatrixWidget extends StatefulWidget {
  const _DoctorScatterMatrixWidget();

  @override
  State<_DoctorScatterMatrixWidget> createState() =>
      _DoctorScatterMatrixWidgetState();
}

class _DoctorScatterMatrixWidgetState
    extends State<_DoctorScatterMatrixWidget> {
  Offset? _hoverPos;
  int? _hoveredDotIndex;

  final _dots = const [
    // Optimal Tier (Green)
    _ScatterDot(age: 35, pdc: 92, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 42, pdc: 95, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 48, pdc: 88, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 55, pdc: 96, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 62, pdc: 90, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 68, pdc: 94, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 74, pdc: 91, color: Color(0xFF00E676), status: 'Optimal Compliance'),
    _ScatterDot(age: 80, pdc: 89, color: Color(0xFF00E676), status: 'Optimal Compliance'),

    // Watchlist Tier (Amber)
    _ScatterDot(age: 38, pdc: 74, color: Color(0xFFFFB300), status: 'Watchlist Refill Gap'),
    _ScatterDot(age: 50, pdc: 71, color: Color(0xFFFFB300), status: 'Watchlist Refill Gap'),
    _ScatterDot(age: 64, pdc: 76, color: Color(0xFFFFB300), status: 'Watchlist Refill Gap'),
    _ScatterDot(age: 72, pdc: 68, color: Color(0xFFFFB300), status: 'Watchlist Refill Gap'),

    // High Risk Tier (Coral/Red)
    _ScatterDot(age: 45, pdc: 52, color: Color(0xFFFF5252), status: 'High-Risk Critical'),
    _ScatterDot(age: 58, pdc: 48, color: Color(0xFFFF5252), status: 'High-Risk Critical'),
    _ScatterDot(age: 67, pdc: 56, color: Color(0xFFFF5252), status: 'High-Risk Critical'),
    _ScatterDot(age: 78, pdc: 44, color: Color(0xFFFF5252), status: 'High-Risk Critical'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return MouseRegion(
          onHover: (event) {
            final pos = event.localPosition;
            int? hit;
            for (int i = 0; i < _dots.length; i++) {
              final dotPos = _getDotOffset(_dots[i], width, height);
              if ((dotPos - pos).distance < 20) {
                hit = i;
                break;
              }
            }
            setState(() {
              _hoverPos = pos;
              _hoveredDotIndex = hit;
            });
          },
          onExit: (_) => setState(() {
            _hoverPos = null;
            _hoveredDotIndex = null;
          }),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _DoctorScatterPainter(
                  dots: _dots,
                  hoveredIndex: _hoveredDotIndex,
                ),
              ),

              // Tooltip
              if (_hoveredDotIndex != null && _hoverPos != null)
                Positioned(
                  left: (_hoverPos!.dx - 80).clamp(10.0, width - 180.0),
                  top: (_hoverPos!.dy - 65).clamp(0.0, height - 70.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentNavy.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.jewelTechCyan.withValues(alpha: 0.4),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentNavy.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Age: ${_dots[_hoveredDotIndex!].age} Years',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'PDC: ${_dots[_hoveredDotIndex!].pdc}% (${_dots[_hoveredDotIndex!].status})',
                              style: GoogleFonts.plusJakartaSans(
                                color: _dots[_hoveredDotIndex!].color,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Offset _getDotOffset(_ScatterDot dot, double w, double h) {
    const padL = 40.0;
    const padR = 20.0;
    const padT = 20.0;
    const padB = 30.0;

    final chartW = w - padL - padR;
    final chartH = h - padT - padB;

    final normX = (dot.age - 25) / (85 - 25);
    final normY = (dot.pdc - 40) / (100 - 40);

    final x = padL + normX * chartW;
    final y = padT + (1.0 - normY) * chartH;

    return Offset(x, y);
  }
}

class _ScatterDot {
  final int age;
  final int pdc;
  final Color color;
  final String status;
  const _ScatterDot({
    required this.age,
    required this.pdc,
    required this.color,
    required this.status,
  });
}

class _DoctorScatterPainter extends CustomPainter {
  final List<_ScatterDot> dots;
  final int? hoveredIndex;

  _DoctorScatterPainter({
    required this.dots,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const padL = 40.0;
    const padR = 20.0;
    const padT = 20.0;
    const padB = 30.0;

    final chartW = w - padL - padR;
    final chartH = h - padT - padB;

    // Background Grid
    final gridPaint = Paint()
      ..color = AppColors.borderLight.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;

    for (int p = 40; p <= 100; p += 20) {
      final y = padT + (1.0 - (p - 40) / 60) * chartH;
      canvas.drawLine(Offset(padL, y), Offset(w - padR, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(
          text: '$p%',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5, color: AppColors.textMuted),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(8, y - 6));
    }

    // 80% Benchmark Line (Green)
    final targetY = padT + (1.0 - (80 - 40) / 60) * chartH;
    final targetPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(padL, targetY), Offset(w - padR, targetY), targetPaint);

    // X Axis Labels
    for (int age = 30; age <= 80; age += 10) {
      final x = padL + ((age - 25) / 60) * chartW;
      final tp = TextPainter(
        text: TextSpan(
          text: '${age}y',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 10, color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - 8, h - 20));
    }

    // Draw Scatter Dots
    for (int i = 0; i < dots.length; i++) {
      final dot = dots[i];
      final isHov = hoveredIndex == i;
      final pt = _DoctorScatterMatrixWidgetState._getDotOffset(dot, w, h);

      // Glow halo
      final haloPaint = Paint()
        ..color = dot.color.withValues(alpha: isHov ? 0.45 : 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isHov ? 14 : 9, haloPaint);

      // Dot Core
      final corePaint = Paint()
        ..color = dot.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isHov ? 7.5 : 5.5, corePaint);

      final centerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isHov ? 3.0 : 2.0, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _DoctorScatterPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex;
  }
}

// =========================================================================
// INTERACTIVE CLINICAL REFERRAL NETWORK NODE MESH WIDGET (CustomPainter)
// =========================================================================
class _DoctorNetworkNodeMeshWidget extends StatefulWidget {
  final double wavePhase;

  const _DoctorNetworkNodeMeshWidget({required this.wavePhase});

  @override
  State<_DoctorNetworkNodeMeshWidget> createState() =>
      _DoctorNetworkNodeMeshWidgetState();
}

class _DoctorNetworkNodeMeshWidgetState
    extends State<_DoctorNetworkNodeMeshWidget> {
  int? _hoveredNodeIndex;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 240.0;

        return MouseRegion(
          onHover: (event) {
            final pos = event.localPosition;
            final nodes = _calculateNodes(width, height, widget.wavePhase);
            int? hit;
            for (int i = 0; i < nodes.length; i++) {
              if ((nodes[i].offset - pos).distance < 24) {
                hit = i;
                break;
              }
            }
            if (hit != _hoveredNodeIndex) {
              setState(() => _hoveredNodeIndex = hit);
            }
          },
          onExit: (_) => setState(() => _hoveredNodeIndex = null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _DoctorNetworkMeshPainter(
                  wavePhase: widget.wavePhase,
                  hoveredIndex: _hoveredNodeIndex,
                ),
              ),
              if (_hoveredNodeIndex != null)
                Positioned(
                  top: 10,
                  right: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentNavy.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.jewelTechCyan.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      _getNodeLabel(_hoveredNodeIndex!),
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF00E5FF),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getNodeLabel(int idx) {
    final labels = [
      'Dr. Rahul Verma (Central Prescriber)',
      'Regional Hospital Alpha (Hub)',
      'Cardiology Care Cohort',
      'Endocrinology Clinic',
      'Oncology Infusion Center',
      'Central Dispense Pharmacy',
      'Express Specialty Rx Hub'
    ];
    return idx < labels.length ? labels[idx] : 'Mesh Telemetry Node';
  }

  List<_NetworkNode> _calculateNodes(double w, double h, double phase) {
    final cx = w / 2;
    final cy = h / 2;

    return [
      _NetworkNode(Offset(cx, cy), const Color(0xFF00E676), 14), // Center
      _NetworkNode(
          Offset(cx - w * 0.28, cy - h * 0.25 + math.sin(phase) * 6),
          const Color(0xFF00B4D8),
          10),
      _NetworkNode(
          Offset(cx + w * 0.28, cy - h * 0.25 + math.cos(phase) * 6),
          const Color(0xFF7209B7),
          10),
      _NetworkNode(
          Offset(cx - w * 0.35, cy + h * 0.28 + math.cos(phase + 1) * 6),
          const Color(0xFFFFB300),
          9),
      _NetworkNode(
          Offset(cx - w * 0.10, cy + h * 0.35 + math.sin(phase + 2) * 6),
          const Color(0xFF00E676),
          9),
      _NetworkNode(
          Offset(cx + w * 0.15, cy + h * 0.35 + math.cos(phase + 3) * 6),
          const Color(0xFF00B4D8),
          9),
      _NetworkNode(
          Offset(cx + w * 0.35, cy + h * 0.25 + math.sin(phase + 4) * 6),
          const Color(0xFFFF5252),
          9),
    ];
  }
}

class _NetworkNode {
  final Offset offset;
  final Color color;
  final double radius;
  _NetworkNode(this.offset, this.color, this.radius);
}

class _DoctorNetworkMeshPainter extends CustomPainter {
  final double wavePhase;
  final int? hoveredIndex;

  _DoctorNetworkMeshPainter({
    required this.wavePhase,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final nodes = [
      _NetworkNode(Offset(cx, cy), const Color(0xFF00E676), 14), // Center
      _NetworkNode(
          Offset(cx - w * 0.28, cy - h * 0.25 + math.sin(wavePhase) * 6),
          const Color(0xFF00B4D8),
          10),
      _NetworkNode(
          Offset(cx + w * 0.28, cy - h * 0.25 + math.cos(wavePhase) * 6),
          const Color(0xFF7209B7),
          10),
      _NetworkNode(
          Offset(cx - w * 0.35, cy + h * 0.28 + math.cos(wavePhase + 1) * 6),
          const Color(0xFF00B4D8),
          9),
      _NetworkNode(
          Offset(cx - w * 0.10, cy + h * 0.35 + math.sin(wavePhase + 2) * 6),
          const Color(0xFF00E676),
          9),
      _NetworkNode(
          Offset(cx + w * 0.15, cy + h * 0.35 + math.cos(wavePhase + 3) * 6),
          const Color(0xFF00B4D8),
          9),
      _NetworkNode(
          Offset(cx + w * 0.35, cy + h * 0.25 + math.sin(wavePhase + 4) * 6),
          const Color(0xFFFF5252),
          9),
    ];

    // Draw Links
    final links = [
      [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6],
      [1, 3], [1, 4], [2, 5], [2, 6], [4, 5]
    ];

    for (final link in links) {
      final p1 = nodes[link[0]].offset;
      final p2 = nodes[link[1]].offset;
      final isHoveredLink =
          hoveredIndex == link[0] || hoveredIndex == link[1];

      final linePaint = Paint()
        ..color = isHoveredLink
            ? const Color(0xFF00E5FF).withValues(alpha: 0.7)
            : AppColors.primaryTeal.withValues(alpha: 0.15)
        ..strokeWidth = isHoveredLink ? 2.2 : 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p2, linePaint);

      // Flowing Pulse Particle along link
      final particleT =
          (wavePhase / (2 * math.pi) + (link[0] * 0.15)) % 1.0;
      final particlePos = Offset(
        p1.dx + (p2.dx - p1.dx) * particleT,
        p1.dy + (p2.dy - p1.dy) * particleT,
      );

      final pulsePaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(particlePos, 2.5, pulsePaint);
    }

    // Draw Nodes
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isHover = hoveredIndex == i;

      // Glow halo
      final haloPaint = Paint()
        ..color = node.color.withValues(alpha: isHover ? 0.4 : 0.18)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node.offset, node.radius + (isHover ? 10 : 5), haloPaint);

      // Node Body
      final bodyPaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node.offset, node.radius, bodyPaint);

      // Center Dot
      final innerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(node.offset, isHover ? 4.5 : 3.0, innerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _DoctorNetworkMeshPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.hoveredIndex != hoveredIndex;
  }
}

// =========================================================================
// SCROLL-LINKED "WHIP & WAVE" CARD REVEAL WRAPPER
// =========================================================================
class _DoctorScrollWaveCard extends StatelessWidget {
  final Widget child;
  final double scrollOffset;
  final double triggerOffset;

  const _DoctorScrollWaveCard({
    required this.child,
    required this.scrollOffset,
    required this.triggerOffset,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        ((scrollOffset - triggerOffset + 250) / 250).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(progress);

    final tiltAngle = (-2.0 * (1.0 - eased)) * (math.pi / 180.0);
    final translateY = 28.0 * (1.0 - eased);
    final opacity = (progress * 1.2).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(0.0, translateY),
        child: Transform.rotate(
          angle: tiltAngle,
          alignment: Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

// =========================================================================
// KINETIC BACKGROUND VECTOR MESH PAINTER (CustomPainter)
// =========================================================================
class _DoctorMeshBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final double wavePhase;

  _DoctorMeshBackgroundPainter({
    required this.scrollOffset,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final meshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.primaryTeal.withValues(alpha: 0.04);

    const lineSpacing = 50.0;
    final numLines = (size.height / lineSpacing).ceil() + 2;

    for (int i = 0; i < numLines; i++) {
      final baseY = i * lineSpacing;
      final path = Path();
      const segments = 24;
      final segWidth = size.width / segments;

      for (int s = 0; s <= segments; s++) {
        final x = s * segWidth;
        final wave = math.sin((x / size.width) * 3 * math.pi +
                wavePhase +
                (scrollOffset * 0.003)) *
            8.0;
        final y = baseY + wave;

        if (s == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, meshPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoctorMeshBackgroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.wavePhase != wavePhase;
  }
}
