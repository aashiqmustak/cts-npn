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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Prescriptions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Upload Prescription',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showUploadModal(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sub-Tabs Bar
          Row(
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

          const SizedBox(height: 20),

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
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        Text('Sort by: Newest First ∨',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),

                    const SizedBox(height: 14),

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

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeFilterTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activeFilterTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.primaryTeal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bgStatus,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: textStatus,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  doctor,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateDetails,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            onPressed: onView,
            child: Row(
              children: const [
                Text('View Details', style: TextStyle(fontSize: 11)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_outlined,
                color: AppColors.textMuted, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading $id PDF...'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
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
            children: const [
              Text(
                'Prescriptions Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'This Year ∨',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _buildMiniCountCard('Total', '12', AppColors.infoBg, AppColors.infoText)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMiniCountCard('Active', '5', AppColors.successBg, AppColors.successText)),
              const SizedBox(width: 8),
              Expanded(
                  child: _buildMiniCountCard('Completed', '7', AppColors.purpleBg, AppColors.purpleText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCountCard(
      String label, String count, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(count,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: text)),
          Text('Prescriptions',
              style: TextStyle(fontSize: 8, color: text.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_outlined, color: AppColors.primaryTeal, size: 20),
              SizedBox(width: 8),
              Text(
                'e-Prescription Benefits',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCheckItem('Secure & digitally verified prescriptions'),
          _buildCheckItem('Easy access anytime, anywhere'),
          _buildCheckItem('Share with pharmacist in one click'),
          _buildCheckItem('Environment friendly'),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Learn More', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check, color: AppColors.primaryTeal, size: 16),
          const SizedBox(width: 6),
          Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 11, color: AppColors.textDark))),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.headset_mic_outlined, color: AppColors.primaryTeal, size: 20),
              SizedBox(width: 8),
              Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'If you have any questions about your prescriptions, our support team is here to help you.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Contact Support >', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildShareBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.send_rounded, color: AppColors.primaryTeal, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Share prescriptions with your pharmacist',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                Text(
                  'Share your e-prescription and get medicines delivered at your doorstep.',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Share Now', style: TextStyle(fontSize: 12)),
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

  void _showUploadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload New Prescription'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Doctor Name')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Prescription ID / Date')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
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
            child: const Text('Upload File'),
          ),
        ],
      ),
    );
  }
}
