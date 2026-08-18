import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class FrictionScreen extends StatelessWidget {
  const FrictionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.filteredFrictionEvents;
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
                    'Prior-Auth & Step-Therapy Friction Center',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Identify claims delayed or abandoned due to prior authorization rules and step therapy restrictions.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${events.length} Active Friction Bottlenecks',
                  style: const TextStyle(
                    color: AppColors.warningText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filters Bar
          _buildFilterBar(context, appState),

          const SizedBox(height: 20),

          // Main Friction Table
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
              children: [
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'No PA or Step Therapy friction points match your query.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: events.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = events[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            // Days Delayed Circle
                            _buildDaysDelayedBadge(event.daysDelayed),

                            const SizedBox(width: 14),

                            // Patient & Drug Info
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${event.patientName} — ${event.drugName}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Friction Index Score: ${event.frictionScore} / 10',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Barrier Type Chip
                            Expanded(
                              flex: 2,
                              child: _buildBarrierChip(event.barrierType),
                            ),

                            // Suggested Alternative & Savings
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (event.suggestedAltName != null) ...[
                                    Text(
                                      'Alt: ${event.suggestedAltName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    Text(
                                      'Est Savings: ${fmt.format(event.estAnnualSavings)}/yr',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.successText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ] else
                                    const Text('No Alt Available',
                                        style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                ],
                              ),
                            ),

                            // Action Buttons
                            Row(
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    _showPAAppealModal(context, event, appState);
                                  },
                                  child: const Text('Expedite PA', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  onPressed: () {
                                    appState.updateFrictionStatus(event.id, FrictionStatus.resolved);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Switched ${event.patientName} to ${event.suggestedAltName}! Friction resolved.',
                                        ),
                                        backgroundColor: AppColors.primaryTeal,
                                      ),
                                    );
                                  },
                                  child: const Text('Switch Alt', style: TextStyle(fontSize: 11)),
                                ),
                              ],
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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search patient name or restricted drug...',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
              onChanged: (val) => appState.setFrictionSearchQuery(val),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<BarrierType?>(
              value: appState.selectedBarrierFilter,
              decoration: const InputDecoration(
                labelText: 'Barrier Type',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Barriers')),
                DropdownMenuItem(value: BarrierType.paRequired, child: Text('Prior Authorization')),
                DropdownMenuItem(value: BarrierType.stepTherapyFailed, child: Text('Step Therapy Friction')),
                DropdownMenuItem(value: BarrierType.quantityLimit, child: Text('Quantity Limit')),
              ],
              onChanged: (val) => appState.setFrictionBarrierFilter(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaysDelayedBadge(int days) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: days > 14 ? AppColors.dangerBg : AppColors.warningBg,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$days',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: days > 14 ? AppColors.dangerText : AppColors.warningText,
            ),
          ),
          Text(
            'Days',
            style: TextStyle(
              fontSize: 9,
              color: days > 14 ? AppColors.dangerText : AppColors.warningText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarrierChip(BarrierType type) {
    String label;
    Color bg;
    Color text;

    switch (type) {
      case BarrierType.paRequired:
        label = 'PA Required';
        bg = AppColors.dangerBg;
        text = AppColors.dangerText;
        break;
      case BarrierType.stepTherapyFailed:
        label = 'Step Therapy';
        bg = AppColors.warningBg;
        text = AppColors.warningText;
        break;
      case BarrierType.quantityLimit:
        label = 'Qty Limit';
        bg = AppColors.infoBg;
        text = AppColors.infoText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPAAppealModal(BuildContext context, PAFrictionEvent event, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Expedite Prior Authorization: ${event.patientName}'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Drug: ${event.drugName}'),
              Text('Days Delayed: ${event.daysDelayed} Days'),
              const SizedBox(height: 12),
              const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Clinical Exception Rationale',
                  hintText: 'Enter clinical justification for Part D prior auth override...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.updateFrictionStatus(event.id, FrictionStatus.appealed);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PA Exception document submitted to health plan! Status set to Appealed.'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: const Text('Submit Exception Request'),
          ),
        ],
      ),
    );
  }
}
