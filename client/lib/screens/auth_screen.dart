import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// Extension for user-friendly presentation of the 5 system roles.
extension UserRoleAuthMeta on UserRole {
  String get label {
    switch (this) {
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

  String get subtitle {
    switch (this) {
      case UserRole.doctor:
        return 'Prescribe & Consult';
      case UserRole.pharmacist:
        return 'Dispense & Adherence';
      case UserRole.patient:
        return 'Meds & Health Hub';
      case UserRole.insuranceAgent:
        return 'Policies & Claims';
      case UserRole.admin:
        return 'System Governance';
    }
  }

  IconData get icon {
    switch (this) {
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

  String get defaultEmail {
    switch (this) {
      case UserRole.doctor:
        return 'doctor@alternea.org';
      case UserRole.pharmacist:
        return 'pharmacist@alternea.org';
      case UserRole.patient:
        return 'patient@alternea.org';
      case UserRole.insuranceAgent:
        return 'insurance@alternea.org';
      case UserRole.admin:
        return 'admin@alternea.org';
    }
  }
}

class AuthScreen extends StatefulWidget {
  final ValueChanged<UserRole>? onRoleChanged;

  const AuthScreen({super.key, this.onRoleChanged});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  int _activeTabIndex = 0; // 0: Sign In, 1: Create Account
  UserRole _selectedRole = UserRole.doctor;

  final _signInEmailController =
      TextEditingController(text: 'doctor@alternea.org');
  final _signInPasswordController = TextEditingController(text: 'password123');
  bool _rememberMe = true;
  bool _obscureSignInPassword = true;

  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _agreeTerms = true;

  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleRoleTap(UserRole role) {
    setState(() {
      _selectedRole = role;
      _signInEmailController.text = role.defaultEmail;
    });
    widget.onRoleChanged?.call(role);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.gradientBrand,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Container(
                    width: isDesktop ? 1080 : 480,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.teal.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                          blurRadius: 56,
                          spreadRadius: -4,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: isDesktop
                        ? SizedBox(
                            height: 740,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Panel — Authentication Bento Core
                                Expanded(
                                  flex: 6,
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(36, 32, 36, 28),
                                    child: _buildFormPanel(context, appState),
                                  ),
                                ),
                                // Right Panel — Artistic Medical Canvas
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(32),
                                      bottomRight: Radius.circular(32),
                                    ),
                                    child: _buildVisualCanvas(isDesktop: true),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(32),
                                  topRight: Radius.circular(32),
                                ),
                                child: SizedBox(
                                  height: 230,
                                  child: _buildVisualCanvas(isDesktop: false),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                                child: _buildFormPanel(context, appState),
                              ),
                            ],
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCanvas({required bool isDesktop}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.gradientCanvas,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background ambient grid texture
          CustomPaint(
            painter: _BackgroundGridPainter(),
          ),
          // Animated floating crystalline medical cross
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) {
              final val = _floatAnim.value;
              final dy = math.sin(val * math.pi) * 7.0;
              return Transform.translate(
                offset: Offset(0, dy),
                child: CustomPaint(
                  painter: _MedicalCrystalPainter(),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          // Floating trust badges (Desktop)
          if (isDesktop) ...[
            Positioned(
              top: 36,
              left: 32,
              child: _buildTrustBadge(
                icon: Icons.security_rounded,
                title: 'HIPAA Certified',
                subtitle: 'SOC-2 Type II Secure',
              ),
            ),
            Positioned(
              bottom: 40,
              right: 32,
              child: _buildTrustBadge(
                icon: Icons.sync_lock_rounded,
                title: 'Real-Time FHIR v4.0',
                subtitle: 'Zero-Trust Data Vault',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildFormPanel(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand Header Module
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: AppColors.gradientPill),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Alternea',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Health',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryTeal,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Clinical Ecosystem',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.successGreen,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'FHIR v4.0 Active',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.successText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Role Selector Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SELECT ACCESS ROLE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '5 Clinical Roles',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 5-Role Horizontal Sliding Selector
        _HorizontalRoleSelector(
          selected: _selectedRole,
          onSelect: _handleRoleTap,
        ),

        const SizedBox(height: 20),

        // Segmented Pill Tab Switcher (Sign In vs Register)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.bgSlate,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderLight, width: 1.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: _segmentTab(
                  label: 'Sign In',
                  index: 0,
                  onTap: () => setState(() => _activeTabIndex = 0),
                ),
              ),
              Expanded(
                child: _segmentTab(
                  label: 'Create Account',
                  index: 1,
                  onTap: () => setState(() => _activeTabIndex = 1),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.fastOutSlowIn,
          switchOutCurve: Curves.fastOutSlowIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: child,
            ),
          ),
          child: _activeTabIndex == 0
              ? KeyedSubtree(
                  key: const ValueKey('signin'),
                  child: _buildSignInTab(context, appState),
                )
              : KeyedSubtree(
                  key: const ValueKey('register'),
                  child: _buildRegisterTab(context, appState),
                ),
        ),
      ],
    );
  }

  Widget _segmentTab({
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: AppColors.gradientPill,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.24),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome Back',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedRole.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Sign in with your ${_selectedRole.label.toLowerCase()} credentials to continue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),

        _fieldLabel('Email Address'),
        const SizedBox(height: 6),
        _ModernFormField(
          controller: _signInEmailController,
          hint: 'e.g. ${_selectedRole.defaultEmail}',
          icon: Icons.alternate_email_rounded,
        ),

        const SizedBox(height: 10),

        _fieldLabel('Password'),
        const SizedBox(height: 6),
        _ModernFormField(
          controller: _signInPasswordController,
          hint: '••••••••••••',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureSignInPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureSignInPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
            onPressed: () {
              setState(() {
                _obscureSignInPassword = !_obscureSignInPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 8),

        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModernCheckbox(
                  value: _rememberMe,
                  onChanged: (val) => setState(() => _rememberMe = val),
                ),
                const SizedBox(width: 7),
                Text(
                  'Remember me for 30 days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: AppColors.primaryTeal,
              ),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _PillCtaButton(
          label: 'Sign In as ${_selectedRole.label}',
          icon: Icons.arrow_forward_rounded,
          onPressed: () {
            final email = _signInEmailController.text.trim();
            final user = User(
              id: 'U_${DateTime.now().millisecondsSinceEpoch}',
              name: email.isEmpty ? _selectedRole.label : email.split('@')[0],
              email: email.isEmpty ? _selectedRole.defaultEmail : email,
              role: _selectedRole,
              assignedPatientIds: const ['PT-301', 'PT-302'],
              avatarUrl: '',
              title: _selectedRole.label,
              doctorId: _selectedRole == UserRole.doctor ? 'DOC-201' : null,
              patientId: _selectedRole == UserRole.patient ? 'PT-301' : null,
              hospitalId: 'HOSP-101',
              hospitalName: 'MetroHealth Medical Center',
            );
            appState.login(user);
          },
        ),

        const SizedBox(height: 12),
        _buildSecurityGuarantee(),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Create Account',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _selectedRole.label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Registering as an authorized ${_selectedRole.label.toLowerCase()}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 14),

        _fieldLabel('Full Legal Name'),
        const SizedBox(height: 6),
        _ModernFormField(
          controller: _regNameController,
          hint: 'e.g. Dr. Ananya Sharma, MD',
          icon: Icons.badge_outlined,
        ),

        const SizedBox(height: 10),

        _fieldLabel('Professional Email'),
        const SizedBox(height: 6),
        _ModernFormField(
          controller: _regEmailController,
          hint: 'asharma@alternea.org',
          icon: Icons.alternate_email_rounded,
        ),

        const SizedBox(height: 10),

        _fieldLabel('Password'),
        const SizedBox(height: 6),
        _ModernFormField(
          controller: _regPasswordController,
          hint: 'At least 8 characters',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureRegPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRegPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: AppColors.textMuted,
            ),
            onPressed: () {
              setState(() {
                _obscureRegPassword = !_obscureRegPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ModernCheckbox(
              value: _agreeTerms,
              onChanged: (val) => setState(() => _agreeTerms = val),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'I acknowledge Alternea Clinical Data Agreement & HIPAA Compliance Policy',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _PillCtaButton(
          label: 'Register ${_selectedRole.label} Account',
          icon: Icons.how_to_reg_rounded,
          onPressed: () {
            final name = _regNameController.text.trim().isEmpty
                ? 'Dr. Ananya Sharma'
                : _regNameController.text.trim();
            final email = _regEmailController.text.trim().isEmpty
                ? _selectedRole.defaultEmail
                : _regEmailController.text.trim();

            appState.register(
              name: name,
              email: email,
              role: _selectedRole,
            );
          },
        ),

        const SizedBox(height: 10),
        _buildSecurityGuarantee(),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      );

  Widget _buildSecurityGuarantee() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined, size: 13, color: AppColors.primaryTeal),
            const SizedBox(width: 5),
            Text(
              'Protected by 256-Bit TLS Encryption • HIPAA Compliant',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalRoleSelector extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onSelect;

  const _HorizontalRoleSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: UserRole.values.map((role) {
            final isSelected = role == selected;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _RoleSelectCard(
                role: role,
                isSelected: isSelected,
                onTap: () => onSelect(role),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RoleSelectCard extends StatefulWidget {
  final UserRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleSelectCard> createState() => _RoleSelectCardState();
}

class _RoleSelectCardState extends State<_RoleSelectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: isSelected ? 1.04 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            width: 104,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: AppColors.gradientPill,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected
                  ? null
                  : (_isHovered
                      ? AppColors.primaryLight.withValues(alpha: 0.65)
                      : AppColors.bgSlate),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (_isHovered
                        ? AppColors.primaryTeal.withValues(alpha: 0.5)
                        : AppColors.borderLight),
                width: 1.4,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : (_isHovered
                      ? [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : []),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.22)
                        : (_isHovered
                            ? AppColors.primaryTeal.withValues(alpha: 0.12)
                            : Colors.white),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.role.icon,
                    size: 18,
                    color: isSelected
                        ? Colors.white
                        : (_isHovered
                            ? AppColors.primaryTeal
                            : AppColors.accentNavy),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.role.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.role.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textMuted,
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

class _ModernFormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const _ModernFormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: AppColors.textMuted.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(icon, color: AppColors.primaryTeal, size: 19),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _ModernCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernCheckbox({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: value ? AppColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: value ? AppColors.primaryTeal : AppColors.borderLight,
            width: 1.5,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
            : null,
      ),
    );
  }
}

class _PillCtaButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PillCtaButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_PillCtaButton> createState() => _PillCtaButtonState();
}

class _PillCtaButtonState extends State<_PillCtaButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.fastOutSlowIn,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientPill,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: _isHovered ? 0.38 : 0.25),
                  blurRadius: _isHovered ? 20 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(widget.icon, color: Colors.white, size: 17),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedicalCrystalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.5);

    final radialGlow = Paint()
      ..shader = ui.Gradient.radial(
        center,
        size.width * 0.55,
        [
          AppColors.accentMint.withValues(alpha: 0.28),
          AppColors.primaryTeal.withValues(alpha: 0.14),
          Colors.transparent,
        ],
        [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(center, size.width * 0.55, radialGlow);

    // Cradling crystal wings
    final wingSize = size.width * 0.85;
    final leftWing = Path()
      ..moveTo(center.dx - wingSize * 0.44, center.dy + wingSize * 0.30)
      ..lineTo(center.dx - wingSize * 0.48, center.dy - wingSize * 0.10)
      ..lineTo(center.dx - wingSize * 0.32, center.dy - wingSize * 0.35)
      ..lineTo(center.dx - wingSize * 0.22, center.dy - wingSize * 0.22)
      ..lineTo(center.dx - wingSize * 0.34, center.dy + wingSize * 0.15)
      ..close();

    final leftPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - wingSize * 0.44, center.dy - wingSize * 0.35),
        Offset(center.dx - wingSize * 0.34, center.dy + wingSize * 0.30),
        [
          const Color(0xFF26A69A).withValues(alpha: 0.45),
          const Color(0xFF004D40).withValues(alpha: 0.20),
        ],
      );
    canvas.drawPath(leftWing, leftPaint);

    final rightWing = Path()
      ..moveTo(center.dx + wingSize * 0.44, center.dy + wingSize * 0.30)
      ..lineTo(center.dx + wingSize * 0.48, center.dy - wingSize * 0.10)
      ..lineTo(center.dx + wingSize * 0.32, center.dy - wingSize * 0.35)
      ..lineTo(center.dx + wingSize * 0.22, center.dy - wingSize * 0.22)
      ..lineTo(center.dx + wingSize * 0.34, center.dy + wingSize * 0.15)
      ..close();

    final rightPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx + wingSize * 0.44, center.dy - wingSize * 0.35),
        Offset(center.dx + wingSize * 0.34, center.dy + wingSize * 0.30),
        [
          const Color(0xFF80CBC4).withValues(alpha: 0.45),
          const Color(0xFF00796B).withValues(alpha: 0.20),
        ],
      );
    canvas.drawPath(rightWing, rightPaint);

    // Medical cross crystal
    final crossSize = size.width * 0.65;
    final armWidth = crossSize * 0.38;
    final crossPath = Path()
      ..moveTo(center.dx - armWidth / 2, center.dy - crossSize / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy - crossSize / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy - armWidth / 2)
      ..lineTo(center.dx + crossSize / 2, center.dy - armWidth / 2)
      ..lineTo(center.dx + crossSize / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy + crossSize / 2)
      ..lineTo(center.dx - armWidth / 2, center.dy + crossSize / 2)
      ..lineTo(center.dx - armWidth / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx - crossSize / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx - crossSize / 2, center.dy - armWidth / 2)
      ..lineTo(center.dx - armWidth / 2, center.dy - armWidth / 2)
      ..close();

    final crossPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx - crossSize / 2, center.dy - crossSize / 2),
        Offset(center.dx + crossSize / 2, center.dy + crossSize / 2),
        [
          const Color(0xFF00897B).withValues(alpha: 0.85),
          const Color(0xFF26A69A).withValues(alpha: 0.75),
        ],
      );
    canvas.drawPath(crossPath, crossPaint);

    // Cross Outline
    canvas.drawPath(
      crossPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}