import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../services/pipecat_service.dart';
import '../widgets/bento_card.dart';

class VoiceAgentScreen extends StatefulWidget {
  const VoiceAgentScreen({super.key});

  @override
  State<VoiceAgentScreen> createState() => _VoiceAgentScreenState();
}

class _VoiceAgentScreenState extends State<VoiceAgentScreen>
    with TickerProviderStateMixin {
  late final PipecatService _pipecatService;
  late final AnimationController _waveController;
  late final AnimationController _pulseController;
  late final AnimationController _visualizerController;

  @override
  void initState() {
    super.initState();
    _pipecatService = PipecatService();
    _pipecatService.addListener(_onServiceUpdate);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _visualizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pipecatService.removeListener(_onServiceUpdate);
    _pipecatService.disconnect();
    _pipecatService.dispose();
    _waveController.dispose();
    _pulseController.dispose();
    _visualizerController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMicTap() async {
    final state = _pipecatService.state;
    if (state == PipecatState.disconnected || state == PipecatState.failed) {
      await _pipecatService.connect();
    } else {
      await _pipecatService.disconnect();
    }
  }

  void _handlePromptTap(String prompt) {
    if (_pipecatService.state == PipecatState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Try speaking: "$prompt"',
              style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.primaryTeal,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connect to the Voice AI agent first, then speak.',
              style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.accentNavy,
        ),
      );
    }
  }

  List<String> _getSamplePromptsForRole(User user) {
    if (user.isDoctor) {
      return [
        'Prescribe Metformin 500mg for Eleanor Vance',
        'Dictate clinical diagnosis for Hypertension visit',
        'Check potential drug interactions for Lisinopril',
        'Retrieve patient medical records from MetroHealth',
      ];
    } else if (user.isPharmacist) {
      return [
        'Lookup active prescriptions for Eleanor Vance',
        'Fulfill and dispense Metformin 500mg tablet',
        'Check patient refill PDC compliance score',
        'Query formulary tier alternatives for Januvia',
      ];
    } else if (user.isPatient) {
      return [
        'I took my morning Metformin 500mg today',
        'When is my next scheduled medication dose?',
        'What is my current adherence streak rating?',
        'Add daily Vitamin D3 supplement to my schedule',
      ];
    } else if (user.isInsuranceAgent) {
      return [
        'Review Prior Authorization claim for Humira',
        'Check Tier 3 Preferred Brand copay structure',
        'Show estimated annual cost savings for Plan 01',
        'Identify active Step Therapy prescription friction',
      ];
    } else {
      return [
        'Check system health and Supabase live sync',
        'Show all authorized medical centers',
        'Generate daily platform analytics report',
        'Inspect security access audit log',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final prompts = _getSamplePromptsForRole(user);
    final state = _pipecatService.state;
    final isConnected = state == PipecatState.connected;
    final isConnecting = state == PipecatState.connecting;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Alternea AI Neural Voice Assistant',
            subtitle:
                'Hands-free clinical speech intelligence powered by WebRTC ultra low-latency streaming.',
            icon: Icons.graphic_eq_rounded,
            statusLabel: isConnected
                ? '🟢 Active Neural Link'
                : isConnecting
                    ? '🟡 Handshaking...'
                    : '⚪ Standby',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Role: ${user.role.name.toUpperCase()}',
                style: AppFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Siri-Style Interactive Voice Visualizer Stage
          BentoCard(
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            child: Column(
              children: [
                // Siri Glowing Orb Animated Stage (Isolated inside RepaintBoundary with fixed dimensions to eliminate all shaking)
                Center(
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: GestureDetector(
                        onTap: _handleMicTap,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Stack(
                            alignment: Alignment.center,
                            clipBehavior: Clip.none,
                            children: [
                              // Siri Animated Wave Aura & Ripples
                              AnimatedBuilder(
                                animation: Listenable.merge([
                                  _waveController,
                                  _pulseController,
                                  _visualizerController,
                                ]),
                                builder: (context, child) {
                                  return CustomPaint(
                                    size: const Size(260, 260),
                                    painter: _SiriWaveOrbPainter(
                                      waveProgress: _waveController.value,
                                      pulseProgress: _pulseController.value,
                                      visualizerProgress:
                                          _visualizerController.value,
                                      isConnected: isConnected,
                                      isConnecting: isConnecting,
                                    ),
                                  );
                                },
                              ),

                              // Core Floating Glass Button
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  final scale = isConnected
                                      ? 1.0 + (_pulseController.value * 0.05)
                                      : 1.0;
                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: isConnected
                                              ? [
                                                  const Color(0xFF00F2FE),
                                                  const Color(0xFF4FACFE),
                                                  const Color(0xFF008080),
                                                  const Color(0xFF0A1128),
                                                ]
                                              : isConnecting
                                                  ? [
                                                      const Color(0xFFFFB703),
                                                      const Color(0xFFFB8500),
                                                      const Color(0xFFD97706),
                                                    ]
                                                  : [
                                                      const Color(0xFF00C9A7),
                                                      const Color(0xFF008080),
                                                      const Color(0xFF0A1128),
                                                    ],
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isConnected
                                                    ? const Color(0xFF00F2FE)
                                                    : isConnecting
                                                        ? const Color(0xFFFFB703)
                                                        : AppColors.primaryTeal)
                                                .withValues(alpha: 0.5),
                                            blurRadius: 28,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isConnecting
                                              ? Icons.hourglass_top_rounded
                                              : isConnected
                                                  ? Icons.graphic_eq_rounded
                                                  : Icons.mic_rounded,
                                          color: Colors.white,
                                          size: 38,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // State Typography & Audio Spectrum Status
                Text(
                  isConnecting
                      ? 'Establishing Low-Latency Neural Link...'
                      : isConnected
                          ? 'Listening to Speech... Speak Naturally'
                          : state == PipecatState.failed
                              ? 'Connection Interrupted • Tap to Reconnect'
                              : 'Tap the Glowing Orb to Begin Voice Session',
                  style: AppFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isConnecting
                        ? AppColors.warningOrange
                        : isConnected
                            ? AppColors.primaryTeal
                            : state == PipecatState.failed
                                ? AppColors.dangerRed
                                : AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isConnected
                      ? '48 kHz WebRTC Opus Stream Active • AI Auto-Transcription On'
                      : 'Zero-latency continuous medical voice dictation & command execution',
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),

                if (isConnected) ...[
                  const SizedBox(height: 20),
                  // Animated Audio Waveform Spectrum Bar
                  _buildLiveAudioSpectrumBar(),
                ],

                const SizedBox(height: 28),

                // Prompt Chips Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 16, color: AppColors.primaryTeal),
                    const SizedBox(width: 8),
                    Text(
                      'Suggested Voice Directives for ${user.role.name.toUpperCase()}',
                      style: AppFonts.googleSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Prompt Action Pills
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: prompts.map((prompt) {
                    return _VoicePromptPill(
                      prompt: prompt,
                      onTap: () => _handlePromptTap(prompt),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Live Speech Transcript Bento Studio
          BentoCard(
            title: 'Real-Time Neural Transcript Feed',
            subtitle:
                'Synchronized multi-speaker medical interaction history',
            trailing: _pipecatService.transcripts.isNotEmpty
                ? TextButton.icon(
                    onPressed: () => _pipecatService.clearTranscripts(),
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.dangerRed),
                    label: Text(
                      'Clear History',
                      style: AppFonts.googleSans(
                        color: AppColors.dangerRed,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_pipecatService.transcripts.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.bgSlate,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.record_voice_over_rounded,
                              size: 32, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Speech Detected Yet',
                          style: AppFonts.googleSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap the glowing Siri sphere above to start speaking or dictating medical instructions.',
                          style: AppFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _pipecatService.transcripts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final item = _pipecatService.transcripts[idx];
                      final isUser = item.sender == 'user';
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primaryLight.withValues(alpha: 0.6)
                              : AppColors.bgSlate,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isUser
                                ? AppColors.primaryTeal.withValues(alpha: 0.25)
                                : AppColors.metallicBorder,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isUser
                                      ? AppColors.gradientPill
                                      : [
                                          AppColors.accentNavy,
                                          AppColors.primaryTeal,
                                        ],
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isUser
                                    ? Icons.person_rounded
                                    : Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        isUser
                                            ? user.name
                                            : 'Alternea Voice AI',
                                        style: AppFonts.googleSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        item.time,
                                        style: AppFonts.googleSans(
                                          fontSize: 10.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.text,
                                    style: AppFonts.googleSans(
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveAudioSpectrumBar() {
    return AnimatedBuilder(
      animation: _visualizerController,
      builder: (context, child) {
        final val = _visualizerController.value;
        final heights = [
          14.0 + (math.sin(val * math.pi * 2) * 12).abs(),
          24.0 + (math.cos(val * math.pi * 3) * 18).abs(),
          36.0 + (math.sin(val * math.pi * 4) * 22).abs(),
          20.0 + (math.cos(val * math.pi * 2.5) * 14).abs(),
          32.0 + (math.sin(val * math.pi * 3.5) * 20).abs(),
          42.0 + (math.sin(val * math.pi * 5) * 26).abs(),
          26.0 + (math.cos(val * math.pi * 4) * 16).abs(),
          16.0 + (math.sin(val * math.pi * 2) * 12).abs(),
        ];

        return Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.bgSlate,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.metallicBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: heights.map((h) {
              return Container(
                width: 4,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F2FE), Color(0xFF008080)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

/// Custom Siri Wave & Glowing Iridescent Orb Painter
class _SiriWaveOrbPainter extends CustomPainter {
  final double waveProgress;
  final double pulseProgress;
  final double visualizerProgress;
  final bool isConnected;
  final bool isConnecting;

  _SiriWaveOrbPainter({
    required this.waveProgress,
    required this.pulseProgress,
    required this.visualizerProgress,
    required this.isConnected,
    required this.isConnecting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.22;

    // 1. Ambient Outer Nebula Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: isConnected
            ? [
                const Color(0xFF00F2FE).withValues(alpha: 0.30),
                const Color(0xFF4FACFE).withValues(alpha: 0.18),
                const Color(0xFF7F00FF).withValues(alpha: 0.10),
                Colors.transparent,
              ]
            : isConnecting
                ? [
                    const Color(0xFFFFB703).withValues(alpha: 0.35),
                    const Color(0xFFFB8500).withValues(alpha: 0.18),
                    Colors.transparent,
                  ]
                : [
                    const Color(0xFF00C9A7).withValues(alpha: 0.20),
                    const Color(0xFF008080).withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
      ).createShader(
        Rect.fromCircle(
            center: center,
            radius: baseRadius * (1.4 + pulseProgress * 0.15)),
      );

    canvas.drawCircle(
      center,
      baseRadius * (1.4 + pulseProgress * 0.15),
      glowPaint,
    );

    // 2. Multi-Layered Rotating Chromatic Wave Harmonics (Siri Waves)
    final numRings = isConnected ? 4 : 2;
    for (int i = 0; i < numRings; i++) {
      final angleOffset = (i * math.pi / 2) + (waveProgress * math.pi * 2);
      final scaleFactor = 1.0 + (i * 0.14) + (pulseProgress * 0.05);

      final path = Path();
      const numPoints = 64;
      for (int j = 0; j <= numPoints; j++) {
        final theta = (j / numPoints) * 2 * math.pi;
        final wave = math.sin(theta * 3 + angleOffset) *
            (isConnected ? 7.0 : 3.0) *
            (1.0 + (i % 2 == 0 ? 0.5 : -0.3));
        final r = (baseRadius * scaleFactor) + wave;
        final x = center.dx + r * math.cos(theta);
        final y = center.dy + r * math.sin(theta);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      final ringColor = isConnected
          ? (i == 0
              ? const Color(0xFF00F2FE)
              : i == 1
                  ? const Color(0xFF4FACFE)
                  : i == 2
                      ? const Color(0xFF00C9A7)
                      : const Color(0xFF7F00FF))
          : (i == 0
              ? const Color(0xFF00C9A7)
              : const Color(0xFF008080));

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 - (i * 0.4)
        ..color = ringColor.withValues(alpha: 0.55 - (i * 0.1));

      canvas.drawPath(path, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SiriWaveOrbPainter oldDelegate) => true;
}

/// Interactive Prompt Action Pill with Hover Animation
class _VoicePromptPill extends StatefulWidget {
  final String prompt;
  final VoidCallback onTap;

  const _VoicePromptPill({
    required this.prompt,
    required this.onTap,
  });

  @override
  State<_VoicePromptPill> createState() => _VoicePromptPillState();
}

class _VoicePromptPillState extends State<_VoicePromptPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primaryLight : AppColors.bgSlate,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryTeal.withValues(alpha: 0.5)
                  : AppColors.metallicBorder,
              width: 1.2,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.record_voice_over_outlined,
                size: 15,
                color: _isHovered
                    ? AppColors.primaryTeal
                    : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                widget.prompt,
                style: AppFonts.googleSans(
                  fontSize: 12,
                  fontWeight:
                      _isHovered ? FontWeight.w800 : FontWeight.w600,
                  color: _isHovered
                      ? AppColors.primaryTeal
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
