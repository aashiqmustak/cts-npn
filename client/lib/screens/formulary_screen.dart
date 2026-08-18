import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class FormularyScreen extends StatelessWidget {
  const FormularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final drugs = appState.filteredDrugs;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Formulary Explorer & Tier Optimization',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Browse Medicare Part D drugs, tier copay rules, and bioequivalent cheaper alternatives.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${drugs.length} Covered Drugs Loaded',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filters Card
          _buildFilterBar(context, appState),

          const SizedBox(height: 20),

          // Formulary Drugs Table Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (drugs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No formulary drugs match your search or filter parameters.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drugs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final drug = drugs[index];
                      final alternatives =
                          appState.dataService.getAlternativesForDrug(drug.id);
                      final hasAlts = alternatives.isNotEmpty;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            // Tier Badge
                            _buildTierBadge(drug.tier),

                            const SizedBox(width: 16),

                            // Drug Details
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    drug.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'NDC: ${drug.ndc} • Class: ${drug.drugClass}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Restrictions Chips
                            Expanded(
                              flex: 2,
                              child: Wrap(
                                spacing: 6,
                                children: [
                                  if (drug.requiresPa)
                                    _buildRestrictionChip('PA (Prior Auth)', AppColors.dangerBg, AppColors.dangerText),
                                  if (drug.stepTherapy)
                                    _buildRestrictionChip('ST (Step Therapy)', AppColors.warningBg, AppColors.warningText),
                                  if (drug.quantityLimit)
                                    _buildRestrictionChip('QL (Qty Limit)', AppColors.infoBg, AppColors.infoText),
                                  if (!drug.requiresPa && !drug.stepTherapy && !drug.quantityLimit)
                                    _buildRestrictionChip('No Restrictions', AppColors.successBg, AppColors.successText),
                                ],
                              ),
                            ),

                            // Est Copay & Cost Share
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${fmt.format(drug.costShare)} / mo copay',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Est. Plan Cost: ${fmt.format(drug.estMonthlyCost)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Alternatives & Action
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (hasAlts) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Save up to ${fmt.format(alternatives.first.estAnnualSavings)}/yr',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasAlts ? AppColors.primaryTeal : AppColors.accentNavy,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    ),
                                    onPressed: () {
                                      _showDrugDetailModal(context, drug, alternatives, appState);
                                    },
                                    child: Text(
                                      hasAlts ? 'Cheaper Alts (${alternatives.length})' : 'Drug Details',
                                      style: const TextStyle(fontSize: 12),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Search Field
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search drug name, NDC, or therapeutic class...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (val) => appState.setFormularySearchQuery(val),
                ),
              ),

              const SizedBox(width: 12),

              // Tier Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int?>(
                  value: appState.selectedTierFilter,
                  decoration: const InputDecoration(
                    labelText: 'Formulary Tier',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Tiers (1 - 5)')),
                    DropdownMenuItem(value: 1, child: Text('Tier 1 - Preferred Generic')),
                    DropdownMenuItem(value: 2, child: Text('Tier 2 - Generic')),
                    DropdownMenuItem(value: 3, child: Text('Tier 3 - Preferred Brand')),
                    DropdownMenuItem(value: 4, child: Text('Tier 4 - Non-Preferred')),
                    DropdownMenuItem(value: 5, child: Text('Tier 5 - Specialty')),
                  ],
                  onChanged: (val) => appState.setTierFilter(val),
                ),
              ),

              const SizedBox(width: 12),

              // Restriction Filter Dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: appState.selectedRestrictionFilter,
                  decoration: const InputDecoration(
                    labelText: 'Restrictions',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Restrictions')),
                    DropdownMenuItem(value: 'PA', child: Text('PA (Prior Authorization)')),
                    DropdownMenuItem(value: 'ST', child: Text('ST (Step Therapy)')),
                    DropdownMenuItem(value: 'QL', child: Text('QL (Quantity Limits)')),
                  ],
                  onChanged: (val) => appState.setRestrictionFilter(val),
                ),
              ),
            ],
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRestrictionChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
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
        title: Row(
          children: [
            const Icon(Icons.medication_rounded, color: AppColors.primaryTeal),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                drug.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drug Summary Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSlate,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Formulary Tier: ${drug.tierLabel}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Est Copay: ${fmt.format(drug.costShare)}/mo',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('NDC: ${drug.ndc}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('Restrictions: ${drug.restrictionsText}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Cheaper Formulary Alternatives & Tier-Down Options',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Substituting lower tier bioequivalent or therapeutically equivalent options lowers patient out-of-pocket costs and improves therapy adherence.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),

                const SizedBox(height: 14),

                if (alternatives.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'This drug is already on a optimal low-tier or has no covered formulary alternatives.',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryDark),
                    ),
                  )
                else
                  Column(
                    children: alternatives.map((alt) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryTeal.withOpacity(0.4)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  alt.altDrugName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Est. Annual Savings: ${fmt.format(alt.estAnnualSavings)}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.successText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tier: Tier ${alt.altTier} • Monthly Copay Reduction: ${fmt.format(alt.copayDiff)}/mo',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Clinical Rationale: ${alt.clinicalNotes}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send_rounded, size: 14),
                                label: const Text('Initiate Tier-Down Suggestion', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Tier-down recommendation for ${alt.altDrugName} submitted to prescriber queue! Est. Savings: ${fmt.format(alt.estAnnualSavings)}/yr',
                                      ),
                                      backgroundColor: AppColors.primaryTeal,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
