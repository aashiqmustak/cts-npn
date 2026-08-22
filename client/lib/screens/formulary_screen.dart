import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class FormularyScreen extends StatelessWidget {
  const FormularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final drugs = appState.filteredDrugs;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Formulary Catalog & Tier Optimization',
            subtitle: 'Medicare Part D covered drug catalog, tier copay algorithms, and bioequivalent cheaper substitutes.',
            icon: Icons.menu_book_rounded,
            statusLabel: 'CMS Ingestion Synced',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${drugs.length} Drugs Available',
                style: AppFonts.googleSans(
                  color: AppColors.primaryTeal,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Command Search & Filter Bento Card
          _buildFilterCard(context, appState),

          const SizedBox(height: 20),

          // 3. Formulary Drugs Table Bento Card
          BentoCard(
            title: 'Active Covered Drug Master Catalog',
            subtitle: 'Real-time Medicare Part D tier mapping, average retail costs, and clinical restrictions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (drugs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Center(
                      child: Text(
                        'No formulary drugs match your search and filter criteria.',
                        style: AppFonts.googleSans(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drugs.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final drug = drugs[index];
                      final alternatives = appState.dataService.getAlternativesForDrug(drug.id);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Tier Badge
                            _buildTierBadge(drug.tier),

                            const SizedBox(width: 14),

                            // Drug Name, NDC & Class
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        drug.name,
                                        style: AppFonts.googleSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      if (drug.tier <= 2) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'GENERIC',
                                            style: AppFonts.googleSans(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.successText,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'NDC: ${drug.ndc} • ${drug.drugClass}',
                                    style: AppFonts.googleSans(
                                      fontSize: 11.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Restrictions (PA, ST, QL)
                            Expanded(
                              flex: 3,
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  if (drug.requiresPa)
                                    _buildRestrictionChip('PA Required', AppColors.dangerBg, AppColors.dangerText),
                                  if (drug.stepTherapy)
                                    _buildRestrictionChip('Step Therapy', AppColors.warningBg, AppColors.warningText),
                                  if (drug.quantityLimit)
                                    _buildRestrictionChip('Quantity Limit', AppColors.infoBg, AppColors.infoText),
                                  if (!drug.requiresPa && !drug.stepTherapy && !drug.quantityLimit)
                                    _buildRestrictionChip('Unrestricted', AppColors.successBg, AppColors.successText),
                                ],
                              ),
                            ),

                            // Cost Column
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${fmt.format(drug.estMonthlyCost)}/mo',
                                    style: AppFonts.googleSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Avg. Retail Price',
                                    style: AppFonts.googleSans(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Details / Alternatives Action Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                _showDrugDetailModal(context, drug, alternatives, appState);
                              },
                              child: Text(
                                alternatives.isNotEmpty
                                    ? 'Alternatives (${alternatives.length})'
                                    : 'Specs',
                                style: AppFonts.googleSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context, AppState appState) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Search Field
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 42,
              child: TextField(
                style: AppFonts.googleSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search drug name, NDC, or therapeutic class...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.primaryTeal),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: AppColors.bgSlate,
                ),
                onChanged: (val) => appState.setFormularySearchQuery(val),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Tier Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int?>(
              value: appState.selectedTierFilter,
              isExpanded: true,
              style: AppFonts.googleSans(fontSize: 13, color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Formulary Tier'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Tiers (1 - 5)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 1, child: Text('Tier 1 - Preferred Generic', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 2, child: Text('Tier 2 - Generic', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 3, child: Text('Tier 3 - Preferred Brand', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 4, child: Text('Tier 4 - Non-Preferred', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 5, child: Text('Tier 5 - Specialty', overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
              onChanged: (val) => appState.setTierFilter(val),
            ),
          ),

          const SizedBox(width: 14),

          // Restriction Filter Dropdown
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String?>(
              value: appState.selectedRestrictionFilter,
              isExpanded: true,
              style: AppFonts.googleSans(fontSize: 13, color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Restrictions'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Restrictions', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 'PA', child: Text('PA (Prior Authorization)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 'ST', child: Text('ST (Step Therapy)', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: 'QL', child: Text('QL (Quantity Limits)', overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
              onChanged: (val) => appState.setRestrictionFilter(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBadge(int tier) {
    Color bg;
    Color text;
    String label = 'Tier $tier';

    switch (tier) {
      case 1:
        bg = AppColors.successBg;
        text = AppColors.successText;
        break;
      case 2:
        bg = AppColors.infoBg;
        text = AppColors.infoText;
        break;
      case 3:
        bg = AppColors.warningBg;
        text = AppColors.warningText;
        break;
      case 4:
        bg = AppColors.dangerBg;
        text = AppColors.dangerText;
        break;
      case 5:
        bg = AppColors.purpleBg;
        text = AppColors.purpleText;
        break;
      default:
        bg = AppColors.bgSlate;
        text = AppColors.textDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppFonts.googleSans(
          color: text,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _buildRestrictionChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppFonts.googleSans(
          color: text,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showDrugDetailModal(BuildContext context, Drug drug,
      List<FormularyAlternative> alternatives, AppState appState) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.medication_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                drug.name,
                style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Therapeutic Class: ${drug.drugClass} • NDC: ${drug.ndc}',
                  style: AppFonts.googleSans(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSlate,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.metallicBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tier ${drug.tier} • ${drug.tierLabel}', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
                      Text('Est. Monthly Cost: ${fmt.format(drug.estMonthlyCost)}/mo', style: AppFonts.googleSans(fontWeight: FontWeight.w800, color: AppColors.primaryTeal)),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Bioequivalent Lower-Tier Alternatives (Cost Savings):',
                  style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                const SizedBox(height: 10),
                if (alternatives.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('This drug is already at the optimal formulary tier.', style: AppFonts.googleSans(color: AppColors.textMuted, fontSize: 12)),
                  )
                else
                  ...alternatives.map((alt) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(alt.altDrugName, style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13)),
                              Text('Moves to Tier ${alt.altTier} • ${alt.clinicalNotes}', style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: AppColors.successGreen, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              'Save ${fmt.format(alt.estMonthlySavings)}/mo',
                              style: AppFonts.googleSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11.5),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
