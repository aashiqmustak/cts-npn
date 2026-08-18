import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

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
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentNavy,
                ),
              ),
              Row(
                children: const [
                  Text(
                    'May 20, 2025',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.calendar_today_outlined,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4 Top KPI Cards Row
          _buildKpiRow(context, appState),

          const SizedBox(height: 24),

          // Main 2-Column Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Flex 7)
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    // My Medicines Quick List
                    _buildMyMedicinesCard(context, appState),

                    const SizedBox(height: 20),

                    // Upcoming Reminders Schedule
                    _buildUpcomingRemindersCard(context),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right Column (Flex 5)
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    // Health Summary Gauge Card
                    _buildHealthSummaryCard(context),

                    const SizedBox(height: 20),

                    // Recent Prescriptions Card
                    _buildRecentPrescriptionsCard(context, appState),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom Notification Reminder Banner
          _buildNotificationBanner(context),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, AppState appState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                title: 'Active Medicines',
                value: '3',
                actionText: 'View all',
                icon: Icons.medication_outlined,
                iconColor: AppColors.primaryTeal,
                bgColor: const Color(0xFFE6F7F5),
                onTap: () => appState.setNavIndex(1),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                title: 'Prescriptions',
                value: '2',
                actionText: 'View all',
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF3E8FF),
                onTap: () => appState.setNavIndex(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                title: 'Insurance Coverage',
                value: 'Active',
                actionText: 'View details',
                icon: Icons.verified_user_outlined,
                iconColor: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                onTap: () => appState.setNavIndex(4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                title: 'Next Reminder',
                value: '8:00 PM',
                subtitle: 'Today',
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(0xFF2563EB),
                bgColor: const Color(0xFFE0F2FE),
                onTap: () => appState.setNavIndex(5),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    String? actionText,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: value == 'Active' ? AppColors.primaryTeal : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            if (actionText != null)
              Row(
                children: [
                  Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              )
            else if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyMedicinesCard(BuildContext context, AppState appState) {
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
                'My Medicines',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () => appState.setNavIndex(1),
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryTeal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildMedicineListItem(
            name: 'Atorvastatin 20mg',
            dosage: '1 tablet • Once daily • After dinner',
            time: '8:00 PM',
            dayLabel: 'Today',
            iconColor: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 10),
          _buildMedicineListItem(
            name: 'Metformin 500mg',
            dosage: '1 tablet • Twice daily • After meals',
            time: '2:00 PM',
            dayLabel: 'Today',
            iconColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _buildMedicineListItem(
            name: 'Vitamin D3 1000 IU',
            dosage: '1 tablet • Once daily • After breakfast',
            time: '8:00 AM',
            dayLabel: 'Tomorrow',
            iconColor: const Color(0xFFF59E0B),
          ),

          const SizedBox(height: 16),

          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () => appState.setNavIndex(1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.list_alt_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('View Full Medication List',
                      style: TextStyle(fontSize: 12)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineListItem({
    required String name,
    required String dosage,
    required String time,
    required String dayLabel,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.medication_rounded, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  dosage,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Active',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.successText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                dayLabel,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }

  Widget _buildUpcomingRemindersCard(BuildContext context) {
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
                'Upcoming Reminders',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: const [
                    Text('View calendar',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primaryTeal),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildReminderRow(
              '8:00 PM', 'Atorvastatin 20mg', '1 tablet • After dinner', 'Today', true),
          _buildReminderRow(
              '8:00 AM', 'Vitamin D3 1000 IU', '1 tablet • After breakfast', 'Tomorrow', false),
          _buildReminderRow(
              '2:00 PM', 'Metformin 500mg', '1 tablet • After lunch', 'Tomorrow', false),
        ],
      ),
    );
  }

  Widget _buildReminderRow(String time, String medicine, String detail,
      String tag, bool isToday) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_none_rounded,
              color: AppColors.primaryTeal, size: 18),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isToday ? AppColors.infoBg : AppColors.bgSlate,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isToday ? AppColors.infoText : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildHealthSummaryCard(BuildContext context) {
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
                'Health Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: const [
                    Text('View full report',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primaryTeal),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              // Circular Gauge Score
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: 0.85,
                      strokeWidth: 7,
                      backgroundColor: AppColors.borderLight,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        '85',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Good',
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Your health score is good!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Keep following your medications and maintain a healthy lifestyle.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 14),

          // 3 Health Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHealthMetricItem(
                icon: Icons.directions_walk_rounded,
                iconColor: AppColors.primaryTeal,
                label: 'Steps',
                val: '6,245',
                target: '/10,000',
              ),
              _buildHealthMetricItem(
                icon: Icons.water_drop_outlined,
                iconColor: Colors.blue,
                label: 'Water',
                val: '6',
                target: 'cups',
              ),
              _buildHealthMetricItem(
                icon: Icons.nightlight_round_outlined,
                iconColor: Colors.purple,
                label: 'Sleep',
                val: '7.2',
                target: 'hrs',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetricItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String val,
    required String target,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: val,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextSpan(
                    text: ' $target',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentPrescriptionsCard(
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
                'Recent Prescriptions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () => appState.setNavIndex(2),
                child: Row(
                  children: const [
                    Text('View all',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryTeal,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primaryTeal),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildPrescriptionItem(
            id: 'Prescription #RX58921',
            doctor: 'Dr. Rahul Verma',
            date: 'May 15, 2025',
            onTap: () => appState.setNavIndex(2),
          ),
          const SizedBox(height: 10),
          _buildPrescriptionItem(
            id: 'Prescription #RX58711',
            doctor: 'Dr. Rahul Verma',
            date: 'Apr 28, 2025',
            onTap: () => appState.setNavIndex(2),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItem({
    required String id,
    required String doctor,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgSlate,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: AppColors.infoText, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    '$doctor • $date',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.successText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Get timely reminders and never miss your medicines',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Turn on notifications to stay updated with your medication schedule.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Medication push notifications enabled!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: const Text('Enable Notifications',
                style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {},
            child: const Text('Not now',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
