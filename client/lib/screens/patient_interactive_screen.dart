import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class PatientInteractiveScreen extends StatefulWidget {
  const PatientInteractiveScreen({super.key});

  @override
  State<PatientInteractiveScreen> createState() =>
      _PatientInteractiveScreenState();
}

class _PatientInteractiveScreenState extends State<PatientInteractiveScreen>
    with TickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _entranceController;
  late final AnimationController _idleWaveController;
  late final AnimationController _chartAnimationController;
  late final AnimationController _lineProgressController;

  final _customMedController = TextEditingController();
  final _timeController = TextEditingController(text: '08:00 AM');

  double _scrollOffset = 0.0;
  String _selectedTimeframe = '7 Days';

  int _touchedBarIndex = -1;
  int _touchedPieIndex = -1;

  // Interactive Multi-Series Legend Visibility Toggles
  bool _showTakenSeries = true;
  bool _showOnTimeSeries = true;
  bool _showSupplementsSeries = true;

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

    // Staggered Entrance Controller
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    // Continuous Idle Living Wave Motion Controller (Looping)
    _idleWaveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    // Bar & Donut Chart Growth Animation Controller
    _chartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Line Graph Progressive Reveal from Jan to Last Month
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
    _customMedController.dispose();
    _timeController.dispose();
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

  void _addCustomMedicine(AppState appState) {
    if (_customMedController.text.trim().isEmpty) return;
    final newLog = PatientMedicineLog(
      id: 'LOG-${DateTime.now().millisecondsSinceEpoch}',
      patientId: appState.currentUser.patientId ?? 'PT-301',
      medicineName: _customMedController.text.trim(),
      scheduledTime: _timeController.text.trim(),
      isTaken: false,
      logDate: DateTime.now(),
      notes: 'Added by patient',
    );
    appState.patientLogs.add(newLog);
    _customMedController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryTeal,
        content: Text(
          'Medicine added to your daily schedule!',
          style: AppFonts.googleSans(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentPatientId = (appState.currentUser.patientId ?? appState.currentUser.id).toLowerCase();

    final logs = appState.patientLogs.where((l) {
      final pid = l.patientId.toLowerCase();
      return pid == currentPatientId ||
          pid == 'pat_00001' ||
          currentPatientId.contains(pid) ||
          pid.contains(currentPatientId);
    }).toList();

    if (logs.isEmpty) {
      final patientRxList = appState.prescriptions.where((r) =>
        r.patientId.toLowerCase() == currentPatientId ||
        currentPatientId.contains(r.patientId.toLowerCase())
      ).toList();

      for (final rx in patientRxList) {
        final items = appState.prescriptionItems.where((i) => i.prescriptionId == rx.id).toList();
        for (final item in items) {
          logs.add(
            PatientMedicineLog(
              id: 'LOG-${item.id}',
              patientId: appState.currentUser.patientId ?? 'PAT_00001',
              medicineName: item.medicineName,
              scheduledTime: item.frequency.contains('bedtime') ? '09:00 PM' : '08:00 AM',
              isTaken: false,
              logDate: DateTime.now(),
              notes: '${item.dosage} • ${item.frequency} • Prescribed by ${rx.prescriberName}',
            ),
          );
        }
      }
    }

    final takenCount = logs.where((l) => l.isTaken).length;
    final progress = logs.isEmpty ? 0.0 : takenCount / logs.length;

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
                painter: _PatientMeshBackgroundPainter(
                  scrollOffset: _scrollOffset,
                  wavePhase: _idleWaveController.value * 2 * math.pi,
                ),
              );
            },
          ),
        ),

        // -----------------------------------------------------------------
        // Main Scroll-Linked Patient Health Hub Viewport
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
              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 0,
                child: BentoHeroBanner(
                  title: 'Welcome Back, ${appState.currentUser.name}!',
                  subtitle:
                      'Track daily medication dosing schedules, monthly adherence streaks, and biomarker telemetries.',
                  icon: Icons.favorite_rounded,
                  statusLabel: '7-Day Adherence Streak 🔥',
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
              // Top Patient Counting Metric Cards Grid (TweenAnimationBuilder)
              // -------------------------------------------------------------
              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 40,
                child: _buildPatientStatsCounterGrid(takenCount, logs.length),
              ),

              const SizedBox(height: 18),

              // -------------------------------------------------------------
              // FIRST ROW: 7-DAY DOSING BAR GRAPH & ROUTINE DONUT GRAPH
              // -------------------------------------------------------------
              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 90,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final barCard = _buildPatientDosingBarChart();
                    final pieCard = _buildPatientRoutineDonutChart();

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
              // SECOND ROW (SCROLL DOWN): BIOMARKER & VITAL SIGNS WAVE GRAPH
              // -------------------------------------------------------------
              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 200,
                child: _buildPatientFluidWaveBiomarkerCard(),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // THIRD ROW (SCROLL FURTHER): MONTHLY WELLNESS VOLUMETRICS
              // -------------------------------------------------------------
              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 340,
                child: _buildPatientVolumetricLineChart(),
              ),

              const SizedBox(height: 20),

              // -------------------------------------------------------------
              // FOURTH ROW: TODAY'S MEDICATION SCHEDULE & QUICK ADD DOSE
              // -------------------------------------------------------------
              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 480,
                child: _buildTodayScheduleCard(logs, takenCount, progress),
              ),

              const SizedBox(height: 18),

              _PatientScrollWaveCard(
                scrollOffset: _scrollOffset,
                triggerOffset: 560,
                child: _buildQuickAddMedicineCard(appState),
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
  Widget _buildPatientStatsCounterGrid(int takenCount, int totalCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final tiles = [
          _buildPatientMetricTile(
            label: 'Adherence Streak',
            targetValue: 7.0,
            prefix: '',
            suffix: ' Days',
            isCurrency: false,
            trendText: '🔥 Fire Streak',
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFFB300),
            iconBg: const Color(0xFFFFF8E1),
          ),
          _buildPatientMetricTile(
            label: 'Overall Compliance',
            targetValue: 94.2,
            prefix: '',
            suffix: '%',
            isCurrency: false,
            trendText: 'Optimal Tier',
            icon: Icons.check_circle_rounded,
            iconColor: const Color(0xFF00E676),
            iconBg: const Color(0xFFE8F5E9),
          ),
          _buildPatientMetricTile(
            label: 'Doses Taken This Month',
            targetValue: 86.0,
            prefix: '',
            suffix: ' / 90',
            isCurrency: false,
            trendText: '95.5% On-Time',
            icon: Icons.medication_rounded,
            iconColor: const Color(0xFF00B4D8),
            iconBg: const Color(0xFFE0F7FA),
          ),
          _buildPatientMetricTile(
            label: 'Active Care Regimens',
            targetValue: 3.0,
            prefix: '',
            suffix: ' Meds',
            isCurrency: false,
            trendText: 'Dr. Rahul Verma',
            icon: Icons.medical_information_rounded,
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

  Widget _buildPatientMetricTile({
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
                displayVal = '${val.toInt()}$suffix';
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
  // FIRST ROW (LEFT): 7-DAY DOSING LOG (Bar Chart)
  // ---------------------------------------------------------------------
  Widget _buildPatientDosingBarChart() {
    return BentoCard(
      title: '7-Day Medication Intake & Adherence Log',
      subtitle: 'Daily scheduled dose completion rate over the past week',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bar_chart_rounded,
            color: Color(0xFF00E676), size: 18),
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
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderLight.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                alignment: BarChartAlignment.spaceAround,
                maxY: 4.5,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.accentNavy,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final days = [
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ];
                      return BarTooltipItem(
                        '${days[group.x.toInt()]}\n',
                        AppFonts.googleSans(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(
                            text: '${rod.toY.toInt()} / 3 Doses Taken',
                            style: AppFonts.googleSans(
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
                  _buildAnimatedPatientBarGroup(
                    x: 0,
                    targetY: 3,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 0,
                    colorStart: const Color(0xFF00E676),
                    colorEnd: const Color(0xFF059669),
                  ),
                  _buildAnimatedPatientBarGroup(
                    x: 1,
                    targetY: 3,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 1,
                    colorStart: const Color(0xFF00E676),
                    colorEnd: const Color(0xFF059669),
                  ),
                  _buildAnimatedPatientBarGroup(
                    x: 2,
                    targetY: 2,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 2,
                    colorStart: const Color(0xFFFFB300),
                    colorEnd: const Color(0xFFFB8500),
                  ),
                  _buildAnimatedPatientBarGroup(
                    x: 3,
                    targetY: 3,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 3,
                    colorStart: const Color(0xFF00E676),
                    colorEnd: const Color(0xFF059669),
                  ),
                  _buildAnimatedPatientBarGroup(
                    x: 4,
                    targetY: 3,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 4,
                    colorStart: const Color(0xFF00E676),
                    colorEnd: const Color(0xFF059669),
                  ),
                  _buildAnimatedPatientBarGroup(
                    x: 5,
                    targetY: 3,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 5,
                    colorStart: const Color(0xFF00E676),
                    colorEnd: const Color(0xFF059669),
                  ),
                  _buildAnimatedPatientBarGroup(
                    x: 6,
                    targetY: 3,
                    animProgress: anim,
                    isSelected: _touchedBarIndex == 6,
                    colorStart: const Color(0xFF00B4D8),
                    colorEnd: const Color(0xFF0077B6),
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
                      interval: 1,
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
                      getTitlesWidget: (val, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              days[idx],
                              style: AppFonts.googleSans(
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

  BarChartGroupData _buildAnimatedPatientBarGroup({
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
          width: isSelected ? 34 : 26, // Increased width
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
            toY: 4.5,
            color: AppColors.bgSlate,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // FIRST ROW (RIGHT): DAILY ROUTINE BREAKDOWN (Donut Chart)
  // ---------------------------------------------------------------------
  Widget _buildPatientRoutineDonutChart() {
    return BentoCard(
      title: 'Daily Medication Schedule Breakdown',
      subtitle: 'Distribution of scheduled doses across day times',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.pie_chart_rounded,
            color: Color(0xFF00B4D8), size: 18),
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
                        _buildPatientDonutSection(
                          index: 0,
                          value: 45,
                          label: '45%',
                          baseColor: const Color(0xFF00E676),
                        ),
                        _buildPatientDonutSection(
                          index: 1,
                          value: 25,
                          label: '25%',
                          baseColor: const Color(0xFF00B4D8),
                        ),
                        _buildPatientDonutSection(
                          index: 2,
                          value: 30,
                          label: '30%',
                          baseColor: const Color(0xFF7209B7),
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
                      '94.2%',
                      style: AppFonts.googleSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Compliance',
                      style: AppFonts.googleSans(
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
              _buildPatientLegendPill(
                index: 0,
                label: 'Morning (08:00)',
                percent: '45%',
                color: const Color(0xFF00E676),
              ),
              _buildPatientLegendPill(
                index: 1,
                label: 'Noon (13:00)',
                percent: '25%',
                color: const Color(0xFF00B4D8),
              ),
              _buildPatientLegendPill(
                index: 2,
                label: 'Evening (20:00)',
                percent: '30%',
                color: const Color(0xFF7209B7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPatientDonutSection({
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
      titleStyle: AppFonts.googleSans(
        color: Colors.white,
        fontSize: isSelected ? 11 : 10.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildPatientLegendPill({
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$label: $percent',
                style: AppFonts.googleSans(
                  fontSize: 10,
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
  // SECOND ROW (SCROLL DOWN): BIOMARKER & VITAL SIGNS WAVE GRAPH
  // ---------------------------------------------------------------------
  Widget _buildPatientFluidWaveBiomarkerCard() {
    return BentoCard(
      title: 'Biomarker Telemetry & Blood Glucose / BP Stability Index',
      subtitle:
          'Real-time wearable sync telemetry and physiological stability tracking • Magnetic hover tracking',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.favorite_outline_rounded,
            color: Color(0xFF00E676), size: 18),
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
              'Biometric Sync Active',
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
          return _PatientFluidWaveGraph(
            scrollOffset: _scrollOffset,
            idlePhase: _idleWaveController.value * 2 * math.pi,
            lineProgress: _lineProgressController.value,
            dataPoints: const [98.0, 96.5, 95.0, 92.5, 91.0, 88.5],
            monthLabels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // THIRD ROW (SCROLL FURTHER): MONTHLY WELLNESS VOLUMETRICS
  // ---------------------------------------------------------------------
  Widget _buildPatientVolumetricLineChart() {
    return BentoCard(
      title: 'Monthly Medication Intake & Wellness Volumetrics',
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
          _buildPatientSeriesToggle(
            label: 'Doses Taken',
            color: const Color(0xFF00E676),
            isActive: _showTakenSeries,
            onToggle: () =>
                setState(() => _showTakenSeries = !_showTakenSeries),
          ),
          const SizedBox(width: 8),
          _buildPatientSeriesToggle(
            label: 'On-Time Doses',
            color: const Color(0xFF00B4D8),
            isActive: _showOnTimeSeries,
            onToggle: () =>
                setState(() => _showOnTimeSeries = !_showOnTimeSeries),
          ),
          const SizedBox(width: 8),
          _buildPatientSeriesToggle(
            label: 'Supplements & Water',
            color: const Color(0xFF7209B7),
            isActive: _showSupplementsSeries,
            onToggle: () => setState(
                () => _showSupplementsSeries = !_showSupplementsSeries),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _lineProgressController,
        builder: (context, child) {
          final progress = _lineProgressController.value.clamp(0.01, 1.0);

          final takenSpots = [
            FlSpot(0, 70 * progress),
            FlSpot(1, 75 * progress),
            FlSpot(2, 80 * progress),
            FlSpot(3, 84 * progress),
            FlSpot(4, 88 * progress),
            FlSpot(5, 90 * progress),
          ];

          final onTimeSpots = [
            FlSpot(0, 62 * progress),
            FlSpot(1, 68 * progress),
            FlSpot(2, 74 * progress),
            FlSpot(3, 80 * progress),
            FlSpot(4, 85 * progress),
            FlSpot(5, 88 * progress),
          ];

          final supplementSpots = [
            FlSpot(0, 30 * progress),
            FlSpot(1, 35 * progress),
            FlSpot(2, 42 * progress),
            FlSpot(3, 50 * progress),
            FlSpot(4, 58 * progress),
            FlSpot(5, 60 * progress),
          ];

          return SizedBox(
            height: 230,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: 100,
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
                          'Taken',
                          'On-Time',
                          'Supplements'
                        ];
                        final colors = [
                          const Color(0xFF00E676),
                          const Color(0xFF00B4D8),
                          const Color(0xFF7209B7)
                        ];
                        final idx = spot.barIndex.clamp(0, 2);
                        return LineTooltipItem(
                          '${names[idx]}: ${spot.y.toInt()} Logs\n',
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
                      interval: 20,
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
                  if (_showTakenSeries)
                    LineChartBarData(
                      spots: takenSpots,
                      isCurved: true,
                      color: const Color(0xFF00E676),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00E676).withValues(alpha: 0.12),
                      ),
                    ),
                  if (_showOnTimeSeries)
                    LineChartBarData(
                      spots: onTimeSpots,
                      isCurved: true,
                      color: const Color(0xFF00B4D8),
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
                      ),
                    ),
                  if (_showSupplementsSeries)
                    LineChartBarData(
                      spots: supplementSpots,
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

  Widget _buildPatientSeriesToggle({
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
  // FOURTH ROW: TODAY'S MEDICATION SCHEDULE & QUICK ADD DOSE
  // ---------------------------------------------------------------------
  Widget _buildTodayScheduleCard(
      List<PatientMedicineLog> logs, int takenCount, double progress) {
    return BentoCard(
      title: 'Today’s Medication Schedule',
      subtitle: 'Tap checkbox once taken to log your adherence timestamp',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '$takenCount / ${logs.length} Taken',
          style: AppFonts.googleSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.bgSlate,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 16),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  'No medications scheduled for today.',
                  style: AppFonts.googleSans(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Checkbox(
                        value: log.isTaken,
                        activeColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        onChanged: (val) {
                          setState(() {
                            log.isTaken = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.medicineName,
                              style: AppFonts.googleSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                decoration: log.isTaken
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: log.isTaken
                                    ? AppColors.textMuted
                                    : AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Scheduled: ${log.scheduledTime} • ${log.notes}',
                              style: AppFonts.googleSans(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '👨‍⚕️ Prescribed by Dr. Tariq Martin, MD • 🏥 Purchased at MetroHealth Pharmacy Hub (#402)',
                              style: AppFonts.googleSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: log.isTaken
                              ? AppColors.successBg
                              : AppColors.warningBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          log.isTaken ? 'Taken' : 'Pending',
                          style: AppFonts.googleSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: log.isTaken
                                ? AppColors.successText
                                : AppColors.warningText,
                          ),
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

  Widget _buildQuickAddMedicineCard(AppState appState) {
    return BentoCard(
      title: 'Add Supplemental Medication / Vitamin',
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _customMedController,
              style: AppFonts.googleSans(fontSize: 13),
              decoration: const InputDecoration(
                hintText:
                    'Medicine / Supplement Name (e.g. Vitamin D3 1000 IU)',
                prefixIcon: Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primaryTeal),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _timeController,
              style: AppFonts.googleSans(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Time (e.g. 08:00 AM)',
                prefixIcon: Icon(Icons.access_time_rounded,
                    color: AppColors.primaryTeal),
              ),
            ),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            onPressed: () => _addCustomMedicine(appState),
            child: Text('Add to Schedule',
                style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// SCROLL-LINKED CARD REVEAL WRAPPER
// =========================================================================
class _PatientScrollWaveCard extends StatelessWidget {
  final Widget child;
  final double scrollOffset;
  final double triggerOffset;

  const _PatientScrollWaveCard({
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
class _PatientMeshBackgroundPainter extends CustomPainter {
  final double scrollOffset;
  final double wavePhase;

  _PatientMeshBackgroundPainter({
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
  bool shouldRepaint(covariant _PatientMeshBackgroundPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.wavePhase != wavePhase;
  }
}

// =========================================================================
// INTERACTIVE FLUID WAVE GRAPH WITH MAGNETIC HOVER RIPPLE (CustomPainter)
// =========================================================================
class _PatientFluidWaveGraph extends StatefulWidget {
  final double scrollOffset;
  final double idlePhase;
  final double lineProgress;
  final List<double> dataPoints;
  final List<String> monthLabels;

  const _PatientFluidWaveGraph({
    required this.scrollOffset,
    required this.idlePhase,
    required this.lineProgress,
    required this.dataPoints,
    required this.monthLabels,
  });

  @override
  State<_PatientFluidWaveGraph> createState() => _PatientFluidWaveGraphState();
}

class _PatientFluidWaveGraphState extends State<_PatientFluidWaveGraph> {
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
                painter: _PatientWaveGraphPainter(
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
                            color:
                                AppColors.jewelTechCyan.withValues(alpha: 0.4),
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
                              '${widget.dataPoints[_hoveredIndex!].toStringAsFixed(1)} mg/dL Mean',
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

class _PatientWaveGraphPainter extends CustomPainter {
  final double scrollOffset;
  final double idlePhase;
  final double lineProgress;
  final List<double> dataPoints;
  final Offset? hoverPos;
  final ValueChanged<int?> onHoverIndexCalculated;

  _PatientWaveGraphPainter({
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
    const maxVal = 120.0;

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
          const Color(0xFF00E676).withValues(alpha: 0.35),
          const Color(0xFF00B4D8).withValues(alpha: 0.18),
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
          Color(0xFF00E676),
          Color(0xFF00E5FF),
          Color(0xFF00B4D8),
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
  bool shouldRepaint(covariant _PatientWaveGraphPainter oldDelegate) {
    return oldDelegate.scrollOffset != scrollOffset ||
        oldDelegate.idlePhase != idlePhase ||
        oldDelegate.lineProgress != lineProgress ||
        oldDelegate.hoverPos != hoverPos;
  }
}
