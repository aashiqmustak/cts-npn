import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Admin Portal: Datasets, Copay Rules & Users',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage CMS Monthly Prescription Drug Plan formulary files, copay tier rules, and user roles.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                label: const Text('Upload CMS Formulary File'),
                onPressed: () {
                  _showSimulatedUploadModal(context, appState);
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Tabs Navigation
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryTeal,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryTeal,
              indicatorWeight: 3,
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
                  text: 'User Account Management',
                ),
              ],
            ),
          ),

          // Tab View Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: SizedBox(
              height: 480,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Ingestion History
                  _buildIngestionTab(context, appState, fmtDate),

                  // Tab 2: Tier Config
                  _buildTierConfigTab(context, appState),

                  // Tab 3: User Management
                  _buildUsersTab(context, appState),
                ],
              ),
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
            const Text(
              'CMS Monthly Ingestion Records',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
          border: TableBorder.all(color: AppColors.borderLight),
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
              children: const [
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Filename', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Upload Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Records Processed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('Uploader', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            ...records.map((r) {
              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.filename, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(fmtDate.format(r.uploadDate), style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text('${r.totalRecords} (Tiers: ${r.updatedTiers})', style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.status, style: const TextStyle(fontSize: 12, color: AppColors.successText, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(r.uploadedBy, style: const TextStyle(fontSize: 12)),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildTierConfigTab(BuildContext context, AppState appState) {
    final tiers = appState.dataService.tierConfigs;

    return ListView(
      children: [
        const Text(
          'Part D Formulary Tier Copay Structure',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Configure default tier copay and coinsurance amounts used to calculate estimated patient cost-share.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        Column(
          children: tiers.map((t) {
            final copayCtrl = TextEditingController(text: t.defaultCopay.toStringAsFixed(0));
            final coinsCtrl = TextEditingController(text: t.coinsurancePct.toStringAsFixed(0));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.bgSlate,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryTeal,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Tier ${t.tier}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(t.isSpecialty ? 'Specialty Coinsurance Rules' : 'Standard Copay Structure',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: copayCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Copay (\$)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: TextField(
                      controller: coinsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Coinsurance (%)',
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final c = double.tryParse(copayCtrl.text) ?? t.defaultCopay;
                      final pct = double.tryParse(coinsCtrl.text) ?? t.coinsurancePct;
                      appState.updateTierCopay(t.tier, c, pct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated Tier ${t.tier} copay to \$${c.toInt()}!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUsersTab(BuildContext context, AppState appState) {
    final users = appState.dataService.users;

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Platform User Accounts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Add User Account'),
              onPressed: () => _showAddUserModal(context, appState),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Column(
          children: users.map((u) {
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(u.avatarUrl),
              ),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${u.title} • Email: ${u.email}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: u.isAdmin ? AppColors.purpleBg : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  u.role.name.toUpperCase(),
                  style: TextStyle(
                    color: u.isAdmin ? AppColors.purpleText : AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showSimulatedUploadModal(BuildContext context, AppState appState) {
    final filenameCtrl = TextEditingController(
        text: 'CMS_2026_Q4_Formulary_PartD_H0001_Update.csv');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate CMS File Ingestion Pipeline'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select or enter a CMS Monthly Prescription Drug Plan Formulary CSV file to normalize and ingest into local dataset.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: filenameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Formulary CSV Filename',
                  prefixIcon: Icon(Icons.file_present_rounded),
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
              appState.simulateFileUpload(filenameCtrl.text);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ingested ${filenameCtrl.text} successfully! Dataset updated.'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: const Text('Start Ingestion'),
          ),
        ],
      ),
    );
  }

  void _showAddUserModal(BuildContext context, AppState appState) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    UserRole selectedRole = UserRole.pharmacist;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User Account'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email Address'),
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
              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                final newUser = User(
                  id: 'U00${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  role: selectedRole,
                  assignedPatientIds: ['PT101', 'PT102'],
                  avatarUrl: 'https://i.pravatar.cc/150?img=68',
                  title: selectedRole == UserRole.admin ? 'System Administrator' : 'Staff Pharmacist',
                );
                appState.addUser(newUser);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User ${nameCtrl.text} added successfully!'),
                    backgroundColor: AppColors.primaryTeal,
                  ),
                );
              }
            },
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }
}
