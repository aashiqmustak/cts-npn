import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class FrictionScreen extends StatefulWidget {
  const FrictionScreen({super.key});

  @override
  State<FrictionScreen> createState() => _FrictionScreenState();
}

class _FrictionScreenState extends State<FrictionScreen> {
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final events = appState.filteredFrictionEvents;
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    // Calculate total pages dynamically
    final totalPages = (events.length / _itemsPerPage).ceil();
    // Ensure _currentPage is bounded correctly
    int activePage = _currentPage;
    if (activePage > totalPages && totalPages > 0) {
      activePage = totalPages;
    }
    if (activePage < 1) {
      activePage = 1;
    }

    final startIndex = (activePage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final paginatedEvents = events.sublist(
      startIndex,
      endIndex > events.length ? events.length : endIndex,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Prior-Auth & Step-Therapy Friction Center',
            subtitle: 'Identify pharmacy claims delayed or abandoned due to prior authorization rules and step therapy restrictions.',
            icon: Icons.fact_check_rounded,
            statusLabel: 'Real-time Claims Stream',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${events.length} Active Bottlenecks',
                style: AppFonts.googleSans(
                  color: AppColors.warningText,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Filters Bento Card
          _buildFilterBar(context, appState),

          const SizedBox(height: 20),

          // 3. Main Friction Table Bento Card
          BentoCard(
            title: 'Prior-Authorization Bottleneck Log',
            subtitle: 'Clinical claims requiring doctor intervention or alternative tier substitution',
            child: Column(
              children: [
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(36.0),
                    child: Center(
                      child: Text(
                        'No PA or Step Therapy friction points match your query.',
                        style: AppFonts.googleSans(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: paginatedEvents.length,
                    separatorBuilder: (context, index) => const Divider(
                      height: 1,
                      color: AppColors.borderLight,
                    ),
                    itemBuilder: (context, index) {
                      final event = paginatedEvents[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type Icon Badge
                            _buildFrictionTypeBadge(event.barrierType),

                            const SizedBox(width: 14),

                            // Patient & Drug Info
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.patientName,
                                    style: AppFonts.googleSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Drug: ${event.drugName} • ${event.daysDelayed} Days Delayed',
                                    style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                  if (event.suggestedAltName != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        'Suggested Alternative: ${event.suggestedAltName}',
                                        style: AppFonts.googleSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryTeal,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Resolution & Savings
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Est. Annual Savings: ${fmt.format(event.estAnnualSavings)}',
                                    style: AppFonts.googleSans(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                      color: AppColors.successText,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Status: ${event.status.name.toUpperCase()}',
                                    style: AppFonts.googleSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: _getStatusColor(event.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Action Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                _showResolveModal(context, event, appState);
                              },
                              child: Text(
                                'Resolve',
                                style: AppFonts.googleSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: activePage > 1
                              ? () => setState(() => _currentPage--)
                              : null,
                          child: const Text('Previous'),
                        ),
                        Text(
                          'Page $activePage of $totalPages',
                          style: AppFonts.googleSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: activePage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                          child: const Text('Next'),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, AppState appState) {
    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 42,
              child: TextField(
                style: AppFonts.googleSans(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search patient, drug, or suggested alternative...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.primaryTeal),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: AppColors.bgSlate,
                ),
                onChanged: (val) => appState.setFrictionSearchQuery(val),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<BarrierType?>(
              value: appState.selectedBarrierFilter,
              isExpanded: true,
              style: AppFonts.googleSans(fontSize: 13, color: AppColors.textDark),
              decoration: const InputDecoration(labelText: 'Barrier Type'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Barriers', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: BarrierType.paRequired, child: Text('Prior Authorization', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: BarrierType.stepTherapyFailed, child: Text('Step Therapy Failed', overflow: TextOverflow.ellipsis, maxLines: 1)),
                DropdownMenuItem(value: BarrierType.quantityLimit, child: Text('Quantity Limit', overflow: TextOverflow.ellipsis, maxLines: 1)),
              ],
              onChanged: (val) => appState.setFrictionBarrierFilter(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrictionTypeBadge(BarrierType type) {
    Color bg;
    Color color;
    IconData icon;

    switch (type) {
      case BarrierType.paRequired:
        bg = AppColors.dangerBg;
        color = AppColors.dangerText;
        icon = Icons.lock_clock_rounded;
        break;
      case BarrierType.stepTherapyFailed:
        bg = AppColors.warningBg;
        color = AppColors.warningText;
        icon = Icons.stairs_rounded;
        break;
      case BarrierType.quantityLimit:
        bg = AppColors.infoBg;
        color = AppColors.infoText;
        icon = Icons.hourglass_top_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getStatusColor(FrictionStatus status) {
    switch (status) {
      case FrictionStatus.blocked:
        return AppColors.dangerText;
      case FrictionStatus.inReview:
        return AppColors.warningText;
      case FrictionStatus.appealed:
        return AppColors.infoText;
      case FrictionStatus.resolved:
        return AppColors.successText;
    }
  }

  void _showResolveModal(BuildContext context, PAFrictionEvent event, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Resolve Claim Bottleneck',
          style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient: ${event.patientName}',
                style: AppFonts.googleSans(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Target Drug: ${event.drugName} • Barrier: ${event.barrierLabel}',
                style: AppFonts.googleSans(color: AppColors.textMuted, fontSize: 12),
              ),
              if (event.suggestedAltName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Suggested Alternative: ${event.suggestedAltName}',
                  style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryTeal),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              appState.updateFrictionStatus(event.id, FrictionStatus.resolved);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Claim Friction Point Marked as Resolved!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: Text('Mark Resolved', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
