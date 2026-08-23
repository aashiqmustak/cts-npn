import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class PharmacistInsuranceScreen extends StatefulWidget {
  const PharmacistInsuranceScreen({super.key});

  @override
  State<PharmacistInsuranceScreen> createState() => _PharmacistInsuranceScreenState();
}

class _PharmacistInsuranceScreenState extends State<PharmacistInsuranceScreen> {
  String? _selectedConnectedCompany;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    // Categorize insurance companies based on request status
    final connectedCompanies = <Map<String, dynamic>>[];
    final otherCompanies = <Map<String, dynamic>>[];
    
    for (var company in appState.insuranceCompanies) {
      final req = appState.connectionRequests.firstWhere(
        (r) => r.insuranceCompany == company['name'],
        orElse: () => PharmacyConnectionRequest(
          id: '',
          pharmacyId: '',
          pharmacyName: '',
          insuranceCompany: '',
          status: 'none',
          requestDate: DateTime.now(),
        ),
      );
      
      final companyData = {
        ...company,
        'status': req.status,
        'request_id': req.id,
      };
      
      if (req.status == 'accepted') {
        connectedCompanies.add(companyData);
      } else {
        otherCompanies.add(companyData);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Connected Insurance Network',
            subtitle: 'Query active routing agreements, inspect plan directories, and request credentials with new payer networks.',
            icon: Icons.hub_rounded,
            statusLabel: 'Routing Engine Active',
          ),

          const SizedBox(height: 24),

          // 2. Connected Insurance Companies
          Text(
            'Connected Insurance Partners (In-Network)',
            style: AppFonts.googleSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          
          if (connectedCompanies.isEmpty) ...[
            BentoCard(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.link_off_rounded, size: 28, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'No Connected Insurance Partners',
                      style: AppFonts.googleSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Request connection below to connect with insurance networks.',
                      style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: connectedCompanies.length,
              itemBuilder: (context, index) {
                final company = connectedCompanies[index];
                final isExpanded = _selectedConnectedCompany == company['name'];
                final List<dynamic> plans = company['plans'];
                final IconData logoIcon = company['logo'] as IconData;
                final Color brandColor = company['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BentoCard(
                    enableHover: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedConnectedCompany = isExpanded ? null : company['name'];
                            });
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: brandColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(logoIcon, color: brandColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      company['name'],
                                      style: AppFonts.googleSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${plans.length} benefit plans active • Connected in-network',
                                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.link_rounded, size: 12, color: AppColors.successText),
                                    const SizedBox(width: 4),
                                    Text(
                                      'CONNECTED',
                                      style: AppFonts.googleSans(
                                        color: AppColors.successText,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                        
                        if (isExpanded) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: AppColors.metallicBorder),
                          ),
                          Text(
                            'ASSOCIATED COVERED BENEFIT PLANS',
                            style: AppFonts.googleSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: plans.length,
                            itemBuilder: (context, planIndex) {
                              final plan = plans[planIndex];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.bgSlate,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.metallicBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.assignment_outlined, size: 16, color: AppColors.primaryTeal),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['name'],
                                            style: AppFonts.googleSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            plan['type'],
                                            style: AppFonts.googleSans(
                                              fontSize: 11,
                                              color: AppColors.textMuted,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 28),

          // 3. Other Insurance Companies
          Text(
            'Other Available Insurance Payer Networks',
            style: AppFonts.googleSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: otherCompanies.length,
            itemBuilder: (context, index) {
              final company = otherCompanies[index];
              final status = company['status'] as String;
              final IconData logoIcon = company['logo'] as IconData;
              final Color brandColor = company['color'] as Color;
              final companyName = company['name'] as String;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  enableHover: true,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: brandColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(logoIcon, color: brandColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              companyName,
                              style: AppFonts.googleSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Benefit routing disabled • Click Request Connection to apply',
                              style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      
                      // Status Action Pill / Button
                      _buildPayerStatusButton(context, appState, companyName, status),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPayerStatusButton(
    BuildContext context,
    AppState appState,
    String companyName,
    String status,
  ) {
    if (status == 'requested') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.warningOrange,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pending Approval',
              style: AppFonts.googleSans(
                color: AppColors.warningOrange,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else if (status == 'rejected') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dangerBg,
          foregroundColor: AppColors.dangerRed,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.dangerRed),
          ),
        ),
        onPressed: () {
          appState.requestConnection(companyName);
          _showRequestToast(context, companyName);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded, size: 14, color: AppColors.dangerRed),
            const SizedBox(width: 6),
            Text(
              'Rejected (Re-apply)',
              style: AppFonts.googleSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    } else {
      // none status
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1244A2),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          appState.requestConnection(companyName);
          _showRequestToast(context, companyName);
        },
        icon: const Icon(Icons.add_rounded, size: 15, color: Colors.white),
        label: Text(
          'Request Connection',
          style: AppFonts.googleSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  void _showRequestToast(BuildContext context, String companyName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Connection request submitted to $companyName successfully!',
          style: AppFonts.googleSans(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
