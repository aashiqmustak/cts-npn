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

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _entranceController;
  late final AnimationController _idleWaveController;
  late final AnimationController _chartAnimationController;
  late final AnimationController _lineProgressController;

  double _scrollOffset = 0.0;
  String _selectedTimeframe = '30 Days';

  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  // Interactive Multi-Series Legend Visibility Toggles
  bool _showDispensedSeries = true;
  bool _showApprovedSeries = true;
  bool _showRefillSeries = true;

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

    // Staggered Entrance Controller (Smooth & Paced)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // Continuous Idle Living Wave Motion Controller (Looping)
    _idleWaveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Bar & Donut Chart Smooth Growth Animation Controller (Calm & Paced)
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Line Graph Progressive Reveal from Jan to Last Month (Slow & Cinematic)
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
    final totalSavings =
        appState.dataService.totalEstimatedAnnualSavingsOpportunity;
    final totalPrescriptions = appState.prescriptions.length * 2840 + 6420;

    return Stack(
      children: [
        // -----------------------------------------------------------------
        // 1. Kinetic Background Vector Mesh Layer (Scroll & Wave Driven)
        // -----------------------------------------------------------------
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _idleWaveController,
            builder: (context, child) {
              return CustomPaint(
                painter: _KineticMeshBackgroundPainter(
                  scrollOffset: _scrollOffset,
                  wavePhase: _idleWaveController.value * 2 * math.pi,
                ),
              );
            },
          ),
        ),

        // -----------------------------------------------------------------
        // 2. Main Scroll-Linked Reports Viewport (Shadcn-Inspired Structure)
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
              _ScrollWaveRevealCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 0,
                child: BentoHeroBanner(
                  title: 'Executive Analytics & System Reports',
                  subtitle:
                      'Real-time cost-savings opportunities, adherence distribution, and scroll-driven fluid waving metrics.',
                  icon: Icons.insights_rounded,
                  statusLabel: 'Fluid Telemetry Active',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timeframe Segmented Control (Shadcn Style)
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
              // Top Stats Counting Metric Cards Grid (TweenAnimationBuilder)
              // -------------------------------------------------------------
              _ScrollWaveRevealCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 40,
                child: _buildRealTimeStatsCounterGrid(
                    totalSavings, totalPrescriptions),
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------------------
              // FIRST ROW: BAR GRAPH & DONUT GRAPH (Top Visual Priority)
              // -------------------------------------------------------------
              _ScrollWaveRevealCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 90,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final barCard = _buildInteractiveSavingsBarChart();
                    final pieCard = _buildInteractiveAdherenceDonutChart();

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: barCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 5, child: pieCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        barCard,
                        const SizedBox(height: 16),
                        pieCard,
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // SECOND ROW (SCROLL DOWN): INTERACTIVE WAVING FLUID LINE GRAPH
              // -------------------------------------------------------------
              _ScrollWaveRevealCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 200,
                child: _buildFluidWavePADelayCard(),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // THIRD ROW (SCROLL FURTHER): MULTI-SERIES KINETIC VOLUMETRICS
              // -------------------------------------------------------------
              _ScrollWaveRevealCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 340,
                child: _buildMultiSeriesVolumetricLineChart(),
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
  Widget _buildRealTimeStatsCounterGrid(
      double totalSavings, int totalPrescriptions) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final tiles = [
          _buildCountingMetricTile(
            label: 'Annualized Net Savings',
            targetValue: totalSavings,
            prefix: '\$',
            suffix: '',
            isCurrency: true,
            trendText: '+24.8% YoY',
            icon: Icons.savings_rounded,
            iconColor: const Color(0xFF00E676),
            iconBg: const Color(0xFFE8F5E9),
          ),
          _buildCountingMetricTile(
            label: 'Total Active Prescriptions',
            targetValue: totalPrescriptions.toDouble(),
            prefix: '',
            suffix: '',
            isCurrency: false,
            trendText: 'Live DEA Stream',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFF00B4D8),
            iconBg: const Color(0xFFE0F7FA),
          ),
          _buildCountingMetricTile(
            label: 'Panel PDC Compliance Rate',
            targetValue: 87.4,
            prefix: '',
            suffix: '%',
            isCurrency: false,
            trendText: 'Optimal Target',
            icon: Icons.health_and_safety_rounded,
            iconColor: AppColors.primaryTeal,
            iconBg: AppColors.primaryLight,
          ),
          _buildCountingMetricTile(
            label: 'PA Claim Friction Resolved',
            targetValue: 94.2,
            prefix: '',
            suffix: '%',
            isCurrency: false,
            trendText: 'Automated e-PA',
            icon: Icons.verified_user_rounded,
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

  Widget _buildCountingMetricTile({
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
              if (isCurrency) {
                displayVal =
                    NumberFormat.currency(symbol: '\$', decimalDigits: 0)
                        .format(val);
              } else if (suffix == '%') {
                displayVal = '${val.toStringAsFixed(1)}%';
              } else {
                displayVal = NumberFormat('#,###').format(val.toInt());
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
  // FIRST ROW (LEFT): INTERACTIVE SAVINGS BY DRUG CLASS (Bar Chart)
  // ---------------------------------------------------------------------
  Widget _buildInteractiveSavingsBarChart() {
    return BentoCard(
      title: 'Cost-Savings Opportunities by Drug Class (\$k)',
      subtitle: 'Top therapeutic category optimization margins • Hover on bars',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bar_chart_rounded,
            color: Color(0xFF00B4D8), size: 18),
      ),
      child: AnimatedBuilder(
        animation: _chartAnimationController,
        builder: (context, child) {
          final anim = CurvedAnimation(
            parent: _chartAnimationController,
            curve: Curves.easeInOutCubic,
          ).value;

          return SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderLight.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                maxY: 25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.accentNavy,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final titles = [
                        'Statins',
                        'DOACs',
                        'SGLT2 Inhibitors',
                        'Biologics & mAbs'
                      ];
                      return BarTooltipItem(
                        '${titles[group.x.toInt()]}\n',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '\$${rod.toY.toStringAsFixed(1)}k Savings',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF00E676),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (response != null && response.spot != null) {
                        _touchedBarIndex =
                            response.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedBarIndex = -1;
                      }
                    });
                  },
                ),
                barGroups: [
                  _buildAnimatedBarGroup(
                    x: 0,
                    targetY: 18.5,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 0,
                    colorStart: const Color(0xFF00B4D8),
                    colorEnd: const Color(0xFF0077B6),
                  ),
                  _buildAnimatedBarGroup(
                    x: 1,
                    targetY: 21.4,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 1,
                    colorStart: const Color(0xFF00E676),
                    colorEnd: const Color(0xFF059669),
                  ),
                  _buildAnimatedBarGroup(
                    x: 2,
                    targetY: 12.8,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 2,
                    colorStart: const Color(0xFFFFB300),
                    colorEnd: const Color(0xFFFB8500),
                  ),
                  _buildAnimatedBarGroup(
                    x: 3,
                    targetY: 16.2,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 3,
                    colorStart: const Color(0xFF8B5CF6),
                    colorEnd: const Color(0xFF6D28D9),
                  ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (val, meta) => Text(
                        '\$${val.toInt()}k',
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
                      getTitlesWidget: (val, meta) {
                        final titles = [
                          'Statins',
                          'DOACs',
                          'SGLT2',
                          'Biologics'
                        ];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              titles[idx],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: _touchedBarIndex == idx
                                    ? FontWeight.w900
                                    : FontWeight.w700,
                                color: _touchedBarIndex == idx
                                    ? AppColors.primaryTeal
                                    : AppColors.textDark,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeInOutCubic,
            ),
          );
        },
      ),
    );
  }

  BarChartGroupData _buildAnimatedBarGroup({
    required int x,
    required double targetY,
    required double animProgress,
    required bool isSelected,
    required Color colorStart,
    required Color colorEnd,
  }) {
    final currentY = targetY * animProgress.clamp(0.01, 1.0);
    final hasActiveSelection = _touchedBarIndex != -1;
    final isDimmed = hasActiveSelection && !isSelected;

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: currentY,
          width: isSelected ? 38 : 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          gradient: LinearGradient(
            colors: isDimmed
                ? [
                    colorStart.withValues(alpha: 0.35),
                    colorEnd.withValues(alpha: 0.35)
                  ]
                : [colorStart, colorEnd],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 25,
            color: AppColors.bgSlate,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // FIRST ROW (RIGHT): INTERACTIVE ADHERENCE RISK (Safe Donut Chart)
  // ---------------------------------------------------------------------
  Widget _buildInteractiveAdherenceDonutChart() {
    return BentoCard(
      title: 'Panel Adherence Distribution',
      subtitle: 'Stratified by PDC compliance risk score',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.pie_chart_rounded,
            color: Color(0xFF00E676), size: 18),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _chartAnimationController,
                  builder: (context, pieChild) {
                    final rot = (1.0 -
                            CurvedAnimation(
                              parent: _chartAnimationController,
                              curve: Curves.easeOutCubic,
                            ).value) *
                        (-math.pi);
                    return Transform.rotate(
                      angle: rot,
                      child: pieChild,
                    );
                  },
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 44,
                      pieTouchData: PieTouchData(
                        touchCallback: (event, pieTouchResponse) {
                          setState(() {
                            if (pieTouchResponse != null &&
                                pieTouchResponse.touchedSection != null) {
                              _touchedPieIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            } else {
                              _touchedPieIndex = -1;
                            }
                          });
                        },
                      ),
                      sections: [
                        _buildSafeDonutSection(
                          index: 0,
                          value: 65,
                          label: '65%',
                          baseColor: const Color(0xFF00E676),
                        ),
                        _buildSafeDonutSection(
                          index: 1,
                          value: 22,
                          label: '22%',
                          baseColor: const Color(0xFFFFB300),
                        ),
                        _buildSafeDonutSection(
                          index: 2,
                          value: 13,
                          label: '13%',
                          baseColor: const Color(0xFFFF5252),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeInOutCubic,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '87.4%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'PDC Mean',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInteractiveLegendPill(
                index: 0,
                label: 'Optimal (≥80%)',
                percent: '65%',
                color: const Color(0xFF00E676),
              ),
              _buildInteractiveLegendPill(
                index: 1,
                label: 'At-Risk (50-79%)',
                percent: '22%',
                color: const Color(0xFFFFB300),
              ),
              _buildInteractiveLegendPill(
                index: 2,
                label: 'Critical (<50%)',
                percent: '13%',
                color: const Color(0xFFFF5252),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildSafeDonutSection({
    required int index,
    required double value,
    required String label,
    required Color baseColor,
  }) {
    final isSelected = _touchedPieIndex == index;
    final hasSelection = _touchedPieIndex != -1;
    final isDimmed = hasSelection && !isSelected;

    final radius = isSelected ? 54.0 : 46.0;
    final color =
        isDimmed ? baseColor.withValues(alpha: 0.40) : baseColor;

    return PieChartSectionData(
      value: value,
      color: color,
      title: isSelected ? '$label\nSelected' : label,
      radius: radius,
      titleStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: isSelected ? 11 : 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildInteractiveLegendPill({
    required int index,
    required String label,
    required String percent,
    required Color color,
  }) {
    final isSelected = _touchedPieIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _touchedPieIndex = _touchedPieIndex == index ? -1 : index;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : AppColors.bgSlate,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.metallicBorder,
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$label: $percent',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SECOND ROW (SCROLL DOWN): FLUID WAVING LINE GRAPH WITH SLOW JAN-JUN REVEAL
  // ---------------------------------------------------------------------
  Widget _buildFluidWavePADelayCard() {
    return BentoCard(
      title: 'Prior Authorization Claim Delay Resolution Trend (Avg Days)',
      subtitle:
          'Starts from Jan and fluidly resolves month-by-month • Magnetic hover tracking with live telemetry',
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
              'Continuous Wave Motion',
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
        animation: Listenable.merge([_idleWaveController, _lineProgressController]),
        builder: (context, child) {
          return _InteractiveFluidWaveGraph(
            scrollOffset: _scrollOffset,
            idlePhase: _idleWaveController.value * 2 * math.pi,
            lineProgress: _lineProgressController.value,
            dataPoints: const [18.0, 15.0, 16.0, 12.0, 9.0, 6.0],
            monthLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // THIRD ROW (SCROLL FURTHER): MULTI-SERIES KINETIC VOLUMETRICS
  // ---------------------------------------------------------------------
  Widget _buildMultiSeriesVolumetricLineChart() {
    return BentoCard(
      title: 'Prescription Dispensing & Prior-Auth Volumetrics',
      subtitle:
          'Starts from Jan and draws progressively • Click legend items below to toggle specific data series',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.stacked_line_chart_rounded,
            color: Color(0xFF7209B7), size: 18),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSeriesToggleFilter(
            label: 'Dispensed e-Rx',
            color: const Color(0xFF00E676),
            isActive: _showDispensedSeries,
            onToggle: () => setState(
                () => _showDispensedSeries = !_showDispensedSeries),
          ),
          const SizedBox(width: 8),
          _buildSeriesToggleFilter(
            label: 'PA Approved',
            color: const Color(0xFF00B4D8),
            isActive: _showApprovedSeries,
            onToggle: () => setState(
                () => _showApprovedSeries = !_showApprovedSeries),
          ),
          const SizedBox(width: 8),
          _buildSeriesToggleFilter(
            label: 'Auto-Refills',
            color: const Color(0xFF7209B7),
            isActive: _showRefillSeries,
            onToggle: () =>
                setState(() => _showRefillSeries = !_showRefillSeries),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _lineProgressController,
        builder: (context, child) {
          final progress = _lineProgressController.value.clamp(0.01, 1.0);

          final dispensedSpots = [
            FlSpot(0, 120 * progress),
            FlSpot(1, 145 * progress),
            FlSpot(2, 160 * progress),
            FlSpot(3, 190 * progress),
            FlSpot(4, 230 * progress),
            FlSpot(5, 280 * progress),
          ];

          final approvedSpots = [
            FlSpot(0, 80 * progress),
            FlSpot(1, 95 * progress),
            FlSpot(2, 110 * progress),
            FlSpot(3, 130 * progress),
            FlSpot(4, 175 * progress),
            FlSpot(5, 215 * progress),
          ];

          final refillSpots = [
            FlSpot(0, 40 * progress),
            FlSpot(1, 55 * progress),
            FlSpot(2, 65 * progress),
            FlSpot(3, 85 * progress),
            FlSpot(4, 110 * progress),
            FlSpot(5, 140 * progress),
          ];

          return SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 300,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
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
                        final names = [
                          'Dispensed',
                          'PA Approved',
                          'Auto-Refill'
                        ];
                        final colors = [
                          const Color(0xFF00E676),
                          const Color(0xFF00B4D8),
                          const Color(0xFF7209B7)
                        ];
                        final idx = spot.barIndex.clamp(0, 2);
                        return LineTooltipItem(
                          '${names[idx]}: ${spot.y.toInt()} Claims\n',
                          GoogleFonts.plusJakartaSans(
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
                      interval: 60,
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
                  if (_showDispensedSeries)
                    LineChartBarData(
                      spots: dispensedSpots,
                      isCurved: true,
                      color: const Color(0xFF00E676),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                      ),
                    ),
                  if (_showApprovedSeries)
                    LineChartBarData(
                      spots: approvedSpots,
                      isCurved: true,
                      color: const Color(0xFF00B4D8),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                      ),
                    ),
                  if (_showRefillSeries)
                    LineChartBarData(
                      spots: refillSpots,
                      isCurved: true,
                      color: const Color(0xFF7209B7),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF7209B7).withValues(alpha: 0.08),
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

  Widget _buildSeriesToggleFilter({
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
              width: isActive ? 1.3 : 1.0,
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
                style: GoogleFonts.plusJakartaSans(
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
}

// =========================================================================
// SCROLL-LINKED "WHIP & WAVE" CARD REVEAL WRAPPER
// =========================================================================
class _ScrollWaveRevealCard extends StatelessWidget {
  final Widget child;
  final double scrollOffset;
  final double triggerOffset;

  const _ScrollWaveRevealCard({
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
class _KineticMeshBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final double wavePhase;

  _KineticMeshBackgroundPainter({
    required this.scrollOffset,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final meshPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.primaryTeal.withValues(alpha: 0.04);

    // Dynamic undulating horizontal kinetic grid lines
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
  bool shouldRepaint(covariant _KineticMeshBackgroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.wavePhase != wavePhase;
  }
}

// =========================================================================
// INTERACTIVE FLUID WAVE GRAPH WITH MAGNETIC HOVER RIPPLE (CustomPainter)
// =========================================================================
class _InteractiveFluidWaveGraph extends StatefulWidget {
  final double scrollOffset;
  final double idlePhase;
  final double lineProgress;
  final List<double> dataPoints;
  final List<String> monthLabels;

  const _InteractiveFluidWaveGraph({
    required this.scrollOffset,
    required this.idlePhase,
    required this.lineProgress,
    required this.dataPoints,
    required this.monthLabels,
  });

  @override
  State<_InteractiveFluidWaveGraph> createState() =>
      _InteractiveFluidWaveGraphState();
}

class _InteractiveFluidWaveGraphState
    extends State<_InteractiveFluidWaveGraph> {
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
                painter: _FluidWaveGraphPainter(
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
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.dataPoints[_hoveredIndex!].toStringAsFixed(0)} Days Delay',
                              style: GoogleFonts.plusJakartaSans(
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

              // Bottom Month Axis Labels (Starts with Jan and goes to last month)
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
                      style: GoogleFonts.plusJakartaSans(
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

class _FluidWaveGraphPainter extends CustomPainter {
  final double scrollOffset;
  final double idlePhase;
  final double lineProgress;
  final List<double> dataPoints;
  final Offset? hoverPos;
  final ValueChanged<int?> onHoverIndexCalculated;

  _FluidWaveGraphPainter({
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

    final chartHeight = size.height - 30; // space for bottom axis
    final width = size.width;
    const maxVal = 20.0;

    final stepX = width / (dataPoints.length - 1);
    final points = <Offset>[];

    int? nearestIdx;
    double nearestDist = double.infinity;

    for (int i = 0; i < dataPoints.length; i++) {
      final x = i * stepX;
      // Fluid Wave transformation linked to scroll + idle oscillation
      final waveOffset = math.sin((i * 1.2) + idlePhase + (scrollOffset * 0.005)) * 4.0;
      final rawY = chartHeight - ((dataPoints[i] / maxVal) * (chartHeight - 30));
      var y = rawY + waveOffset;

      // Magnetic Attraction toward Hover Cursor
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

    // 1. Build Smooth Progressive Spline Path from Jan (0.0) up to lineProgress
    final currentEndIdxFloat = (points.length - 1) * lineProgress.clamp(0.01, 1.0);
    final maxDrawnIndex = currentEndIdxFloat.floor().clamp(0, points.length - 2);

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

      final controlPoint1 = Offset(p0.dx + (currentTargetP1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (currentTargetP1.dx - p0.dx) / 2, currentTargetP1.dy);

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

    // 2. Draw Undulating Healthcare Gradient Fill Under Curve
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

    // 3. Draw Fluid Wave Stroke
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

    // 4. Draw Data Point Vertices with Ripple Pulse up to progress
    for (int i = 0; i <= currentEndIdxFloat.ceil().clamp(0, points.length - 1); i++) {
      final pt = points[i];
      final isHovered = nearestIdx == i;

      if (isHovered) {
        // Glowing Halo Pulse
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
        ..color = isHovered ? const Color(0xFF00E5FF) : const Color(0xFF008080)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3.5 : 2.5;
      canvas.drawCircle(pt, isHovered ? 6.5 : 4.5, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _FluidWaveGraphPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.idlePhase != idlePhase ||
        oldDelegate.lineProgress != lineProgress ||
        oldDelegate.hoverPos != hoverPos;
  }
}
