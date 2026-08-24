import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/health_records_vault_data.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/prescription_ocr_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

// ============================================================================
// DATA MODELS FOR HEALTH RECORDS VAULT (THERAPEUTIC CLASSES FROM DATASET)
// ============================================================================

enum DocumentCategory {
  all,
  cardiovascular,
  diabetes,
  respiratory,
  antibiotics,
  painManagement,
  otherClasses,
}

enum DocumentStatus {
  verified,
  pendingReview,
  requiresAttention,
}

enum ActivityType {
  uploaded,
  viewed,
  pendingReview,
  requiresAttention,
}

class VaultDocument {
  final String id;
  final String title;
  final String patientId;
  final String patientName;
  final DocumentCategory category;
  final DocumentStatus status;
  final String provider;
  final DateTime date;
  final String fileSize;
  final String fileFormat; // PDF, DICOM, JPG, PNG, HL7
  final String rawTherapeuticClass;
  final String? ocrSummary;
  final String? detectedMedication;
  final String? detectedDosage;
  final String? indication;
  final double confidence;
  final String? rawText;
  final String? base64Data;
  final bool isUserUploaded;

  VaultDocument({
    required this.id,
    required this.title,
    required this.patientId,
    required this.patientName,
    required this.category,
    required this.status,
    required this.provider,
    required this.date,
    required this.fileSize,
    required this.fileFormat,
    required this.rawTherapeuticClass,
    this.ocrSummary,
    this.detectedMedication,
    this.detectedDosage,
    this.indication,
    this.confidence = 0.98,
    this.rawText,
    this.base64Data,
    this.isUserUploaded = false,
  });

  String get categoryLabel {
    switch (category) {
      case DocumentCategory.cardiovascular:
        return 'Cardiovascular';
      case DocumentCategory.diabetes:
        return 'Diabetes';
      case DocumentCategory.respiratory:
        return 'Respiratory';
      case DocumentCategory.antibiotics:
        return 'Antibiotics';
      case DocumentCategory.painManagement:
        return 'Pain Management';
      case DocumentCategory.otherClasses:
        return 'Other Classes';
      case DocumentCategory.all:
      default:
        return 'All Prescriptions';
    }
  }

  String get statusLabel {
    switch (status) {
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.pendingReview:
        return 'Pending Review';
      case DocumentStatus.requiresAttention:
        return 'Requires Attention';
    }
  }
}

class VaultActivity {
  final String id;
  final String title;
  final String docName;
  final String? docId;
  final ActivityType type;
  final String timeStr;
  final DateTime timestamp;

  VaultActivity({
    required this.id,
    required this.title,
    required this.docName,
    this.docId,
    required this.type,
    required this.timeStr,
    required this.timestamp,
  });
}

// ============================================================================
// HEALTH RECORDS SCREEN
// ============================================================================

class HealthRecordsScreen extends StatefulWidget {
  const HealthRecordsScreen({super.key});

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen> {
  // Active Filter & Navigation State
  DocumentCategory _selectedCategory = DocumentCategory.all;
  String _selectedPatient = 'PAT_001 - John Smith';
  String _selectedDateRange = 'Last 30 Days';
  String _searchQuery = '';
  String _sortBy = 'Newest First';
  int _currentPage = 1;
  final int _itemsPerPage = 6;

  final TextEditingController _searchController = TextEditingController();

  // Unified dynamic dataset
  late List<VaultDocument> _documents;
  late List<VaultActivity> _activities;

  final List<String> _patientOptions = [
    'All Patients',
    'PAT_001 - John Smith',
    'PAT_002 - Sarah Jenkins',
    'PAT_003 - Michael Chang',
    'PAT_004 - Emily Davis',
    'PAT_005 - David Wilson',
  ];

  final List<String> _dateRangeOptions = [
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
    'This Year',
    'All Time',
  ];

  final List<String> _sortOptions = [
    'Newest First',
    'Oldest First',
    'Title (A-Z)',
    'File Size',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initializeData() {
    final now = DateTime.now();

    // 1. Load authentic dataset records from HealthRecordsVaultDataset
    _documents = HealthRecordsVaultDataset.getInitialDocuments();

    // 2. Initial recent activity stream
    _activities = [
      VaultActivity(
        id: 'ACT-1',
        title: 'Prescription verified',
        docName: 'Levetiracetam 500 MG Oral Tablet',
        docId: 'RX_00181',
        type: ActivityType.uploaded,
        timeStr: '10:24 AM Today',
        timestamp: now,
      ),
      VaultActivity(
        id: 'ACT-2',
        title: 'Prescription viewed',
        docName: 'Diclofenac Sodium 50 MG Delayed Release',
        docId: 'RX_02339',
        type: ActivityType.viewed,
        timeStr: 'Yesterday 04:35 PM',
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      VaultActivity(
        id: 'ACT-3',
        title: 'Pending review',
        docName: 'Sitagliptin 50 MG Oral Tablet',
        docId: 'RX_03825',
        type: ActivityType.pendingReview,
        timeStr: 'May 18, 2025 11:20 AM',
        timestamp: now.subtract(const Duration(days: 3)),
      ),
      VaultActivity(
        id: 'ACT-4',
        title: 'Requires attention',
        docName: 'Metformin HCl 500 MG Oral Tablet',
        docId: 'RX_04260',
        type: ActivityType.requiresAttention,
        timeStr: 'May 16, 2025 09:15 AM',
        timestamp: now.subtract(const Duration(days: 5)),
      ),
    ];
  }

  // ==========================================================================
  // FILTERING AND SORTING LOGIC (DYNAMIC BINDING)
  // ==========================================================================

  /// Get the list of documents belonging to the currently selected patient
  List<VaultDocument> get _patientDocuments {
    if (_selectedPatient == 'All Patients') {
      return _documents;
    }
    final targetId = _selectedPatient.split(' - ').first.trim();
    return _documents.where((d) {
      return d.patientId == targetId ||
          _selectedPatient.toLowerCase().contains(d.patientName.toLowerCase());
    }).toList();
  }

  /// Get the final filtered list applying patient, therapeutic category, search, and date range
  List<VaultDocument> get _filteredDocuments {
    final now = DateTime.now();

    return _patientDocuments.where((doc) {
      // 1. Therapeutic category filter
      if (_selectedCategory != DocumentCategory.all && doc.category != _selectedCategory) {
        return false;
      }

      // 2. Search query filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = doc.title.toLowerCase().contains(q);
        final matchProvider = doc.provider.toLowerCase().contains(q);
        final matchCategory = doc.categoryLabel.toLowerCase().contains(q);
        final matchRawClass = doc.rawTherapeuticClass.toLowerCase().contains(q);
        final matchIndication = (doc.indication ?? '').toLowerCase().contains(q);
        final matchPatient = doc.patientName.toLowerCase().contains(q);
        if (!matchTitle && !matchProvider && !matchCategory && !matchRawClass && !matchIndication && !matchPatient) {
          return false;
        }
      }

      // 3. Date range filter
      if (_selectedDateRange == 'Last 7 Days') {
        if (doc.date.isBefore(now.subtract(const Duration(days: 7)))) return false;
      } else if (_selectedDateRange == 'Last 30 Days') {
        if (doc.date.isBefore(now.subtract(const Duration(days: 30)))) return false;
      } else if (_selectedDateRange == 'Last 90 Days') {
        if (doc.date.isBefore(now.subtract(const Duration(days: 90)))) return false;
      } else if (_selectedDateRange == 'This Year') {
        if (doc.date.year != now.year) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        if (_sortBy == 'Oldest First') {
          return a.date.compareTo(b.date);
        } else if (_sortBy == 'Title (A-Z)') {
          return a.title.compareTo(b.title);
        } else if (_sortBy == 'File Size') {
          return b.fileSize.compareTo(a.fileSize);
        } else {
          // Newest First
          return b.date.compareTo(a.date);
        }
      });
  }

  /// Dynamic distribution count for a given therapeutic category based on selected patient
  int _getCountForCategory(DocumentCategory cat) {
    return _patientDocuments.where((d) => d.category == cat).length;
  }

  // ==========================================================================
  // MAIN BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDocuments;
    final totalCount = filtered.length;
    final totalPages = (totalCount / _itemsPerPage).ceil().clamp(1, 99);
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalCount);
    final pagedDocs = (startIndex < totalCount) ? filtered.sublist(startIndex, endIndex) : <VaultDocument>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Hero Banner (Electronic Health Records Vault)
            _buildHeroBanner(context),
            const SizedBox(height: 18),

            // 2. Control Bar: Patient Selector + Date Range + Search Input
            _buildFilterControlCard(),
            const SizedBox(height: 14),

            // 3. Category Filter Buttons Row (Therapeutic Classes)
            _buildCategoryFilterRow(),
            const SizedBox(height: 20),

            // 4. Asymmetric 2-Column Grid: Left Documents List + Right Distribution & Activity
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 980;

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Document List & Pagination
                      Expanded(
                        flex: 65,
                        child: _buildDocumentsListPanel(
                          docs: pagedDocs,
                          totalCount: totalCount,
                          totalPages: totalPages,
                        ),
                      ),
                      const SizedBox(width: 22),

                      // Right Column: Vault Distribution + Recent Activity
                      Expanded(
                        flex: 35,
                        child: Column(
                          children: [
                            _buildVaultDistributionCard(),
                            const SizedBox(height: 18),
                            _buildRecentActivityCard(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildDocumentsListPanel(
                        docs: pagedDocs,
                        totalCount: totalCount,
                        totalPages: totalPages,
                      ),
                      const SizedBox(height: 20),
                      _buildVaultDistributionCard(),
                      const SizedBox(height: 18),
                      _buildRecentActivityCard(),
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 22),

            // 5. Bottom Security Footer Banner
            _buildSecurityFooterBanner(),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 1. TOP HERO BANNER
  // ==========================================================================
  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF072152), Color(0xFF0A378C), Color(0xFF0052CC)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052CC).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Folder icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.folder_shared_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 18),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Electronic Health Records Vault',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C49F).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF00C49F).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'End-to-End Encrypted',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'HIPAA-compliant document management categorized by therapeutic class across all prescribed medications.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Upload Document Pill Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0062FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.transparent,
            ),
            icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
            label: Text(
              'Upload Document',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () => _showUploadDocumentModal(context),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. CONTROL BAR (PATIENT SELECTOR + DATE RANGE + SEARCH)
  // ==========================================================================
  Widget _buildFilterControlCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // A. Patient Selector Dropdown
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPatient,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  items: _patientOptions.map((p) {
                    return DropdownMenuItem<String>(
                      value: p,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_rounded,
                            size: 16,
                            color: Color(0xFF0062FF),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedPatient = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // B. Date Range Dropdown
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedDateRange,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                  items: _dateRangeOptions.map((dr) {
                    return DropdownMenuItem<String>(
                      value: dr,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Text(dr),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedDateRange = val;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // C. Search Input Field
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Search medications by drug name, therapeutic class, or indication...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 19,
                    color: Color(0xFF0062FF),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _currentPage = 1;
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF0062FF), width: 1.4),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                    _currentPage = 1;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 3. CATEGORY FILTER PILLS ROW (5 MAJOR THERAPEUTIC CLASSES + OTHERS)
  // ==========================================================================
  Widget _buildCategoryFilterRow() {
    final categories = [
      {'cat': DocumentCategory.all, 'label': 'All Classes', 'icon': Icons.medical_services_rounded},
      {'cat': DocumentCategory.cardiovascular, 'label': 'Cardiovascular', 'icon': Icons.favorite_rounded},
      {'cat': DocumentCategory.diabetes, 'label': 'Diabetes', 'icon': Icons.bloodtype_rounded},
      {'cat': DocumentCategory.respiratory, 'label': 'Respiratory', 'icon': Icons.air_rounded},
      {'cat': DocumentCategory.antibiotics, 'label': 'Antibiotics', 'icon': Icons.biotech_rounded},
      {'cat': DocumentCategory.painManagement, 'label': 'Pain Management', 'icon': Icons.healing_rounded},
      {'cat': DocumentCategory.otherClasses, 'label': 'Other Classes', 'icon': Icons.category_rounded},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: categories.map((item) {
          final cat = item['cat'] as DocumentCategory;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isActive = _selectedCategory == cat;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _selectedCategory = cat;
                  _currentPage = 1;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF0A1931) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? const Color(0xFF0A1931) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: const Color(0xFF0A1931).withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    else
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================================================
  // 4. DOCUMENTS LIST PANEL (MAIN COLUMN)
  // ==========================================================================
  Widget _buildDocumentsListPanel({
    required List<VaultDocument> docs,
    required int totalCount,
    required int totalPages,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with dynamic count & sort selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Documents ($totalCount)',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Row(
              children: [
                Text(
                  'Sort by: ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      isDense: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0062FF),
                      ),
                      items: _sortOptions.map((s) {
                        return DropdownMenuItem<String>(
                          value: s,
                          child: Text(s),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sortBy = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List of Document Cards
        if (docs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_off_rounded,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(height: 12),
                Text(
                  'No prescriptions found in this category',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try selecting a different therapeutic class or clearing your search query.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final doc = docs[idx];
              return _buildDocumentRowCard(doc);
            },
          ),

        const SizedBox(height: 18),

        // Pagination Bar (< 1 2 3 >)
        _buildPaginationControls(totalPages: totalPages),
      ],
    );
  }

  // ==========================================================================
  // SINGLE DOCUMENT ROW CARD
  // ==========================================================================
  Widget _buildDocumentRowCard(VaultDocument doc) {
    // Determine icon colors based on therapeutic category
    Color iconColor;
    Color iconBg;
    IconData icon;

    switch (doc.category) {
      case DocumentCategory.cardiovascular:
        iconColor = const Color(0xFF0062FF);
        iconBg = const Color(0xFFEFF6FF);
        icon = Icons.favorite_rounded;
        break;
      case DocumentCategory.diabetes:
        iconColor = const Color(0xFF0D9488);
        iconBg = const Color(0xFFCCFBF1);
        icon = Icons.bloodtype_rounded;
        break;
      case DocumentCategory.respiratory:
        iconColor = const Color(0xFF0284C7);
        iconBg = const Color(0xFFE0F2FE);
        icon = Icons.air_rounded;
        break;
      case DocumentCategory.antibiotics:
        iconColor = const Color(0xFF9333EA);
        iconBg = const Color(0xFFF3E8FF);
        icon = Icons.biotech_rounded;
        break;
      case DocumentCategory.painManagement:
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        icon = Icons.healing_rounded;
        break;
      case DocumentCategory.otherClasses:
      case DocumentCategory.all:
      default:
        iconColor = const Color(0xFFDC2626);
        iconBg = const Color(0xFFFEE2E2);
        icon = Icons.picture_as_pdf_rounded;
        break;
    }

    // Status Badge colors
    Color statusTextColor;
    Color statusBgColor;
    switch (doc.status) {
      case DocumentStatus.verified:
        statusTextColor = const Color(0xFF16A34A);
        statusBgColor = const Color(0xFFDCFCE7);
        break;
      case DocumentStatus.pendingReview:
        statusTextColor = const Color(0xFFD97706);
        statusBgColor = const Color(0xFFFEF3C7);
        break;
      case DocumentStatus.requiresAttention:
        statusTextColor = const Color(0xFFDC2626);
        statusBgColor = const Color(0xFFFEE2E2);
        break;
    }

    // Category badge color
    Color catTextColor;
    Color catBgColor;
    switch (doc.category) {
      case DocumentCategory.cardiovascular:
        catTextColor = const Color(0xFF0062FF);
        catBgColor = const Color(0xFFEFF6FF);
        break;
      case DocumentCategory.diabetes:
        catTextColor = const Color(0xFF0D9488);
        catBgColor = const Color(0xFFCCFBF1);
        break;
      case DocumentCategory.respiratory:
        catTextColor = const Color(0xFF0284C7);
        catBgColor = const Color(0xFFE0F2FE);
        break;
      case DocumentCategory.antibiotics:
        catTextColor = const Color(0xFF9333EA);
        catBgColor = const Color(0xFFF3E8FF);
        break;
      case DocumentCategory.painManagement:
        catTextColor = const Color(0xFFD97706);
        catBgColor = const Color(0xFFFEF3C7);
        break;
      case DocumentCategory.otherClasses:
      default:
        catTextColor = const Color(0xFF475569);
        catBgColor = const Color(0xFFF1F5F9);
        break;
    }

    final dateFormatted = DateFormat('MMM dd, yyyy').format(doc.date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left File Icon Box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Center: Title + Badges + Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        doc.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.categoryLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: catTextColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.statusLabel,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle Info
                Text(
                  'Provider: ${doc.provider} • $dateFormatted • ${doc.rawTherapeuticClass} • ${doc.fileSize}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Right Action Icons: View (Eye), Download, More (3 Dots)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Eye Action Button
              IconButton(
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                color: const Color(0xFF0062FF),
                tooltip: 'Preview Prescription',
                splashRadius: 20,
                onPressed: () {
                  _logActivity(ActivityType.viewed, 'Prescription viewed', doc.title, docId: doc.id);
                  _showDocumentPreviewModal(context, doc);
                },
              ),

              // Download Action Button
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 18),
                color: const Color(0xFF0062FF),
                tooltip: 'Download Record',
                splashRadius: 20,
                onPressed: () {
                  _downloadDocument(doc);
                },
              ),

              // More Actions Dropdown
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                splashRadius: 20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) {
                  if (val == 'view') {
                    _showDocumentPreviewModal(context, doc);
                  } else if (val == 'download') {
                    _downloadDocument(doc);
                  } else if (val == 'ocr') {
                    _showOcrAnalysisModal(context, doc);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_rounded, size: 16, color: Color(0xFF0062FF)),
                        const SizedBox(width: 10),
                        Text('View Prescription Details', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'ocr',
                    child: Row(
                      children: [
                        const Icon(Icons.auto_fix_high_rounded, size: 16, color: Color(0xFF9333EA)),
                        const SizedBox(width: 10),
                        Text('Therapeutic Analysis', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'download',
                    child: Row(
                      children: [
                        const Icon(Icons.download_rounded, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 10),
                        Text('Download e-Rx PDF', style: GoogleFonts.inter(fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // PAGINATION CONTROLS
  // ==========================================================================
  Widget _buildPaginationControls({required int totalPages}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Prev Page Button
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: _currentPage > 1 ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Page Number Buttons
        for (int i = 1; i <= totalPages; i++) ...[
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _currentPage = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _currentPage == i ? const Color(0xFF0062FF) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _currentPage == i ? const Color(0xFF0062FF) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                '$i',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _currentPage == i ? Colors.white : const Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],

        // Next Page Button
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: _currentPage < totalPages ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // 5. VAULT DISTRIBUTION CARD (RIGHT COLUMN) - 5 MAJOR CLASSES + OTHERS
  // ==========================================================================
  Widget _buildVaultDistributionCard() {
    final cardioCount = _getCountForCategory(DocumentCategory.cardiovascular);
    final diabetesCount = _getCountForCategory(DocumentCategory.diabetes);
    final respiratoryCount = _getCountForCategory(DocumentCategory.respiratory);
    final antibioticsCount = _getCountForCategory(DocumentCategory.antibiotics);
    final painCount = _getCountForCategory(DocumentCategory.painManagement);
    final othersCount = _getCountForCategory(DocumentCategory.otherClasses);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vault Distribution',
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Therapeutic class allocation (Click to filter)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Cardiovascular
          _buildDistributionTile(
            title: 'Cardiovascular',
            count: cardioCount,
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFF0062FF),
            targetCategory: DocumentCategory.cardiovascular,
          ),
          const SizedBox(height: 10),

          // 2. Diabetes
          _buildDistributionTile(
            title: 'Diabetes',
            count: diabetesCount,
            icon: Icons.bloodtype_rounded,
            iconColor: const Color(0xFF0D9488),
            targetCategory: DocumentCategory.diabetes,
          ),
          const SizedBox(height: 10),

          // 3. Respiratory
          _buildDistributionTile(
            title: 'Respiratory',
            count: respiratoryCount,
            icon: Icons.air_rounded,
            iconColor: const Color(0xFF0284C7),
            targetCategory: DocumentCategory.respiratory,
          ),
          const SizedBox(height: 10),

          // 4. Antibiotics
          _buildDistributionTile(
            title: 'Antibiotics',
            count: antibioticsCount,
            icon: Icons.biotech_rounded,
            iconColor: const Color(0xFF9333EA),
            targetCategory: DocumentCategory.antibiotics,
          ),
          const SizedBox(height: 10),

          // 5. Pain Management
          _buildDistributionTile(
            title: 'Pain Management',
            count: painCount,
            icon: Icons.healing_rounded,
            iconColor: const Color(0xFFD97706),
            targetCategory: DocumentCategory.painManagement,
          ),
          const SizedBox(height: 10),

          // 6. Other Classes
          _buildDistributionTile(
            title: 'Other Classes',
            count: othersCount,
            icon: Icons.category_rounded,
            iconColor: const Color(0xFF64748B),
            targetCategory: DocumentCategory.otherClasses,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionTile({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
    required DocumentCategory targetCategory,
  }) {
    final isSelected = _selectedCategory == targetCategory;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          // Toggle filter
          _selectedCategory = isSelected ? DocumentCategory.all : targetCategory;
          _currentPage = 1;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFEFF6FF)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0062FF)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? const Color(0xFF0062FF) : const Color(0xFF1E293B),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0062FF) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count Files',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 6. RECENT ACTIVITY CARD (RIGHT COLUMN)
  // ==========================================================================
  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: const Color(0xFF0A1931),
                      content: Text('All ${_activities.length} recent vault activities synchronized.'),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0062FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            separatorBuilder: (context, idx) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final act = _activities[idx];
              return _buildActivityItem(act);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(VaultActivity act) {
    Color iconColor;
    Color iconBg;
    IconData icon;

    switch (act.type) {
      case ActivityType.uploaded:
        iconColor = const Color(0xFF16A34A);
        iconBg = const Color(0xFFDCFCE7);
        icon = Icons.arrow_upward_rounded;
        break;
      case ActivityType.viewed:
        iconColor = const Color(0xFF0062FF);
        iconBg = const Color(0xFFEFF6FF);
        icon = Icons.remove_red_eye_outlined;
        break;
      case ActivityType.pendingReview:
        iconColor = const Color(0xFFD97706);
        iconBg = const Color(0xFFFEF3C7);
        icon = Icons.access_time_rounded;
        break;
      case ActivityType.requiresAttention:
        iconColor = const Color(0xFFDC2626);
        iconBg = const Color(0xFFFEE2E2);
        icon = Icons.warning_amber_rounded;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        if (act.docId != null) {
          final matched = _documents.where((d) => d.id == act.docId).toList();
          if (matched.isNotEmpty) {
            _showDocumentPreviewModal(context, matched.first);
            return;
          }
        }
        final matchByName = _documents.where((d) => d.title.toLowerCase().contains(act.docName.toLowerCase())).toList();
        if (matchByName.isNotEmpty) {
          _showDocumentPreviewModal(context, matchByName.first);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    act.title,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    act.docName,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              act.timeStr,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 7. BOTTOM SECURITY FOOTER BANNER
  // ==========================================================================
  Widget _buildSecurityFooterBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFF0062FF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data is secure',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'All documents are encrypted and stored in compliance with HIPAA standards and healthcare regulations.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Badges
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF93C5FD)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF0062FF)),
                    const SizedBox(width: 6),
                    Text(
                      'HIPAA Compliant',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0062FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      'End-to-End Encrypted',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // INTERACTIVE MODALS (PREVIEW, UPLOAD WITH OCR, DOWNLOAD)
  // ==========================================================================

  void _logActivity(ActivityType type, String title, String docName, {String? docId}) {
    setState(() {
      _activities.insert(
        0,
        VaultActivity(
          id: 'ACT-${DateTime.now().millisecondsSinceEpoch}',
          title: title,
          docName: docName,
          docId: docId,
          type: type,
          timeStr: 'Just now',
          timestamp: DateTime.now(),
        ),
      );
      if (_activities.length > 6) {
        _activities.removeLast();
      }
    });
  }

  Future<void> _downloadDocument(VaultDocument doc) async {
    _logActivity(ActivityType.viewed, 'Document downloaded', doc.title, docId: doc.id);

    try {
      await PdfExportService.instance.downloadOrShareVaultPdf(
        docId: doc.id,
        title: doc.title,
        patientName: doc.patientName,
        patientId: doc.patientId,
        provider: doc.provider,
        date: doc.date,
        therapeuticClass: doc.rawTherapeuticClass,
        categoryLabel: doc.categoryLabel,
        statusLabel: doc.statusLabel,
        dosage: doc.detectedDosage,
        indication: doc.indication,
        summary: doc.ocrSummary,
        rawText: doc.rawText,
        confidence: doc.confidence,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.download_done_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Downloaded "${doc.title}.${doc.fileFormat.toLowerCase()}" (${doc.fileSize}) successfully.',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Failed to download document: $e',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  void _showDocumentPreviewModal(BuildContext context, VaultDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            width: 780,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1931),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          doc.title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Modal Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Key Metadata Strip
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetaCol('Patient', '${doc.patientName} (${doc.patientId})'),
                              _buildMetaCol('Therapeutic Class', doc.rawTherapeuticClass),
                              _buildMetaCol('Category', doc.categoryLabel),
                              _buildMetaCol('Provider', doc.provider),
                              _buildMetaCol('Date', DateFormat('MMM dd, yyyy').format(doc.date)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Clinical / OCR Extracted Summary Card
                        if (doc.ocrSummary != null) ...[
                          Text(
                            'Therapeutic & Clinical Summary',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF0062FF), size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    doc.ocrSummary!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E3A8A),
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Raw Extracted Text / Medical OCR
                        if (doc.rawText != null) ...[
                          Text(
                            'Verified Formulary Record Transcript',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: SelectableText(
                              doc.rawText!,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Modal Footer Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded, size: 14, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Text(
                            'HIPAA Cryptographically Signed Record',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0062FF),
                              side: const BorderSide(color: Color(0xFF0062FF)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: Text('Download File', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _downloadDocument(doc);
                            },
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A1931),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetaCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showOcrAnalysisModal(BuildContext context, VaultDocument doc) {
    _showDocumentPreviewModal(context, doc);
  }

  // ==========================================================================
  // FUNCTIONAL UPLOAD DOCUMENT MODAL WITH OCR FLOW
  // ==========================================================================
  void _showUploadDocumentModal(BuildContext context) {
    final titleController = TextEditingController();
    final providerController = TextEditingController(text: 'MetroHealth Pharmacy');
    DocumentCategory uploadCategory = DocumentCategory.cardiovascular;
    String selectedPatientId = 'PAT_001';
    String selectedPatientName = 'John Smith';
    bool isProcessingOcr = false;
    String? detectedOcrText;
    String? pickedFileName;
    int pickedFileBytesCount = 0;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 640,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A1931),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Text(
                            'Upload & Ingest Prescription Record',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Body Form
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File Drop / Picker Area
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () async {
                              try {
                                final result = await FilePicker.pickFiles(
                                  type: FileType.custom,
  allowedExtensions: [
    'pdf',
    'png',
    'jpg',
    'jpeg',
    'txt',
    'hl7',
    'json',
    'dicom',
  ],
  withData: true,
);

if (result != null && result.files.isNotEmpty) {
                                  final file = result.files.first;
                                  final bytes = file.bytes ?? Uint8List(0);

                                  setModalState(() {
                                    pickedFileName = file.name;
                                    pickedFileBytesCount = bytes.length;
                                    isProcessingOcr = true;
                                    if (titleController.text.isEmpty) {
                                      titleController.text = file.name.split('.').first.replaceAll('_', ' ');
                                    }
                                  });

                                  // Run OCR Extraction in background
                                  final ocr = await PrescriptionOcrService.processPrescription(
                                    fileName: file.name,
                                    bytes: bytes,
                                    patientId: selectedPatientId,
                                  );

                                  setModalState(() {
                                    isProcessingOcr = false;
                                    detectedOcrText = ocr.rawText.isNotEmpty
                                        ? ocr.rawText
                                        : 'Extracted: ${ocr.drugName} ${ocr.strength} • Diagnosis: ${ocr.indication}';
                                  });
                                }
                              } catch (e) {
                                setModalState(() => isProcessingOcr = false);
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: pickedFileName != null ? const Color(0xFF16A34A) : const Color(0xFF0062FF),
                                  style: BorderStyle.solid,
                                  width: 1.4,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    pickedFileName != null ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                                    size: 36,
                                    color: pickedFileName != null ? const Color(0xFF16A34A) : const Color(0xFF0062FF),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    pickedFileName ?? 'Click to select PDF, JPG, PNG, or DICOM file',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    pickedFileName != null
                                        ? '${(pickedFileBytesCount / 1024).toStringAsFixed(1)} KB • AI OCR Ready'
                                        : 'Automatic AI text & clinical parameter extraction',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Document Title
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'Medication / Document Title',
                              hintText: 'e.g. Atorvastatin 20 MG Oral Tablet',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Row: Patient Selector + Category
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedPatientId,
                                  decoration: InputDecoration(
                                    labelText: 'Assign to Patient',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'PAT_001', child: Text('PAT_001 - John Smith')),
                                    DropdownMenuItem(value: 'PAT_002', child: Text('PAT_002 - Sarah Jenkins')),
                                    DropdownMenuItem(value: 'PAT_003', child: Text('PAT_003 - Michael Chang')),
                                    DropdownMenuItem(value: 'PAT_004', child: Text('PAT_004 - Emily Davis')),
                                    DropdownMenuItem(value: 'PAT_005', child: Text('PAT_005 - David Wilson')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      selectedPatientId = val;
                                      if (val == 'PAT_001') selectedPatientName = 'John Smith';
                                      if (val == 'PAT_002') selectedPatientName = 'Sarah Jenkins';
                                      if (val == 'PAT_003') selectedPatientName = 'Michael Chang';
                                      if (val == 'PAT_004') selectedPatientName = 'Emily Davis';
                                      if (val == 'PAT_005') selectedPatientName = 'David Wilson';
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<DocumentCategory>(
                                  value: uploadCategory,
                                  decoration: InputDecoration(
                                    labelText: 'Therapeutic Class',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: DocumentCategory.cardiovascular,
                                      child: Text('Cardiovascular'),
                                    ),
                                    DropdownMenuItem(
                                      value: DocumentCategory.diabetes,
                                      child: Text('Diabetes'),
                                    ),
                                    DropdownMenuItem(
                                      value: DocumentCategory.respiratory,
                                      child: Text('Respiratory'),
                                    ),
                                    DropdownMenuItem(
                                      value: DocumentCategory.antibiotics,
                                      child: Text('Antibiotics'),
                                    ),
                                    DropdownMenuItem(
                                      value: DocumentCategory.painManagement,
                                      child: Text('Pain Management'),
                                    ),
                                    DropdownMenuItem(
                                      value: DocumentCategory.otherClasses,
                                      child: Text('Other Classes'),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) uploadCategory = val;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Provider
                          TextField(
                            controller: providerController,
                            decoration: InputDecoration(
                              labelText: 'Dispensing Pharmacy / Provider',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),

                          if (isProcessingOcr) ...[
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0062FF)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Processing OCR & Extracting Clinical Data...',
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF0062FF)),
                                ),
                              ],
                            ),
                          ],

                          if (detectedOcrText != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Text(
                                'AI OCR Result: $detectedOcrText',
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 16),
                            label: Text(
                              'Ingest to Vault',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              final docTitle = titleController.text.trim().isNotEmpty
                                  ? titleController.text.trim()
                                  : (pickedFileName ?? 'Prescription Record');

                              final newDoc = VaultDocument(
                                id: 'RX_${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                                title: docTitle,
                                patientId: selectedPatientId,
                                patientName: selectedPatientName,
                                category: uploadCategory,
                                status: DocumentStatus.verified,
                                provider: providerController.text.trim().isNotEmpty
                                    ? providerController.text.trim()
                                    : 'MetroHealth Pharmacy',
                                date: DateTime.now(),
                                fileSize: pickedFileBytesCount > 0
                                    ? '${(pickedFileBytesCount / (1024 * 1024)).toStringAsFixed(1)} MB'
                                    : '1.8 MB',
                                fileFormat: pickedFileName != null && pickedFileName!.contains('.')
                                    ? pickedFileName!.split('.').last.toUpperCase()
                                    : 'PDF',
                                rawTherapeuticClass: uploadCategory.name,
                                ocrSummary: detectedOcrText ?? 'Verified prescription uploaded to vault.',
                                rawText: detectedOcrText,
                                isUserUploaded: true,
                              );

                              setState(() {
                                _documents.insert(0, newDoc);
                              });

                              _logActivity(ActivityType.uploaded, 'Prescription uploaded', docTitle, docId: newDoc.id);

                              Navigator.of(ctx).pop();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Uploaded "$docTitle" to Health Records Vault.',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
