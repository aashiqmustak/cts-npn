import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

// Screens for pre-cached IndexedStack navigation viewport
import '../screens/doctor_prescription_screen.dart';
import '../screens/pharmacist_dispense_screen.dart';
import '../screens/prescriptions_screen.dart';
import '../screens/prescription_details_screen.dart';
import '../screens/adherence_screen.dart';
import '../screens/formulary_screen.dart';
import '../screens/patient_interactive_screen.dart';
import '../screens/my_medicines_screen.dart';
import '../screens/hospitals_screen.dart';
import '../screens/health_records_screen.dart';
import '../screens/insurance_portal_screen.dart';
import '../screens/friction_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/dashboard_overview_screen.dart';
import '../screens/pharmacist_analytics_screen.dart';
import '../screens/admin_data_users_screen.dart';
import '../screens/admin_reports_screen.dart';
import '../screens/voice_agent_screen.dart';

class MainLayout extends StatelessWidget {
  final Widget? child;

  const MainLayout({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final isDesktop = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppColors.bgSlate,
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: _buildSidebar(context, appState, user),
            )
          : null,
      body: Row(
        children: [
          // 1. Floating Frosted Glass Vertical Command Panel (Desktop)
          if (isDesktop) _buildSidebar(context, appState, user),

          // 2. Main Content Portal Canvas Area
          Expanded(
            child: Column(
              children: [
                // Top Command Header & Interactive Role Switcher
                _buildTopBar(context, appState, user, isDesktop),

                // Buttery-Smooth Hot-Memory Viewport Layer
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.015), // subtle 10-pixel upward slide
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${user.role.name}_${appState.currentNavIndex}_${appState.selectedPrescriptionId ?? 'none'}',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: child ?? _RoleScreenStack(appState: appState, user: user),
                      ),
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

  Widget _buildSidebar(BuildContext context, AppState appState, User user) {
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.metallicBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Identity Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: AppColors.gradientPill,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Alternea',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Health',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primaryTeal,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Clinical Ecosystem',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Divider(
                  color: AppColors.metallicBorder,
                  height: 1,
                ),
              ),
              const SizedBox(height: 14),

              // Active Role Switcher Card
              _RoleSwitcherSidebarCard(user: user, appState: appState),

              const SizedBox(height: 16),

              // Navigation Scope List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _getNavItemsForRole(appState, user),
                ),
              ),

              // FHIR v4.0 Active Status Badge
              Container(
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.successGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'FHIR v4.0 Synchronized',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.successText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getNavItemsForRole(AppState appState, User user) {
    if (user.isDoctor) {
      return [
        _SidebarNavItem(
          index: 0,
          icon: Icons.edit_note_rounded,
          label: 'Issue Prescription',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 1,
          icon: Icons.folder_shared_rounded,
          label: 'Health Records Vault',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 2,
          icon: Icons.local_hospital_rounded,
          label: 'Hospitals Directory',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.analytics_rounded,
          label: 'Clinical Analytics',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
      ];
    } else if (user.isPharmacist) {
      return [
        _SidebarNavItem(
          index: 0,
          icon: Icons.local_pharmacy_rounded,
          label: 'Dispense Engine',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 1,
          icon: Icons.receipt_long_rounded,
          label: 'Live Prescriptions',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 2,
          icon: Icons.insights_rounded,
          label: 'Adherence Risk Core',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.analytics_rounded,
          label: 'Pharmacy Analytics',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.explore_rounded,
          label: 'Formulary Catalog',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 5,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
      ];
    } else if (user.isPatient) {
      return [
        _SidebarNavItem(
          index: 0,
          icon: Icons.favorite_rounded,
          label: 'My Health Hub',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 1,
          icon: Icons.medication_rounded,
          label: 'Medicine Cabinet',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 2,
          icon: Icons.local_hospital_rounded,
          label: 'Hospitals & Doctors',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
      ];
    } else if (user.isInsuranceAgent) {
      return [
        _SidebarNavItem(
          index: 0,
          icon: Icons.verified_user_rounded,
          label: 'Insurance Portal',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 1,
          icon: Icons.explore_rounded,
          label: 'Formulary Catalog',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 2,
          icon: Icons.fact_check_rounded,
          label: 'PA Friction Review',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
      ];
    } else {
      // Admin Role
      return [
        _SidebarNavItem(
          index: 0,
          icon: Icons.dashboard_customize_rounded,
          label: 'Overview Dashboard',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 1,
          icon: Icons.local_hospital_rounded,
          label: 'Hospitals Directory',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 2,
          icon: Icons.folder_shared_rounded,
          label: 'Health Records Vault',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin Data & Users',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.insights_rounded,
          label: 'Executive Analytics',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 5,
          icon: Icons.bar_chart_rounded,
          label: 'System Reports',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 6,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
      ];
    }
  }

  Widget _buildTopBar(
    BuildContext context,
    AppState appState,
    User user,
    bool isDesktop,
  ) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: AppColors.metallicBorder,
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),

          // Command Bar Search Input
          Expanded(
            child: Container(
              height: 42,
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                decoration: InputDecoration(
                  hintText: 'Search patients, medicines, doctors, NDC codes...',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primaryTeal,
                    size: 19,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  filled: true,
                  fillColor: AppColors.bgSlate,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.metallicBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.metallicBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primaryTeal,
                      width: 1.6,
                    ),
                  ),
                ),
                onChanged: (val) => appState.setGlobalSearchQuery(val),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // User Profile Status Pill (Static Role Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.metallicBorder,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _UserAvatarBadge(user: user, radius: 12),
                const SizedBox(width: 8),
                Text(
                  user.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Sign Out Option (Only way to switch accounts)
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () => appState.logout(),
          ),
        ],
      ),
    );
  }
}

/// Hot-Memory Viewport Layer using IndexedStack
class _RoleScreenStack extends StatelessWidget {
  final AppState appState;
  final User user;

  const _RoleScreenStack({
    required this.appState,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    if (user.isDoctor) {
      return IndexedStack(
        index: appState.currentNavIndex.clamp(0, 4),
        children: const [
          DoctorPrescriptionScreen(),
          HealthRecordsScreen(),
          HospitalsScreen(),
          DashboardOverviewScreen(),
          VoiceAgentScreen(),
        ],
      );
    } else if (user.isPharmacist) {
      final isViewingDetails = appState.selectedPrescriptionId != null;
      return IndexedStack(
        index: appState.currentNavIndex.clamp(0, 5),
        children: [
          const PharmacistDispenseScreen(),
          isViewingDetails
              ? PrescriptionDetailsScreen(
                  prescriptionId: appState.selectedPrescriptionId!,
                )
              : const PrescriptionsScreen(),
          const AdherenceScreen(),
          const PharmacistAnalyticsScreen(),
          const FormularyScreen(),
          const VoiceAgentScreen(),
        ],
      );
    } else if (user.isPatient) {
      return IndexedStack(
        index: appState.currentNavIndex.clamp(0, 3),
        children: const [
          PatientInteractiveScreen(),
          MyMedicinesScreen(),
          HospitalsScreen(),
          VoiceAgentScreen(),
        ],
      );
    } else if (user.isInsuranceAgent) {
      return IndexedStack(
        index: appState.currentNavIndex.clamp(0, 3),
        children: const [
          InsurancePortalScreen(),
          FormularyScreen(),
          FrictionScreen(),
          VoiceAgentScreen(),
        ],
      );
    } else {
      // Admin Role
      return IndexedStack(
        index: appState.currentNavIndex.clamp(0, 6),
        children: const [
          DashboardScreen(),
          HospitalsScreen(),
          HealthRecordsScreen(),
          AdminDataUsersScreen(),
          DashboardOverviewScreen(),
          AdminReportsScreen(),
          VoiceAgentScreen(),
        ],
      );
    }
  }
}

/// Interactive Role Switcher in Top Bar
class _RoleSwitcherTopButton extends StatefulWidget {
  final User user;
  final AppState appState;

  const _RoleSwitcherTopButton({
    required this.user,
    required this.appState,
  });

  @override
  State<_RoleSwitcherTopButton> createState() => _RoleSwitcherTopButtonState();
}

class _RoleSwitcherTopButtonState extends State<_RoleSwitcherTopButton> {
  bool _isHovered = false;

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return Icons.medical_services_rounded;
      case UserRole.pharmacist:
        return Icons.local_pharmacy_rounded;
      case UserRole.patient:
        return Icons.favorite_rounded;
      case UserRole.insuranceAgent:
        return Icons.verified_user_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String _getRoleShortTitle(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.patient:
        return 'Patient';
      case UserRole.insuranceAgent:
        return 'Insurance Agent';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String _getRoleDesc(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'Prescribe & EMR Consult';
      case UserRole.pharmacist:
        return 'Dispense Engine & Adherence';
      case UserRole.patient:
        return 'Medication Cabinet & Health';
      case UserRole.insuranceAgent:
        return 'Plan Formularies & Claims';
      case UserRole.admin:
        return 'CMS Pipelines & Governance';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = widget.user.role;

    return PopupMenuButton<UserRole>(
      tooltip: 'Switch Active Role (Click to Change)',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.primaryTeal.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      elevation: 16,
      shadowColor: AppColors.accentNavy.withValues(alpha: 0.25),
      color: Colors.white,
      onSelected: (UserRole selectedRole) {
        widget.appState.switchRole(selectedRole);
      },
      itemBuilder: (BuildContext context) {
        return UserRole.values.map((UserRole role) {
          final isSelected = role == currentRole;
          return PopupMenuItem<UserRole>(
            value: role,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryLight
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTeal.withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : AppColors.bgSlate,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getRoleIcon(role),
                      size: 16,
                      color: isSelected
                          ? Colors.white
                          : AppColors.primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getRoleShortTitle(role),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.primaryTeal
                                : AppColors.textDark,
                          ),
                        ),
                        Text(
                          _getRoleDesc(role),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: AppColors.primaryTeal,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.primaryLight.withValues(alpha: 0.9)
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? AppColors.primaryTeal.withValues(alpha: 0.6)
                  : AppColors.primaryTeal.withValues(alpha: 0.28),
              width: 1.3,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getRoleIcon(currentRole),
                color: AppColors.primaryTeal,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _getRoleShortTitle(currentRole),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryTeal,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static User Profile Card in Sidebar
class _RoleSwitcherSidebarCard extends StatelessWidget {
  final User user;
  final AppState appState;

  const _RoleSwitcherSidebarCard({
    required this.user,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.metallicBorder,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          _UserAvatarBadge(user: user, radius: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  user.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation item featuring hover scaling (1.02), slide-in teal marker pill, and glowing indicator.
class _SidebarNavItem extends StatefulWidget {
  final int index;
  final IconData icon;
  final String label;
  final AppState appState;

  const _SidebarNavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.appState,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.appState.currentNavIndex == widget.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          widget.appState.setNavIndex(widget.index);
        },
        child: AnimatedScale(
          scale: isSelected ? 1.02 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 6),
            padding: EdgeInsets.fromLTRB(
              isSelected ? 14 : (_isHovered ? 15 : 12),
              11,
              12,
              11,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryLight
                  : (_isHovered
                      ? AppColors.primaryLight.withValues(alpha: 0.45)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryTeal.withValues(alpha: 0.28)
                    : (_isHovered
                        ? AppColors.primaryTeal.withValues(alpha: 0.15)
                        : Colors.transparent),
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                // Slide-in vertical surgical teal marker pill on left edge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 3.5 : (_isHovered ? 3.0 : 0.0),
                  height: isSelected ? 18 : (_isHovered ? 12 : 0),
                  margin: EdgeInsets.only(
                    right: (isSelected || _isHovered) ? 10 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                ),

                Icon(
                  widget.icon,
                  color: isSelected
                      ? AppColors.primaryTeal
                      : (_isHovered
                          ? AppColors.primaryTeal
                          : AppColors.textMuted),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected
                          ? AppColors.primaryTeal
                          : (_isHovered
                              ? AppColors.textDark
                              : AppColors.textMuted),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryTeal,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryTeal.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Native Clinical User Avatar Badge with Initial Generator
class _UserAvatarBadge extends StatelessWidget {
  final User user;
  final double radius;

  const _UserAvatarBadge({
    required this.user,
    this.radius = 17,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: AppColors.gradientPill,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.28),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _getInitials(user.name),
        style: GoogleFonts.plusJakartaSans(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}
