import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class InsurancePharmacyConnectionsScreen extends StatefulWidget {
  const InsurancePharmacyConnectionsScreen({super.key});

  @override
  State<InsurancePharmacyConnectionsScreen> createState() =>
      _InsurancePharmacyConnectionsScreenState();
}

class _InsurancePharmacyConnectionsScreenState
    extends State<InsurancePharmacyConnectionsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final requests = appState.connectionRequests;

    final acceptedList = requests.where((r) => r.status == 'accepted').toList();
    final pendingList = requests.where((r) => r.status == 'requested').toList();
    final rejectedList = requests.where((r) => r.status == 'rejected').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Enterprise Bento Hero Banner
        BentoHeroBanner(
          title: 'Pharmacy Connected Directory',
          subtitle: 'Evaluate in-network routing requests, authorize pharmacy terminals, and audit active dispensing nodes.',
          icon: Icons.connect_without_contact_rounded,
          statusLabel: 'Payer Network Manager',
        ),

        const SizedBox(height: 20),

        // 2. High-Density Segmented Tab Bar
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.metallicBorder),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradientPill),
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: AppFonts.googleSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            unselectedLabelStyle: AppFonts.googleSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
            dividerColor: Colors.transparent,
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Accepted (${acceptedList.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.pending_actions_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Request (${pendingList.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.link_off_rounded, size: 16),
                    const SizedBox(width: 6),
                    Text('Rejected (${rejectedList.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. Tab Views content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(context, appState, acceptedList, 'accepted'),
              _buildRequestsList(context, appState, pendingList, 'requested'),
              _buildRequestsList(context, appState, rejectedList, 'rejected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList(
    BuildContext context,
    AppState appState,
    List<PharmacyConnectionRequest> items,
    String type,
  ) {
    if (items.isEmpty) {
      String message = '';
      IconData icon = Icons.check_circle_rounded;
      if (type == 'accepted') {
        message = 'No active pharmacy routing connections configured.';
        icon = Icons.link_off_rounded;
      } else if (type == 'requested') {
        message = 'No pending pharmacy connection requests received.';
        icon = Icons.mark_email_read_rounded;
      } else {
        message = 'No rejected pharmacy connection records.';
        icon = Icons.verified_user_rounded;
      }

      return BentoCard(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.bgSlate,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              Text(
                'No Connection Records',
                style: AppFonts.googleSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final req = items[index];
        final timeStr = '${req.requestDate.hour.toString().padLeft(2, '0')}:${req.requestDate.minute.toString().padLeft(2, '0')}';
        final dateStr = '${req.requestDate.day}/${req.requestDate.month}/${req.requestDate.year}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BentoCard(
            enableHover: true,
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.primaryTeal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Connection details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.pharmacyName,
                        style: AppFonts.googleSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgSlate,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.metallicBorder),
                            ),
                            child: Text(
                              'Payer: ${req.insuranceCompany}',
                              style: AppFonts.googleSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Requested: $dateStr at $timeStr',
                            style: AppFonts.googleSans(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Action Buttons
                _buildActionButtons(context, appState, req, type),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    AppState appState,
    PharmacyConnectionRequest req,
    String type,
  ) {
    if (type == 'requested') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reject Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dangerRed,
              side: const BorderSide(color: AppColors.dangerRed),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              appState.updateConnectionStatus(req.id, 'rejected');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.dangerRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    'Connection request from ${req.pharmacyName} has been Rejected.',
                    style: AppFonts.googleSans(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.close_rounded, size: 14),
            label: Text(
              'Reject',
              style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 8),
          
          // Approve Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              appState.updateConnectionStatus(req.id, 'accepted');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.successGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text(
                    'Connection request from ${req.pharmacyName} Approved successfully!',
                    style: AppFonts.googleSans(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            label: Text(
              'Approve',
              style: AppFonts.googleSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      );
    } else if (type == 'accepted') {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dangerRed,
          side: const BorderSide(color: AppColors.dangerRed),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          appState.updateConnectionStatus(req.id, 'rejected');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                'Connection routing revoked for ${req.pharmacyName}.',
                style: AppFonts.googleSans(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          );
        },
        icon: const Icon(Icons.link_off_rounded, size: 14),
        label: Text(
          'Revoke Routing',
          style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800),
        ),
      );
    } else {
      // rejected
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1244A2),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          appState.updateConnectionStatus(req.id, 'accepted');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                'Re-evaluated and approved connection request from ${req.pharmacyName}!',
                style: AppFonts.googleSans(fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
          );
        },
        icon: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        label: Text(
          'Approve Connection',
          style: AppFonts.googleSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }
  }
}
