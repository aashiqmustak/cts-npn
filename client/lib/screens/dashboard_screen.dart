import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'formulary_screen.dart';
import 'adherence_screen.dart';
import 'friction_screen.dart';
import 'admin_data_users_screen.dart';
import 'admin_reports_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Page Title & Subtitle Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Insurance & Costs',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your insurance, claims and track your medical expenses',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Role: ${user.role.name.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Horizontal Sub-Tabs Row
          _buildSubTabsRow(context, appState),

          const SizedBox(height: 20),

          // 3. Dynamic Sub-Tab Content Switcher
          if (appState.activeSubTabIndex == 0)
            _buildOverviewTabContent(context, appState)
          else if (appState.activeSubTabIndex == 1)
            const FormularyScreen()
          else if (appState.activeSubTabIndex == 2)
            const AdherenceScreen()
          else if (appState.activeSubTabIndex == 3)
            const FrictionScreen()
          else if (appState.activeSubTabIndex == 4)
            const AdminDataUsersScreen()
          else
            const AdminReportsScreen(),
        ],
      ),
    );
  }

  Widget _buildSubTabsRow(BuildContext context, AppState appState) {
    final tabs = [
      'Overview',
      'Formulary Explorer',
      'Adherence Risk',
      'PA Friction',
      if (appState.currentUser.isAdmin) 'Admin Data',
      if (appState.currentUser.isAdmin) 'Reports',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final title = entry.value;
            final isSelected = appState.activeSubTabIndex == idx;

            return InkWell(
              onTap: () => appState.setActiveSubTabIndex(idx),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryTeal
                        : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOverviewTabContent(BuildContext context, AppState appState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Main Column (Flex 7)
        Expanded(
          flex: 7,
          child: Column(
            children: [
              // Summary Card (Insurance Summary / Formulary Policy)
              _buildInsuranceSummaryCard(context),

              const SizedBox(height: 20),

              // Data Table Card (Recent Claims / Risk Table)
              _buildRecentClaimsTableCard(context, appState),

              const SizedBox(height: 20),

              // Bottom Reassurance Banner Card
              _buildBottomBannerCard(context),
            ],
          ),
        ),

        const SizedBox(width: 20),

        // Right Sidebar Column (Flex 4)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              // Widget 1: Coverage Overview Donut Chart Card
              _buildCoverageOverviewDonutCard(context),

              const SizedBox(height: 20),

              // Widget 2: Cashless Hospitals Provider List
              _buildCashlessHospitalsCard(context),

              const SizedBox(height: 20),

              // Widget 3: Quick Actions 4-Button Grid
              _buildQuickActionsGridCard(context, appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceSummaryCard(BuildContext context) {
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
                'Insurance Summary',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                ),
                onPressed: () {},
                child: Row(
                  children: const [
                    Text('View Policy Details', style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Active Policy Shield Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primaryTeal,
                  size: 34,
                ),
              ),

              const SizedBox(width: 16),

              // Policy Main Header Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Active Policy',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Health Secure Plus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Policy ID: HSN789456123',
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

          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          // 2x3 Key-Value Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Insurer', 'Health Secure Insurance Co.'),
              _buildMetricColumn('Policy Start Date', 'Jan 01, 2025'),
              _buildMetricColumn('Policy End Date', 'Dec 31, 2025'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Sum Insured', '₹ 5,00,000',
                  isBoldValue: true),
              _buildMetricColumn('Family Floater', 'Yes'),
              _buildMetricColumn('Members Covered', '4'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value,
      {bool isBoldValue = false}) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentClaimsTableCard(
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
                'Recent Claims',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All Claims',
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

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text('Claim ID',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Type',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Date',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Amount Claimed',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted)),
                ),
                Expanded(
                  flex: 2,
                  child: AlignmentText(
                    text: 'Status',
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          _buildClaimRow(
              'CLM789456',
              'General Consultation',
              Icons.assignment_outlined,
              Colors.purple,
              'May 10, 2025',
              '₹ 1,200',
              'Approved',
              AppColors.successBg,
              AppColors.successText),
          _buildClaimRow(
              'CLM789455',
              'Lab Test',
              Icons.science_outlined,
              Colors.blue,
              'May 08, 2025',
              '₹ 2,500',
              'Approved',
              AppColors.successBg,
              AppColors.successText),
          _buildClaimRow(
              'CLM789454',
              'Hospitalization',
              Icons.single_bed_outlined,
              Colors.orange,
              'Apr 28, 2025',
              '₹ 45,000',
              'Under Review',
              AppColors.warningBg,
              AppColors.warningText),
          _buildClaimRow(
              'CLM789453',
              'Medicines',
              Icons.medication_outlined,
              Colors.pink,
              'Apr 20, 2025',
              '₹ 1,800',
              'Approved',
              AppColors.successBg,
              AppColors.successText),
          _buildClaimRow(
              'CLM789452',
              'Diagnostic Scan',
              Icons.qr_code_scanner_rounded,
              Colors.teal,
              'Apr 15, 2025',
              '₹ 3,200',
              'Rejected',
              AppColors.dangerBg,
              AppColors.dangerText),

          const SizedBox(height: 16),

          Center(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () {},
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('View All Claims', style: TextStyle(fontSize: 12)),
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

  Widget _buildClaimRow(
    String id,
    String type,
    IconData icon,
    Color iconColor,
    String date,
    String amount,
    String status,
    Color bgStatus,
    Color textStatus,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              id,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              amount,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: bgStatus,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textStatus,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBannerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Stay stress-free with cashless hospitalization.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Check your coverage, find network hospitals and file claims easily.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {},
            child: Row(
              children: const [
                Text('Explore Benefits', style: TextStyle(fontSize: 12)),
                SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageOverviewDonutCard(BuildContext context) {
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
          const Text(
            'Coverage Overview',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              // Circular Donut Chart
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        startDegreeOffset: 270,
                        sections: [
                          PieChartSectionData(
                            color: AppColors.primaryTeal,
                            value: 25,
                            showTitle: false,
                            radius: 14,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFF2563EB),
                            value: 72,
                            showTitle: false,
                            radius: 14,
                          ),
                          PieChartSectionData(
                            color: const Color(0xFFF59E0B),
                            value: 3,
                            showTitle: false,
                            radius: 14,
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            '₹ 1,25,000',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'of ₹ 5,00,000 used',
                            style: TextStyle(
                              fontSize: 8,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow(
                        AppColors.primaryTeal, 'Used', '₹ 1,25,000'),
                    const SizedBox(height: 8),
                    _buildLegendRow(
                        const Color(0xFF2563EB), 'Available', '₹ 3,75,000'),
                    const SizedBox(height: 8),
                    _buildLegendRow(
                        const Color(0xFFF59E0B), 'Pending Claims', '₹ 15,000'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.25,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '25% of sum insured used',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
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

  Widget _buildCashlessHospitalsCard(BuildContext context) {
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
                'Cashless Hospitals',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'View All',
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

          _buildHospitalRow(
              'Apollo Hospitals', 'Chennai, Tamil Nadu', '2.1 km'),
          _buildHospitalRow(
              'Fortis Malar Hospital', 'Chennai, Tamil Nadu', '3.4 km'),
          _buildHospitalRow(
              'MIOT International', 'Chennai, Tamil Nadu', '5.2 km'),
          _buildHospitalRow(
              'Kauvery Hospital', 'Chennai, Tamil Nadu', '6.8 km'),
        ],
      ),
    );
  }

  Widget _buildHospitalRow(String name, String location, String distance) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.local_hospital_outlined,
                color: AppColors.primaryTeal, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                distance,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGridCard(
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),

          const SizedBox(height: 16),

          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSquareActionItem(Icons.note_add_outlined, 'File a Claim'),
              _buildSquareActionItem(
                  Icons.description_outlined, 'View Policy'),
              _buildSquareActionItem(
                  Icons.calculate_outlined, 'Check Coverage'),
              _buildSquareActionItem(
                  Icons.download_rounded, 'Download E-Card'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareActionItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class AlignmentText extends StatelessWidget {
  final String text;
  final Alignment alignment;

  const AlignmentText({super.key, required this.text, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
