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

class PharmacistAnalyticsScreen extends StatefulWidget {
  const PharmacistAnalyticsScreen({super.key});

  @override
  State<PharmacistAnalyticsScreen> createState() =>
      _PharmacistAnalyticsScreenState();
}

class _PharmacistAnalyticsScreenState
    extends State<PharmacistAnalyticsScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _entranceController;
  late final AnimationController _idleWaveController;
  late final AnimationController _chartAnimationController;
  late final AnimationController _lineProgressController;

  double _scrollOffset = 0.0;
  String _selectedTimeframe = '30 Days';

  int _selectedTierIndex = -1;
  int _hoveredPipelineStage = -1;

  // Multi-Series Area Chart Series Toggles
  bool _showDispensedArea = true;
  bool _showRefillArea = true;
  bool _showInterventionArea = true;

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
    final flags = appState.filteredAdherenceFlags;
    final totalDispensed = appState.dataService.getPharmacistDispensedCount(_selectedTimeframe);
    final meanPdc = appState.dataService.getDoctorAveragePdc(null) * 100;
    final refillIndex = appState.dataService.getPharmacistRefillRate(_selectedTimeframe);

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
                painter: _PharmacyMeshBackgroundPainter(
                  scrollOffset: _scrollOffset,
                  wavePhase: _idleWaveController.value * 2 * math.pi,
                ),
              );
            },
          ),
        ),

        // -----------------------------------------------------------------
        // Main Scroll-Linked Pharmacy Reports Viewport
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
              _PharmacyScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 0,
                child: BentoHeroBanner(
                  title: 'Pharmacy Dispense Velocity & Inventory Intelligence',
                  subtitle:
                      'Layered area fulfillment volumes, stacked formulary tier progress, curved spline wave telemetry, and live interactive dispensing pipeline.',
                  icon: Icons.analytics_rounded,
                  statusLabel: 'Pharmacy Core Active',
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
                                  style: AppFonts.googleSans(
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
                          style: AppFonts.googleSans(
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
              // Top Pharmacy Counting Metric Cards Grid (TweenAnimationBuilder)
              // -------------------------------------------------------------
              _PharmacyScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 40,
                child: _buildPharmacyStatsCounterGrid(
                    totalDispensed, flags.length, meanPdc, refillIndex),
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------------------
              // FIRST ROW: LAYERED AREA CHART & STACKED HORIZONTAL PROGRESS BAR
              // -------------------------------------------------------------
              _PharmacyScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 90,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final areaCard = _buildPharmacyAreaChart();
                    final stackedBarCard = _buildFormularyStackedProgressBar();

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: areaCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: stackedBarCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        areaCard,
                        const SizedBox(height: 16),
                        stackedBarCard,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // SECOND ROW (SCROLL DOWN): CURVED SPLINE WAVE CHART
              // -------------------------------------------------------------
              _PharmacyScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 200,
                child: _buildPharmacyCurvedSplineWaveCard(),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // THIRD ROW (SCROLL FURTHER): INTERACTIVE DISPENSE FLOW DIAGRAM
              // -------------------------------------------------------------
              _PharmacyScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 340,
                child: _buildPharmacyInteractiveFlowDiagramCard(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 1. TOP PHARMACY STATS COUNTER ROW (TweenAnimationBuilder)
  // ---------------------------------------------------------------------
  Widget _buildPharmacyStatsCounterGrid(int totalDispensed, int flaggedCount, double meanPdc, double refillIndex) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final tiles = [
          _buildPharmacyMetricTile(
            label: 'Prescriptions Dispensed',
            targetValue: totalDispensed.toDouble(),
            prefix: '',
            suffix: ' Units',
            isCurrency: false,
            trendText: '+22.1% MoM',
            icon: Icons.local_pharmacy_rounded,
            iconColor: const Color(0xFF00B4D8),
            iconBg: const Color(0xFFE0F7FA),
          ),
          _buildPharmacyMetricTile(
            label: 'Mean Panel PDC Compliance',
            targetValue: meanPdc,
            prefix: '',
            suffix: '%',
            isCurrency: false,
            trendText: meanPdc >= 80.0 ? '★ CMS 5-Star Target' : 'Near Target',
            icon: Icons.verified_rounded,
            iconColor: AppColors.primaryTeal,
            iconBg: AppColors.primaryLight,
          ),
          _buildPharmacyMetricTile(
            label: 'High-Risk Patients Flagged',
            targetValue: flaggedCount.toDouble(),
            prefix: '',
            suffix: ' Claims',
            isCurrency: false,
            trendText: 'Action Required',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFFF5252),
            iconBg: const Color(0xFFFFEBEE),
          ),
          _buildPharmacyMetricTile(
            label: 'Refill Timeliness Index',
            targetValue: refillIndex,
            prefix: '',
            suffix: '%',
            isCurrency: false,
            trendText: 'Optimal Sync',
            icon: Icons.schedule_rounded,
            iconColor: const Color(0xFF00E676),
            iconBg: const Color(0xFFE8F5E9),
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

  Widget _buildPharmacyMetricTile({
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
                  style: AppFonts.googleSans(
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
            style: AppFonts.googleSans(
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
                style: AppFonts.googleSans(
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
  // FIRST ROW (LEFT): LAYERED AREA CHART (Monthly Dispensed vs Refills vs Gap)
  // ---------------------------------------------------------------------
  Widget _buildPharmacyAreaChart() {
    return BentoCard(
      title: 'Layered Area Fulfillment & Dispensing Volumes (Monthly)',
      subtitle: 'Continuous cumulative dispensing volume across fulfillment streams • Hover to inspect',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.area_chart_rounded,
            color: Color(0xFF00B4D8), size: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPharmacyAreaToggle(
            label: 'Dispensed',
            color: const Color(0xFF00E676),
            isActive: _showDispensedArea,
            onToggle: () => setState(() => _showDispensedArea = !_showDispensedArea),
          ),
          const SizedBox(width: 8),
          _buildPharmacyAreaToggle(
            label: 'Auto Refills',
            color: const Color(0xFF00B4D8),
            isActive: _showRefillArea,
            onToggle: () => setState(() => _showRefillArea = !_showRefillArea),
          ),
          const SizedBox(width: 8),
          _buildPharmacyAreaToggle(
            label: 'MTM Gaps',
            color: const Color(0xFF7209B7),
            isActive: _showInterventionArea,
            onToggle: () => setState(() => _showInterventionArea = !_showInterventionArea),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _lineProgressController,
        builder: (context, child) {
          final progress = _lineProgressController.value.clamp(0.01, 1.0);

          final dispensedSpots = [
            FlSpot(0, 160 * progress),
            FlSpot(1, 205 * progress),
            FlSpot(2, 250 * progress),
            FlSpot(3, 295 * progress),
            FlSpot(4, 340 * progress),
            FlSpot(5, 395 * progress),
          ];

          final refillSpots = [
            FlSpot(0, 110 * progress),
            FlSpot(1, 145 * progress),
            FlSpot(2, 185 * progress),
            FlSpot(3, 225 * progress),
            FlSpot(4, 270 * progress),
            FlSpot(5, 320 * progress),
          ];

          final gapSpots = [
            FlSpot(0, 45 * progress),
            FlSpot(1, 60 * progress),
            FlSpot(2, 75 * progress),
            FlSpot(3, 90 * progress),
            FlSpot(4, 110 * progress),
            FlSpot(5, 135 * progress),
          ];

          return SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 430,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 80,
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
                        final names = ['Dispensed Units', 'Auto Refills', 'MTM Gap Interventions'];
                        final colors = [
                          const Color(0xFF00E676),
                          const Color(0xFF00B4D8),
                          const Color(0xFF7209B7)
                        ];
                        final idx = spot.barIndex.clamp(0, 2);
                        return LineTooltipItem(
                          '${names[idx]}: ${spot.y.toInt()} Units\n',
                          AppFonts.googleSans(
                            color: colors[idx],
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 80,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        '${val.toInt()}',
                        style: AppFonts.googleSans(
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
                              style: AppFonts.googleSans(
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
                  if (_showDispensedArea)
                    LineChartBarData(
                      spots: dispensedSpots,
                      isCurved: true,
                      color: const Color(0xFF00E676),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00E676).withValues(alpha: 0.38),
                            const Color(0xFF00E676).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  if (_showRefillArea)
                    LineChartBarData(
                      spots: refillSpots,
                      isCurved: true,
                      color: const Color(0xFF00B4D8),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00B4D8).withValues(alpha: 0.30),
                            const Color(0xFF00B4D8).withValues(alpha: 0.04),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  if (_showInterventionArea)
                    LineChartBarData(
                      spots: gapSpots,
                      isCurved: true,
                      color: const Color(0xFF7209B7),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF7209B7).withValues(alpha: 0.25),
                            const Color(0xFF7209B7).withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
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

  Widget _buildPharmacyAreaToggle({
    required String label,
    required Color color,
    required bool isActive,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : AppColors.bgSlate,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color : AppColors.metallicBorder,
              width: 1.3,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? color : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive ? color : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // FIRST ROW (RIGHT): STACKED HORIZONTAL PROGRESS BAR (Formulary Tiers)
  // ---------------------------------------------------------------------
  Widget _buildFormularyStackedProgressBar() {
    return BentoCard(
      title: 'Formulary Tier Dispense Stratification',
      subtitle: 'Stacked volume breakdown: Tier 1 Generic to Tier 4 Specialty • Tap tier to focus',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.stacked_bar_chart_rounded,
            color: Color(0xFF00E676), size: 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _chartAnimationController,
            builder: (context, child) {
              final anim = CurvedAnimation(
                parent: _chartAnimationController,
                curve: Curves.easeOutCubic,
              ).value;

              return ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      // Tier 1: Generic (55%)
                      Expanded(
                        flex: (55 * anim).toInt().clamp(1, 55),
                        child: _buildTierSegment(
                          index: 0,
                          label: 'T1 Generic',
                          pct: '55%',
                          color: const Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Tier 2: Preferred Brand (25%)
                      Expanded(
                        flex: (25 * anim).toInt().clamp(1, 25),
                        child: _buildTierSegment(
                          index: 1,
                          label: 'T2 Preferred',
                          pct: '25%',
                          color: const Color(0xFF00B4D8),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Tier 3: Non-Preferred (12%)
                      Expanded(
                        flex: (12 * anim).toInt().clamp(1, 12),
                        child: _buildTierSegment(
                          index: 2,
                          label: 'T3 Non-Pref',
                          pct: '12%',
                          color: const Color(0xFFFFB300),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Tier 4: Specialty / Biologics (8%)
                      Expanded(
                        flex: (8 * anim).toInt().clamp(1, 8),
                        child: _buildTierSegment(
                          index: 3,
                          label: 'T4 Specialty',
                          pct: '8%',
                          color: const Color(0xFF7209B7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Tier Legend Cards
          Row(
            children: [
              Expanded(
                child: _buildTierInfoCard(
                  index: 0,
                  tierName: 'Tier 1: Generic',
                  units: '2,112 Units',
                  share: '55%',
                  color: const Color(0xFF00E676),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTierInfoCard(
                  index: 1,
                  tierName: 'Tier 2: Brand',
                  units: '960 Units',
                  share: '25%',
                  color: const Color(0xFF00B4D8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildTierInfoCard(
                  index: 2,
                  tierName: 'Tier 3: Non-Pref',
                  units: '460 Units',
                  share: '12%',
                  color: const Color(0xFFFFB300),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTierInfoCard(
                  index: 3,
                  tierName: 'Tier 4: Specialty',
                  units: '308 Units',
                  share: '8%',
                  color: const Color(0xFF7209B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierSegment({
    required int index,
    required String label,
    required String pct,
    required Color color,
  }) {
    final isSelected = _selectedTierIndex == index;
    final hasSelection = _selectedTierIndex != -1;
    final isDimmed = hasSelection && !isSelected;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTierIndex = _selectedTierIndex == index ? -1 : index;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDimmed ? color.withValues(alpha: 0.35) : color,
            border: isSelected
                ? Border.all(color: Colors.white, width: 2.2)
                : null,
          ),
          child: Text(
            pct,
            style: AppFonts.googleSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTierInfoCard({
    required int index,
    required String tierName,
    required String units,
    required String share,
    required Color color,
  }) {
    final isSelected = _selectedTierIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTierIndex = _selectedTierIndex == index ? -1 : index;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.bgSlate,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.metallicBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tierName,
                    style: AppFonts.googleSans(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? color : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Text(
                '$share ($units)',
                style: AppFonts.googleSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECOND ROW (SCROLL DOWN): CURVED SPLINE WAVE CHART
  // ---------------------------------------------------------------------
  Widget _buildPharmacyCurvedSplineWaveCard() {
    return BentoCard(
      title: 'Curved Spline Wave: Refill Fulfillment Lag & Resolution (Avg Days)',
      subtitle:
          'Continuous live organic wave curve with mathematical sine oscillation • Magnetic cursor telemetry tracking',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.waves_rounded,
            color: Color(0xFF00B4D8), size: 18),
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
            const Icon(Icons.auto_awesome_rounded,
                size: 13, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              'Curved Spline Active',
              style: AppFonts.googleSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryTeal,
              ),
            ),
          ],
        ),
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_idleWaveController, _lineProgressController]),
        builder: (context, child) {
          return _PharmacySplineWaveGraph(
            scrollOffset: _scrollOffset,
            idlePhase: _idleWaveController.value * 2 * math.pi,
            lineProgress: _lineProgressController.value,
            dataPoints: const [16.0, 13.5, 12.0, 8.5, 5.0, 3.1],
            monthLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // THIRD ROW (SCROLL FURTHER): INTERACTIVE DISPENSE FLOW DIAGRAM
  // ---------------------------------------------------------------------
  Widget _buildPharmacyInteractiveFlowDiagramCard() {
    return BentoCard(
      title: 'Prescription Dispense Pipeline & Verification Flow',
      subtitle:
          'End-to-end dispensing stages with animated particle transmission • Tap stage to inspect telemetry',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.alt_route_rounded,
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
            const Icon(Icons.flash_on_rounded,
                size: 13, color: AppColors.primaryTeal),
            const SizedBox(width: 4),
            Text(
              '4 Pipeline Stages Active',
              style: AppFonts.googleSans(
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
          return _PharmacyFlowDiagramWidget(
            wavePhase: _idleWaveController.value * 2 * math.pi,
            hoveredStage: _hoveredPipelineStage,
            onStageHover: (idx) {
              setState(() => _hoveredPipelineStage = idx ?? -1);
            },
          );
        },
      ),
    );
  }
}

// =========================================================================
// INTERACTIVE DISPENSE FLOW DIAGRAM WIDGET (CustomPainter)
// =========================================================================
class _PharmacyFlowDiagramWidget extends StatelessWidget {
  final double wavePhase;
  final int hoveredStage;
  final ValueChanged<int?> onStageHover;

  const _PharmacyFlowDiagramWidget({
    required this.wavePhase,
    required this.hoveredStage,
    required this.onStageHover,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 220.0;

        return MouseRegion(
          onHover: (event) {
            final x = event.localPosition.dx;
            final stageWidth = width / 4;
            final idx = (x / stageWidth).floor().clamp(0, 3);
            onStageHover(idx);
          },
          onExit: (_) => onStageHover(null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _PharmacyFlowDiagramPainter(
                  wavePhase: wavePhase,
                  hoveredStage: hoveredStage,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PharmacyFlowDiagramPainter extends CustomPainter {
  final double wavePhase;
  final int hoveredStage;

  _PharmacyFlowDiagramPainter({
    required this.wavePhase,
    required this.hoveredStage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const numStages = 4;
    final stageWidth = w / numStages;

    final stages = [
      {'title': '1. e-Rx Ingestion', 'stat': '3,840 Received', 'color': const Color(0xFF00B4D8)},
      {'title': '2. DDI & Formulary', 'stat': '99.4% Approved', 'color': const Color(0xFF00E676)},
      {'title': '3. PA Verification', 'stat': '96.2% Clean', 'color': const Color(0xFFFFB300)},
      {'title': '4. Final Dispense', 'stat': '3,695 Dispensed', 'color': const Color(0xFF7209B7)},
    ];

    final centerY = h * 0.45;

    // Draw Connecting Flow Pipe
    final pipePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..color = AppColors.primaryTeal.withValues(alpha: 0.18)
      ..strokeCap = StrokeCap.round;

    final pipePath = Path();
    pipePath.moveTo(stageWidth * 0.5, centerY);
    for (int i = 1; i < numStages; i++) {
      final prevX = stageWidth * (i - 0.5);
      final currX = stageWidth * (i + 0.5);
      final midX = (prevX + currX) / 2;
      pipePath.cubicTo(midX, centerY - 15, midX, centerY + 15, currX, centerY);
    }
    canvas.drawPath(pipePath, pipePaint);

    // Draw Flowing Particles along pipe
    for (int i = 0; i < 3; i++) {
      final t = (wavePhase / (2 * math.pi) + (i * 0.33)) % 1.0;
      final startX = stageWidth * 0.5;
      final endX = stageWidth * 3.5;
      final px = startX + (endX - startX) * t;
      final py = centerY + math.sin(t * 3 * math.pi + wavePhase) * 6;

      final particlePaint = Paint()
        ..color = const Color(0xFF00E5FF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 4.0, particlePaint);
    }

    // Draw Stage Nodes & Cards
    for (int i = 0; i < numStages; i++) {
      final stage = stages[i];
      final nodeX = stageWidth * (i + 0.5);
      final nodeY = centerY;
      final isHover = hoveredStage == i;
      final color = stage['color'] as Color;

      // Pulse Halo
      final halo = Paint()
        ..color = color.withValues(alpha: isHover ? 0.35 : 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nodeX, nodeY), isHover ? 22 : 16, halo);

      // Center Node
      final nodeBody = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nodeX, nodeY), isHover ? 12 : 9, nodeBody);

      final nodeDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nodeX, nodeY), isHover ? 4.5 : 3.0, nodeDot);

      // Stage Title Text
      final titlePainter = TextPainter(
        text: TextSpan(
          text: stage['title'] as String,
          style: AppFonts.googleSans(
            fontSize: isHover ? 12 : 11,
            fontWeight: isHover ? FontWeight.w900 : FontWeight.w700,
            color: isHover ? color : AppColors.textDark,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: stageWidth - 10);

      titlePainter.paint(
        canvas,
        Offset(nodeX - (titlePainter.width / 2), nodeY - 45),
      );

      // Stage Stat Subtitle Text
      final statPainter = TextPainter(
        text: TextSpan(
          text: stage['stat'] as String,
          style: AppFonts.googleSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isHover ? color : AppColors.textMuted,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout(maxWidth: stageWidth - 10);

      statPainter.paint(
        canvas,
        Offset(nodeX - (statPainter.width / 2), nodeY + 24),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PharmacyFlowDiagramPainter oldDelegate) {
    return oldDelegate.wavePhase != wavePhase ||
        oldDelegate.hoveredStage != hoveredStage;
  }
}

// =========================================================================
// CURVED SPLINE WAVE GRAPH WITH MAGNETIC HOVER RIPPLE (CustomPainter)
// =========================================================================
class _PharmacySplineWaveGraph extends StatefulWidget {
  final double scrollOffset;
  final double idlePhase;
  final double lineProgress;
  final List<double> dataPoints;
  final List<String> monthLabels;

  const _PharmacySplineWaveGraph({
    required this.scrollOffset,
    required this.idlePhase,
    required this.lineProgress,
    required this.dataPoints,
    required this.monthLabels,
  });

  @override
  State<_PharmacySplineWaveGraph> createState() =>
      _PharmacySplineWaveGraphState();
}

class _PharmacySplineWaveGraphState
    extends State<_PharmacySplineWaveGraph> {
  Offset? _hoverPos;
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoverPos = event.localPosition;
        });
      },
      onExit: (_) {
        setState(() {
          _hoverPos = null;
          _hoveredIndex = null;
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const height = 240.0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _PharmacySplinePainter(
                  scrollOffset: widget.scrollOffset,
                  idlePhase: widget.idlePhase,
                  lineProgress: widget.lineProgress,
                  dataPoints: widget.dataPoints,
                  hoverPos: _hoverPos,
                  onHoverIndexCalculated: (idx) {
                    _hoveredIndex = idx;
                  },
                ),
              ),

              // Floating Magnetic Tooltip
              if (_hoverPos != null &&
                  _hoveredIndex != null &&
                  _hoveredIndex! >= 0 &&
                  _hoveredIndex! < widget.dataPoints.length)
                Positioned(
                  left: (_hoverPos!.dx - 70).clamp(10.0, width - 150.0),
                  top: (_hoverPos!.dy - 65).clamp(0.0, height - 70.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentNavy.withValues(alpha: 0.90),
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
                              '${widget.monthLabels[_hoveredIndex!]} 2026',
                              style: AppFonts.googleSans(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.dataPoints[_hoveredIndex!].toStringAsFixed(1)} Days Lag',
                              style: AppFonts.googleSans(
                                color: const Color(0xFF00E5FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Bottom Month Axis Labels
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: widget.monthLabels.asMap().entries.map((entry) {
                    final isHov = _hoveredIndex == entry.key;
                    return Text(
                      entry.value,
                      style: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight:
                            isHov ? FontWeight.w900 : FontWeight.w700,
                        color: isHov
                            ? AppColors.primaryTeal
                            : AppColors.textMuted,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PharmacySplinePainter extends CustomPainter {
  final double scrollOffset;
  final double idlePhase;
  final double lineProgress;
  final List<double> dataPoints;
  final Offset? hoverPos;
  final ValueChanged<int?> onHoverIndexCalculated;

  _PharmacySplinePainter({
    required this.scrollOffset,
    required this.idlePhase,
    required this.lineProgress,
    required this.dataPoints,
    required this.hoverPos,
    required this.onHoverIndexCalculated,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final chartHeight = size.height - 30;
    final width = size.width;
    const maxVal = 20.0;

    final stepX = width / (dataPoints.length - 1);
    final points = <Offset>[];

    int? nearestIdx;
    double nearestDist = double.infinity;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      final waveOffset =
          math.sin((i * 1.2) + idlePhase + (scrollOffset * 0.005)) * 4.0;
      final rawY =
          chartHeight - ((dataPoints[i] / maxVal) * (chartHeight - 30));
      var y = rawY + waveOffset;

      if (hoverPos != null) {
        final dist = (Offset(x, y) - hoverPos!).distance;
        if (dist < 45) {
          y += (hoverPos!.dy - y) * 0.25;
        }
        if (dist < nearestDist) {
          nearestDist = dist;
          nearestIdx = i;
        }
      }

      points.add(Offset(x, y));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      onHoverIndexCalculated(nearestIdx);
    });

    final currentEndIdxFloat =
        (points.length - 1) * lineProgress.clamp(0.01, 1.0);
    final maxDrawnIndex =
        currentEndIdxFloat.floor().clamp(0, points.length - 2);

    final path = Path();
    final fillPath = Path();

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, chartHeight);
    fillPath.lineTo(points[0].dx, points[0].dy);

    Offset lastPoint = points[0];

    for (int i = 0; i <= maxDrawnIndex; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      final segmentProgress = (currentEndIdxFloat - i).clamp(0.0, 1.0);
      final currentTargetP1 = Offset(
        p0.dx + (p1.dx - p0.dx) * segmentProgress,
        p0.dy + (p1.dy - p0.dy) * segmentProgress,
      );

      final controlPoint1 =
          Offset(p0.dx + (currentTargetP1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 =
          Offset(p0.dx + (currentTargetP1.dx - p0.dx) / 2, currentTargetP1.dy);

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        currentTargetP1.dx,
        currentTargetP1.dy,
      );

      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        currentTargetP1.dx,
        currentTargetP1.dy,
      );

      lastPoint = currentTargetP1;
      if (segmentProgress < 1.0) break;
    }

    fillPath.lineTo(lastPoint.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF00B4D8).withValues(alpha: 0.35),
          const Color(0xFF00C9A7).withValues(alpha: 0.18),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF00E5FF),
          Color(0xFF00B4D8),
          Color(0xFF00C9A7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, chartHeight));

    canvas.drawPath(path, strokePaint);

    for (int i = 0;
        i <= currentEndIdxFloat.ceil().clamp(0, points.length - 1);
        i++) {
      final pt = points[i];
      final isHovered = nearestIdx == i;

      if (isHovered) {
        final haloPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, 12, haloPaint);
      }

      final circlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isHovered ? 6.5 : 4.5, circlePaint);

      final ringPaint = Paint()
        ..color = isHovered
            ? const Color(0xFF00E5FF)
            : const Color(0xFF008080)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3.5 : 2.5;
      canvas.drawCircle(pt, isHovered ? 6.5 : 4.5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PharmacySplinePainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.idlePhase != idlePhase ||
        oldDelegate.lineProgress != lineProgress ||
        oldDelegate.hoverPos != hoverPos;
  }
}

// =========================================================================
// SCROLL-LINKED CARD REVEAL WRAPPER
// =========================================================================
class _PharmacyScrollWaveCard extends StatelessWidget {
  final Widget child;
  final double scrollOffset;
  final double triggerOffset;

  const _PharmacyScrollWaveCard({
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
class _PharmacyMeshBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final double wavePhase;

  _PharmacyMeshBackgroundPainter({
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
  bool shouldRepaint(covariant _PharmacyMeshBackgroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.wavePhase != wavePhase;
  }
}
