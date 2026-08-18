import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/mock_data.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sign In Form Controllers
  User _selectedDemoUser = MockData.users[0]; // Sarah Jenkins
  final _signInEmailController =
      TextEditingController(text: 'sjenkins@pharmaassist.org');
  final _signInPasswordController = TextEditingController(text: '••••••••••••');
  bool _rememberMe = true;

  // Register Form Controllers
  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regConfirmPasswordController = TextEditingController();
  UserRole _selectedRegRole = UserRole.pharmacist;
  bool _agreeTerms = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      backgroundColor: AppColors.bgSlate,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Header Brand Banner
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'PharmaAssist',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentNavy,
                                ),
                              ),
                              Text(
                                'Smarter Medication Decisions',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Tab Bar Toggle (Sign In vs Register)
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.bgSlate,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: AppColors.primaryTeal,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Create Account'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderLight),

                // Form Tab Content Area
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: SizedBox(
                    height: 400,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Sign In Form
                        _buildSignInForm(context, appState),

                        // Tab 2: Register Account Form
                        _buildRegisterForm(context, appState),
                      ],
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

  Widget _buildSignInForm(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sign in to access your medication panel and formulary workspace.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),

          const SizedBox(height: 16),

          // Email Field
          const Text('Email Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _signInEmailController,
            decoration: const InputDecoration(
              hintText: 'name@pharmaassist.org',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 12),

          // Password Field
          const Text('Password',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _signInPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: '••••••••••••',
              prefixIcon: Icon(Icons.lock_outline, size: 18),
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
                    style: TextStyle(fontSize: 12, color: AppColors.primaryTeal)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Sign In Primary Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                appState.login(_selectedDemoUser);
              },
              child: const Text('Sign In to PharmaAssist'),
            ),
          ),

          const SizedBox(height: 18),

          // Demo Fast Login Switcher Section
          const Center(
            child: Text(
              '— OR FAST DEMO LOGIN AS —',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    appState.login(MockData.users[0]); // Sarah Jenkins (Pharmacist)
                  },
                  child: const Text('Pharmacist', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () {
                    appState.login(MockData.users[1]); // Mark Vance (Admin)
                  },
                  child: const Text('Administrator', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, AppState appState) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join PharmaAssist for smarter medication and formulary decisions.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),

          const SizedBox(height: 14),

          // Full Name
          const Text('Full Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _regNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Dr. Ananya Sharma',
              prefixIcon: Icon(Icons.person_outline, size: 18),
            ),
          ),

          const SizedBox(height: 10),

          // Email Address
          const Text('Work Email Address',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _regEmailController,
            decoration: const InputDecoration(
              hintText: 'asharma@pharmaassist.org',
              prefixIcon: Icon(Icons.email_outlined, size: 18),
            ),
          ),

          const SizedBox(height: 10),

          // Role Selection Dropdown
          const Text('Account Role',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<UserRole>(
            value: _selectedRegRole,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.shield_outlined, size: 18),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: UserRole.pharmacist,
                child: Text('Clinical Pharmacist (Panel & Adherence Monitoring)'),
              ),
              DropdownMenuItem(
                value: UserRole.admin,
                child: Text('Formulary Admin (File Ingestion & Analytics)'),
              ),
            ],
            onChanged: (role) {
              if (role != null) {
                setState(() {
                  _selectedRegRole = role;
                });
              }
            },
          ),

          const SizedBox(height: 10),

          // Password
          const Text('Create Password',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _regPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'At least 8 characters',
              prefixIcon: Icon(Icons.lock_outline, size: 18),
            ),
          ),

          const SizedBox(height: 10),

          // Terms Checkbox
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
                  'I agree to the Terms of Service & Privacy Policy',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Register Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                final name = _regNameController.text.isEmpty
                    ? 'Ananya Sharma'
                    : _regNameController.text;
                final email = _regEmailController.text.isEmpty
                    ? 'asharma@pharmaassist.org'
                    : _regEmailController.text;

                appState.register(
                  name: name,
                  email: email,
                  role: _selectedRegRole,
                );
              },
              child: const Text('Create PharmaAssist Account'),
            ),
          ),
        ],
      ),
    );
  }
}
