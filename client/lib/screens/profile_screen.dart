import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _notificationsEnabled = true;

  String _getCleanInitials(String rawName, UserRole role) {
    final clean = rawName.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    final parts = clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) {
      final firstChar = parts[0][0];
      final secondChar = parts[1][0];
      if (RegExp(r'[a-zA-Z]').hasMatch(firstChar) && RegExp(r'[a-zA-Z]').hasMatch(secondChar)) {
        return '$firstChar$secondChar'.toUpperCase();
      }
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      final firstChar = parts[0][0];
      if (RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
        return '${firstChar}T'.toUpperCase();
      }
    }
    switch (role) {
      case UserRole.doctor:
        return 'DR';
      case UserRole.pharmacist:
        return 'PH';
      case UserRole.patient:
        return 'PT';
      case UserRole.insuranceAgent:
        return 'IN';
      case UserRole.admin:
        return 'AD';
    }
  }

  String _getCleanDisplayName(String rawName, UserRole role) {
    final clean = rawName.replaceAll(RegExp(r'\([^)]*\)'), '').trim();
    if (clean.isNotEmpty) return clean;
    return role.name.toUpperCase();
  }

  void _showEditProfileDialog(User user, AppState appState) {
    final nameController = TextEditingController(text: _getCleanDisplayName(user.name, user.role));
    final emailController = TextEditingController(text: user.email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit Profile Details',
          style: AppFonts.googleSans(fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_rounded, color: Color(0xFF1244A2)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address / User ID',
                prefixIcon: Icon(Icons.email_rounded, color: Color(0xFF1244A2)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppFonts.googleSans(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newEmail = emailController.text.trim();
              if (newName.isNotEmpty) {
                final updatedUser = User(
                  id: user.id,
                  name: newName,
                  email: newEmail.isNotEmpty ? newEmail : user.email,
                  role: user.role,
                  hospitalName: user.hospitalName,
                  title: user.title,
                );
                appState.updateUser(updatedUser);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile details updated successfully!'),
                  backgroundColor: Color(0xFF1244A2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1244A2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save Changes', style: AppFonts.googleSans(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.bgSlate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. High-Performance Sapphire Brand Hero Card (0ms Lag)
            _buildProfileHeroCard(user, appState),

            const SizedBox(height: 20),

            // 2. Bento Grid Details based on User Role
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 850;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _buildRoleSpecificBento(user)),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: _buildAccountSettingsBento(user, appState)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildRoleSpecificBento(user),
                          const SizedBox(height: 20),
                          _buildAccountSettingsBento(user, appState),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard(User user, AppState appState) {
    const brandColor = Color(0xFF1244A2);
    final initials = _getCleanInitials(user.name, user.role);
    final displayName = _getCleanDisplayName(user.name, user.role);
    final facilityName = user.hospitalName ?? 'MetroHealth Medical Center';

    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Avatar Initial Emblem Badge in #1244A2 Sapphire Palette
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandColor,
              boxShadow: [
                BoxShadow(
                  color: brandColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppFonts.googleSans(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 20),

          // User Info & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: AppFonts.googleSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: AppFonts.googleSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getUserSubtitle(user),
                  style: AppFonts.googleSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryTeal,
                  ),
                ),
                const SizedBox(height: 10),

                // Role & Facility Pills in #1244A2 Brand Palette
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: brandColor.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        'Role: ${user.roleLabel}',
                        style: AppFonts.googleSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: brandColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.lock_rounded, color: Color(0xFF64748B), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            facilityName,
                            style: AppFonts.googleSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Profile Action Button
          ElevatedButton.icon(
            onPressed: () => _showEditProfileDialog(user, appState),
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(
              'Edit Profile',
              style: AppFonts.googleSans(fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificBento(User user) {
    if (user.role == UserRole.doctor) {
      return _buildDoctorCredentialsBento(user);
    } else if (user.role == UserRole.pharmacist) {
      return _buildPharmacistCredentialsBento(user);
    } else if (user.role == UserRole.patient) {
      return _buildPatientHealthProfileBento(user);
    } else if (user.role == UserRole.insuranceAgent) {
      return _buildInsuranceCredentialsBento(user);
    } else {
      return _buildAdminCredentialsBento(user);
    }
  }

  // Doctor Credentials Bento
  Widget _buildDoctorCredentialsBento(User user) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_information_rounded, color: Color(0xFF1244A2), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Practitioner Credentials & Clinical Context',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 28),

          _buildStyledTileRow(Icons.local_hospital_rounded, 'Clinical Specialty', 'Chief of Cardiology & Internal Medicine'),
          _buildStyledTileRow(Icons.domain_rounded, 'Facility Context', user.hospitalName ?? 'MetroHealth Medical Center', isHighlight: true),
          _buildStyledTileRow(Icons.verified_rounded, 'NPI Registry Number', 'NPI-1982049182 (Verified National Registry)'),
          _buildStyledTileRow(Icons.card_membership_rounded, 'Medical Board License', 'NC Medical Board License #84920'),
          _buildStyledTileRow(Icons.local_pharmacy_rounded, 'Prescribing DEA Number', 'DEA License #BM4092102'),
          _buildStyledTileRow(Icons.insights_rounded, 'Daily Prescribing Output', '24 Prescriptions Issued Today • 8 Pending PA'),
        ],
      ),
    );
  }

  // Pharmacist Credentials Bento
  Widget _buildPharmacistCredentialsBento(User user) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_pharmacy_rounded, color: Color(0xFF1244A2), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Pharmacy License & Dispensing Metrics',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 28),

          _buildStyledTileRow(Icons.storefront_rounded, 'Pharmacy Location', user.hospitalName ?? 'MetroHealth Pharmacy Hub #402', isHighlight: true),
          _buildStyledTileRow(Icons.verified_user_rounded, 'PharmD License ID', 'NC State Board of Pharmacy License #PH-99201'),
          _buildStyledTileRow(Icons.assignment_turned_in_rounded, 'Controlled Substance License', 'DEA Dispenser Registration #BD9021820'),
          _buildStyledTileRow(Icons.speed_rounded, 'Dispense SLA Performance', '99.4% On-Time Fulfillment Accuracy Rate'),
          _buildStyledTileRow(Icons.inventory_2_rounded, 'Weekly Dispensed Count', '142 Prescriptions Processed & Dispensed'),
        ],
      ),
    );
  }

  // Patient Health Profile Bento
  Widget _buildPatientHealthProfileBento(User user) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.badge_rounded, color: Color(0xFF1244A2), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Patient Health Record & Insurance Coverage',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 28),

          _buildStyledTileRow(Icons.fingerprint_rounded, 'Medical Record Number (MRN)', 'PAT-301 (Verified System ID)', isHighlight: true),
          _buildStyledTileRow(Icons.person_pin_rounded, 'Primary Care Physician', 'Dr. Tariq Martin, MD (MetroHealth Cardiology)'),
          _buildStyledTileRow(Icons.health_and_safety_rounded, 'Insurance Plan Provider', 'Medicare Part D — SilverScript Choice (#MED-99201)'),
          _buildStyledTileRow(Icons.payments_rounded, 'Insurance Copay Tier', 'Tier 1 Generics (\$0.00) • Tier 2 Preferred (\$5.00)'),
          _buildStyledTileRow(Icons.warning_amber_rounded, 'Blood Type & Allergies', 'Blood Type: O+ Positive • Penicillin (Severe)'),
          _buildStyledTileRow(Icons.contact_phone_rounded, 'Emergency Contact', 'Sarah Rostova (Spouse) • (336) 555-0199'),
        ],
      ),
    );
  }

  // Insurance Credentials Bento
  Widget _buildInsuranceCredentialsBento(User user) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.verified_user_rounded, color: Color(0xFF1244A2), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Payer Credentials & Prior Auth Adjudication',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 28),

          _buildStyledTileRow(Icons.shield_rounded, 'Insurance Payer Network', 'SilverScript Choice Insurance Corp'),
          _buildStyledTileRow(Icons.badge_rounded, 'Agent Identifier', 'AG-88291 (Senior Adjudication Officer)'),
          _buildStyledTileRow(Icons.gavel_rounded, 'License Registration', 'NC Insurance Commissioner #30291'),
          _buildStyledTileRow(Icons.trending_up_rounded, 'Prior Auth Approval Rate', '96.4% Decision Velocity'),
          _buildStyledTileRow(Icons.timer_rounded, 'Average SLA Response Time', '4.2 Hours (Industry Benchmark: 48h)'),
        ],
      ),
    );
  }

  // Admin Credentials Bento
  Widget _buildAdminCredentialsBento(User user) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF1244A2), size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'System Administrator Privilege & Audit Log',
                style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
            ],
          ),
          const Divider(height: 28),

          _buildStyledTileRow(Icons.security_rounded, 'Access Control Level', 'Root System Administrator (Level 5)'),
          _buildStyledTileRow(Icons.dns_rounded, 'Database System State', 'Supabase Auth & PostgreSQL Multi-Tenant Active'),
          _buildStyledTileRow(Icons.phonelink_setup_rounded, 'Server Security Protocol', 'SSL/TLS Encrypted • JWT Session Management Active'),
        ],
      ),
    );
  }

  // Account Settings Bento
  Widget _buildAccountSettingsBento(User user, AppState appState) {
    return BentoCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Preferences & Security',
            style: AppFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const Divider(height: 24),

          // Notifications Switch
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: SwitchListTile(
              title: Text('Clinical Notification Alerts', style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800)),
              subtitle: Text('Receive immediate push alerts for Rx & PA updates', style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted)),
              value: _notificationsEnabled,
              activeColor: const Color(0xFF1244A2),
              onChanged: (val) => setState(() => _notificationsEnabled = val),
              contentPadding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(height: 14),

          // Persistent Sign-In Badge Tile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Single Sign-In Persistent Session',
                        style: AppFonts.googleSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF065F46)),
                      ),
                      Text(
                        'Session encrypted & stored via SharedPreferences',
                        style: AppFonts.googleSans(fontSize: 11, color: const Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Active',
                    style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Log Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                appState.logout();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFFEF2F2),
              ),
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 18),
              label: Text(
                'Log Out of Clinical Account',
                style: AppFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTileRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlight ? const Color(0xFF1244A2).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isHighlight ? const Color(0xFF1244A2) : AppColors.textMuted),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: AppFonts.googleSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppFonts.googleSans(
                fontSize: 12.5,
                fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
                color: isHighlight ? const Color(0xFF1244A2) : AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserSubtitle(User user) {
    switch (user.role) {
      case UserRole.doctor:
        return 'Chief of Cardiology • Prescribing Physician';
      case UserRole.pharmacist:
        return 'Lead Dispensing Pharmacist • Dispensary Hub';
      case UserRole.patient:
        return 'Registered Patient • Medicare Part D Subscriber';
      case UserRole.insuranceAgent:
        return 'Prior Authorization Senior Adjudicator';
      case UserRole.admin:
        return 'System Administrator & Security Operator';
    }
  }
}
