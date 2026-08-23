import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/main_layout.dart';

class PatientProfileCompletionScreen extends StatefulWidget {
  const PatientProfileCompletionScreen({super.key});

  @override
  State<PatientProfileCompletionScreen> createState() => _PatientProfileCompletionScreenState();
}

class _PatientProfileCompletionScreenState extends State<PatientProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _chronicConditionsController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDate;
  int _age = 0;

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_onAgeInputChanged);
  }

  void _onAgeInputChanged() {
    final parsed = int.tryParse(_ageController.text.trim());
    if (parsed != null && parsed > 0 && parsed != _age) {
      _age = parsed;
      if (_selectedDate == null) {
        final estYear = DateTime.now().year - parsed;
        _dobController.text = '$estYear-01-01';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _bloodGroupController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    super.dispose();
  }

  void _populateFields(AppState appState) {
    final profile = appState.currentUser.patientProfile;
    if (profile == null && _nameController.text.isNotEmpty) {
      return;
    }

    _nameController.text = profile?.name ?? appState.currentUser.name;
    _phoneController.text = profile?.phone ?? appState.currentUser.phone ?? '';
    _emailController.text = profile?.email ?? appState.currentUser.email;
    _addressController.text = profile?.address ?? '';
    _cityController.text = profile?.city ?? '';
    _heightController.text = profile?.height ?? '';
    _weightController.text = profile?.weight ?? '';
    _bloodGroupController.text = profile?.bloodGroup ?? '';
    _allergiesController.text = profile?.allergies ?? '';
    _chronicConditionsController.text = profile?.chronicConditions ?? '';
    _selectedGender = profile?.gender ?? 'Female';
    if (profile?.dateOfBirth != null) {
      _selectedDate = profile!.dateOfBirth;
      _dobController.text = _formatDate(_selectedDate!);
      _age = _calculateAge(_selectedDate!);
      _ageController.text = '$_age';
    } else if (profile?.age != null && profile!.age > 0) {
      _age = profile.age;
      _ageController.text = '$_age';
      final estYear = DateTime.now().year - _age;
      _dobController.text = '$estYear-01-01';
    } else {
      _dobController.clear();
      _ageController.clear();
      _age = 0;
    }
  }

  String _formatDate(DateTime dob) {
    final month = dob.month.toString().padLeft(2, '0');
    final day = dob.day.toString().padLeft(2, '0');
    return '${dob.year}-$month-$day';
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
      _dobController.text = _formatDate(picked);
      _age = _calculateAge(picked);
      _ageController.text = '$_age';
    });
  }

  void _submit(AppState appState) {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final height = _heightController.text.trim().isNotEmpty ? _heightController.text.trim() : "5'6\"";
    final weight = _weightController.text.trim().isNotEmpty ? _weightController.text.trim() : "145 lbs";
    final address = _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : "100 Healthcare Way";
    final city = _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : "Metro City";
    final bloodGroup = _bloodGroupController.text.trim().isNotEmpty ? _bloodGroupController.text.trim() : "O+";
    final allergies = _allergiesController.text.trim().isNotEmpty ? _allergiesController.text.trim() : "None";
    final chronicConditions = _chronicConditionsController.text.trim().isNotEmpty ? _chronicConditionsController.text.trim() : "None";
    final enteredAge = int.tryParse(_ageController.text.trim()) ?? _age;

    if (name.isEmpty) {
      _showMessage('Please enter your full legal name.');
      return;
    }

    if (enteredAge <= 0 && _dobController.text.trim().isEmpty && _selectedDate == null) {
      _showMessage('Please enter your age or date of birth.');
      return;
    }

    if (email.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    final dob = _selectedDate ?? DateTime.tryParse(_dobController.text.trim()) ?? DateTime(DateTime.now().year - (enteredAge > 0 ? enteredAge : 30), 1, 1);
    final effectiveAge = enteredAge > 0 ? enteredAge : _calculateAge(dob);

    final patientProfile = PatientProfile(
      patientId: appState.currentUser.patientId ?? appState.currentUser.id,
      name: name,
      dateOfBirth: dob,
      age: effectiveAge,
      gender: _selectedGender ?? 'Female',
      phone: phone.isNotEmpty ? phone : '+1 (555) 019-2831',
      email: email.isNotEmpty ? email : appState.currentUser.email,
      height: height,
      weight: weight,
      address: address,
      city: city,
      bloodGroup: bloodGroup,
      allergies: allergies,
      chronicConditions: chronicConditions,
    );

    appState.savePatientProfile(patientProfile);
    appState.setNavIndex(0);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (route) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryTeal,
        content: Text(
          message,
          style: AppFonts.googleSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    if (_nameController.text.isEmpty && _emailController.text.isEmpty) {
      _populateFields(appState);
    }

    return Scaffold(
      backgroundColor: AppColors.bgSlate,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentNavy.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: AppColors.gradientPill),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Complete Your Profile',
                                style: AppFonts.googleSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Finish your patient profile to unlock your dashboard.',
                                style: AppFonts.googleSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(width: 260, child: _buildField('Name', _nameController)),
                        SizedBox(width: 220, child: _buildDateField('DOB', _dobController, _pickDate)),
                        SizedBox(width: 120, child: _buildField('Age', _ageController, keyboardType: TextInputType.number)),
                        SizedBox(width: 180, child: _buildGenderField()),
                        SizedBox(width: 240, child: _buildField('Phone Number', _phoneController, keyboardType: TextInputType.phone)),
                        SizedBox(width: 260, child: _buildField('Email', _emailController, keyboardType: TextInputType.emailAddress)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Physical Information'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(width: 220, child: _buildField('Height', _heightController)),
                        SizedBox(width: 220, child: _buildField('Weight', _weightController)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Address'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(width: 420, child: _buildField('Address', _addressController)),
                        SizedBox(width: 220, child: _buildField('City', _cityController)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Medical Information'),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(width: 180, child: _buildField('Blood Group', _bloodGroupController)),
                        SizedBox(width: 340, child: _buildField('Allergies', _allergiesController)),
                        SizedBox(width: 340, child: _buildField('Chronic Conditions', _chronicConditionsController)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 220,
                        child: ElevatedButton(
                          onPressed: () => _submit(appState),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Save & Continue',
                            style: AppFonts.googleSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppFonts.googleSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.googleSans(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, VoidCallback onTap) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppFonts.googleSans(color: AppColors.textMuted, fontSize: 12),
        suffixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.primaryTeal),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGender,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: AppFonts.googleSans(color: AppColors.textMuted, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      items: const [
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
        DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
      ],
      onChanged: (value) => setState(() => _selectedGender = value),
    );
  }
}
