import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // 1. Page Title & Role Banner
          // -------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientBrand,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentNavy.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insurance & Financial Portal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage your health insurance policies, claims records, and drug copay structures.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Role: ${user.role.name.toUpperCase()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------
          // 2. Horizontal Sub-Tabs Row
          // -------------------------------------------------------------
          _buildSubTabsRow(context, appState),

          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // 3. Dynamic Sub-Tab Content Switcher
          // -------------------------------------------------------------
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final idx = entry.key;
            final title = entry.value;
            final isSelected = appState.activeSubTabIndex == idx;

            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => appState.setActiveSubTabIndex(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryTeal : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textMuted,
                    ),
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
              _buildInsuranceSummaryCard(context),
              const SizedBox(height: 20),
              _buildRecentClaimsTableCard(context, appState),
              const SizedBox(height: 20),
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
              _buildCoverageOverviewDonutCard(context),
              const SizedBox(height: 20),
              _buildCashlessHospitalsCard(context),
              const SizedBox(height: 20),
              _buildQuickActionsGridCard(context, appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Coverage Summary',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  side: const BorderSide(color: AppColors.borderLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: Row(
                  children: [
                    Text('View Policy Details', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.primaryTeal,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active Health Plan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alternea Health Secure Plus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Policy ID: HSN789456123 • Medicare Part D',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Insurer Carrier', 'Alternea CMS Health Network'),
              _buildMetricColumn('Coverage Start', 'Jan 01, 2025'),
              _buildMetricColumn('Coverage End', 'Dec 31, 2025'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricColumn('Maximum Sum Insured', '\$500,000', isBoldValue: true),
              _buildMetricColumn('Family Benefit Floater', 'Included'),
              _buildMetricColumn('Dependents Covered', '4 Persons'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, {bool isBoldValue = false}) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentClaimsTableCard(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Reimbursement Claims',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'All Claims Verified',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildClaimRow('CLM789456', 'Consultation', Icons.assignment_outlined, AppColors.primaryTeal, 'May 10, 2025', '\$120', 'Approved', AppColors.successBg, AppColors.successText),
          _buildClaimRow('CLM789455', 'Lab Diagnostic', Icons.science_outlined, AppColors.accentMint, 'May 08, 2025', '\$250', 'Approved', AppColors.successBg, AppColors.successText),
          _buildClaimRow('CLM789454', 'Specialist Care', Icons.single_bed_outlined, AppColors.warningOrange, 'Apr 28, 2025', '\$1,450', 'Under Review', AppColors.warningBg, AppColors.warningText),
          _buildClaimRow('CLM789453', 'Prescriptions', Icons.medication_outlined, AppColors.primaryTeal, 'Apr 20, 2025', '\$180', 'Approved', AppColors.successBg, AppColors.successText),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.0)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(id, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: iconColor, size: 15),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(type, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(date, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textDark)),
          ),
          Expanded(
            flex: 2,
            child: Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: bgStatus, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  status,
                  style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: textStatus),
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
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stress-free cashless coverage active across all network facilities.', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                Text('Real-time prescription coordination and electronic prior-authorization enabled.', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageOverviewDonutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.12),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Coverage Utilization',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Active Plan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 104,
                height: 104,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 32,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.jewelTechCyan,
                        value: 25,
                        showTitle: false,
                        radius: 14,
                      ),
                      PieChartSectionData(
                        color: AppColors.jewelSapphire,
                        value: 72,
                        showTitle: false,
                        radius: 14,
                      ),
                      PieChartSectionData(
                        color: AppColors.jewelWarmAmber,
                        value: 3,
                        showTitle: false,
                        radius: 14,
                      ),
                    ],
                  ),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _buildLegendRow(AppColors.jewelTechCyan, 'Used (25%)', '\$125,000'),
                    const SizedBox(height: 6),
                    _buildLegendRow(AppColors.jewelSapphire, 'Available (72%)', '\$375,000'),
                    const SizedBox(height: 6),
                    _buildLegendRow(AppColors.jewelWarmAmber, 'Pending (3%)', '\$15,000'),
                  ],
                ),
              ),
            ],
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
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(amount, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildCashlessHospitalsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'In-Network Health Facilities',
            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          _buildFacilityRow('MetroHealth Medical Center', 'Boston, MA • 2.1 mi'),
          _buildFacilityRow('Saint Jude Memorial Hospital', 'Boston, MA • 3.4 mi'),
        ],
      ),
    );
  }

  Widget _buildFacilityRow(String name, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: AppColors.bgSlate, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryTeal, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800)),
                Text(details, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGridCard(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildSquareActionItem(Icons.note_add_outlined, 'File Claim')),
              const SizedBox(width: 8),
              Expanded(child: _buildSquareActionItem(Icons.description_outlined, 'Policy PDF')),
              const SizedBox(width: 8),
              Expanded(child: _buildSquareActionItem(Icons.download_rounded, 'E-Card')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareActionItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}
