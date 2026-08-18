import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _activeTabIndex = 0; // 0: Sign In, 1: Create Account

  final _signInEmailController =
      TextEditingController(text: 'doctor@alternea.org');
  final _signInPasswordController = TextEditingController(text: 'password123');
  bool _rememberMe = true;
  bool _obscureSignInPassword = true;

  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  UserRole _selectedRegRole = UserRole.doctor;
  bool _agreeTerms = true;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDesktop = MediaQuery.of(context).size.width >= 850;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF0D9488)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: isDesktop ? 900 : 460,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 36,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: isDesktop
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Clean Brand Hero Panel (No demo tiles)
                          Expanded(
                            flex: 5,
                            child: _buildBrandHeroPanel(),
                          ),
                          // Vertical Divider
                          Container(width: 1, color: AppColors.borderLight),
                          // Right Form Panel
                          Expanded(
                            flex: 6,
                            child: _buildFormPanel(context, appState),
                          ),
                        ],
                      ),
                    )
                  : _buildFormPanel(context, appState),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHeroPanel() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Brand Logo Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Alternea',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Healthcare Ecosystem',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryTeal,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Central Graphic Illustration Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: AppColors.primaryTeal,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Unified Clinical Platform',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Seamless digital prescriptions, hospital mapping, pharmacist dispensing, and interactive patient care.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Bottom HIPAA / Security Compliance Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.verified_user_rounded,
                    color: AppColors.primaryTeal, size: 18),
                SizedBox(width: 10),
                Text(
                  'HIPAA & Supabase Cloud Security',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabIndex = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 0 ? AppColors.primaryTeal : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _activeTabIndex == 0 ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTabIndex = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTabIndex == 1 ? AppColors.primaryTeal : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Create Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _activeTabIndex == 1 ? Colors.white : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _activeTabIndex == 0
              ? _buildSignInTab(context, appState)
              : _buildRegisterTab(context, appState),
        ],
      ),
    );
  }

  Widget _buildSignInTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign In',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.accentNavy,
          ),
        ),
        const SizedBox(height: 18),

        // Email Field
        const Text('Email Address',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _signInEmailController,
          decoration: const InputDecoration(
            hintText: 'e.g. doctor@alternea.org',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
          ),
        ),

        const SizedBox(height: 14),

        // Password Field
        const Text('Password',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: _signInPasswordController,
          obscureText: _obscureSignInPassword,
          decoration: InputDecoration(
            hintText: '••••••••••••',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignInPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscureSignInPassword = !_obscureSignInPassword;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Remember Me & Forgot Password
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  activeColor: AppColors.primaryTeal,
                  onChanged: (val) {
                    setState(() {
                      _rememberMe = val ?? true;
                    });
                  },
                ),
                const Text('Remember me', style: TextStyle(fontSize: 12)),
              ],
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Forgot password?',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () {
              final email = _signInEmailController.text.trim();
              final role = email.contains('pharmacist')
                  ? UserRole.pharmacist
                  : email.contains('patient')
                      ? UserRole.patient
                      : email.contains('insurance')
                          ? UserRole.insuranceAgent
                          : email.contains('admin')
                              ? UserRole.admin
                              : UserRole.doctor;

              final user = User(
                id: 'U_${DateTime.now().millisecondsSinceEpoch}',
                name: email.isEmpty ? 'Attending Physician' : email.split('@')[0],
                email: email.isEmpty ? 'doctor@alternea.org' : email,
                role: role,
                assignedPatientIds: [],
                avatarUrl: 'https://i.pravatar.cc/150?img=12',
                title: role.name,
              );
              appState.login(user);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Sign In to Alternea',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterTab(BuildContext context, AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.accentNavy,
          ),
        ),
        const SizedBox(height: 14),

        // Role Chips Selection
        const Text('Account Role',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),

        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildRoleChipCard('Doctor', UserRole.doctor, Icons.medical_services_outlined),
            _buildRoleChipCard('Pharmacist', UserRole.pharmacist, Icons.local_pharmacy_outlined),
            _buildRoleChipCard('Patient', UserRole.patient, Icons.person_outline),
            _buildRoleChipCard('Insurance', UserRole.insuranceAgent, Icons.shield_outlined),
            _buildRoleChipCard('Software Admin', UserRole.admin, Icons.admin_panel_settings_outlined),
          ],
        ),

        const SizedBox(height: 14),

        TextField(
          controller: _regNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'e.g. Dr. Ananya Sharma',
            prefixIcon: Icon(Icons.person_outline, size: 18),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _regEmailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'asharma@alternea.org',
            prefixIcon: Icon(Icons.email_outlined, size: 18),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: _regPasswordController,
          obscureText: _obscureRegPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'At least 8 characters',
            prefixIcon: const Icon(Icons.lock_outline, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureRegPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
              onPressed: () {
                setState(() {
                  _obscureRegPassword = !_obscureRegPassword;
                });
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Checkbox(
              value: _agreeTerms,
              activeColor: AppColors.primaryTeal,
              onChanged: (val) {
                setState(() {
                  _agreeTerms = val ?? true;
                });
              },
            ),
            const Expanded(
              child: Text(
                'I agree to Alternea Terms & Privacy Policy',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
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
                role: _selectedRegRole,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              'Create ${_selectedRegRole.name.toUpperCase()} Account',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChipCard(String label, UserRole role, IconData icon) {
    final isSelected = _selectedRegRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRegRole = role),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryTeal.withValues(alpha: 0.12)
              : AppColors.bgSlate,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryTeal : AppColors.borderLight,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primaryTeal : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
