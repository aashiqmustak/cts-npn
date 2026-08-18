import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.bgSlate,
      body: Row(
        children: [
          // Left Sidebar Navigation
          if (isDesktop) _buildSidebar(context, appState, user),

          // Main Workspace Area
          Expanded(
            child: Column(
              children: [
                // Top Search Header & Role Badge
                _buildTopBar(context, appState, user),

                // Main Content Screen
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState appState, User user) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Brand Logo & Title (Alternea)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Alternea',
                      style: TextStyle(
                        color: AppColors.accentNavy,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Healthcare & Prescription Ecosystem',
                      style: TextStyle(
                        color: AppColors.primaryTeal,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. Role Selector Pill Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(user.avatarUrl),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        PopupMenuButton<UserRole>(
                          tooltip: 'Switch Active Role (5 Roles Available)',
                          onSelected: (selectedRole) {
                            final roleUser = User(
                              id: 'U_${selectedRole.name}',
                              name: '${selectedRole.name.toUpperCase()} User',
                              email: '${selectedRole.name}@alternea.org',
                              role: selectedRole,
                              assignedPatientIds: [],
                              avatarUrl: 'https://i.pravatar.cc/150?img=12',
                              title: selectedRole.name,
                            );
                            appState.setCurrentUser(roleUser);
                          },
                          itemBuilder: (context) => UserRole.values.map((role) {
                            return PopupMenuItem<UserRole>(
                              value: role,
                              child: Row(
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      size: 16, color: AppColors.primaryTeal),
                                  const SizedBox(width: 8),
                                  Text(
                                    role.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          child: Row(
                            children: [
                              Text(
                                user.roleLabel,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 14,
                                color: AppColors.primaryTeal,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Dynamic Sidebar Navigation Menu Items Based on Active Role
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: _getNavItemsForRole(appState, user),
            ),
          ),

          // 4. Supabase Status Indicator
          Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_done, color: AppColors.primaryTeal, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Supabase DB Sync Ready',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
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

  List<Widget> _getNavItemsForRole(AppState appState, User user) {
    if (user.isDoctor) {
      return [
        _buildNavItem(0, Icons.edit_note_rounded, 'Issue Prescription', appState),
        _buildNavItem(1, Icons.people_outline, 'My Patients', appState),
        _buildNavItem(2, Icons.local_hospital_outlined, 'Hospitals Directory', appState),
        _buildNavItem(3, Icons.analytics_outlined, 'Clinical Analytics', appState),
      ];
    } else if (user.isPharmacist) {
      return [
        _buildNavItem(0, Icons.local_pharmacy_rounded, 'Dispense Portal', appState),
        _buildNavItem(1, Icons.receipt_long_outlined, 'Prescriptions List', appState),
        _buildNavItem(2, Icons.warning_amber_rounded, 'Adherence Risk', appState),
        _buildNavItem(3, Icons.explore_outlined, 'Formulary Explorer', appState),
      ];
    } else if (user.isPatient) {
      return [
        _buildNavItem(0, Icons.favorite_rounded, 'My Health & Meds', appState),
        _buildNavItem(1, Icons.history_rounded, 'Prescription History', appState),
        _buildNavItem(2, Icons.local_hospital_outlined, 'Hospitals & Doctors', appState),
      ];
    } else if (user.isInsuranceAgent) {
      return [
        _buildNavItem(0, Icons.verified_user_outlined, 'Insurance Portal', appState),
        _buildNavItem(1, Icons.explore_outlined, 'Formulary Catalog', appState),
        _buildNavItem(2, Icons.fact_check_outlined, 'PA Friction Review', appState),
      ];
    } else {
      // Admin Role
      return [
        _buildNavItem(0, Icons.dashboard_customize_rounded, 'Overview Dashboard', appState),
        _buildNavItem(1, Icons.local_hospital_outlined, 'Hospitals Directory', appState),
        _buildNavItem(2, Icons.badge_outlined, 'Doctors Directory', appState),
        _buildNavItem(3, Icons.local_pharmacy_rounded, 'Pharmacists & Users', appState),
        _buildNavItem(4, Icons.cloud_upload_outlined, 'Formulary Ingestion', appState),
        _buildNavItem(5, Icons.bar_chart_rounded, 'System Reports', appState),
      ];
    }
  }

  Widget _buildNavItem(
      int index, IconData icon, String label, AppState appState) {
    final isSelected = appState.currentNavIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            appState.setNavIndex(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.textDark,
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppState appState, User user) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          // Search Input Bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 480),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search patients, medicines, doctors, hospitals in Alternea...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textMuted, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.primaryTeal),
                  ),
                ),
                onChanged: (val) => appState.setGlobalSearchQuery(val),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Role Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Role: ${user.roleLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Sign Out Option
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 20),
            onPressed: () => appState.logout(),
          ),
        ],
      ),
    );
  }
}
