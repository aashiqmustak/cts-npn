import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// ======================================================================
/// PharmacyRole — the 5-role selection model requested for this screen.
///
/// NOTE / INTEGRATION POINT:
/// Your existing `UserRole` enum (models.dart) doesn't yet have `cashier`
/// or `inventoryManager`. Rather than silently mocking new backend states,
/// this screen exposes both:
///   1. `onRoleChanged(PharmacyRole role)` — fire this straight into your
///      real backend/auth flow however you need to.
///   2. `_mapToUserRole()` below — a best-effort mapping onto your CURRENT
///      enum so `appState.login` / `appState.register` keep working out
///      of the box. Replace this mapping once your backend enum grows to
///      cover Cashier / Inventory Manager.
/// ======================================================================
enum PharmacyRole { admin, pharmacist, doctor, cashier, inventoryManager }

extension PharmacyRoleMeta on PharmacyRole {
  String get label {
    switch (this) {
      case PharmacyRole.admin:
        return 'Admin';
      case PharmacyRole.pharmacist:
        return 'Pharmacist';
      case PharmacyRole.doctor:
        return 'Doctor';
      case PharmacyRole.cashier:
        return 'Cashier';
      case PharmacyRole.inventoryManager:
        return 'Inventory';
    }
  }

  IconData get icon {
    switch (this) {
      case PharmacyRole.admin:
        return Icons.admin_panel_settings_rounded;
      case PharmacyRole.pharmacist:
        return Icons.local_pharmacy_rounded;
      case PharmacyRole.doctor:
        return Icons.medical_services_rounded;
      case PharmacyRole.cashier:
        return Icons.point_of_sale_rounded;
      case PharmacyRole.inventoryManager:
        return Icons.inventory_2_rounded;
    }
  }
}

class AuthScreen extends StatefulWidget {
  /// Clean integration point for your real backend / auth pipeline.
  /// Fired every time the user picks a different role, independent of
  /// sign-in / register submission.
  final ValueChanged<PharmacyRole>? onRoleChanged;

  const AuthScreen({super.key, this.onRoleChanged});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  int _activeTabIndex = 0; // 0: Sign In, 1: Create Account
  PharmacyRole _selectedRole = PharmacyRole.doctor;

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

  /// Best-effort mapping onto your CURRENT UserRole enum. See class-level
  /// doc comment above — replace once your backend supports all 5 roles.
  UserRole _mapToUserRole(PharmacyRole role) {
    switch (role) {
      case PharmacyRole.admin:
        return UserRole.admin;
      case PharmacyRole.pharmacist:
        return UserRole.pharmacist;
      case PharmacyRole.doctor:
        return UserRole.doctor;
      case PharmacyRole.cashier:
        return UserRole.patient; // TODO: map to a real Cashier role
      case PharmacyRole.inventoryManager:
        return UserRole.insuranceAgent; // TODO: map to a real Inventory role
    }
  }

  void _handleRoleTap(PharmacyRole role) {
    setState(() => _selectedRole = role);
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
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    width: isDesktop ? 1040 : 460,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 48,
                          offset: const Offset(0, 24),
                        ),
                      ],
                    ),
                    child: isDesktop
                        ? SizedBox(
                            // Fixed height instead of IntrinsicHeight: the
                            // canvas panel uses height: double.infinity to
                            // fill whatever space it's given, and Flutter
                            // cannot compute an "intrinsic" height for an
                            // infinitely-tall box — that combination is what
                            // was throwing the repeated
                            // "Assertion failed: box.dart:2251" and blanking
                            // the whole screen. A bounded height avoids
                            // intrinsic sizing entirely.
                            height: 720,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left Panel — Auth Form (scrollable safety
                                // net in case content ever exceeds 720px,
                                // e.g. larger text-scale settings)
                                Expanded(
                                  flex: 6,
                                  child: SingleChildScrollView(
                                    child: _buildFormPanel(context, appState),
                                  ),
                                ),
                                // Right Panel — Visual Canvas
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
                                  height: 220,
                                  child: _buildVisualCanvas(isDesktop: false),
                                ),
                              ),
                              _buildFormPanel(context, appState),
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

  // ------------------------------------------------------------------
  // VISUAL CANVAS — low-poly medical illustration, gentle float loop
  // ------------------------------------------------------------------
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
        children: [
          // Ambient soft blobs for depth
          Positioned(
            top: -60,
            right: -40,
            child: _glowBlob(180, Colors.white.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: _glowBlob(220, Colors.black.withOpacity(0.08)),
          ),

          // Floating faceted illustration
          Center(
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, child) {
                final dy = math.sin(_floatAnim.value * math.pi * 2) * 10;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: child,
                );
              },
              child: RepaintBoundary(
                child: SizedBox(
                  width: isDesktop ? 320 : 200,
                  height: isDesktop ? 320 : 200,
                  child: CustomPaint(painter: _LowPolyMedicalPainter()),
                ),
              ),
            ),
          ),

          // Floating trust badges (desktop only — keeps mobile canvas clean)
          if (isDesktop) ...[
            Positioned(
              top: 28,
              left: 28,
              child: _floatingBadge(
                icon: Icons.verified_user_rounded,
                label: 'HIPAA Compliant',
                delayOffset: 0.0,
              ),
            ),
            Positioned(
              bottom: 36,
              right: 28,
              child: _floatingBadge(
                icon: Icons.bolt_rounded,
                label: 'Real-time Sync',
                delayOffset: 0.5,
              ),
            ),
          ],

          // Bottom caption
          Positioned(
            left: 28,
            right: 28,
            bottom: isDesktop ? 96 : 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'One platform.\nEvery role, in sync.',
                  style: TextStyle(
                    fontSize: isDesktop ? 22 : 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: -0.3,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(height: 8),
                  Text(
                    'From prescribing to dispensing to inventory — Vivara keeps every pharmacy role moving together.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _floatingBadge({
    required IconData icon,
    required String label,
    required double delayOffset,
  }) {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        final dy =
            math.sin((_floatAnim.value + delayOffset) * math.pi * 2) * 6;
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // FORM PANEL
  // ------------------------------------------------------------------
  Widget _buildFormPanel(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 40, 36, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand mark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.gradientPill,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.medical_services_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Vivara',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // 5-role selection module — shared across Sign In & Create Account
          const Text('Continue as',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.3)),
          const SizedBox(height: 10),
          _RoleGrid(
            selected: _selectedRole,
            onSelect: _handleRoleTap,
          ),

          const SizedBox(height: 26),

          // Segmented Pill Tab Bar (Sign In vs Create Account)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _segmentTab(
                      'Sign In', 0, () => setState(() => _activeTabIndex = 0)),
                ),
                Expanded(
                  child: _segmentTab('Create Account', 1,
                      () => setState(() => _activeTabIndex = 1)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
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
      ),
    );
  }

  Widget _segmentTab(String label, int index, VoidCallback onTap) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: AppColors.gradientPill)
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isActive ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // SIGN IN
  // ------------------------------------------------------------------
  Widget _buildSignInTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Signing in as ${_selectedRole.label}',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        _fieldLabel('Email Address'),
        const SizedBox(height: 6),
        _PremiumTextField(
          controller: _signInEmailController,
          hint: 'e.g. doctor@alternea.org',
          icon: Icons.mail_outline_rounded,
        ),

        const SizedBox(height: 14),

        _fieldLabel('Password'),
        const SizedBox(height: 6),
        _PremiumTextField(
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

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _MiniCheckbox(
                  value: _rememberMe,
                  onChanged: (val) => setState(() => _rememberMe = val),
                ),
                const SizedBox(width: 6),
                const Text('Remember me',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textDark)),
              ],
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal),
              child: const Text('Forgot password?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),

        const SizedBox(height: 22),

        _PillSubmitButton(
          label: 'Sign In to Vivara',
          onPressed: () {
            final email = _signInEmailController.text.trim();
            final user = User(
              id: 'U_${DateTime.now().millisecondsSinceEpoch}',
              name: email.isEmpty ? 'Attending Physician' : email.split('@')[0],
              email: email.isEmpty ? 'doctor@alternea.org' : email,
              role: _mapToUserRole(_selectedRole),
              assignedPatientIds: const [],
              avatarUrl: 'https://i.pravatar.cc/150?img=12',
              title: _selectedRole.label,
            );
            appState.login(user);
          },
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // REGISTER
  // ------------------------------------------------------------------
  Widget _buildRegisterTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create your account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Registering as ${_selectedRole.label}',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
        ),
        const SizedBox(height: 18),

        _fieldLabel('Full Name'),
        const SizedBox(height: 6),
        _PremiumTextField(
          controller: _regNameController,
          hint: 'e.g. Dr. Ananya Sharma',
          icon: Icons.person_outline_rounded,
        ),

        const SizedBox(height: 12),

        _fieldLabel('Email Address'),
        const SizedBox(height: 6),
        _PremiumTextField(
          controller: _regEmailController,
          hint: 'asharma@alternea.org',
          icon: Icons.mail_outline_rounded,
        ),

        const SizedBox(height: 12),

        _fieldLabel('Password'),
        const SizedBox(height: 6),
        _PremiumTextField(
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

        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MiniCheckbox(
              value: _agreeTerms,
              onChanged: (val) => setState(() => _agreeTerms = val),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'I agree to Vivara Terms & Privacy Policy',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        _PillSubmitButton(
          label: 'Create ${_selectedRole.label} Account',
          onPressed: () {
            final name = _regNameController.text.trim().isEmpty
                ? 'Ananya Sharma'
                : _regNameController.text.trim();
            final email = _regEmailController.text.trim().isEmpty
                ? 'asharma@alternea.org'
                : _regEmailController.text.trim();

            appState.register(
              name: name,
              email: email,
              role: _mapToUserRole(_selectedRole),
            );
          },
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
      );
}

// ==========================================================================
// ROLE GRID — sleek 2x3-ish minimalist grid with organic hover/select motion
// ==========================================================================
class _RoleGrid extends StatelessWidget {
  final PharmacyRole selected;
  final ValueChanged<PharmacyRole> onSelect;

  const _RoleGrid({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        const cols = 3;
        final itemWidth =
            (constraints.maxWidth - spacing * (cols - 1)) / cols;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: PharmacyRole.values.map((role) {
            return SizedBox(
              width: itemWidth,
              child: _RoleCard(
                role: role,
                isSelected: role == selected,
                onTap: () => onSelect(role),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _RoleCard extends StatefulWidget {
  final PharmacyRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastOutSlowIn,
          tween: Tween<double>(
            begin: 1.0,
            end: isActive
                ? 1.06
                : (_hovering ? 1.03 : 1.0),
          ),
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(colors: AppColors.gradientPill)
                  : null,
              color: isActive
                  ? null
                  : (_hovering
                      ? AppColors.primaryLight.withOpacity(0.6)
                      : AppColors.bgSlate),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : (_hovering
                        ? AppColors.primaryTeal.withOpacity(0.35)
                        : AppColors.borderLight),
                width: 1.4,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryTeal.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.role.icon,
                  size: 20,
                  color: isActive ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.role.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? Colors.white : AppColors.textDark,
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

// ==========================================================================
// PREMIUM TEXT FIELD
// ==========================================================================
class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 13.5, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.7)),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primaryTeal),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.bgSlate,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.6),
        ),
      ),
    );
  }
}

// ==========================================================================
// MINI CHECKBOX (custom, matches the pill/rounded language)
// ==========================================================================
class _MiniCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MiniCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(colors: AppColors.gradientPill)
              : null,
          color: value ? null : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: value ? Colors.transparent : AppColors.borderLight,
            width: 1.4,
          ),
        ),
        child: value
            ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
            : null,
      ),
    );
  }
}

// ==========================================================================
// PILL SUBMIT BUTTON
// ==========================================================================
class _PillSubmitButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _PillSubmitButton({required this.label, required this.onPressed});

  @override
  State<_PillSubmitButton> createState() => _PillSubmitButtonState();
}

class _PillSubmitButtonState extends State<_PillSubmitButton> {
  bool _pressed = false;
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : (_hovering ? 1.01 : 1.0),
          duration: const Duration(milliseconds: 180),
          curve: Curves.fastOutSlowIn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradientPill),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withOpacity(0.35),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// LOW-POLY MEDICAL ILLUSTRATION — faceted cross + capsule + molecular bonds
// Static geometry (painted once); only the wrapping Transform.translate
// animates, keeping this a cheap, steady 60fps loop.
// ==========================================================================
class _LowPolyMedicalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.20), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.6));
    canvas.drawCircle(center, size.width * 0.6, glowPaint);

    _drawFacetedCross(canvas, center, size.width * 0.75);
    _drawCapsule(
      canvas,
      Offset(center.dx - size.width * 0.30, center.dy + size.height * 0.30),
      size.width * 0.34,
    );
    _drawMolecularBonds(canvas, size);
  }

  void _drawFacetedCross(Canvas canvas, Offset center, double armLength) {
    final armWidth = armLength * 0.40;
    final crossPath = Path()
      ..moveTo(center.dx - armWidth / 2, center.dy - armLength / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy - armLength / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy - armWidth / 2)
      ..lineTo(center.dx + armLength / 2, center.dy - armWidth / 2)
      ..lineTo(center.dx + armLength / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx + armWidth / 2, center.dy + armLength / 2)
      ..lineTo(center.dx - armWidth / 2, center.dy + armLength / 2)
      ..lineTo(center.dx - armWidth / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx - armLength / 2, center.dy + armWidth / 2)
      ..lineTo(center.dx - armLength / 2, center.dy - armWidth / 2)
      ..lineTo(center.dx - armWidth / 2, center.dy - armWidth / 2)
      ..close();

    final bounds = crossPath.getBounds();
    const cols = 7;
    const rows = 7;
    final cellW = bounds.width / cols;
    final cellH = bounds.height / rows;

    const baseColors = [
      Color(0xFFFF3D9A), // hot magenta
      Color(0xFF9B2FD6), // vivid purple
      Color(0xFFFF8A3D), // vivid orange
    ];

    int seed = 0;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final x = bounds.left + c * cellW;
        final y = bounds.top + r * cellH;
        final p1 = Offset(x, y);
        final p2 = Offset(x + cellW, y);
        final p3 = Offset(x, y + cellH);
        final p4 = Offset(x + cellW, y + cellH);

        final triA = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();
        final triB = Path()
          ..moveTo(p2.dx, p2.dy)
          ..lineTo(p4.dx, p4.dy)
          ..lineTo(p3.dx, p3.dy)
          ..close();

        final clippedA = Path.combine(PathOperation.intersect, triA, crossPath);
        final clippedB = Path.combine(PathOperation.intersect, triB, crossPath);

        final tA = (seed * 0.37) % 1.0;
        final colorA = Color.lerp(
                baseColors[seed % 3], baseColors[(seed + 1) % 3], tA)!
            .withOpacity(0.82 + 0.16 * ((seed % 4) / 4));
        seed++;

        final tB = (seed * 0.37) % 1.0;
        final colorB = Color.lerp(
                baseColors[seed % 3], baseColors[(seed + 1) % 3], tB)!
            .withOpacity(0.82 + 0.16 * ((seed % 4) / 4));
        seed++;

        canvas.drawPath(clippedA, Paint()..color = colorA);
        canvas.drawPath(clippedB, Paint()..color = colorB);
      }
    }

    canvas.drawPath(
      crossPath,
      Paint()
        ..color = Colors.white.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawCapsule(Canvas canvas, Offset pos, double length) {
    final rect =
        Rect.fromCenter(center: pos, width: length, height: length * 0.42);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2));
    final path = Path()..addRRect(rrect);

    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(-0.4);
    canvas.translate(-pos.dx, -pos.dy);

    final leftHalf = Path()
      ..addRect(Rect.fromLTRB(rect.left, rect.top, rect.center.dx, rect.bottom));
    final rightHalf = Path()
      ..addRect(Rect.fromLTRB(rect.center.dx, rect.top, rect.right, rect.bottom));

    canvas.drawPath(
      Path.combine(PathOperation.intersect, path, leftHalf),
      Paint()..color = const Color(0xFFFF8A3D).withOpacity(0.92),
    );
    canvas.drawPath(
      Path.combine(PathOperation.intersect, path, rightHalf),
      Paint()..color = Colors.white.withOpacity(0.92),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  void _drawMolecularBonds(Canvas canvas, Size size) {
    final nodes = [
      Offset(size.width * 0.16, size.height * 0.20),
      Offset(size.width * 0.30, size.height * 0.08),
      Offset(size.width * 0.88, size.height * 0.16),
      Offset(size.width * 0.92, size.height * 0.70),
      Offset(size.width * 0.12, size.height * 0.82),
      Offset(size.width * 0.72, size.height * 0.90),
    ];

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.4;

    canvas.drawLine(nodes[0], nodes[1], linePaint);
    canvas.drawLine(nodes[2], nodes[3], linePaint);
    canvas.drawLine(nodes[4], nodes[5], linePaint);

    const dotColors = [Colors.white, Color(0xFFFFD9EE), Color(0xFFFFE1C7)];
    for (int i = 0; i < nodes.length; i++) {
      canvas.drawCircle(
        nodes[i],
        5 + (i % 3) * 2,
        Paint()..color = dotColors[i % dotColors.length].withOpacity(0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}