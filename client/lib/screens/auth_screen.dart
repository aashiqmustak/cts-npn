import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  int _activeTabIndex = 0; // 0: Sign In, 1: Create Account
  UserRole _selectedRole = UserRole.doctor;

  bool _otpSent = false;
  final _signInEmailController = TextEditingController();
  final _otpController = TextEditingController();

  final _regNameController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _agreeTerms = true;
  bool _isPatientLoginMode = false;
  Map<String, dynamic>? _verifiedUserMap;
  late PageController _pageController;
  Timer? _carouselTimer;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _regPasswordController.addListener(_onPasswordChanged);
    _pageController = PageController();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients) {
        final nextIndex = (_currentCarouselIndex + 1) % 3;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            if (isDesktop) {
              return Row(
                children: [
                  // Left Side — White Form Panel
                  Expanded(
                    flex: 5,
                    child: _buildLeftFormPanel(context, appState),
                  ),
                  // Right Side — Ice Blue Auto-Rotating Carousel Showcase
                  Expanded(flex: 6, child: _buildRightCarouselPanel()),
                ],
              );
            }

            // Mobile / Tablet Viewport
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
                    SizedBox(
                      height: 480,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _buildRightCarouselPanel(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
          'Alternea',
          style: AppFonts.googleSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Health',
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
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 56,
        vertical: isMobile ? 8 : 40,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isMobile) _buildBrandLogoHeader(),

          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _activeTabIndex == 0
                        ? 'Sign in to Alternea'
                        : 'Create an Account',
                    textAlign: TextAlign.center,
                    style: AppFonts.googleSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeTabIndex == 0
                        ? 'All Your Hospital & Pharmacy Needs in One Place.'
                        : 'Join the Alternea Intelligent Healthcare Ecosystem.',
                    textAlign: TextAlign.center,
                    style: AppFonts.googleSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _activeTabIndex == 0
                      ? _buildSignInTab(context, appState)
                      : _buildRegisterTab(context, appState),
                ],
              ),
            ),
          ),

          if (!isMobile) _buildTrustFooter(),
        ],
      ),
    );
  }

  Widget _buildRightCarouselPanel() {
    return Container(
      color: const Color(0xFFF4F7FC),
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
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
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: 3,
                onPageChanged: (index) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildCarouselSlide(index);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildCarouselDots(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselSlide(int index) {
    final slides = [
      {
        'title': 'Transform Hospital Management with a Single Robust Platform',
        'subtitle':
            'All your hospital\'s core operations, patients, staff, billing, and inventory, managed seamlessly in one place to boost efficiency and care.',
      },
      {
        'title': 'Accelerate Pharmacy Fulfillment & Adherence Telemetry',
        'subtitle':
            'Empower clinical pharmacists with automated prior authorization checks, step-therapy warnings, and intelligent drug substitutes.',
      },
      {
        'title': 'AI-Driven Intelligence & Zero-Trust Enterprise Security',
        'subtitle':
            'Protect sensitive clinical health records with state-of-the-art encryption while leveraging neural speech AI for hands-free charting.',
      },
    ];

    final slide = slides[index];

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildCarouselMockupContent(index),
            ),
          ),

          Column(
            children: [
              Text(
                slide['title']!,
                textAlign: TextAlign.center,
                style: AppFonts.googleSans(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.4,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                slide['subtitle']!,
                textAlign: TextAlign.center,
                style: AppFonts.googleSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselMockupContent(int index) {
    if (index == 0) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1244A2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Alternea Dashboard',
                      style: AppFonts.googleSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Live EHR Sync',
                    style: AppFonts.googleSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _mockMetricTile(
                    label: "Today's Appointments",
                    value: '255',
                    change: '+12.4%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mockMetricTile(
                    label: 'New Patients Today',
                    value: '98',
                    change: '+8.2%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _mockMetricTile(
                    label: 'Bed Occupancy',
                    value: '72%',
                    change: '-3.1%',
                    isPositive: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Appointments Schedule',
                      style: AppFonts.googleSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _mockTableRow(
                      'Emily Johnson',
                      'Cardiology',
                      'Dr. Robert Brown',
                      '10:30 AM',
                      'Confirmed',
                    ),
                    _mockTableRow(
                      'Michael Lee',
                      'Dermatology',
                      'Dr. Sarah Davis',
                      '11:00 AM',
                      'Confirmed',
                    ),
                    _mockTableRow(
                      'Jessica Taylor',
                      'Pediatrics',
                      'Dr. Karen White',
                      '01:15 PM',
                      'In-Progress',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (index == 1) {
      return Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Color(0xFF1244A2),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fulfillment Engine',
                      style: AppFonts.googleSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '94.2% PDC Adherence',
                    style: AppFonts.googleSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  _mockDispenseRow(
                    'Atorvastatin 20mg',
                    'Prescribed',
                    'Dr. Tariq Martin',
                    '\$42 Savings',
                  ),
                  const SizedBox(height: 8),
                  _mockDispenseRow(
                    'Metformin 500mg',
                    'Dispensed',
                    'Dr. Sarah Davis',
                    '\$18 Savings',
                  ),
                  const SizedBox(height: 8),
                  _mockDispenseRow(
                    'Lisnopril 10mg',
                    'Verified',
                    'Dr. Karen White',
                    '\$25 Savings',
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF1244A2),
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Zero-Trust Enterprise Vault',
            style: AppFonts.googleSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '256-Bit TLS Audit Log & HIPAA Compliance Verified',
            style: AppFonts.googleSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockMetricTile({
    required String label,
    required String value,
    required String change,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.googleSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: AppFonts.googleSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                change,
                style: AppFonts.googleSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color:
                      isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mockTableRow(
    String name,
    String dept,
    String doc,
    String time,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.googleSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              dept,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.googleSans(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            time,
            style: AppFonts.googleSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mockDispenseRow(
    String med,
    String status,
    String doc,
    String savings,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                med,
                style: AppFonts.googleSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                doc,
                style: AppFonts.googleSans(
                  fontSize: 9.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              savings,
              style: AppFonts.googleSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarouselDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isSelected = index == _currentCarouselIndex;
        return GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isSelected ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF1244A2)
                      : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTrustFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 14,
                color: Color(0xFF10B981),
              ),
              const SizedBox(width: 4),
              Text(
                '256-Bit TLS',
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 14,
                color: Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 4),
              Text(
                'HIPAA Audit',
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Container(width: 1, height: 12, color: const Color(0xFFCBD5E1)),
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 4),
              Text(
                'Zero-Trust',
                style: AppFonts.googleSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignInTab(BuildContext context, AppState appState) {
    if (!_otpSent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GlowBorderFormField(
            controller: _signInEmailController,
            label: 'Email',
            hint: 'jessicathompson@mail.com',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 16),

          _GradientBlueCtaButton(
            label: 'Verify User ID & Continue →',
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

          const SizedBox(height: 20),

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

          const SizedBox(height: 20),

          // Google Sign-In with actual 4-color Google logo strictly for patients
          GoogleSignInButton(
            text: 'Sign in with Google (Patients)',
            onPressed: () async {
              await appState.signInWithGooglePatient();
            },
          ),

          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an Account? ",
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
                    color: const Color(0xFF1244A2),
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
          label: 'FULL LEGAL NAME',
          hint: 'e.g. Dr. Ananya Sharma, MD',
          icon: Icons.badge_outlined,
        ),

        const SizedBox(height: 12),

        _GlowBorderFormField(
          controller: _regEmailController,
          label: 'PROFESSIONAL EMAIL',
          hint: 'you@domain.com',
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

            await appState.registerAccount(
              name: name,
              email: email,
              password: password,
              role: _selectedRole,
            );
          },
        ),

        const SizedBox(height: 10),
        _buildSecurityGuarantee(),
      ],
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
              UserRole.values.map((role) {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryTeal.withValues(alpha: 0.08),
            AppColors.primaryLight.withValues(alpha: 0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryTeal.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getRoleIcon(role), size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.googleSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children:
                badges.map((badge) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryTeal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: AppColors.primaryTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: AppFonts.googleSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryTeal,
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

class _GlowBorderFormField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: AppFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppFonts.googleSans(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}

class _GradientBlueCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _GradientBlueCtaButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
