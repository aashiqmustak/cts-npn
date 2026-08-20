import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MyMedicinesScreen extends StatefulWidget {
  const MyMedicinesScreen({super.key});

  @override
  State<MyMedicinesScreen> createState() => _MyMedicinesScreenState();
}

class _MyMedicinesScreenState extends State<MyMedicinesScreen> {
  int _activeFilterTab = 0; // 0: All, 1: Active, 2: Completed, 3: On Hold
  final TextEditingController _aiChatController = TextEditingController();
  final List<String> _chatMessages = [];

  @override
  void dispose() {
    _aiChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'My Medicines',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Track, manage and understand your medications',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Add Medicine',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showAddMedicineModal(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sub-Tabs Bar & Sort Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildSubTabButton(0, 'All Medicines'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(1, 'Active'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(2, 'Completed'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(3, 'On Hold'),
                ],
              ),
              Row(
                children: const [
                  Text('Sort by: ',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('Recently Added ∨',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main 2-Column Content Area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Flex 7) — Medication Cards List
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    if (appState.patientLogs.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: const [
                            Icon(Icons.medication_outlined, size: 44, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text(
                              'No Medicines Recorded in Database',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.accentNavy),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Your active medications and daily logs will appear here once recorded in Supabase.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: appState.patientLogs.map((log) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildMedicineDetailCard(
                              name: log.medicineName,
                              condition: log.notes ?? 'Prescribed Medication',
                              schedule: '☀️ Scheduled • ${log.scheduledTime}',
                              status: log.isTaken ? 'Taken ✓' : 'Active',
                              nextDose: log.scheduledTime,
                              remaining: 'Active Schedule',
                              refillDate: 'On Schedule',
                              adherencePct: log.isTaken ? 1.0 : 0.85,
                              adherenceLabel: log.isTaken ? '100% Taken' : 'Pending Dose',
                              pillColor: log.isTaken ? AppColors.primaryTeal : const Color(0xFF8B5CF6),
                              bgColor: log.isTaken ? AppColors.primaryLight : const Color(0xFFF3E8FF),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right Column (Flex 4) — Summary, AI Bot & Actions
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Widget 1: Your Medication Summary Donut Card
                    _buildMedicationSummaryCard(context, appState),

                    const SizedBox(height: 20),

                    // Widget 2: AI Medication Assistant Robot Widget 🤖
                    _buildAiAssistantCard(context),

                    const SizedBox(height: 20),

                    // Widget 3: Quick Actions Grid
                    _buildQuickActionsGrid(context, appState),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeFilterTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activeFilterTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineDetailCard({
    required String name,
    required String condition,
    required String schedule,
    required String status,
    required String nextDose,
    required String remaining,
    required String refillDate,
    required double adherencePct,
    required String adherenceLabel,
    required Color pillColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Pill 3D Render Placeholder Box
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.medication_rounded,
                    color: pillColor, size: 30),
              ),

              const SizedBox(width: 14),

              // Name & Condition
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      condition,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      schedule,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),

              // Active Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.successText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 20),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),

          // 4 Grid Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMedicineStatItem('Next Dose', nextDose, Icons.access_time_rounded),
              _buildMedicineStatItem('Remaining', remaining, Icons.inventory_2_outlined),
              _buildMedicineStatItem('Refill On', refillDate, Icons.calendar_today_outlined),

              // Adherence Donut Meter
              Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: adherencePct,
                      strokeWidth: 4,
                      backgroundColor: AppColors.borderLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Adherence',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textMuted)),
                      Text(
                        adherenceLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineStatItem(String label, String val, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primaryTeal),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text(
              val,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicationSummaryCard(
      BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Medication Summary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View Details >',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.primaryTeal)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 110,
                height: 110,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 32,
                        sections: [
                          PieChartSectionData(
                              color: AppColors.primaryTeal,
                              value: 876,
                              showTitle: false,
                              radius: 12),
                          PieChartSectionData(
                              color: const Color(0xFF2563EB),
                              value: 278,
                              showTitle: false,
                              radius: 12),
                          PieChartSectionData(
                              color: const Color(0xFFF59E0B),
                              value: 100,
                              showTitle: false,
                              radius: 12),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Total Monthly',
                            style: TextStyle(
                                fontSize: 8, color: AppColors.textMuted)),
                        Text('₹1,254',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // Legend
              Expanded(
                child: Column(
                  children: [
                    _buildSummaryLegendRow(
                        AppColors.primaryTeal, 'Covered by Insurance', '₹876'),
                    const SizedBox(height: 6),
                    _buildSummaryLegendRow(
                        const Color(0xFF2563EB), 'You Pay', '₹278'),
                    const SizedBox(height: 6),
                    _buildSummaryLegendRow(
                        const Color(0xFFF59E0B), 'Not Covered', '₹100'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Savings Pill Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You can save up to ₹180',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0369A1)),
                      ),
                      Text(
                        'Explore cost-effective alternatives',
                        style: TextStyle(
                            fontSize: 9, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLegendRow(Color color, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        Text(amount,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildAiAssistantCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.smart_toy_outlined,
                  color: AppColors.primaryTeal, size: 22),
              SizedBox(width: 8),
              Text(
                'AI Medication Assistant',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentNavy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            'Need help with your medicines?\nAsk me anything about dosage, side effects, interactions, etc.',
            style: TextStyle(fontSize: 11, color: AppColors.textDark),
          ),

          const SizedBox(height: 12),

          // Chat Messages Box
          if (_chatMessages.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _chatMessages
                    .map((msg) => Text(msg,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textDark)))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Chat Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiChatController,
                  decoration: const InputDecoration(
                    hintText: 'Ask something...',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fillColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  if (_aiChatController.text.isNotEmpty) {
                    setState(() {
                      _chatMessages.add('You: ${_aiChatController.text}');
                      _chatMessages.add(
                          'Bot: Take Atorvastatin after dinner to optimize statin absorption.');
                      _aiChatController.clear();
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryTeal,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(
      BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSquareAction(Icons.upload_file_rounded, 'Upload Prescription'),
              _buildSquareAction(Icons.notifications_none_rounded, 'Set Reminder'),
              _buildSquareAction(Icons.shopping_bag_outlined, 'Order Refill'),
              _buildSquareAction(Icons.search_rounded, 'Find Medicine'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Medication'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Medicine Name')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Dosage & Frequency')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Medication added successfully!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: const Text('Save Medication'),
          ),
        ],
      ),
    );
  }
}
