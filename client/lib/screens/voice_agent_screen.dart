import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class VoiceAgentScreen extends StatefulWidget {
  const VoiceAgentScreen({super.key});

  @override
  State<VoiceAgentScreen> createState() => _VoiceAgentScreenState();
}

enum VoiceState { idle, listening, processing, speaking }

class _VoiceAgentScreenState extends State<VoiceAgentScreen>
    with SingleTickerProviderStateMixin {
  VoiceState _voiceState = VoiceState.idle;
  late AnimationController _pulseController;
  final TextEditingController _voiceInputController = TextEditingController();

  final List<Map<String, String>> _transcriptHistory = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _voiceInputController.dispose();
    super.dispose();
  }

  void _triggerVoiceCommand(String commandText, AppState appState) async {
    setState(() {
      _voiceState = VoiceState.listening;
      _voiceInputController.text = commandText;
      _transcriptHistory.insert(0, {
        'sender': 'user',
        'text': commandText,
        'time': 'Just now',
      });
    });

    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _voiceState = VoiceState.processing;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    String aiResponse = _generateRoleResponse(commandText, appState);

    setState(() {
      _voiceState = VoiceState.speaking;
      _transcriptHistory.insert(0, {
        'sender': 'agent',
        'text': aiResponse,
        'time': 'Just now',
      });
    });

    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _voiceState = VoiceState.idle;
      });
    }
  }

  String _generateRoleResponse(String query, AppState appState) {
    final user = appState.currentUser;
    final lowerQuery = query.toLowerCase();

    if (user.isDoctor) {
      if (lowerQuery.contains('prescribe') || lowerQuery.contains('metformin')) {
        return 'Understood, Doctor. Preparing digital prescription for Metformin 500mg, twice daily for Eleanor Vance at St. Jude Hospital. Shall I issue it to the pharmacist?';
      } else if (lowerQuery.contains('notes') || lowerQuery.contains('visit')) {
        return 'Clinical notes logged: Patient presented with routine hypertension checkup. Blood pressure stable at 128/82. Prescription updated in Supabase.';
      }
      return 'Doctor AI Assistant active. You can dictate patient visit details, prescribe medications, or query hospital records by voice.';
    } else if (user.isPharmacist) {
      if (lowerQuery.contains('eleanor') || lowerQuery.contains('lookup')) {
        return 'Found 1 active prescription for Eleanor Vance: Metformin 500mg issued by Dr. Robert Vance at St. Jude Hospital. Status is ready for dispensing.';
      } else if (lowerQuery.contains('dispense') || lowerQuery.contains('fill')) {
        return 'Dispensed Metformin 500mg for Eleanor Vance. Inventory updated and patient notification sent.';
      }
      return 'Pharmacist AI Assistant active. Voice lookup for patient names, inspect doctor notes, or confirm medication dispensing.';
    } else if (user.isPatient) {
      if (lowerQuery.contains('took') || lowerQuery.contains('taken') || lowerQuery.contains('metformin')) {
        return 'Great job! I logged your 500mg Metformin as taken today at 8:00 AM. Your adherence streak is now 7 days! 🔥';
      } else if (lowerQuery.contains('next') || lowerQuery.contains('schedule')) {
        return 'Your next scheduled medication is Lisinopril 10mg at 8:00 PM tonight.';
      }
      return 'Personal Health Voice Agent active. Ask me if you took your pills, log new supplements, or check your daily medication schedule!';
    } else if (user.isInsuranceAgent) {
      if (lowerQuery.contains('prior') || lowerQuery.contains('humira') || lowerQuery.contains('pa')) {
        return 'Humira 40mg requires Prior Authorization on Tier 5 Specialty. 2 preferred generic alternatives available with \$450 monthly savings.';
      }
      return 'Insurance & Formulary Voice Agent active. Ask about tier copays, prior authorization requirements, or alternative savings.';
    } else {
      // Software Admin
      if (lowerQuery.contains('hospital') || lowerQuery.contains('status')) {
        return 'Software System Status: Supabase cloud database connected. Active hospitals registered: 3. Total prescriptions processed: 142.';
      }
      return 'Alternea Software Admin AI active. Request system diagnostics, active user counts, or database sync status.';
    }
  }

  List<String> _getSamplePromptsForRole(User user) {
    if (user.isDoctor) {
      return [
        'Prescribe Metformin 500mg for Eleanor Vance',
        'Dictate visit notes for Hypertension checkup',
        'Check drug interactions for Lisinopril',
        'Query St. Jude Hospital patient queue',
      ];
    } else if (user.isPharmacist) {
      return [
        'Lookup prescriptions for Eleanor Vance',
        'Confirm dispensing for Metformin 500mg',
        'Speak dosage instructions for patient',
        'Check refill authorization status',
      ];
    } else if (user.isPatient) {
      return [
        'I took my 8 AM Metformin 500mg today',
        'What is my next medication schedule?',
        'What is my current adherence streak?',
        'Add Daily Vitamin D3 supplement',
      ];
    } else if (user.isInsuranceAgent) {
      return [
        'Check Prior Authorization for Humira',
        'What is the Tier 3 Preferred Brand copay?',
        'Show lower-cost formulary alternatives',
        'Review recent PA friction events',
      ];
    } else {
      return [
        'System Status & Supabase DB Sync',
        'Show active registered hospitals',
        'Generate daily platform usage report',
        'Check active user security logs',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final prompts = _getSamplePromptsForRole(user);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Alternea AI Voice Agent',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Role: ${user.roleLabel}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Speak commands or select voice actions tailored to your active workflow.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Central Voice Visualizer & Controls
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Animated Glowing Microphone Circle
                GestureDetector(
                  onTap: () {
                    if (_voiceState == VoiceState.idle) {
                      _triggerVoiceCommand(prompts.first, appState);
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      final pulseScale = _voiceState != VoiceState.idle
                          ? 1.0 + (_pulseController.value * 0.15)
                          : 1.0;
                      return Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _voiceState == VoiceState.listening
                                  ? [AppColors.warningOrange, Colors.deepOrange]
                                  : _voiceState == VoiceState.speaking
                                      ? [AppColors.successGreen, Colors.teal]
                                      : [AppColors.primaryTeal, AppColors.accentNavy],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_voiceState == VoiceState.listening
                                        ? AppColors.warningOrange
                                        : AppColors.primaryTeal)
                                    .withValues(alpha: 0.4),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            _voiceState == VoiceState.listening
                                ? Icons.mic_rounded
                                : _voiceState == VoiceState.speaking
                                    ? Icons.volume_up_rounded
                                    : Icons.mic_none_rounded,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Status Indicator Text
                Text(
                  _voiceState == VoiceState.listening
                      ? 'Listening to your voice command...'
                      : _voiceState == VoiceState.processing
                          ? 'Processing AI Audio Stream...'
                          : _voiceState == VoiceState.speaking
                              ? 'AI Assistant Speaking Response...'
                              : 'Tap Microphone or select prompt below to speak',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _voiceState == VoiceState.listening
                        ? AppColors.warningOrange
                        : _voiceState == VoiceState.speaking
                            ? AppColors.primaryTeal
                            : AppColors.accentNavy,
                  ),
                ),

                const SizedBox(height: 24),

                // Voice Prompt Chips Grid
                const Text(
                  'Recommended Voice Commands:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: prompts.map((prompt) {
                    return ActionChip(
                      avatar: const Icon(Icons.record_voice_over_outlined,
                          size: 16, color: AppColors.primaryTeal),
                      label: Text(
                        prompt,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                        ),
                      ),
                      backgroundColor: AppColors.bgSlate,
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onPressed: () => _triggerVoiceCommand(prompt, appState),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Live Speech Transcript & History Log
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Voice Transcript & Interaction History',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentNavy,
                      ),
                    ),
                    if (_transcriptHistory.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => setState(() => _transcriptHistory.clear()),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Clear Transcript'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_transcriptHistory.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Column(
                      children: const [
                        Icon(Icons.forum_outlined,
                            size: 40, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No voice transcript recorded yet.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Column(
                    children: _transcriptHistory.map((item) {
                      final isUser = item['sender'] == 'user';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? AppColors.primaryTeal.withValues(alpha: 0.08)
                              : AppColors.bgSlate,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUser
                                ? AppColors.primaryTeal.withValues(alpha: 0.2)
                                : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: isUser
                                  ? AppColors.primaryTeal
                                  : AppColors.accentNavy,
                              child: Icon(
                                isUser ? Icons.person : Icons.smart_toy_rounded,
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
                                        isUser ? user.name : 'Alternea Voice AI',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      Text(
                                        item['time'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['text'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                        height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
