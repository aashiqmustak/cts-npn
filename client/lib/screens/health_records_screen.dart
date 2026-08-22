import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  int _activeCategoryTab = 0; // 0: All, 1: Reports, 2: Lab Results, 3: Scans, 4: Vaccination, 5: Others
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _userRecords = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Electronic Health Records Vault',
            subtitle: 'HIPAA-compliant document management for diagnostic lab panels, clinical imaging, and certificates.',
            icon: Icons.folder_shared_rounded,
            statusLabel: 'End-to-End Encrypted',
            trailing: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientPill),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Upload Document',
                  style: AppFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                onPressed: () => _showUploadRecordModal(context),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Category Filter Pills & Search Bar Bento Card
          BentoCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category Pills Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSubTabButton(0, 'All Documents', Icons.grid_view_rounded),
                      const SizedBox(width: 8),
                      _buildSubTabButton(1, 'Clinical Reports', Icons.article_rounded),
                      const SizedBox(width: 8),
                      _buildSubTabButton(2, 'Lab Diagnostics', Icons.science_rounded),
                      const SizedBox(width: 8),
                      _buildSubTabButton(3, 'Imaging & Scans', Icons.qr_code_scanner_rounded),
                      const SizedBox(width: 8),
                      _buildSubTabButton(4, 'Vaccination', Icons.verified_user_rounded),
                      const SizedBox(width: 8),
                      _buildSubTabButton(5, 'Other Files', Icons.folder_open_rounded),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Search Bar
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 42,
                        child: TextField(
                          controller: _searchController,
                          style: AppFonts.googleSans(fontSize: 13, color: AppColors.textDark),
                          decoration: InputDecoration(
                            hintText: 'Search documents by patient, provider, or record title...',
                            hintStyle: AppFonts.googleSans(fontSize: 12.5, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppColors.primaryTeal),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                            filled: true,
                            fillColor: AppColors.bgSlate,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Asymmetric Bento 2-Column Workspace
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 920;

              final recordsColumn = Column(
                children: [
                  _buildRecordCard(
                    title: 'Complete Blood Count (CBC) Panel',
                    tag: 'Lab Diagnostic',
                    tagColor: AppColors.infoText,
                    tagBg: AppColors.infoBg,
                    icon: Icons.science_rounded,
                    dateInfo: 'May 10, 2025 • 2.4 MB PDF',
                    provider: 'Quest Diagnostics',
                  ),
                  const SizedBox(height: 12),
                  _buildRecordCard(
                    title: 'Chest X-Ray Radiograph (AP/Lateral)',
                    tag: 'Imaging & Scans',
                    tagColor: AppColors.purpleText,
                    tagBg: AppColors.purpleBg,
                    icon: Icons.qr_code_scanner_rounded,
                    dateInfo: 'Apr 22, 2025 • 18.2 MB DICOM',
                    provider: 'MetroHealth Imaging Center',
                  ),
                  const SizedBox(height: 12),
                  _buildRecordCard(
                    title: 'Annual Cardiology Clinical Summary',
                    tag: 'Clinical Report',
                    tagColor: AppColors.warningText,
                    tagBg: AppColors.warningBg,
                    icon: Icons.article_rounded,
                    dateInfo: 'Mar 15, 2025 • 1.1 MB PDF',
                    provider: 'Dr. Rahul Verma',
                  ),
                  const SizedBox(height: 12),
                  _buildRecordCard(
                    title: 'COVID-19 & Influenza Vaccine Card',
                    tag: 'Vaccination',
                    tagColor: AppColors.successText,
                    tagBg: AppColors.successBg,
                    icon: Icons.verified_user_rounded,
                    dateInfo: 'Jan 08, 2025 • 0.8 MB PDF',
                    provider: 'CVS MinuteClinic',
                  ),

                  if (_userRecords.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _userRecords.length,
                      itemBuilder: (context, idx) {
                        final record = _userRecords[idx];
                        final tag = record['tag'] ?? 'Report';

                        Color tagColor = AppColors.primaryTeal;
                        Color tagBg = AppColors.primaryLight;
                        IconData icon = Icons.science_rounded;

                        if (tag == 'Imaging') {
                          tagColor = AppColors.purpleText;
                          tagBg = AppColors.purpleBg;
                          icon = Icons.qr_code_scanner_rounded;
                        } else if (tag == 'Vaccination') {
                          tagColor = AppColors.successText;
                          tagBg = AppColors.successBg;
                          icon = Icons.verified_user_rounded;
                        } else if (tag == 'Report') {
                          tagColor = AppColors.warningText;
                          tagBg = AppColors.warningBg;
                          icon = Icons.article_rounded;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: BentoCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: tagBg,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(icon, color: tagColor, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            record['title'] ?? 'Medical Report',
                                            style: AppFonts.googleSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tagBg,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              tag,
                                              style: AppFonts.googleSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: tagColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Provider: ${record['provider']} • Added: ${record['dateInfo']}',
                                        style: AppFonts.googleSans(
                                          fontSize: 11.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download_rounded, color: AppColors.primaryTeal, size: 20),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.dangerRed, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _userRecords.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );

              final sideColumn = Column(
                children: [
                  _buildCategoryCountListCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsBento(),
                  const SizedBox(height: 16),
                  _buildSecurityCard(),
                ],
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: recordsColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: sideColumn),
                  ],
                );
              }

              return Column(
                children: [
                  sideColumn,
                  const SizedBox(height: 20),
                  recordsColumn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label, IconData icon) {
    final isSelected = _activeCategoryTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeCategoryTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.bgSlate,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.metallicBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard({
    required String title,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required IconData icon,
    required String dateInfo,
    required String provider,
  }) {
    return BentoCard(
      enableHover: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: tagColor, size: 22),
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
                      style: AppFonts.googleSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: AppFonts.googleSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: tagColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Provider: $provider • $dateInfo',
                  style: AppFonts.googleSans(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bgSlate,
              foregroundColor: AppColors.primaryTeal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.metallicBorder),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: Text(
              'Download',
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBento() {
    return BentoCard(
      title: 'Vault Operations',
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildSquareAction(Icons.cloud_upload_outlined, 'Upload File', () => _showUploadRecordModal(context)),
          _buildSquareAction(Icons.create_new_folder_outlined, 'New Folder', () {}),
          _buildSquareAction(Icons.share_outlined, 'Share Access', () {}),
          _buildSquareAction(Icons.lock_outline_rounded, 'Audit Logs', () {}),
        ],
      ),
    );
  }

  Widget _buildSquareAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgSlate,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.metallicBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryTeal),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppFonts.googleSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCountListCard() {
    return BentoCard(
      title: 'Vault Distribution',
      subtitle: 'Categorized document allocation',
      child: Column(
        children: [
          _buildCategoryRow('Clinical Consultations', '14 Files', Icons.article_rounded, AppColors.jewelTechCyan),
          const SizedBox(height: 8),
          _buildCategoryRow('Diagnostic Panels', '8 Files', Icons.science_rounded, AppColors.jewelEmerald),
          const SizedBox(height: 8),
          _buildCategoryRow('Radiology Scans', '3 Files', Icons.qr_code_scanner_rounded, AppColors.purpleText),
          const SizedBox(height: 8),
          _buildCategoryRow('Immunization Records', '5 Files', Icons.verified_user_rounded, AppColors.jewelWarmAmber),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String label, String count, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.metallicBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ],
          ),
          Text(
            count,
            style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return BentoCard(
      title: 'Vault Security Standards',
      subtitle: 'Protected by AES-256 GCM',
      child: Column(
        children: [
          _buildSecurityRow(
            'Zero-Knowledge Access',
            'Patient medical documents are encrypted in transit and at rest with role-based access verification.',
          ),
          const SizedBox(height: 10),
          _buildSecurityRow(
            'HIPAA & HITECH Audits',
            'Automated access timestamping logs every physician, pharmacist, and patient record inspection.',
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityRow(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.metallicBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security_rounded, size: 16, color: AppColors.primaryTeal),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadRecordModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final providerCtrl = TextEditingController();
    String selectedTag = 'Report';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Upload Electronic Health Record',
            style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: AppFonts.googleSans(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Document Title',
                    hintText: 'e.g. Lipid Profile Lab Results',
                    prefixIcon: Icon(Icons.title_rounded, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerCtrl,
                  style: AppFonts.googleSans(fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Provider / Clinic Origin',
                    hintText: 'e.g. Quest Diagnostics',
                    prefixIcon: Icon(Icons.business_rounded, color: AppColors.primaryTeal),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedTag,
                  isExpanded: true,
                  style: AppFonts.googleSans(fontSize: 13, color: AppColors.textDark),
                  decoration: const InputDecoration(labelText: 'Record Category'),
                  items: const [
                    DropdownMenuItem(value: 'Report', child: Text('Clinical Report', overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'Lab', child: Text('Lab Diagnostics', overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'Imaging', child: Text('Imaging & Scans', overflow: TextOverflow.ellipsis, maxLines: 1)),
                    DropdownMenuItem(value: 'Vaccination', child: Text('Vaccination Record', overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedTag = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: AppFonts.googleSans(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                if (titleCtrl.text.isNotEmpty) {
                  setState(() {
                    _userRecords.add({
                      'title': titleCtrl.text.trim(),
                      'provider': providerCtrl.text.trim().isEmpty ? 'MetroHealth' : providerCtrl.text.trim(),
                      'tag': selectedTag,
                      'dateInfo': 'Just now • PDF Document',
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document Uploaded Successfully to Encrypted Vault!'),
                      backgroundColor: AppColors.primaryTeal,
                    ),
                  );
                }
              },
              child: Text('Save Record', style: AppFonts.googleSans(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
