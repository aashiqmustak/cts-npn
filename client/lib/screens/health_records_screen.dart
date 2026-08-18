import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  int _activeCategoryTab = 0; // 0: All, 1: Reports, 2: Lab Results, 3: Scans, 4: Vaccination, 5: Others
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    'Health Records',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Securely store and manage all your health documents',
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
                label: const Text('+ Upload Record',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showUploadRecordModal(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sub-Tabs Row
          Row(
            children: [
              _buildSubTabButton(0, 'All Records'),
              const SizedBox(width: 8),
              _buildSubTabButton(1, 'Reports'),
              const SizedBox(width: 8),
              _buildSubTabButton(2, 'Lab Results'),
              const SizedBox(width: 8),
              _buildSubTabButton(3, 'Scans'),
              const SizedBox(width: 8),
              _buildSubTabButton(4, 'Vaccination'),
              const SizedBox(width: 8),
              _buildSubTabButton(5, 'Others'),
            ],
          ),

          const SizedBox(height: 16),

          // Filter & Search Bar
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: Icon(Icons.search_rounded, size: 18),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Sort by: ',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Text('Newest First ∨',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                icon: const Icon(Icons.filter_list_rounded, size: 16),
                label: const Text('Filter', style: TextStyle(fontSize: 11)),
                onPressed: () {},
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main 2-Column Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Flex 7) — Document Cards List
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildRecordCard(
                      title: 'Complete Blood Count Report',
                      tag: 'Lab Report',
                      provider: 'City Care Diagnostic Center',
                      fileInfo: 'PDF • 1.2 MB',
                      dateInfo: 'May 14, 2025 • 09:30 AM',
                      tagColor: AppColors.primaryTeal,
                      tagBg: AppColors.primaryLight,
                      icon: Icons.science_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildRecordCard(
                      title: 'Chest X-Ray',
                      tag: 'Imaging',
                      provider: 'City Care Diagnostic Center',
                      fileInfo: 'JPG • 2.4 MB',
                      dateInfo: 'May 10, 2025 • 11:15 AM',
                      tagColor: AppColors.purpleText,
                      tagBg: AppColors.purpleBg,
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildRecordCard(
                      title: 'Health Checkup Report',
                      tag: 'Report',
                      provider: 'Wellness Clinic',
                      fileInfo: 'PDF • 1.8 MB',
                      dateInfo: 'May 05, 2025 • 04:20 PM',
                      tagColor: const Color(0xFFD97706),
                      tagBg: const Color(0xFFFEF3C7),
                      icon: Icons.article_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildRecordCard(
                      title: 'COVID-19 Vaccination Certificate',
                      tag: 'Vaccination',
                      provider: 'Govt. Vaccination Center',
                      fileInfo: 'PDF • 0.9 MB',
                      dateInfo: 'Apr 25, 2025 • 10:30 AM',
                      tagColor: const Color(0xFF2563EB),
                      tagBg: const Color(0xFFE0F2FE),
                      icon: Icons.verified_user_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildRecordCard(
                      title: 'HbA1c Test Report',
                      tag: 'Lab Report',
                      provider: 'HealthPlus Diagnostics',
                      fileInfo: 'PDF • 1.1 MB',
                      dateInfo: 'Apr 20, 2025 • 09:10 AM',
                      tagColor: AppColors.primaryTeal,
                      tagBg: AppColors.primaryLight,
                      icon: Icons.science_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildRecordCard(
                      title: 'ECG Report',
                      tag: 'Report',
                      provider: 'City Care Diagnostic Center',
                      fileInfo: 'PDF • 1.6 MB',
                      dateInfo: 'Apr 15, 2025 • 02:45 PM',
                      tagColor: const Color(0xFFD97706),
                      tagBg: const Color(0xFFFEF3C7),
                      icon: Icons.monitor_heart_outlined,
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                        ),
                        onPressed: () {},
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('Load More Records',
                                style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right Column (Flex 4) — Storage, Quick Actions, Categories
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Widget 1: Storage & Usage Donut Card
                    _buildStorageUsageCard(),

                    const SizedBox(height: 20),

                    // Widget 2: Quick Actions Grid
                    _buildQuickActionsGrid(context),

                    const SizedBox(height: 20),

                    // Widget 3: Records by Category List
                    _buildCategoryCountListCard(),

                    const SizedBox(height: 20),

                    // Widget 4: Encryption Security Card
                    _buildSecurityCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeCategoryTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          _activeCategoryTab = index;
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

  Widget _buildRecordCard({
    required String title,
    required String tag,
    required String provider,
    required String fileInfo,
    required String dateInfo,
    required Color tagColor,
    required Color tagBg,
    required IconData icon,
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
              color: tagBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tagColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  provider,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileInfo,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateInfo,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.more_vert_rounded,
                  color: AppColors.textMuted, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageUsageCard() {
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
          const Text(
            'Storage & Usage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: [
                          PieChartSectionData(
                              color: AppColors.primaryTeal,
                              value: 1.2,
                              showTitle: false,
                              radius: 12),
                          PieChartSectionData(
                              color: const Color(0xFF2563EB),
                              value: 0.8,
                              showTitle: false,
                              radius: 12),
                          PieChartSectionData(
                              color: const Color(0xFFF59E0B),
                              value: 0.4,
                              showTitle: false,
                              radius: 12),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('2.4 GB',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        Text('of 10 GB used',
                            style: TextStyle(
                                fontSize: 7, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  children: [
                    _buildStorageLegendRow(
                        AppColors.primaryTeal, 'Documents', '1.2 GB'),
                    const SizedBox(height: 6),
                    _buildStorageLegendRow(
                        const Color(0xFF2563EB), 'Images', '0.8 GB'),
                    const SizedBox(height: 6),
                    _buildStorageLegendRow(
                        const Color(0xFFF59E0B), 'Others', '0.4 GB'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.23,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('23% of storage used',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
                onPressed: () {},
                child: const Text('Manage Storage',
                    style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageLegendRow(Color color, String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        Text(amount,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark)),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSquareAction(Icons.cloud_upload_outlined, 'Upload Record'),
              _buildSquareAction(Icons.create_new_folder_outlined, 'Create Folder'),
              _buildSquareAction(Icons.share_outlined, 'Share Record'),
              _buildSquareAction(Icons.lock_outline, 'Privacy Settings'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSquareAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryTeal, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCountListCard() {
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
          const Text(
            'Records by Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildCategoryRow('Lab Reports', '12', Icons.science_outlined, AppColors.primaryTeal),
          _buildCategoryRow('Imaging Reports', '8', Icons.qr_code_scanner_rounded, AppColors.purpleText),
          _buildCategoryRow('Health Reports', '6', Icons.article_outlined, const Color(0xFFD97706)),
          _buildCategoryRow('Vaccination', '5', Icons.verified_user_outlined, const Color(0xFF2563EB)),
          _buildCategoryRow('Others', '4', Icons.folder_open_outlined, AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
      String name, String count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name,
                style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(count,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF99F6E4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Your Data is Secure',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'We use end-to-end encryption to keep your health records safe and private.',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadRecordModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Health Record Document'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              TextField(decoration: InputDecoration(labelText: 'Document Title')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Provider / Clinic Name')),
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
                  content: Text('Health Record uploaded successfully!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: const Text('Upload Document'),
          ),
        ],
      ),
    );
  }
}
