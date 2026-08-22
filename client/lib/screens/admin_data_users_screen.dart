import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AdminDataUsersScreen extends StatefulWidget {
  const AdminDataUsersScreen({super.key});

  @override
  State<AdminDataUsersScreen> createState() => _AdminDataUsersScreenState();
}

class _AdminDataUsersScreenState extends State<AdminDataUsersScreen>
    with SingleTickerProviderStateMixin {
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
    final fmtDate = DateFormat('MMM d, yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------------------------------------------------------------
          // Header Bento Banner
          // -------------------------------------------------------------
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientBrand,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentNavy.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System Administration & User Governance',
                          style: AppFonts.googleSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage CMS Monthly formulary ingestion pipelines, plan copay tier rules, and user roles.',
                          style: AppFonts.googleSans(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
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
                    onPressed: () => _showSimulatedUploadModal(context, appState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18, color: Colors.white),
                    label: Text(
                      'Ingest CMS File',
                      style: AppFonts.googleSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // -------------------------------------------------------------
          // Tabs Navigation Bar
          // -------------------------------------------------------------
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight, width: 1.2),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primaryTeal,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.primaryTeal,
                  indicatorWeight: 3,
                  labelStyle: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13),
                  unselectedLabelStyle: AppFonts.googleSans(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.dataset_rounded, size: 18),
                      text: 'Formulary Ingestion Pipeline',
                    ),
                    Tab(
                      icon: Icon(Icons.price_change_rounded, size: 18),
                      text: 'Plan Copay Tier Rules',
                    ),
                    Tab(
                      icon: Icon(Icons.people_alt_rounded, size: 18),
                      text: 'User Governance & Roles',
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 480,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildIngestionTab(context, appState, fmtDate),
                        _buildTierConfigTab(context, appState),
                        _buildUsersTab(context, appState),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngestionTab(
      BuildContext context, AppState appState, DateFormat fmtDate) {
    final records = appState.dataService.ingestionRecords;

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CMS Monthly Ingestion Records',
              style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Simulate File ETL Ingestion'),
              onPressed: () => _showSimulatedUploadModal(context, appState),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Table(
          border: TableBorder.all(color: AppColors.borderLight, borderRadius: BorderRadius.circular(12)),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(2),
            4: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.bgSlate),
              children: [
                _tableHeader('Filename'),
                _tableHeader('Upload Date'),
                _tableHeader('Records Processed'),
                _tableHeader('Status'),
                _tableHeader('Uploader'),
              ],
            ),
            ...records.map((r) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.filename, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(fmtDate.format(r.uploadDate), style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('${r.totalRecords}', style: AppFonts.googleSans(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        r.status.toUpperCase(),
                        style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.successText),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.uploadedBy, style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 11.5, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildTierConfigTab(BuildContext context, AppState appState) {
    final rules = appState.dataService.tierConfigs;

    return ListView(
      children: [
        Text(
          'Medicare Part D Copay Tier Configuration',
          style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 14),
        ...rules.map((rule) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier ${rule.tier}: ${rule.name}',
                      style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    Text(
                      rule.isSpecialty ? 'Coinsurance: ${rule.coinsurancePct.toInt()}%' : 'Standard In-Network Copay',
                      style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
                Text(
                  rule.isSpecialty ? '${rule.coinsurancePct.toInt()}% Coinsurance' : '\$${rule.defaultCopay.toInt()} Flat Copay',
                  style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13.5, color: AppColors.primaryTeal),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildUsersTab(BuildContext context, AppState appState) {
    final doctors = appState.doctors;

    return ListView(
      children: [
        Text(
          'Active Clinical Users & Prescribers',
          style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 14),
        ...doctors.map((d) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: const Icon(Icons.person_rounded, color: AppColors.primaryTeal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      Text('${d.specialty} • ${d.email}', style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('Doctor (Verified)', style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.successText)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _showSimulatedUploadModal(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('CMS Formulary File Ingestion', style: AppFonts.googleSans(fontWeight: FontWeight.w800)),
        content: Text(
          'This initiates an automated background ETL job parsing Medicare Part D formulary TXT/CSV files into Supabase.',
          style: AppFonts.googleSans(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: AppFonts.googleSans())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ETL Ingestion Job Triggered Successfully!'), backgroundColor: AppColors.primaryTeal),
              );
            },
            child: Text('Trigger ETL Ingestion', style: AppFonts.googleSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
