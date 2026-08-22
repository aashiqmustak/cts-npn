import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class InsurancePortalScreen extends StatelessWidget {
  const InsurancePortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final plans = appState.dataService.plans;
    final drugs = appState.dataService.drugs;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Insurance Plan & Formulary Portal',
            subtitle: 'Review CMS Part D plan formularies, prior authorization claims, and cost optimization opportunities.',
            icon: Icons.verified_user_rounded,
            statusLabel: 'CMS Certified Portal',
          ),

          const SizedBox(height: 20),

          // 2. High-Density Metric Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final tiles = [
                BentoMetricTile(
                  label: 'Active Covered Plans',
                  value: '${plans.length} Plans',
                  trendText: 'Medicare Part D',
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: AppColors.primaryTeal,
                  iconBgColor: AppColors.primaryLight,
                ),
                BentoMetricTile(
                  label: 'Formulary Drug Catalog',
                  value: '${drugs.length} Drugs',
                  trendText: '5 Tiers Active',
                  icon: Icons.medication_liquid_rounded,
                  iconColor: AppColors.jewelTechCyan,
                  iconBgColor: AppColors.infoBg,
                ),
                BentoMetricTile(
                  label: 'Annual Savings Target',
                  value: '\$${appState.dataService.totalEstimatedAnnualSavingsOpportunity.toStringAsFixed(0)}',
                  trendText: '+14.2% YoY',
                  icon: Icons.savings_rounded,
                  iconColor: AppColors.jewelEmerald,
                  iconBgColor: AppColors.successBg,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: 14),
                    Expanded(child: tiles[1]),
                    const SizedBox(width: 14),
                    Expanded(child: tiles[2]),
                  ],
                );
              }
              return Column(
                children: [
                  tiles[0],
                  const SizedBox(height: 10),
                  tiles[1],
                  const SizedBox(height: 10),
                  tiles[2],
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 3. Covered Plans Bento Card
          BentoCard(
            title: 'Configured CMS Part D & Advantage Plans',
            subtitle: 'Formulary design guidelines, deductible brackets, and member enrollment',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: AppFonts.googleSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'CMS ID: ${plan.cmsPlanId} • Formulary Year: ${plan.formularyYear} • Enrollees: ${plan.totalEnrollees}',
                              style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${plan.deductible.toInt()} Deductible',
                            style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Text(
                            'Medicare Standard',
                            style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
