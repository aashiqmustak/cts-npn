import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/google_logo.dart';

class AuthScreen extends StatefulWidget {
  final ValueChanged<UserRole>? onRoleChanged;

  const AuthScreen({super.key, this.onRoleChanged});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _activeTabIndex = 1; // 0: Sign In, 1: Create Account
  UserRole _selectedRole = UserRole.insuranceAgent;

  bool _otpSent = false;
  final _signInEmailController = TextEditingController();
  final _otpController = TextEditingController();

  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  String _selectedInsuranceCompany = 'Blue Cross Blue Shield';
  final Set<String> _selectedInsurancePlans = {
    'Blue Cross PPO Premier',
    'Blue Cross Advantage Plus',
  };
  bool _obscureRegPassword = true;
  bool _agreeTerms = true;
  bool _isPatientLoginMode = false;
  Map<String, dynamic>? _verifiedUserMap;

  @override
  void initState() {
    super.initState();
    _regPasswordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _signInEmailController.dispose();
    _otpController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  void _handleRoleTap(UserRole role) {
    setState(() {
      _selectedRole = role;
      _isPatientLoginMode = (role == UserRole.patient);
      _signInEmailController.text = role.defaultEmail;
    });
    widget.onRoleChanged?.call(role);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 960;

            if (_activeTabIndex == 1) {
              return _buildRegistrationView(context, appState, isDesktop: isDesktop);
            }

            if (isDesktop) {
              return Row(
                children: [
                  // Left Side — White Sign In Form Panel
                  Expanded(
                    flex: 5,
                    child: _buildLeftFormPanel(context, appState),
                  ),
                  // Right Side — AI-Powered Medication Intelligence Feature Showcase
                  Expanded(
                    flex: 6,
                    child: _buildRightShowcasePanel(),
                  ),
                ],
              );
            }

            // Mobile / Tablet Viewport for Sign In
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBrandLogoHeader(),
                    const SizedBox(height: 24),
                    _buildLeftFormPanel(context, appState, isMobile: true),
                    const SizedBox(height: 32),
                    _buildRightShowcasePanel(isMobile: true),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegistrationView(
    BuildContext context,
    AppState appState, {
    required bool isDesktop,
  }) {
    if (isDesktop) {
      return Stack(
        children: [
          // Background ambient soft glow orbs
          Positioned(
            top: -90,
            left: -90,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.07),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(170),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(160),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // Main 2-Column Split
          Row(
            children: [
              // Left Hero Column (flex: 4)
              Expanded(
                flex: 4,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildRegisterHeroLeftPanel(),
                ),
              ),
              // Right Grand Registration Card (flex: 7)
              Expanded(
                flex: 7,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    child: _buildRegisterGrandCard(context, appState),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Mobile / Tablet Registration View
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBrandLogoHeader(),
          const SizedBox(height: 20),
          _buildRegisterHeroLeftPanel(isMobile: true),
          const SizedBox(height: 24),
          _buildRegisterGrandCard(context, appState, isMobile: true),
        ],
      ),
    );
  }

  Widget _buildRegisterHeroLeftPanel({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 36,
        vertical: isMobile ? 16 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMobile ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          if (!isMobile) ...[
            _buildBrandLogoHeader(),
            const SizedBox(height: 32),
          ],

          // Title: Join the Intelligent Healthcare Ecosystem
          RichText(
            text: TextSpan(
              style: AppFonts.googleSans(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                height: 1.18,
                letterSpacing: -0.8,
              ),
              children: [
                const TextSpan(text: 'Join the\n'),
                TextSpan(
                  text: 'Intelligent\nHealthcare\n',
                  style: const TextStyle(color: Color(0xFF1D61E7)),
                ),
                const TextSpan(text: 'Ecosystem'),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 3.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Create your account to unlock smarter medication insights, better outcomes, and lower costs.',
            style: AppFonts.googleSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 22),

          // 3D Pedestal & Heart-Shield Graphic
          Center(
            child: _buildPedestalHeartShieldGraphic(),
          ),

          const SizedBox(height: 24),

          // 3 Stacked Trust Cards
          _buildRegisterTrustCard(
            icon: Icons.shield_outlined,
            title: 'Secure & Compliant',
            subtitle: 'HIPAA-compliant & enterprise-grade security',
          ),
          const SizedBox(height: 10),
          _buildRegisterTrustCard(
            icon: Icons.lock_outline_rounded,
            title: 'Your Data, Protected',
            subtitle: 'We keep your data private and secure',
          ),
          const SizedBox(height: 10),
          _buildRegisterTrustCard(
            icon: Icons.check_circle_outline_rounded,
            title: 'Built for Healthcare',
            subtitle: 'Designed to simplify workflows and improve care',
          ),
        ],
      ),
    );
  }

  Widget _buildPedestalHeartShieldGraphic() {
    return SizedBox(
      width: 280,
      height: 185,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            ),
          ),

          // Orbiting Mini Badges
          Positioned(
            top: 22,
            left: 24,
            child: _buildMiniOrbitBadge(Icons.show_chart_rounded, const Color(0xFF2563EB)),
          ),
          Positioned(
            top: 26,
            right: 26,
            child: _buildMiniOrbitBadge(Icons.assignment_outlined, const Color(0xFF2563EB)),
          ),

          // Base 3D Pedestal Platform
          Positioned(
            bottom: 12,
            child: Container(
              width: 165,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(85),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFEFF6FF),
                    Color(0xFFDBEAFE),
                    Color(0xFFBFDBFE),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 135,
                  height: 28,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(70),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFEFF6FF)],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Center 3D Blue Shield with Heart & ECG Pulse
          Positioned(
            bottom: 30,
            child: Container(
              width: 78,
              height: 92,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(38),
                  bottomRight: Radius.circular(38),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1D4ED8).withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.monitor_heart_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Left 3D Pill Bottle
          Positioned(
            left: 20,
            bottom: 22,
            child: Container(
              width: 36,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDBEAFE), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right 3D Capsule Pill
          Positioned(
            right: 22,
            bottom: 26,
            child: Transform.rotate(
              angle: 0.6,
              child: Container(
                width: 17,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniOrbitBadge(IconData icon, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  Widget _buildRegisterTrustCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppFonts.googleSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: AppFonts.googleSans(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterGrandCard(
    BuildContext context,
    AppState appState, {
    bool isMobile = false,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 820),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 36,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Centered Header
          Text(
            'Create an Account',
            textAlign: TextAlign.center,
            style: AppFonts.googleSans(
              fontSize: isMobile ? 22 : 26,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Join the Alternae Intelligent Healthcare Ecosystem.',
            textAlign: TextAlign.center,
            style: AppFonts.googleSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 24),

          // Inner Top Subheader Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Create Account',
                    style: AppFonts.googleSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      size: 14,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _selectedRole.label,
                      style: AppFonts.googleSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2-Column Split Body (or Stack on Mobile)
          if (isMobile) ...[
            _buildRegisterLeftSubColumn(context, appState),
            const SizedBox(height: 24),
            _buildRegisterRightSubColumn(context, appState),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Sub-Column (Privilege Banner + 3 Role Cards + Google Sign Up)
                Expanded(
                  flex: 5,
                  child: _buildRegisterLeftSubColumn(context, appState),
                ),
                const SizedBox(width: 28),
                // Vertical Divider
                Container(
                  width: 1,
                  height: 420,
                  color: const Color(0xFFF1F5F9),
                ),
                const SizedBox(width: 28),
                // Right Sub-Column (Inputs + Strength + Terms + CTA)
                Expanded(
                  flex: 6,
                  child: _buildRegisterRightSubColumn(context, appState),
                ),
              ],
            ),
          ],

          const SizedBox(height: 28),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          // Bottom 3-Column Security Footer Strip
          _buildRegisterFooterSecurityStrip(),
        ],
      ),
    );
  }

  Widget _buildRegisterLeftSubColumn(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Role Privileges Banner Card
        _RolePrivilegesBanner(role: _selectedRole),

        const SizedBox(height: 16),

        // 4 Role Selection Cards in Row (Patient, Insurance, Doctor, Pharmacist)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildRoleSelectCardV2(
                role: UserRole.patient,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEF4444),
                iconBg: const Color(0xFFFEF2F2),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildRoleSelectCardV2(
                role: UserRole.insuranceAgent,
                icon: Icons.verified_user_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildRoleSelectCardV2(
                role: UserRole.doctor,
                icon: Icons.medical_services_rounded,
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFFECFDF5),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildRoleSelectCardV2(
                role: UserRole.pharmacist,
                icon: Icons.local_pharmacy_rounded,
                iconColor: const Color(0xFF9333EA),
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
          ],
        ),

        if (_selectedRole == UserRole.patient) ...[
          const SizedBox(height: 18),
          // Google Sign-Up Button (Patient Portal Exclusive)
          GoogleSignInButton(
            text: 'Sign up with Google (Patient Portal)',
            onPressed: () async {
              await appState.signInWithGooglePatient();
            },
          ),
        ] else ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 14,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Institutional verification required for ${_selectedRole.label}s.',
                    style: AppFonts.googleSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoleSelectCardV2({
    required UserRole role,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
  }) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () => _handleRoleTap(role),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                  : const Color(0xFF0F172A).withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  role.label,
                  textAlign: TextAlign.center,
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  role.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.googleSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -8,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterRightSubColumn(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Divider OR MANUAL REGISTRATION
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'OR MANUAL REGISTRATION',
                style: AppFonts.googleSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          ],
        ),

        const SizedBox(height: 14),

        // Full Legal Name
        _GlowBorderFormField(
          controller: _regNameController,
          label: _selectedRole.nameFieldLabel,
          hint: 'e.g. ${_selectedRole.sampleName}',
          icon: Icons.assignment_ind_outlined,
        ),

        const SizedBox(height: 12),

        // Professional Email
        _GlowBorderFormField(
          controller: _regEmailController,
          label: _selectedRole.emailFieldLabel,
          hint: _selectedRole.sampleEmail,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),

        // Password
        _GlowBorderFormField(
          controller: _regPasswordController,
          label: 'PASSWORD',
          hint: 'At least 8 characters',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureRegPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRegPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: const Color(0xFF1D4ED8),
            ),
            onPressed: () {
              setState(() {
                _obscureRegPassword = !_obscureRegPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        // Password Strength Meter
        _PasswordStrengthMeter(password: _regPasswordController.text),

        if (_selectedRole == UserRole.insuranceAgent) ...[
          const SizedBox(height: 12),
          _buildInsuranceAgentRegisterFields(),
        ],

        const SizedBox(height: 12),

        // Terms and conditions
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
                'I acknowledge Alternae Clinical Data Agreement & HIPAA Compliance Policy',
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Create Account CTA Button
        _GradientBlueCtaButton(
          label: 'Create Account',
          onPressed: () async {
            final name = _regNameController.text.trim().isEmpty
                ? 'Authorized User'
                : _regNameController.text.trim();
            final email = _regEmailController.text.trim();
            final password = _regPasswordController.text.trim();

            List<String> finalPlans = _selectedInsurancePlans.toList();
            if (finalPlans.isEmpty) {
              finalPlans = ['Comprehensive Rx Plan'];
            }

            await appState.registerAccount(
              name: name,
              email: email,
              password: password,
              role: _selectedRole,
              insuranceCompany: _selectedRole == UserRole.insuranceAgent ? _selectedInsuranceCompany : null,
              insurancePlans: _selectedRole == UserRole.insuranceAgent ? finalPlans : const [],
              insuranceMedicines: const [],
              insuranceHospitals: const [],
            );
          },
        ),

        const SizedBox(height: 16),

        // Footer: Already have an account? Sign in
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: AppFonts.googleSans(
                fontSize: 12.5,
                color: const Color(0xFF64748B),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _activeTabIndex = 0;
                });
              },
              child: Text(
                'Sign in',
                style: AppFonts.googleSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D61E7),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterFooterSecurityStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildFooterSecurityItem(
            icon: Icons.shield_outlined,
            title: 'HIPAA Compliant',
            subtitle: 'Your data is safe with us',
          ),
        ),
        Container(
          height: 28,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: _buildFooterSecurityItem(
            icon: Icons.lock_outline_rounded,
            title: 'Enterprise Security',
            subtitle: 'Industry-leading protection',
          ),
        ),
        Container(
          height: 28,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFFE2E8F0),
        ),
        Expanded(
          child: _buildFooterSecurityItem(
            icon: Icons.cloud_outlined,
            title: 'Always Available',
            subtitle: 'Access anytime, anywhere',
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSecurityItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: AppFonts.googleSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandLogoHeader({double size = 36}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/app_logo.png',
          height: size,
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1244A2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 20,
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        Text(
          'Alternae',
          style: AppFonts.googleSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          '.ai',
          style: AppFonts.googleSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1244A2),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLeftFormPanel(
    BuildContext context,
    AppState appState, {
    bool isMobile = false,
  }) {
    return Stack(
      children: [
        // Premium Ambient Glow Orbs in Background (Mesh Gradient style)
        if (!isMobile) ...[
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.08),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(170),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ],

        // Main Form Content Scroll Layer
        Container(
          color: Colors.transparent,
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 28,
                vertical: isMobile ? 16 : 70,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 430),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 32,
                        vertical: isMobile ? 24 : 34,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _activeTabIndex == 0
                                ? 'Welcome back 👋'
                                : 'Create an Account',
                            textAlign: TextAlign.center,
                            style: AppFonts.googleSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _activeTabIndex == 0
                                ? 'Sign in to your Alternae account to continue'
                                : 'Join the Alternae Intelligent Healthcare Ecosystem.',
                            textAlign: TextAlign.center,
                            style: AppFonts.googleSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          if (_activeTabIndex == 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'All Your Hospital & Pharmacy Needs in One Place.',
                              textAlign: TextAlign.center,
                              style: AppFonts.googleSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          _activeTabIndex == 0
                              ? _buildSignInTab(context, appState)
                              : _buildRegisterTab(context, appState),
                        ],
                      ),
                    ),

                    if (!isMobile) ...[
                      const SizedBox(height: 24),
                      _buildTrustBadgesStrip(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Pinned Brand Logo Header in top-left corner
        if (!isMobile)
          Positioned(
            top: 28,
            left: 36,
            child: _buildBrandLogoHeader(),
          ),
      ],
    );
  }

  Widget _buildTrustBadgesStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTrustBadgeItem(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            bgColor: const Color(0xFFEFF6FF),
            title: '256-Bit TLS',
            subtitle: 'Secure Connection',
          ),
          Container(
            height: 26,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFE2E8F0),
          ),
          _buildTrustBadgeItem(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF10B981),
            bgColor: const Color(0xFFECFDF5),
            title: 'HIPAA Audit',
            subtitle: 'Compliance Verified',
          ),
          Container(
            height: 26,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFE2E8F0),
          ),
          _buildTrustBadgeItem(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF9333EA),
            bgColor: const Color(0xFFFAF5FF),
            title: 'Healthcare Grade',
            subtitle: 'Trusted & Reliable',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadgeItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppFonts.googleSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              subtitle,
              style: AppFonts.googleSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRightShowcasePanel({bool isMobile = false}) {
    final panelContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(isMobile ? 18 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Showcase Header
          if (isMobile) ...[
            Text(
              'AI-Powered Medication',
              style: AppFonts.googleSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Intelligence',
              style: AppFonts.googleSans(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF2563EB),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 3.5,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'From prescriptions to better outcomes. Smarter coverage, lower costs, and improved patient care.',
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: _buildMedicalIntelligenceGraphic(),
            ),
          ] else ...[
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'AI-Powered Medication',
                          style: AppFonts.googleSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Intelligence',
                          style: AppFonts.googleSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2563EB),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 36,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'From prescriptions to better outcomes.\nSmarter coverage, lower costs,\nand improved patient care.',
                          style: AppFonts.googleSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _buildMedicalIntelligenceGraphic(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // 6 Feature Cards Grid
          if (isMobile) ...[
            _buildFeatureCard(
              icon: Icons.description_outlined,
              iconColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF),
              title: 'Prescription Parsing',
              description:
                  'Extracts drug names, dosages, routes, frequencies, and diagnostic codes (ICD-10/RxNorm) from unstructured prescriptions.',
            ),
            const SizedBox(height: 10),
            _buildFeatureCard(
              icon: Icons.assignment_turned_in_outlined,
              iconColor: const Color(0xFF059669),
              bgColor: const Color(0xFFECFDF5),
              title: 'Formulary & Tier Check',
              description:
                  'Verifies coverage across commercial, Medicare, and Medicaid plans. Identifies tiers, restrictions, step therapies, and deductible impact.',
            ),
            const SizedBox(height: 10),
            _buildFeatureCard(
              icon: Icons.medication_outlined,
              iconColor: const Color(0xFF9333EA),
              bgColor: const Color(0xFFFAF5FF),
              title: 'Formulary Alternatives',
              description:
                  'Finds clinically appropriate alternatives and compares coverage to estimate patient out-of-pocket savings.',
            ),
            const SizedBox(height: 10),
            _buildFeatureCard(
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFFBEB),
              title: 'Prior Authorization',
              description:
                  'Checks PA requirements, including labs, specialist notes, and previous therapy failure, and prepares fast-track PA submission packages.',
            ),
            const SizedBox(height: 10),
            _buildFeatureCard(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFFE11D48),
              bgColor: const Color(0xFFFEF2F2),
              title: 'Adherence & Abandonment',
              description:
                  'Predicts adherence drop-off and pharmacy abandonment risk before the patient reaches the pharmacy counter.',
            ),
            const SizedBox(height: 10),
            _buildFeatureCard(
              icon: Icons.mic_none_rounded,
              iconColor: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
              title: 'Alternea Voice',
              description:
                  'WebRTC-based voice companion powered by Pipechat for real-time conversational intake and voice commands.',
            ),
          ] else ...[
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.description_outlined,
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            title: 'Prescription Parsing',
                            description:
                                'Extracts drug names, dosages, routes, frequencies, and diagnostic codes (ICD-10/RxNorm) from unstructured prescriptions.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.assignment_turned_in_outlined,
                            iconColor: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                            title: 'Formulary & Tier Check',
                            description:
                                'Verifies coverage across commercial, Medicare, and Medicaid plans. Identifies tiers, restrictions, step therapies, and deductible impact.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.medication_outlined,
                            iconColor: const Color(0xFF9333EA),
                            bgColor: const Color(0xFFFAF5FF),
                            title: 'Formulary Alternatives',
                            description:
                                'Finds clinically appropriate alternatives and compares coverage to estimate patient out-of-pocket savings.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.assignment_outlined,
                            iconColor: const Color(0xFFD97706),
                            bgColor: const Color(0xFFFFFBEB),
                            title: 'Prior Authorization',
                            description:
                                'Checks PA requirements, including labs, specialist notes, and previous therapy failure, and prepares fast-track PA submission packages.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFFE11D48),
                            bgColor: const Color(0xFFFEF2F2),
                            title: 'Adherence & Abandonment',
                            description:
                                'Predicts adherence drop-off and pharmacy abandonment risk before the patient reaches the pharmacy counter.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFeatureCard(
                            icon: Icons.mic_none_rounded,
                            iconColor: const Color(0xFF4F46E5),
                            bgColor: const Color(0xFFEEF2FF),
                            title: 'Alternea Voice',
                            description:
                                'WebRTC-based voice companion powered by Pipechat for real-time conversational intake and voice commands.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Bottom Banner Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF2563EB),
                    size: 17,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'One Platform. Smarter Decisions. Better Outcomes.',
                        style: AppFonts.googleSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Unified intelligence to simplify medication access and improve patient care.',
                        style: AppFonts.googleSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF1E40AF),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return panelContent;
    }

    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(28),
      child: panelContent,
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.googleSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              description,
              style: AppFonts.googleSans(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
                height: 1.3,
              ),
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalIntelligenceGraphic() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Soft glowing backdrop orb
            Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFFE0EDFF),
                    Color(0xFFF0F6FF),
                  ],
                ),
              ),
            ),

            // Dashed / Orbit ring
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                  width: 1.5,
                ),
              ),
            ),

            // Central Prescription Sheet
            Positioned(
              top: 14,
              child: Container(
                width: 90,
                height: 110,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
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
                          'Rx',
                          style: AppFonts.googleSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF2563EB),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildRxCheckLine(),
                    const SizedBox(height: 4),
                    _buildRxCheckLine(),
                    const SizedBox(height: 4),
                    _buildRxCheckLine(),
                    const Spacer(),
                    Container(
                      height: 3,
                      width: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Blue Medicine Pill Bottle in foreground
            Positioned(
              bottom: 14,
              right: 28,
              child: Container(
                width: 42,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cap
                    Positioned(
                      top: 0,
                      child: Container(
                        width: 34,
                        height: 7,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 14,
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Pill Capsule in front left
            Positioned(
              bottom: 16,
              left: 28,
              child: Transform.rotate(
                angle: -0.3,
                child: Container(
                  width: 32,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.15),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            borderRadius: BorderRadius.horizontal(left: Radius.circular(8)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 4 Orbiting Badges:
            Positioned(
              top: 8,
              left: 10,
              child: _buildOrbitBadge(Icons.description_outlined, const Color(0xFF2563EB)),
            ),
            Positioned(
              top: 8,
              right: 10,
              child: _buildOrbitBadge(Icons.shield_outlined, const Color(0xFF4F46E5)),
            ),
            Positioned(
              bottom: 20,
              left: 4,
              child: _buildOrbitBadge(Icons.insert_chart_outlined_rounded, const Color(0xFF2563EB)),
            ),
            Positioned(
              bottom: 20,
              right: 4,
              child: _buildOrbitBadge(Icons.person_outline_rounded, const Color(0xFF2563EB)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrbitBadge(IconData icon, Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDBEAFE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, size: 14, color: color),
    );
  }

  Widget _buildRxCheckLine() {
    return Row(
      children: [
        const Icon(Icons.check_rounded, size: 10, color: Color(0xFF2563EB)),
        const SizedBox(width: 4),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInTab(BuildContext context, AppState appState) {
    if (!_otpSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Email address',
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _GlowBorderFormField(
            controller: _signInEmailController,
            label: 'Email address',
            hint: 'e.g. dr.ananya.sharma@hospital.org / jessicathompson@mail.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 10),

          // Quick Role Preset Selectors
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildRoleQuickPill('👨‍⚕️ Dr. Ananya (Doctor)', UserRole.doctor.sampleEmail),
              _buildRoleQuickPill('💊 Marcus (Pharmacist)', UserRole.pharmacist.sampleEmail),
              _buildRoleQuickPill('🩺 Jessica (Patient)', UserRole.patient.sampleEmail),
              _buildRoleQuickPill('🛡️ Robert (Payer)', UserRole.insuranceAgent.sampleEmail),
            ],
          ),

          const SizedBox(height: 14),

          _GradientBlueCtaButton(
            label: 'VERIFY USER ID & CONTINUE →',
            icon: Icons.verified_user_outlined,
            onPressed: () async {
              final val = _signInEmailController.text.trim();
              if (val.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter your User ID or Email address'),
                  ),
                );
                return;
              }
              final check = appState.checkUserIdentifier(val);
              await appState.sendOtp(val);
              setState(() {
                _verifiedUserMap = check;
                _otpSent = true;
                _otpController.clear();
              });
            },
          ),

          const SizedBox(height: 18),

          // Divider OR
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),

          const SizedBox(height: 18),

          // Google Sign-In with actual 4-color Google logo strictly for patients
          GoogleSignInButton(
            text: 'Sign in with Google (Patients)',
            onPressed: () async {
              await appState.signInWithGooglePatient();
            },
          ),

          const SizedBox(height: 22),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: AppFonts.googleSans(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTabIndex = 1;
                  });
                },
                child: Text(
                  'Register',
                  style: AppFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D61E7),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final userExists = _verifiedUserMap?['exists'] == true;
    final userName = _verifiedUserMap?['name'] ?? '';
    final userRole = _verifiedUserMap?['role'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userExists ? 'User ID Verified' : 'New User ID Intake',
                    style: AppFonts.googleSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    userExists
                        ? '$userName ($userRole)'
                        : 'ID: ${_signInEmailController.text}',
                    style: AppFonts.googleSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _GlowBorderFormField(
          controller: _otpController,
          label: 'OTP VERIFICATION CODE',
          hint: 'e.g. 6-digit code',
          icon: Icons.lock_clock_rounded,
          keyboardType: TextInputType.number,
        ),

        const SizedBox(height: 20),

        _GradientBlueCtaButton(
          label: 'Complete Sign In & Launch Workspace →',
          onPressed: () async {
            final val = _signInEmailController.text.trim();
            final otp = _otpController.text.trim();
            await appState.verifyOtpAndLogin(
              email: val,
              otp: otp,
              isPatient: _isPatientLoginMode,
            );
          },
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                  _verifiedUserMap = null;
                  _otpController.clear();
                });
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 14),
              label: Text(
                'Back to User ID',
                style: AppFonts.googleSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1244A2),
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final email = _signInEmailController.text.trim();
                await appState.sendOtp(email);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('OTP verification code resent successfully'),
                  ),
                );
              },
              child: Text(
                'Resend Code',
                style: AppFonts.googleSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPill,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Create Account',
                  style: AppFonts.googleSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryTeal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 13,
                    color: AppColors.primaryTeal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedRole.label,
                    style: AppFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _RolePrivilegesBanner(role: _selectedRole),

        const SizedBox(height: 12),

        _HorizontalRoleSelector(
          selected: _selectedRole,
          onSelect: _handleRoleTap,
        ),

        const SizedBox(height: 14),

        if (_selectedRole == UserRole.patient) ...[
          GoogleSignInButton(
            text: 'Sign up with Google (Patient)',
            onPressed: () async {
              await appState.signInWithGooglePatient();
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR MANUAL REGISTRATION',
                  style: AppFonts.googleSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 14),
        ],

        _GlowBorderFormField(
          controller: _regNameController,
          label: _selectedRole.nameFieldLabel,
          hint: 'e.g. ${_selectedRole.sampleName}',
          icon: Icons.badge_outlined,
        ),

        const SizedBox(height: 12),

        _GlowBorderFormField(
          controller: _regEmailController,
          label: _selectedRole.emailFieldLabel,
          hint: _selectedRole.sampleEmail,
          icon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),

        const SizedBox(height: 12),

        _GlowBorderFormField(
          controller: _regPasswordController,
          label: 'PASSWORD',
          hint: 'At least 8 characters',
          icon: Icons.lock_outline_rounded,
          obscureText: _obscureRegPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureRegPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
              color: const Color(0xFF1D4ED8),
            ),
            onPressed: () {
              setState(() {
                _obscureRegPassword = !_obscureRegPassword;
              });
            },
          ),
        ),

        const SizedBox(height: 10),

        _PasswordStrengthMeter(password: _regPasswordController.text),

        if (_selectedRole == UserRole.insuranceAgent) ...[
          const SizedBox(height: 12),
          _buildInsuranceAgentRegisterFields(),
        ],

        const SizedBox(height: 12),

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
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _GradientBlueCtaButton(
          label: 'CREATE ACCOUNT',
          onPressed: () async {
            final name =
                _regNameController.text.trim().isEmpty
                    ? 'Authorized User'
                    : _regNameController.text.trim();
            final email = _regEmailController.text.trim();
            final password = _regPasswordController.text.trim();

            List<String> finalPlans = _selectedInsurancePlans.toList();
            if (finalPlans.isEmpty) {
              finalPlans = ['Comprehensive Rx Plan'];
            }

            await appState.registerAccount(
              name: name,
              email: email,
              password: password,
              role: _selectedRole,
              insuranceCompany: _selectedRole == UserRole.insuranceAgent ? _selectedInsuranceCompany : null,
              insurancePlans: _selectedRole == UserRole.insuranceAgent ? finalPlans : const [],
              insuranceMedicines: const [],
              insuranceHospitals: const [],
            );
          },
        ),

        const SizedBox(height: 10),
        _buildSecurityGuarantee(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an Account? ",
              style: AppFonts.googleSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _activeTabIndex = 0;
                });
              },
              child: Text(
                'Sign In',
                style: AppFonts.googleSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1244A2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsuranceAgentRegisterFields() {
    final companyPlansMap = {
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

    final currentAvailablePlans = companyPlansMap[_selectedInsuranceCompany] ?? companyPlansMap['Blue Cross Blue Shield']!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Insurance Company Dropdown
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_rounded, color: Color(0xFF1D4ED8), size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                '1. SELECT INSURANCE COMPANY / PAYER',
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
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedInsuranceCompany,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1D4ED8)),
                style: AppFonts.googleSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                items: companyPlansMap.keys.map((c) {
                  return DropdownMenuItem<String>(
                    value: c,
                    child: Text(c),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedInsuranceCompany = val;
                      _selectedInsurancePlans.clear();
                      final defaults = companyPlansMap[val];
                      if (defaults != null && defaults.isNotEmpty) {
                        _selectedInsurancePlans.addAll(defaults.take(2));
                      }
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Benefit Plans Dropdown & Selected Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '2. COVERED BENEFIT PLANS (${_selectedInsurancePlans.length} Selected)',
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: Text('Select a plan to add/toggle...', style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8))),
                icon: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF1D4ED8), size: 18),
                items: currentAvailablePlans.map((p) {
                  final isAlreadySelected = _selectedInsurancePlans.contains(p);
                  return DropdownMenuItem<String>(
                    value: p,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(p, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                        Icon(
                          isAlreadySelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                          size: 16,
                          color: isAlreadySelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      if (_selectedInsurancePlans.contains(val)) {
                        _selectedInsurancePlans.remove(val);
                      } else {
                        _selectedInsurancePlans.add(val);
                      }
                    });
                  }
                },
              ),
            ),
          ),
          if (_selectedInsurancePlans.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedInsurancePlans.map((plan) {
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
                  onDeleted: () {
                    setState(() {
                      _selectedInsurancePlans.remove(plan);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityGuarantee() {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 13,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(width: 5),
            Text(
              'Protected by 256-Bit TLS Encryption • HIPAA Compliant',
              style: AppFonts.googleSans(
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

  Widget _buildRoleQuickPill(String label, String email) {
    final isSelected = _signInEmailController.text == email;
    return InkWell(
      onTap: () {
        setState(() {
          _signInEmailController.text = email;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: AppFonts.googleSans(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
          ),
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
          children:
              UserRole.values
                  .where((role) => role != UserRole.admin)
                  .map((role) {
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.fastOutSlowIn,
                width: 108,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? const LinearGradient(
                            colors: AppColors.gradientPill,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : null,
                  color:
                      isSelected
                          ? null
                          : (_isHovered
                              ? AppColors.primaryLight.withValues(alpha: 0.65)
                              : AppColors.bgSlate),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected
                            ? Colors.transparent
                            : (_isHovered
                                ? AppColors.primaryTeal.withValues(alpha: 0.5)
                                : AppColors.borderLight),
                    width: 1.4,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: AppColors.primaryTeal.withValues(
                                alpha: 0.32,
                              ),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                          : (_isHovered
                              ? [
                                BoxShadow(
                                  color: AppColors.primaryTeal.withValues(
                                    alpha: 0.12,
                                  ),
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
                        color:
                            isSelected
                                ? Colors.white.withValues(alpha: 0.22)
                                : (_isHovered
                                    ? AppColors.primaryTeal.withValues(
                                      alpha: 0.12,
                                    )
                                    : Colors.white),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.role.icon,
                        size: 18,
                        color:
                            isSelected
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
                      style: AppFonts.googleSans(
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
                      style: AppFonts.googleSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? Colors.white.withValues(alpha: 0.85)
                                : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppColors.primaryTeal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePrivilegesBanner extends StatelessWidget {
  final UserRole role;

  const _RolePrivilegesBanner({required this.role});

  @override
  Widget build(BuildContext context) {
    final title = _getRoleTitle(role);
    final badges = _getRoleBadges(role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDBEAFE),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getRoleIcon(role), size: 14, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.googleSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                badges.map((badge) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFBFDBFE),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 12,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: AppFonts.googleSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return 'Physician & Prescriber Account';
      case UserRole.pharmacist:
        return 'Clinical Dispensing Portal';
      case UserRole.patient:
        return 'Patient Health & Adherence Vault';
      case UserRole.insuranceAgent:
        return 'Payer & Formulary Management';
      case UserRole.admin:
        return 'Ecosystem Administrative Access';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.insuranceAgent:
        return Icons.verified_user_rounded;
      case UserRole.doctor:
        return Icons.medical_services_rounded;
      case UserRole.pharmacist:
        return Icons.medication_rounded;
      case UserRole.patient:
        return Icons.favorite_rounded;
    }
  }

  List<String> _getRoleBadges(UserRole role) {
    switch (role) {
      case UserRole.doctor:
        return const ['E-Prescribing', 'EHR Integration', 'PA Pre-Check'];
      case UserRole.pharmacist:
        return const ['Rx Verification', 'Med Dispensing', 'Refill Audit'];
      case UserRole.patient:
        return const ['Med Tracking', 'Adherence Alerts', 'Copay Savings'];
      case UserRole.insuranceAgent:
        return const ['Tier Management', 'Prior Auth Audit', 'Cost Analytics'];
      case UserRole.admin:
        return const ['User Control', 'System Logs', 'FHIR Config'];
    }
  }
}

class _PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const _PasswordStrengthMeter({required this.password});

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore(password);
    final label = _getLabel(score);
    final color = _getColor(score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PASSWORD SECURITY STRENGTH',
              style: AppFonts.googleSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppFonts.googleSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (index) {
            final isActive = index < score;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 4.0 : 0.0),
                decoration: BoxDecoration(
                  color: isActive ? color : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _checkItem('8+ Chars', password.length >= 8),
            _checkItem('Upper & Lower', _hasUpperAndLower(password)),
            _checkItem('Numbers', _hasNumber(password)),
            _checkItem('Symbols', _hasSymbol(password)),
          ],
        ),
      ],
    );
  }

  int _calculateScore(String password) {
    if (password.isEmpty) return 0;
    int s = 0;
    if (password.length >= 8) s++;
    if (_hasUpperAndLower(password)) s++;
    if (_hasNumber(password)) s++;
    if (_hasSymbol(password)) s++;
    return s == 0 && password.isNotEmpty ? 1 : s;
  }

  bool _hasUpperAndLower(String p) =>
      p.contains(RegExp(r'[A-Z]')) && p.contains(RegExp(r'[a-z]'));
  bool _hasNumber(String p) => p.contains(RegExp(r'[0-9]'));
  bool _hasSymbol(String p) => p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  String _getLabel(int score) {
    if (password.isEmpty) return 'Enter password';
    switch (score) {
      case 1:
        return 'Weak Security';
      case 2:
        return 'Fair Protection';
      case 3:
        return 'Strong Password';
      case 4:
        return 'Ultra Secure';
      default:
        return 'Weak Security';
    }
  }

  Color _getColor(int score) {
    if (password.isEmpty) return AppColors.textMuted;
    switch (score) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return AppColors.primaryTeal;
      case 4:
        return const Color(0xFF10B981);
      default:
        return AppColors.textMuted;
    }
  }

  Widget _checkItem(String text, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 11,
          color:
              isMet
                  ? AppColors.primaryTeal
                  : AppColors.textMuted.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 3),
        Text(
          text,
          style: AppFonts.googleSans(
            fontSize: 9.5,
            fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
            color: isMet ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ModernCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModernCheckbox({required this.value, required this.onChanged});

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
        child:
            value
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
                  color: AppColors.primaryTeal.withValues(
                    alpha: _isHovered ? 0.38 : 0.25,
                  ),
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
                  style: AppFonts.googleSans(
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

class _GlowBorderFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _GlowBorderFormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  State<_GlowBorderFormField> createState() => _GlowBorderFormFieldState();
}

class _GlowBorderFormFieldState extends State<_GlowBorderFormField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          width: _isFocused ? 1.6 : 1.2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Icon(
            widget.icon,
            color: _isFocused ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              style: AppFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppFonts.googleSans(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
          if (widget.suffixIcon != null) widget.suffixIcon!,
        ],
      ),
    );
  }
}

class _GradientBlueCtaButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  const _GradientBlueCtaButton({
    required this.label,
    this.icon,
    required this.onPressed,
  });

  @override
  State<_GradientBlueCtaButton> createState() => _GradientBlueCtaButtonState();
}

class _GradientBlueCtaButtonState extends State<_GradientBlueCtaButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.012 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D61E7), Color(0xFF1852CD)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D61E7).withValues(alpha: _isHovered ? 0.4 : 0.25),
                blurRadius: _isHovered ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 17),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: AppFonts.googleSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
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
}
