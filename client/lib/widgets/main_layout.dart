import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

import '../screens/doctor_overview_screen.dart';
import '../screens/doctor_prescription_screen.dart';
import '../screens/pharmacist_dispense_screen.dart';
import '../screens/prescriptions_screen.dart';
import '../screens/prescription_details_screen.dart';
import '../screens/adherence_screen.dart';
import '../screens/formulary_screen.dart';
import '../screens/patient_interactive_screen.dart';
import '../screens/my_medicines_screen.dart';
import '../screens/hospitals_screen.dart';
import '../screens/authorized_pharmacy_screen.dart';
import '../screens/health_records_screen.dart';
import '../screens/insurance_portal_screen.dart';
import '../screens/friction_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/dashboard_overview_screen.dart';
import '../screens/pharmacist_analytics_screen.dart';
import '../screens/admin_data_users_screen.dart';
import '../screens/admin_reports_screen.dart';
import '../screens/voice_agent_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/pharmacist_insurance_screen.dart';
import '../screens/insurance_pharmacy_connections_screen.dart';
import '../screens/alternate_agent_screen.dart';

class MainLayout extends StatefulWidget {
  final Widget? child;

  const MainLayout({super.key, this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _checkedInsuranceSetup = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInsuranceSetup();
    });
  }

  void _checkInsuranceSetup() {
    if (!mounted) return;
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;
    if (user.role == UserRole.insuranceAgent &&
        (user.insuranceCompany == null || user.insuranceCompany!.isEmpty || user.insurancePlans.isEmpty) &&
        !_checkedInsuranceSetup) {
      _checkedInsuranceSetup = true;
      _showInsuranceAgentSetupDialog(context, appState, user);
    }
  }

  void _showInsuranceAgentSetupDialog(BuildContext context, AppState appState, User user) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _InsuranceAgentSetupDialog(
        appState: appState,
        initialCompany: user.insuranceCompany,
        initialPlans: user.insurancePlans,
      ),
    );
  }

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
      body: Stack(
        children: [
          Row(
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
                      child: KeyedSubtree(
                        key: ValueKey(user.role.name),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ),
                          child: widget.child ?? _RoleScreenStack(appState: appState, user: user),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Interactive Draggable Floating e-Rx Notification Card Overlay (Only shown for Patient and Doctor)
          if (appState.notifications.isNotEmpty &&
              (appState.currentUser.role == UserRole.patient ||
               appState.currentUser.role == UserRole.doctor))
            _DraggableNotificationCard(appState: appState),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState appState, User user) {
    return Container(
      width: 276,
      margin: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppColors.metallicBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentNavy.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Brand Identity Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      height: 36,
                      width: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.gradientPill,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Alternae',
                              style: AppFonts.googleSans(
                                color: AppColors.textDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '.ai',
                              style: AppFonts.googleSans(
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
                          style: AppFonts.googleSans(
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
                        style: AppFonts.googleSans(
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
      );
    }

  List<Widget> _getNavItemsForRole(AppState appState, User user) {
    if (user.isDoctor) {
      return [
        _SidebarNavItem(
          index: 0,
          icon: Icons.dashboard_rounded,
          label: 'Clinical Dashboard',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 1,
          icon: Icons.edit_note_rounded,
          label: 'Issue Prescription',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 2,
          icon: Icons.auto_awesome_rounded,
          label: 'Alternate Agent',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.folder_shared_rounded,
          label: 'Health Records Vault',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.local_hospital_rounded,
          label: 'Hospitals Directory',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 5,
          icon: Icons.analytics_rounded,
          label: 'Clinical Analytics',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 6,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 7,
          icon: Icons.person_rounded,
          label: 'My Profile',
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
          icon: Icons.auto_awesome_rounded,
          label: 'Alternate Agent',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.insights_rounded,
          label: 'Adherence Risk Core',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.analytics_rounded,
          label: 'Pharmacy Analytics',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 5,
          icon: Icons.explore_rounded,
          label: 'Formulary Catalog',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 6,
          icon: Icons.verified_user_rounded,
          label: 'Connected Insurance',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 7,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 8,
          icon: Icons.person_rounded,
          label: 'My Profile',
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
          icon: Icons.storefront_rounded,
          label: 'Authorized Pharmacy',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 3,
          icon: Icons.local_hospital_rounded,
          label: 'Hospitals & Doctors',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 5,
          icon: Icons.person_rounded,
          label: 'My Profile',
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
          icon: Icons.connect_without_contact_rounded,
          label: 'Pharmacy Connected',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 4,
          icon: Icons.graphic_eq_rounded,
          label: 'AI Voice Assistant',
          appState: appState,
        ),
        _SidebarNavItem(
          index: 5,
          icon: Icons.person_rounded,
          label: 'My Profile',
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
        _SidebarNavItem(
          index: 7,
          icon: Icons.person_rounded,
          label: 'My Profile',
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
          const SizedBox(width: 8),

          // Active Workspace Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryTeal.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: AppColors.primaryTeal,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  user.roleLabel,
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Locked Facility / Insurance Carrier Badge
          GestureDetector(
            onTap: user.isInsuranceAgent
                ? () => _showInsuranceAgentSetupDialog(context, appState, user)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isInsuranceAgent ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: user.isInsuranceAgent ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    user.isInsuranceAgent ? Icons.business_rounded : Icons.lock_rounded,
                    color: user.isInsuranceAgent ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isInsuranceAgent
                        ? (user.insuranceCompany != null && user.insuranceCompany!.isNotEmpty
                            ? '${user.insuranceCompany} (${user.insurancePlans.length} Plans)'
                            : 'Set Insurance Company & Plans')
                        : (user.hospitalName ?? 'MetroHealth Medical Center'),
                    style: AppFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: user.isInsuranceAgent ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                    ),
                  ),
                  if (user.isInsuranceAgent) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF1D4ED8)),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Clinical Notifications Bell Action Button
          _NotificationIconButton(user: user),
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
      switch (appState.currentNavIndex.clamp(0, 7)) {
        case 0:
          return const DoctorOverviewDashboardScreen();
        case 1:
          return const DoctorPrescriptionScreen();
        case 2:
          return const AlternateAgentScreen();
        case 3:
          return const HealthRecordsScreen();
        case 4:
          return const HospitalsScreen();
        case 5:
          return const DashboardOverviewScreen();
        case 6:
          return const VoiceAgentScreen();
        case 7:
          return const UserProfileScreen();
        default:
          return const DoctorOverviewDashboardScreen();
      }
    } else if (user.isPharmacist) {
      final isViewingDetails = appState.selectedPrescriptionId != null;
      switch (appState.currentNavIndex.clamp(0, 8)) {
        case 0:
          return const PharmacistDispenseScreen();
        case 1:
          return isViewingDetails
              ? PrescriptionDetailsScreen(
                  prescriptionId: appState.selectedPrescriptionId!,
                )
              : const PrescriptionsScreen();
        case 2:
          return const AlternateAgentScreen();
        case 3:
          return const AdherenceScreen();
        case 4:
          return const PharmacistAnalyticsScreen();
        case 5:
          return const FormularyScreen();
        case 6:
          return const PharmacistInsuranceScreen();
        case 7:
          return const VoiceAgentScreen();
        case 8:
          return const UserProfileScreen();
        default:
          return const PharmacistDispenseScreen();
      }
    } else if (user.isPatient) {
      switch (appState.currentNavIndex.clamp(0, 5)) {
        case 0:
          return const PatientInteractiveScreen();
        case 1:
          return const MyMedicinesScreen();
        case 2:
          return const AuthorizedPharmacyScreen();
        case 3:
          return const HospitalsScreen();
        case 4:
          return const VoiceAgentScreen();
        case 5:
          return const UserProfileScreen();
        default:
          return const PatientInteractiveScreen();
      }
    } else if (user.isInsuranceAgent) {
      switch (appState.currentNavIndex.clamp(0, 5)) {
        case 0:
          return const InsurancePortalScreen();
        case 1:
          return const FormularyScreen();
        case 2:
          return const FrictionScreen();
        case 3:
          return const InsurancePharmacyConnectionsScreen();
        case 4:
          return const VoiceAgentScreen();
        case 5:
          return const UserProfileScreen();
        default:
          return const InsurancePortalScreen();
      }
    } else {
      // Admin Role
      switch (appState.currentNavIndex.clamp(0, 7)) {
        case 0:
          return const DashboardScreen();
        case 1:
          return const HospitalsScreen();
        case 2:
          return const HealthRecordsScreen();
        case 3:
          return const AdminDataUsersScreen();
        case 4:
          return const DashboardOverviewScreen();
        case 5:
          return const AdminReportsScreen();
        case 6:
          return const VoiceAgentScreen();
        case 7:
          return const UserProfileScreen();
        default:
          return const DashboardScreen();
      }
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
                          style: AppFonts.googleSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? AppColors.primaryTeal
                                : AppColors.textDark,
                          ),
                        ),
                        Text(
                          _getRoleDesc(role),
                          style: AppFonts.googleSans(
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
                style: AppFonts.googleSans(
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
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  user.roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.googleSans(
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

                _AnimatedSidebarIcon(
                  icon: widget.icon,
                  isSelected: isSelected,
                  isHovered: _isHovered,
                  appState: widget.appState,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppFonts.googleSans(
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

/// Unique Animated Icon Builder for Sidebar Navigation
class _AnimatedSidebarIcon extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final bool isHovered;
  final AppState appState;

  const _AnimatedSidebarIcon({
    required this.icon,
    required this.isSelected,
    required this.isHovered,
    required this.appState,
  });

  @override
  State<_AnimatedSidebarIcon> createState() => _AnimatedSidebarIconState();
}

class _AnimatedSidebarIconState extends State<_AnimatedSidebarIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (!widget.isSelected) {
      _controller.repeat(reverse: true);
    }
  }



  Color _getIconColor(IconData icon) {
    if (icon == Icons.dashboard_rounded || icon == Icons.dashboard_customize_rounded) {
      return const Color(0xFF2563EB);
    }
    if (icon == Icons.edit_note_rounded) return const Color(0xFF10B981);
    if (icon == Icons.folder_shared_rounded) return const Color(0xFFF59E0B);
    if (icon == Icons.favorite_rounded) return const Color(0xFFEF4444);
    if (icon == Icons.medication_rounded) return const Color(0xFF00B4D8);
    if (icon == Icons.storefront_rounded || icon == Icons.local_pharmacy_rounded) {
      return const Color(0xFF10B981);
    }
    if (icon == Icons.local_hospital_rounded) return const Color(0xFF6366F1);
    if (icon == Icons.graphic_eq_rounded) return const Color(0xFF8B5CF6);
    if (icon == Icons.explore_rounded) return const Color(0xFFF59E0B);
    if (icon == Icons.analytics_rounded || icon == Icons.bar_chart_rounded) {
      return const Color(0xFFEC4899);
    }
    if (icon == Icons.verified_user_rounded || icon == Icons.fact_check_rounded) {
      return const Color(0xFF3B82F6);
    }
    if (icon == Icons.person_rounded) return const Color(0xFF8B5CF6);
    return const Color(0xFF1244A2);
  }

  @override
  void didUpdateWidget(covariant _AnimatedSidebarIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // When SELECTED: Stationary, solid, clean icon in primary Sapphire Navy (#1244A2)
    if (widget.isSelected) {
      const activeColor = Color(0xFF1244A2);
      return Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activeColor.withValues(alpha: 0.3)),
        ),
        child: Icon(
          widget.icon,
          color: activeColor,
          size: 19,
        ),
      );
    }

    // When UNSELECTED: Vibrant unique colored badge + distinct icon motion animation!
    final color = _getIconColor(widget.icon);
    final badgeBg = widget.isHovered
        ? color.withValues(alpha: 0.22)
        : color.withValues(alpha: 0.12);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;

        return Container(
          width: 33,
          height: 33,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: color.withValues(alpha: widget.isHovered ? 0.4 : 0.2),
            ),
            boxShadow: widget.isHovered
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: _buildUniqueIconAnimation(widget.icon, color, progress),
        );
      },
    );
  }

  Widget _buildUniqueIconAnimation(IconData icon, Color color, double progress) {
    // 1. Clinical Dashboard Grid Pulse for Dashboard
    if (icon == Icons.dashboard_rounded || icon == Icons.dashboard_customize_rounded) {
      return CustomPaint(
        painter: _DashboardPainter(color: color, progress: progress),
      );
    }

    // 2. Issue Prescription Pen Drawing Glider
    if (icon == Icons.edit_note_rounded) {
      final dx = (progress - 0.5) * 3.5;
      final dy = (progress - 0.5) * 1.5;
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Icon(Icons.edit_note_rounded, color: color, size: 19),
      );
    }

    // 3. Health Records Vault Folder Open & Slide
    if (icon == Icons.folder_shared_rounded) {
      final scale = 1.0 + (progress * 0.18);
      return Transform.scale(
        scale: scale,
        child: Icon(Icons.folder_shared_rounded, color: color, size: 19),
      );
    }

    // 4. Equalizer Audio Spectrum for AI Voice Assistant
    if (icon == Icons.graphic_eq_rounded) {
      return CustomPaint(
        painter: _EqualizerPainter(color: color, progress: progress),
      );
    }

    // 5. Heart Beat ECG for My Health Hub
    if (icon == Icons.favorite_rounded) {
      final scale = 1.0 + (progress * 0.22);
      return Transform.scale(
        scale: scale,
        child: Icon(Icons.favorite_rounded, color: color, size: 19),
      );
    }

    // 6. Medicine Capsule Rotation Wobble for Medicine Cabinet
    if (icon == Icons.medication_rounded) {
      final angle = (progress - 0.5) * 0.5;
      return Transform.rotate(
        angle: angle,
        child: Icon(Icons.medication_rounded, color: color, size: 19),
      );
    }

    // 7. Pharmacy Storefront Awning Pulse for Authorized Pharmacy
    if (icon == Icons.storefront_rounded || icon == Icons.local_pharmacy_rounded) {
      final scale = 0.9 + (progress * 0.22);
      return Transform.scale(
        scale: scale,
        child: Icon(icon, color: color, size: 19),
      );
    }

    // 8. Hospital Cross Pulse Halo for Hospitals & Doctors
    if (icon == Icons.local_hospital_rounded) {
      return CustomPaint(
        painter: _HospitalCrossPainter(color: color, progress: progress),
      );
    }

    // 9. Compass Spin for Formulary Catalog
    if (icon == Icons.explore_rounded) {
      final angle = progress * 2 * 3.14159;
      return Transform.rotate(
        angle: angle,
        child: Icon(Icons.explore_rounded, color: color, size: 19),
      );
    }

    // 10. Dynamic Bar Chart Growing Columns for Executive Analytics
    if (icon == Icons.analytics_rounded || icon == Icons.bar_chart_rounded) {
      return CustomPaint(
        painter: _BarChartPainter(color: color, progress: progress),
      );
    }

    // 11. User Profile Avatar Scale & Vertical Bounce for My Profile
    if (icon == Icons.person_rounded) {
      final scale = 1.0 + (progress * 0.16);
      return Transform.translate(
        offset: Offset(0, -progress * 2.2),
        child: Transform.scale(
          scale: scale,
          child: Icon(Icons.person_rounded, color: color, size: 19),
        ),
      );
    }

    // Default icon fallback
    return Icon(icon, color: color, size: 19);
  }
}

/// Dynamic Audio Equalizer Bars Painter
class _EqualizerPainter extends CustomPainter {
  final Color color;
  final double progress;

  _EqualizerPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    final w = size.width;
    final h = size.height;

    final h1 = h * (0.3 + 0.6 * progress);
    final h2 = h * (0.8 - 0.5 * progress);
    final h3 = h * (0.4 + 0.5 * progress);
    final h4 = h * (0.7 - 0.4 * progress);

    canvas.drawLine(Offset(w * 0.15, h), Offset(w * 0.15, h - h1), paint);
    canvas.drawLine(Offset(w * 0.38, h), Offset(w * 0.38, h - h2), paint);
    canvas.drawLine(Offset(w * 0.62, h), Offset(w * 0.62, h - h3), paint);
    canvas.drawLine(Offset(w * 0.85, h), Offset(w * 0.85, h - h4), paint);
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Dynamic Bar Chart Growing Columns Painter
class _BarChartPainter extends CustomPainter {
  final Color color;
  final double progress;

  _BarChartPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;

    final barW = w * 0.22;
    final b1H = h * (0.3 + 0.5 * progress);
    final b2H = h * (0.8 - 0.4 * progress);
    final b3H = h * (0.5 + 0.45 * progress);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h - b1H, barW, b1H), const Radius.circular(2)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barW + 2, h - b2H, barW, b2H), const Radius.circular(2)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH((barW + 2) * 2, h - b3H, barW, b3H), const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
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
        style: AppFonts.googleSans(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}



/// Interactive Clinical Notification Button with Badge Counter & Modal List
class _NotificationIconButton extends StatelessWidget {
  final User user;

  const _NotificationIconButton({required this.user});

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer<AppState>(
          builder: (context, state, child) {
            final list = state.notifications;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF1244A2), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Clinical Alerts & Notifications',
                        style: AppFonts.googleSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      if (list.isNotEmpty)
                        TextButton(
                          onPressed: () => state.markAllNotificationsRead(),
                          child: Text('Mark All Read', style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF1244A2))),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No active unread notifications',
                          style: AppFonts.googleSans(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: list.map((n) {
                        return _buildNotificationItem(
                          context: context,
                          appState: state,
                          notification: n,
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required BuildContext context,
    required AppState appState,
    required ClinicalNotification notification,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: notification.color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(notification.icon, color: notification.color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notification.title, style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    Text(notification.time, style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(notification.subtitle, style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Remove Notification',
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
            onPressed: () => appState.dismissNotification(notification.id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final count = appState.unreadNotificationsCount;

    return Stack(
      children: [
        IconButton(
          tooltip: 'Clinical Notifications',
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.metallicBorder),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF1244A2),
              size: 20,
            ),
          ),
          onPressed: () => _showNotificationsSheet(context),
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: AppFonts.googleSans(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Movable & Interactive Floating e-Rx Notification Card Widget
class _DraggableNotificationCard extends StatefulWidget {
  final AppState appState;

  const _DraggableNotificationCard({required this.appState});

  @override
  State<_DraggableNotificationCard> createState() => _DraggableNotificationCardState();
}

class _DraggableNotificationCardState extends State<_DraggableNotificationCard> {
  Offset? _offset;

  @override
  Widget build(BuildContext context) {
    final notifs = widget.appState.notifications;
    if (notifs.isEmpty) return const SizedBox.shrink();

    final notif = notifs.first;
    final screenSize = MediaQuery.of(context).size;
    const cardWidth = 360.0;
    const cardHeight = 220.0;

    final initialLeft = (screenSize.width - cardWidth) / 2;
    final initialTop = (screenSize.height - cardHeight) / 2;

    final currentOffset = _offset ?? Offset(initialLeft, initialTop);

    return Positioned(
      left: currentOffset.dx,
      top: currentOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset = Offset(
              (currentOffset.dx + details.delta.dx).clamp(10.0, screenSize.width - cardWidth - 10.0),
              (currentOffset.dy + details.delta.dy).clamp(10.0, screenSize.height - cardHeight - 10.0),
            );
          });
        },
        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.6), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.drag_indicator_rounded, color: Color(0xFF38BDF8), size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '⚡ MOVABLE CLINICAL ALERT',
                      style: AppFonts.googleSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF38BDF8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => widget.appState.dismissNotification(notif.id),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 15, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: notif.color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(notif.icon, color: notif.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title,
                            style: AppFonts.googleSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notif.subtitle,
                            style: AppFonts.googleSans(fontSize: 11.5, color: const Color(0xFF94A3B8), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.appState.dismissNotification(notif.id),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Dismiss / Remove',
                          style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    if (widget.appState.currentUser.isPatient) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.appState.dismissNotification(notif.id);
                            widget.appState.setNavIndex(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            'View Cabinet',
                            style: AppFonts.googleSans(fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dynamic 2x2 Dashboard Grid Pulsing Painter
class _DashboardPainter extends CustomPainter {
  final Color color;
  final double progress;

  _DashboardPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gap = 2.0;
    final blockW = (w - gap) / 2;
    final blockH = (h - gap) / 2;

    final p1 = 0.5 + 0.5 * (progress);
    final p2 = 0.5 + 0.5 * (1.0 - progress);

    final paint1 = Paint()..color = color.withValues(alpha: p1);
    final paint2 = Paint()..color = color.withValues(alpha: p2);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, blockW, blockH), const Radius.circular(2.5)), paint1);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(blockW + gap, 0, blockW, blockH), const Radius.circular(2.5)), paint2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, blockH + gap, blockW, blockH), const Radius.circular(2.5)), paint2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(blockW + gap, blockH + gap, blockW, blockH), const Radius.circular(2.5)), paint1);
  }

  @override
  bool shouldRepaint(covariant _DashboardPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Dynamic Hospital Cross Pulse Ring Painter
class _HospitalCrossPainter extends CustomPainter {
  final Color color;
  final double progress;

  _HospitalCrossPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * (0.6 + 0.4 * progress);
    final ringPaint = Paint()
      ..color = color.withValues(alpha: (1.0 - progress) * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawCircle(center, radius, ringPaint);

    final crossPaint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.2;

    final arm = size.width * 0.35;
    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), crossPaint);
  }

  @override
  bool shouldRepaint(covariant _HospitalCrossPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Real-Time Patient Search Bar by ID & Name with Dropdown Overlay
class _PatientSearchBar extends StatefulWidget {
  final AppState appState;

  const _PatientSearchBar({required this.appState});

  @override
  State<_PatientSearchBar> createState() => _PatientSearchBarState();
}

class _PatientSearchBarState extends State<_PatientSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _showDropdown = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final allPatients = widget.appState.patientRecords;

    final results = query.isEmpty
        ? <PatientRecord>[]
        : allPatients.where((p) {
            final idMatch = p.id.toLowerCase().contains(query);
            final nameMatch = p.name.toLowerCase().contains(query);
            final problemMatch = p.currentProblem.toLowerCase().contains(query);
            final docMatch = (p.assignedDoctorName ?? '').toLowerCase().contains(query);
            return idMatch || nameMatch || problemMatch || docMatch;
          }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: BoxDecoration(
            color: AppColors.bgSlate,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _showDropdown && results.isNotEmpty
                  ? const Color(0xFF1244A2)
                  : AppColors.metallicBorder,
              width: _showDropdown && results.isNotEmpty ? 1.5 : 1.0,
            ),
          ),
          child: TextField(
            controller: _controller,
            onChanged: (val) {
              setState(() {
                _showDropdown = val.trim().isNotEmpty;
              });
              widget.appState.setGlobalSearchQuery(val);
            },
            onTap: () {
              if (_controller.text.trim().isNotEmpty) {
                setState(() => _showDropdown = true);
              }
            },
            style: AppFonts.googleSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Search Patient by ID (e.g. PAT-301) or Name...',
              hintStyle: AppFonts.googleSans(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF1244A2),
                size: 18,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _showDropdown = false);
                        widget.appState.setGlobalSearchQuery('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),

        // Floating Search Results Card Dropdown Overlay
        if (_showDropdown && results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.metallicBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: results.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final patient = results[index];
                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_search_rounded, color: Color(0xFF1244A2), size: 18),
                  ),
                  title: Row(
                    children: [
                      Text(
                        patient.name,
                        style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF1244A2).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'ID: ${patient.id}',
                          style: AppFonts.googleSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF1244A2)),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${patient.currentProblem} • ${patient.assignedDoctorName ?? "MetroHealth Cardiology"}',
                    style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  onTap: () {
                    setState(() => _showDropdown = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Selected Patient: ${patient.name} (ID: ${patient.id})'),
                        backgroundColor: const Color(0xFF1244A2),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Insurance Organization & Benefit Plans Setup Dialog for Insurance Agents
class _InsuranceAgentSetupDialog extends StatefulWidget {
  final AppState appState;
  final String? initialCompany;
  final List<String> initialPlans;

  const _InsuranceAgentSetupDialog({
    required this.appState,
    this.initialCompany,
    this.initialPlans = const [],
  });

  @override
  State<_InsuranceAgentSetupDialog> createState() => _InsuranceAgentSetupDialogState();
}

class _InsuranceAgentSetupDialogState extends State<_InsuranceAgentSetupDialog> {
  late String _selectedCompany;
  late final Set<String> _selectedPlans;
  late final Set<String> _selectedMedicines;
  late final Set<String> _selectedHospitals;

  final Map<String, List<String>> _companyPlansMap = {
    'Blue Cross Blue Shield': [
      'Blue Cross PPO Premier',
      'Blue Cross Advantage Plus',
      'Blue Cross Rx Comprehensive',
      'Blue Care HMO Gold',
    ],
    'UnitedHealthcare (UHC)': [
      'UHC Choice Plus Comprehensive',
      'UHC Medicare Part D Standard',
      'UHC Dual Complete (HMO-POS)',
      'Optum Rx Preferred',
    ],
    'Medicare Part D (CMS)': [
      'SilverScript Choice (PDP)',
      'Medicare Advantage Part D Gold',
      'WellCare Value Script (PDP)',
      'Humana Premier Rx (PDP)',
    ],
    'Aetna Health': [
      'Aetna Medicare Part D Value',
      'Aetna Open Access PPO',
      'Aetna Premier Rx Tier 1-5',
    ],
    'Cigna Healthcare': [
      'Cigna Secure Rx (PDP)',
      'Cigna Total Care Plus',
      'Cigna Essential Rx Plan',
    ],
    'Humana Rx': [
      'Humana Walmart Value Rx',
      'Humana Gold Plus (HMO)',
      'Humana Premier Part D',
    ],
    'Kaiser Permanente': [
      'Kaiser Senior Advantage',
      'Kaiser Permanente Deductible Plan',
      'Kaiser Specialty Rx',
    ],
  };

  final List<String> _availableMedicinesList = [
    'Atorvastatin (Lipitor) 20mg',
    'Metformin HCl 500mg',
    'Lisinopril 10mg',
    'Ozempic (Semaglutide) 2mg/3mL',
    'Eliquis (Apixaban) 5mg',
    'Levothyroxine 50mcg',
    'Amlodipine Besylate 5mg',
    'Omeprazole 20mg',
    'Losartan Potassium 50mg',
    'Jardiance (Empagliflozin) 10mg',
    'Gabapentin 300mg',
    'Hydrochlorothiazide 25mg',
  ];

  final List<String> _availableHospitalsList = [
    'MetroHealth Medical Center (Cleveland, OH)',
    'St. Jude Memorial Hospital (Fullerton, CA)',
    'Johns Hopkins Hospital (Baltimore, MD)',
    'Cleveland Clinic Main Campus (Cleveland, OH)',
    'Duke University Hospital (Durham, NC)',
    'Mayo Clinic Hospital (Rochester, MN)',
    'Massachusetts General Hospital (Boston, MA)',
    'Northwestern Memorial Hospital (Chicago, IL)',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCompany != null &&
        widget.initialCompany!.isNotEmpty &&
        _companyPlansMap.containsKey(widget.initialCompany)) {
      _selectedCompany = widget.initialCompany!;
    } else {
      _selectedCompany = 'Blue Cross Blue Shield';
    }

    if (widget.initialPlans.isNotEmpty) {
      _selectedPlans = Set<String>.from(widget.initialPlans);
    } else {
      _selectedPlans = Set<String>.from(
          _companyPlansMap[_selectedCompany]?.take(2) ?? ['Comprehensive Rx Plan']);
    }

    _selectedMedicines = Set<String>.from(
      widget.appState.currentUser.insuranceMedicines.isNotEmpty
          ? widget.appState.currentUser.insuranceMedicines
          : ['Atorvastatin (Lipitor) 20mg', 'Metformin HCl 500mg', 'Eliquis (Apixaban) 5mg'],
    );

    _selectedHospitals = Set<String>.from(
      widget.appState.currentUser.insuranceHospitals.isNotEmpty
          ? widget.appState.currentUser.insuranceHospitals
          : ['MetroHealth Medical Center (Cleveland, OH)', 'Cleveland Clinic Main Campus (Cleveland, OH)'],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlans = _companyPlansMap[_selectedCompany] ?? _companyPlansMap['Blue Cross Blue Shield']!;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 620,
        padding: const EdgeInsets.all(26),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFF1D4ED8), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insurance Agency Portfolio Setup',
                          style: AppFonts.googleSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select your payer company, covered benefit plans, formulary medicines, and in-network hospitals.',
                          style: AppFonts.googleSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 26),

              // 1. Company Dropdown
              Text(
                '1. SELECT INSURANCE PAYER COMPANY',
                style: AppFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCompany,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1D4ED8)),
                    style: AppFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    items: _companyPlansMap.keys.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCompany = val;
                          _selectedPlans.clear();
                          final defaults = _companyPlansMap[val];
                          if (defaults != null && defaults.isNotEmpty) {
                            _selectedPlans.addAll(defaults.take(2));
                          }
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 2. Plans Dropdown & Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '2. BENEFIT PLANS MANAGED (${_selectedPlans.length} Selected)',
                    style: AppFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select plan to toggle on/off...', style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8))),
                    icon: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF1D4ED8), size: 18),
                    items: currentPlans.map((p) {
                      final isSelected = _selectedPlans.contains(p);
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 16,
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          if (_selectedPlans.contains(val)) {
                            _selectedPlans.remove(val);
                          } else {
                            _selectedPlans.add(val);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_selectedPlans.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedPlans.map((plan) {
                    return Chip(
                      label: Text(plan),
                      backgroundColor: const Color(0xFFDBEAFE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      labelStyle: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E40AF),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF1E40AF)),
                      onDeleted: () => setState(() => _selectedPlans.remove(plan)),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // 3. Medicines Dropdown & Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '3. COVERED MEDICINES (${_selectedMedicines.length} Selected)',
                    style: AppFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select medicine to add/remove...', style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8))),
                    icon: const Icon(Icons.medication_rounded, color: Color(0xFF1D4ED8), size: 18),
                    items: _availableMedicinesList.map((med) {
                      final isSelected = _selectedMedicines.contains(med);
                      return DropdownMenuItem<String>(
                        value: med,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(med, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 16,
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          if (_selectedMedicines.contains(val)) {
                            _selectedMedicines.remove(val);
                          } else {
                            _selectedMedicines.add(val);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_selectedMedicines.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedMedicines.map((med) {
                    return Chip(
                      label: Text(med),
                      backgroundColor: const Color(0xFFE0F2FE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                      labelStyle: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0369A1),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0369A1)),
                      onDeleted: () => setState(() => _selectedMedicines.remove(med)),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // 4. Hospitals Dropdown & Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '4. IN-NETWORK HOSPITALS (${_selectedHospitals.length} Selected)',
                    style: AppFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('Select hospital to add/remove...', style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8))),
                    icon: const Icon(Icons.local_hospital_rounded, color: Color(0xFF1D4ED8), size: 18),
                    items: _availableHospitalsList.map((hosp) {
                      final isSelected = _selectedHospitals.contains(hosp);
                      return DropdownMenuItem<String>(
                        value: hosp,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(hosp, style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                            Icon(
                              isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 16,
                              color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          if (_selectedHospitals.contains(val)) {
                            _selectedHospitals.remove(val);
                          } else {
                            _selectedHospitals.add(val);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_selectedHospitals.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedHospitals.map((hosp) {
                    return Chip(
                      label: Text(hosp),
                      backgroundColor: const Color(0xFFECFDF5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF34D399)),
                      ),
                      labelStyle: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF047857),
                      ),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF047857)),
                      onDeleted: () => setState(() => _selectedHospitals.remove(hosp)),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppFonts.googleSans(fontWeight: FontWeight.w700, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      String finalCompany = _selectedCompany;
                      List<String> finalPlans = _selectedPlans.toList();
                      if (finalPlans.isEmpty) {
                        finalPlans = ['Comprehensive Rx Plan'];
                      }

                      widget.appState.updateInsuranceAgentDetails(
                        company: finalCompany,
                        plans: finalPlans,
                        medicines: _selectedMedicines.toList(),
                        hospitals: _selectedHospitals.toList(),
                      );

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Insurance Portfolio Configured: $finalCompany (${finalPlans.length} Plans, ${_selectedMedicines.length} Drugs, ${_selectedHospitals.length} Hospitals)'),
                          backgroundColor: const Color(0xFF1D4ED8),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save Agency Portfolio →',
                      style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
