import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PrescriptionsScreen extends StatefulWidget {
  const PrescriptionsScreen({super.key});

  @override
  State<PrescriptionsScreen> createState() => _PrescriptionsScreenState();
}

class _PrescriptionsScreenState extends State<PrescriptionsScreen> {
  int _activeFilterTab = 0; // 0: All, 1: Active, 2: Completed, 3: Expired, 4: Drafts

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Prescriptions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentNavy,
                      letterSpacing: 0.1,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View and manage all your prescriptions in one place',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  shadowColor:
                      MaterialStateProperty.all(AppColors.primaryTeal.withOpacity(0.35)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Upload Prescription',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                onPressed: () {
                  _showUploadModal(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Sub-Tabs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSubTabButton(0, 'All Prescriptions'),
                const SizedBox(width: 8),
                _buildSubTabButton(1, 'Active'),
                const SizedBox(width: 8),
                _buildSubTabButton(2, 'Completed'),
                const SizedBox(width: 8),
                _buildSubTabButton(3, 'Expired'),
                const SizedBox(width: 8),
                _buildSubTabButton(4, 'Drafts'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Main 2-Column Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Flex 7) — Prescription Cards List
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('5 Prescriptions Found',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Row(
                          children: [
                            Text('Sort by: Newest First',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textMuted)),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildPrescriptionCard(
                      id: 'Prescription #RX58921',
                      doctor: 'Dr. Rahul Verma • General Physician',
                      dateDetails: 'May 15, 2025 • 3 Medicines',
                      status: 'Active',
                      bgStatus: AppColors.successBg,
                      textStatus: AppColors.successText,
                      onView: () => appState.setSelectedPrescriptionId('RX58921'),
                    ),
                    const SizedBox(height: 12),
                    _buildPrescriptionCard(
                      id: 'Prescription #RX58711',
                      doctor: 'Dr. Neha Kapoor • Cardiologist',
                      dateDetails: 'Apr 28, 2025 • 2 Medicines',
                      status: 'Active',
                      bgStatus: AppColors.successBg,
                      textStatus: AppColors.successText,
                      onView: () => appState.setSelectedPrescriptionId('RX58711'),
                    ),
                    const SizedBox(height: 12),
                    _buildPrescriptionCard(
                      id: 'Prescription #RX58432',
                      doctor: 'Dr. Rahul Verma • General Physician',
                      dateDetails: 'Mar 20, 2025 • 4 Medicines',
                      status: 'Completed',
                      bgStatus: AppColors.purpleBg,
                      textStatus: AppColors.purpleText,
                      onView: () => appState.setSelectedPrescriptionId('RX58432'),
                    ),
                    const SizedBox(height: 12),
                    _buildPrescriptionCard(
                      id: 'Prescription #RX58109',
                      doctor: 'Dr. Neha Kapoor • Cardiologist',
                      dateDetails: 'Feb 18, 2025 • 3 Medicines',
                      status: 'Expired',
                      bgStatus: AppColors.dangerBg,
                      textStatus: AppColors.dangerText,
                      onView: () => appState.setSelectedPrescriptionId('RX58109'),
                    ),
                    const SizedBox(height: 12),
                    _buildPrescriptionCard(
                      id: 'Prescription #RX57902',
                      doctor: 'Dr. Amit Singh • Orthopedic',
                      dateDetails: 'Jan 10, 2025 • 2 Medicines',
                      status: 'Active',
                      bgStatus: AppColors.successBg,
                      textStatus: AppColors.successText,
                      onView: () => appState.setSelectedPrescriptionId('RX57902'),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right Column (Flex 4) — Overview & Benefits
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Widget 1: Prescriptions Overview Cards
                    _buildOverviewCard(),

                    const SizedBox(height: 20),

                    // Widget 2: e-Prescription Benefits Card
                    _buildBenefitsCard(context),

                    const SizedBox(height: 20),

                    // Widget 3: Need Help Callout Card
                    _buildSupportCard(context),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bottom Share Banner
          _buildShareBanner(context),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // FILTER TABS
  // ------------------------------------------------------------------
  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeFilterTab == index;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _activeFilterTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // PRESCRIPTION CARD
  // ------------------------------------------------------------------
  Widget _buildPrescriptionCard({
    required String id,
    required String doctor,
    required String dateDetails,
    required String status,
    required Color bgStatus,
    required Color textStatus,
    required VoidCallback onView,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryTeal.withOpacity(0.16),
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_rounded,
                color: AppColors.primaryTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: bgStatus,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: textStatus,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  doctor,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 5),
                    Text(
                      dateDetails,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryTeal,
              side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onView,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View Details',
                    style:
                        TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 15),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.download_rounded,
                  color: AppColors.textMuted, size: 19),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    content: Text('Downloading $id PDF...'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // OVERVIEW CARD
  // ------------------------------------------------------------------
  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Prescriptions Overview',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  Text(
                    'This Year',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 14, color: AppColors.textMuted),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildMiniCountCard('Total', '12', AppColors.infoBg,
                      AppColors.infoText)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMiniCountCard('Active', '5',
                      AppColors.successBg, AppColors.successText)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMiniCountCard('Completed', '7',
                      AppColors.purpleBg, AppColors.purpleText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCountCard(
      String label, String count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(count,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: text)),
          const SizedBox(height: 1),
          Text('Prescriptions',
              style: TextStyle(fontSize: 8, color: text.withOpacity(0.75))),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // BENEFITS CARD
  // ------------------------------------------------------------------
  Widget _buildBenefitsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.verified_rounded,
                    color: AppColors.primaryTeal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'e-Prescription Benefits',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCheckItem('Secure & digitally verified prescriptions'),
          const SizedBox(height: 10),
          _buildCheckItem('Easy access anytime, anywhere'),
          const SizedBox(height: 10),
          _buildCheckItem('Share with pharmacist in one click'),
          const SizedBox(height: 10),
          _buildCheckItem('Environment friendly'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                side: BorderSide(color: AppColors.primaryTeal.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Learn More',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.primaryTeal.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.primaryTeal, size: 12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textDark, height: 1.3)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // SUPPORT CARD
  // ------------------------------------------------------------------
  Widget _buildSupportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFF7FCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.headset_mic_rounded,
                    color: AppColors.primaryTeal, size: 18),
              ),
              const SizedBox(width: 10),
              const Text('Need Help?',
                  style:
                      TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'If you have any questions about your prescriptions, our support team is here to help you.',
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryTeal,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFBAE6FD)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Contact Support',
                      style: TextStyle(
                          fontSize: 11.5, fontWeight: FontWeight.w700)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SHARE BANNER
  // ------------------------------------------------------------------
  Widget _buildShareBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF5FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.send_rounded,
                color: AppColors.primaryTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Share prescriptions with your pharmacist',
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark),
                ),
                SizedBox(height: 3),
                Text(
                  'Share your e-prescription and get medicines delivered at your doorstep.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted, height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.ios_share_rounded, size: 16),
            label: const Text('Share Now',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prescription shared with pharmacy panel!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // UPLOAD MODAL
  // ------------------------------------------------------------------
  void _showUploadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.upload_file_rounded,
                  color: AppColors.primaryTeal, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Upload New Prescription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Doctor Name',
                  filled: true,
                  fillColor: AppColors.bgSlate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Prescription ID / Date',
                  filled: true,
                  fillColor: AppColors.bgSlate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
              child: const Text('Cancel',
                  style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prescription uploaded successfully!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Upload File',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}