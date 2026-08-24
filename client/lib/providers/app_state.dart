import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/data_service.dart';
import '../services/web_audio.dart';

class ClinicalNotification {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color color;
  bool isRead;
  bool isDismissed;

  ClinicalNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.color,
    this.isRead = false,
    this.isDismissed = false,
  });
}

class PharmacyConnectionRequest {
  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String insuranceCompany;
  String status; // 'requested', 'accepted', 'rejected'
  final DateTime requestDate;

  PharmacyConnectionRequest({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.insuranceCompany,
    required this.status,
    required this.requestDate,
  });
}

class AppState extends ChangeNotifier {
  final DataService dataService = DataService();

  // Authentication State
  bool _isLoggedIn = false;
  late User _currentUser;

  // Navigation Index
  int _currentNavIndex = 0;
  bool _hasInteractedWithNav = false;
  bool get hasInteractedWithNav => _hasInteractedWithNav;
  int _activeSubTabIndex = 0;
  String? _selectedPrescriptionId;
  String? _evaluatingPrescriptionId;
  String? get evaluatingPrescriptionId => _evaluatingPrescriptionId;

  void setEvaluatingPrescriptionId(String? id) {
    _evaluatingPrescriptionId = id;
    notifyListeners();
  }

  // Search & Filter States
  String _globalSearchQuery = '';
  String _formularySearchQuery = '';
  int? _selectedTierFilter;
  String? _selectedPlanFilter;
  String? _selectedRestrictionFilter;

  double _pdcThreshold = 0.80;
  String _adherenceSearchQuery = '';
  RiskLevel? _selectedRiskFilter;
  String? _selectedDrugClassFilter;

  String _frictionSearchQuery = '';
  BarrierType? _selectedBarrierFilter;
  final List<ClinicalNotification> _userNotifications = [
    ClinicalNotification(
      id: 'N-INIT-1',
      title: 'Prior Auth Approved',
      subtitle: 'Amantadine 100mg PA #88201 approved by Medicare Part D.',
      time: '12m ago',
      icon: Icons.verified_rounded,
      color: const Color(0xFF10B981),
    ),
    ClinicalNotification(
      id: 'N-INIT-2',
      title: 'Pharmacy Fill Ready',
      subtitle: 'Lipitor 20mg fill available at CVS Pharmacy Hub #402.',
      time: '45m ago',
      icon: Icons.local_pharmacy_rounded,
      color: const Color(0xFF1244A2),
    ),
  ];

  List<ClinicalNotification> get notifications =>
      _userNotifications.where((n) => !n.isDismissed).toList();

  int get unreadNotificationsCount =>
      _userNotifications.where((n) => !n.isDismissed && !n.isRead).length;

  void addNotification(ClinicalNotification notification) {
    _userNotifications.insert(0, notification);
    notifyListeners();
  }

  void dismissNotification(String id) async {
    final idx = _userNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _userNotifications[idx].isDismissed = true;
      _userNotifications[idx].isRead = true;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        final dismissed = prefs.getStringList('dismissed_notifications') ?? [];
        if (!dismissed.contains(id)) {
          dismissed.add(id);
          await prefs.setStringList('dismissed_notifications', dismissed);
        }
      } catch (e) {
        debugPrint('Error persisting dismissed notification: $e');
      }
    }
  }

  void markAllNotificationsRead() {
    for (final n in _userNotifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  AppState() {
    _currentUser = const User(
      id: 'U_INIT',
      name: 'User Account',
      email: '',
      role: UserRole.pharmacist,
      assignedPatientIds: [],
      avatarUrl: '',
      title: 'Clinical Pharmacist',
      doctorId: 'DOC-201',
    );
    _loadSavedSession();
    refreshData();
  }

  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('user_session');
      if (sessionJson != null && sessionJson.isNotEmpty) {
        final map = jsonDecode(sessionJson) as Map<String, dynamic>;
        final loadedUser = User.fromJson(map);
        if (loadedUser.email.isNotEmpty && loadedUser.id.isNotEmpty && loadedUser.id != 'U_INIT') {
          _currentUser = loadedUser;
          _isLoggedIn = true;
        } else {
          _isLoggedIn = false;
        }
      } else {
        _isLoggedIn = false;
      }

      final dismissed = prefs.getStringList('dismissed_notifications') ?? [];
      for (final n in _userNotifications) {
        if (dismissed.contains(n.id)) {
          n.isDismissed = true;
          n.isRead = true;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring user session or dismissed notifications: $e');
    }
  }

  Future<void> updateUser(User user) async {
    _currentUser = user;
    _saveSession(user);
    if (dataService.supabaseService.isInitialized) {
      await dataService.supabaseService.upsertUserProfile(
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        hospitalName: user.hospitalName,
        hospitalId: user.hospitalId,
        doctorId: user.doctorId,
        role: user.role,
      );
    }
    notifyListeners();
  }

  Future<void> _saveSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
    } catch (e) {
      debugPrint('Error clearing user session: $e');
    }
  }

  Future<void> refreshData() async {
    await dataService.loadAllFromSupabase();
    notifyListeners();
  }

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  User get currentUser => _currentUser;
  int get currentNavIndex => _currentNavIndex;
  int get activeSubTabIndex => _activeSubTabIndex;
  String? get selectedPrescriptionId => _selectedPrescriptionId;
  double get pdcThreshold => _pdcThreshold;

  void setSelectedPrescriptionId(String? id) {
    _selectedPrescriptionId = id;
    notifyListeners();
  }

  String get globalSearchQuery => _globalSearchQuery;
  String get formularySearchQuery => _formularySearchQuery;
  int? get selectedTierFilter => _selectedTierFilter;
  String? get selectedPlanFilter => _selectedPlanFilter;
  String? get selectedRestrictionFilter => _selectedRestrictionFilter;

  String get adherenceSearchQuery => _adherenceSearchQuery;
  RiskLevel? get selectedRiskFilter => _selectedRiskFilter;
  String? get selectedDrugClassFilter => _selectedDrugClassFilter;

  String get frictionSearchQuery => _frictionSearchQuery;
  BarrierType? get selectedBarrierFilter => _selectedBarrierFilter;

  // Domain Getters
  List<Hospital> get hospitals => dataService.hospitals;
  List<Doctor> get doctors => dataService.doctors;
  List<PatientRecord> get patientRecords => dataService.patientRecords;
  List<PrescriptionItem> get prescriptionItems => dataService.prescriptionItems;
  List<PatientMedicineLog> get patientLogs => dataService.patientLogs;
  List<PharmacistDispenseRecord> get dispenseRecords =>
      dataService.dispenseRecords;
  List<Prescription> get prescriptions => dataService.prescriptions;

  // Connected Insurance Payers State
  final List<Map<String, dynamic>> insuranceCompanies = [
    {
      'name': 'SilverScript Choice',
      'logo': Icons.shield_rounded,
      'color': Colors.indigo,
      'plans': [
        {'id': 'P-001', 'name': 'SilverScript Choice Plan #MED-99201', 'type': 'Medicare Part D Prescription Drug Plan'},
        {'id': 'P-002', 'name': 'SilverScript Value Rx Plan', 'type': 'Value Prescription Plan'},
      ]
    },
    {
      'name': 'Aetna Medicare Advantage',
      'logo': Icons.health_and_safety_rounded,
      'color': Colors.red,
      'plans': [
        {'id': 'P-003', 'name': 'Aetna Medicare Saver Plus (PDP)', 'type': 'Saver Prescription Plan'},
        {'id': 'P-004', 'name': 'Aetna Rx Essential (PDP)', 'type': 'Essential Prescription Plan'},
      ]
    },
    {
      'name': 'UnitedHealthcare Rx',
      'logo': Icons.add_moderator_rounded,
      'color': Colors.blue,
      'plans': [
        {'id': 'P-005', 'name': 'UHC MedicareRx Preferred (PDP)', 'type': 'Preferred Prescription Plan'},
        {'id': 'P-006', 'name': 'UHC MedicareRx Saver (PDP)', 'type': 'Saver Prescription Plan'},
      ]
    },
    {
      'name': 'Blue Cross Blue Shield',
      'logo': Icons.security_rounded,
      'color': Colors.lightBlue,
      'plans': [
        {'id': 'P-007', 'name': 'BCBS Blue Medicare Rx (PDP)', 'type': 'Medicare Prescription Plan'},
        {'id': 'P-008', 'name': 'BCBS Blue Rx Value (PDP)', 'type': 'Value Prescription Plan'},
      ]
    },
    {
      'name': 'Cigna Medicare Rx',
      'logo': Icons.health_and_safety_outlined,
      'color': Colors.teal,
      'plans': [
        {'id': 'P-009', 'name': 'Cigna Secure Rx (PDP)', 'type': 'Secure Prescription Plan'},
        {'id': 'P-010', 'name': 'Cigna Extra Rx (PDP)', 'type': 'Extra Prescription Plan'},
      ]
    },
  ];

  final List<PharmacyConnectionRequest> _connectionRequests = [
    PharmacyConnectionRequest(
      id: 'CONN-001',
      pharmacyId: 'PHARM-001',
      pharmacyName: 'MetroHealth In-Network Pharmacy',
      insuranceCompany: 'SilverScript Choice',
      status: 'accepted',
      requestDate: DateTime.now().subtract(const Duration(days: 5)),
    ),
    PharmacyConnectionRequest(
      id: 'CONN-002',
      pharmacyId: 'PHARM-001',
      pharmacyName: 'MetroHealth In-Network Pharmacy',
      insuranceCompany: 'UnitedHealthcare Rx',
      status: 'requested',
      requestDate: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  List<PharmacyConnectionRequest> get connectionRequests => _connectionRequests;

  void requestConnection(String insuranceCompany) {
    final exists = _connectionRequests.any((req) => req.insuranceCompany == insuranceCompany);
    if (!exists) {
      _connectionRequests.add(
        PharmacyConnectionRequest(
          id: 'CONN-${DateTime.now().millisecondsSinceEpoch}',
          pharmacyId: 'PHARM-001',
          pharmacyName: 'MetroHealth In-Network Pharmacy',
          insuranceCompany: insuranceCompany,
          status: 'requested',
          requestDate: DateTime.now(),
        ),
      );
      notifyListeners();
    } else {
      final index = _connectionRequests.indexWhere((req) => req.insuranceCompany == insuranceCompany);
      if (index != -1 && _connectionRequests[index].status == 'rejected') {
        _connectionRequests[index].status = 'requested';
        notifyListeners();
      }
    }
  }

  void updateConnectionStatus(String requestId, String status) {
    final index = _connectionRequests.indexWhere((req) => req.id == requestId);
    if (index != -1) {
      _connectionRequests[index].status = status;
      notifyListeners();
    }
  }

  // Actions
  Future<void> dispenseItem(String itemId) async {
    await dataService.dispenseItem(
      itemId,
      pharmacistId: _currentUser.id,
      pharmacistName: _currentUser.name,
    );
    notifyListeners();
  }

  Future<void> createDoctorPrescription({
    required String patientId,
    required String doctorId,
    required String hospitalId,
    required String diagnosis,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    await dataService.createDoctorPrescription(
      patientId: patientId,
      doctorId: doctorId,
      hospitalId: hospitalId,
      diagnosis: diagnosis,
      notes: notes,
      items: items,
    );

    final firstDrugName = items.isNotEmpty ? items.first['medicineName'] : 'e-Prescription Payload';
    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '⚡ New e-Prescription Issued',
        subtitle: 'Dr. Tariq Martin issued e-Rx for $firstDrugName ($diagnosis). Available in Medicine Cabinet.',
        time: 'Just now',
        icon: Icons.edit_note_rounded,
        color: const Color(0xFF1244A2),
      ),
    );
    notifyListeners();
  }

  Future<void> togglePatientLog(String logId, bool isTaken) async {
    await dataService.togglePatientLog(logId, isTaken);
    notifyListeners();
  }

  void updatePrescriptionStatus(String rxId, String status) {
    dataService.updatePrescriptionStatus(rxId, status);
    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '📋 Prescription Status Updated',
        subtitle: 'Prescription $rxId status updated to "$status".',
        time: 'Just now',
        icon: Icons.sync_alt_rounded,
        color: const Color(0xFF10B981),
      ),
    );
    notifyListeners();
  }

  void resolveFrictionEvent(String frictionId) {
    dataService.resolveFrictionEvent(frictionId);
    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '✅ Prior Auth Approved',
        subtitle: 'Claim bottleneck $frictionId resolved. Prescription unblocked for dispensing.',
        time: 'Just now',
        icon: Icons.verified_rounded,
        color: const Color(0xFF10B981),
      ),
    );
    notifyListeners();
  }

  void requestPrescriptionRefill(String rxId) {
    dataService.requestPrescriptionRefill(rxId);
    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '🔄 Refill Request Dispatched',
        subtitle: 'Patient requested refill for Rx $rxId. Sent to Pharmacist Queue.',
        time: 'Just now',
        icon: Icons.autorenew_rounded,
        color: const Color(0xFF1244A2),
      ),
    );
    notifyListeners();
  }

  void addHospital(Hospital hospital) {
    dataService.addHospital(hospital);
    notifyListeners();
  }

  void deleteHospital(String id) {
    dataService.deleteHospital(id);
    notifyListeners();
  }

  Map<String, dynamic> checkUserIdentifier(String identifier) {
    final clean = identifier.trim().toLowerCase();
    if (clean.isEmpty) return {'exists': false};

    final match = dataService.users.firstWhere(
      (u) =>
          u.id.toLowerCase() == clean ||
          u.email.toLowerCase() == clean ||
          (u.phone != null && u.phone!.toLowerCase().contains(clean)) ||
          (u.patientId != null && u.patientId!.toLowerCase() == clean) ||
          (u.doctorId != null && u.doctorId!.toLowerCase() == clean),
      orElse: () => const User(
        id: '',
        name: '',
        email: '',
        role: UserRole.patient,
        assignedPatientIds: [],
        avatarUrl: '',
        title: '',
      ),
    );

    if (match.id.isNotEmpty) {
      return {
        'exists': true,
        'user': match,
        'name': match.name,
        'role': match.role.label,
        'email': match.email,
        'phone': match.phone,
      };
    }

    return {'exists': false};
  }

  // Auth Actions
  void login(User user) {
    _currentUser = user;
    _isLoggedIn = true;
    _currentNavIndex = 0;
    _saveSession(user);
    notifyListeners();
  }

  Future<bool> sendOtp(String email) async {
    if (email.isNotEmpty) {
      await dataService.supabaseService.sendOtpCode(email);
    }
    return true;
  }

  Future<bool> verifyOtp({required String email, required String otp}) async {
    return await dataService.supabaseService.verifyOtpCode(
      email: email,
      otp: otp,
    );
  }

  Future<bool> verifyDoctorLicense({
    required String email,
    required String licenseNumber,
  }) async {
    return await dataService.supabaseService.verifyDoctorLicense(
      email: email,
      licenseNumber: licenseNumber,
    );
  }

  Future<bool> verifyOtpAndLogin({
    required String email,
    required String otp,
    bool isPatient = false,
  }) async {
    final isValid = await dataService.supabaseService.verifyOtpCode(
      email: email,
      otp: otp,
    );

    if (!isValid) {
      return false;
    }

    if (dataService.supabaseService.isInitialized) {
      try {
        final profile = await dataService.supabaseService.fetchUserProfile(email);
        if (profile != null) {
          login(profile);
          return true;
        }
      } catch (_) {}
    }

    final inputClean = email.trim();
    final lower = inputClean.toLowerCase();
    final isPhoneOrMrn = isPatient ||
        !lower.contains('@') ||
        lower.startsWith('pat') ||
        RegExp(r'^[0-9\+\-\s\(\)]+$').hasMatch(lower);

    final existingUser = dataService.users.firstWhere(
      (u) =>
          u.id.toLowerCase() == lower ||
          u.email.toLowerCase() == lower ||
          (u.phone != null && u.phone!.toLowerCase().contains(lower)) ||
          (u.patientId != null && u.patientId!.toLowerCase() == lower) ||
          (u.doctorId != null && u.doctorId!.toLowerCase() == lower),
      orElse: () {
        UserRole targetRole = isPhoneOrMrn ? UserRole.patient : UserRole.doctor;
        if (lower.contains('pharmacist') || lower.contains('pharm')) {
          targetRole = UserRole.pharmacist;
        } else if (lower.contains('doctor') || lower.contains('doc')) {
          targetRole = UserRole.doctor;
        } else if (lower.contains('admin')) {
          targetRole = UserRole.admin;
        } else if (lower.contains('insurance') || lower.contains('ins')) {
          targetRole = UserRole.insuranceAgent;
        }

        final displayName = targetRole == UserRole.patient
            ? 'Patient (MRN: ${inputClean.isEmpty ? 'PT-301' : inputClean})'
            : (targetRole == UserRole.pharmacist
                ? 'Pharmacist (ID: $inputClean)'
                : (inputClean.isEmpty ? 'Authorized Practitioner' : inputClean.split('@')[0]));

        return User(
          id: 'U_${DateTime.now().millisecondsSinceEpoch}',
          name: displayName,
          email: lower.contains('@') ? lower : 'user_${DateTime.now().millisecondsSinceEpoch}@alternea.health',
          phone: isPhoneOrMrn ? inputClean : null,
          role: targetRole,
          assignedPatientIds: const ['PT-301', 'PT-302'],
          avatarUrl: '',
          title: _getRoleTitle(targetRole),
          patientId: targetRole == UserRole.patient ? 'PT-301' : null,
          doctorId: targetRole == UserRole.doctor ? 'DOC-201' : null,
          hospitalId: 'HOSP-101',
          hospitalName: 'MetroHealth Medical Center',
        );
      },
    );
    login(existingUser);
    return true;
  }

  Future<void> signInWithGooglePatient() async {
    if (dataService.supabaseService.isInitialized) {
      try {
        await dataService.supabaseService.signInWithGoogle();
      } catch (e) {
        debugPrint('Supabase Google OAuth error: $e');
      }
    }

    // Authenticate as a Patient account
    final patientUser = dataService.users.firstWhere(
      (u) => u.role == UserRole.patient,
      orElse: () => const User(
        id: 'U_GOOGLE_PATIENT',
        name: 'Jessica Thompson',
        email: 'jessica.thompson@gmail.com',
        phone: '+1 (555) 234-5678',
        role: UserRole.patient,
        assignedPatientIds: ['PT-301'],
        avatarUrl: '',
        title: 'Patient Account',
        patientId: 'PT-301',
        hospitalId: 'HOSP-101',
        hospitalName: 'MetroHealth Medical Center',
      ),
    );

    login(patientUser);
  }

  Future<bool> registerAccount({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? hospitalId,
    String? hospitalName,
    String? specialty,
    String? insuranceCompany,
    List<String> insurancePlans = const [],
    List<String> insuranceMedicines = const [],
    List<String> insuranceHospitals = const [],
  }) async {
    if (dataService.supabaseService.isInitialized && password.isNotEmpty) {
      try {
        final authRes = await dataService.supabaseService.signUp(
          email: email,
          password: password,
          name: name,
          role: role,
          hospitalId: hospitalId,
          hospitalName: hospitalName,
          specialty: specialty,
        );
        if (authRes?.user != null) {
          final doctorRecordId = role == UserRole.doctor
              ? 'DOC-${authRes!.user!.id.replaceAll('-', '').substring(0, 8).toUpperCase()}'
              : null;

          final profile = User(
            id: authRes!.user!.id,
            name: name,
            email: email,
            role: role,
            assignedPatientIds: const ['PT-301', 'PT-302'],
            avatarUrl: '',
            title: (specialty != null && specialty.isNotEmpty) ? specialty : _getRoleTitle(role),
            hospitalId: hospitalId,
            hospitalName: hospitalName,
            doctorId: doctorRecordId,
            insuranceCompany: insuranceCompany,
            insurancePlans: insurancePlans,
            insuranceMedicines: insuranceMedicines,
            insuranceHospitals: insuranceHospitals,
          );

          if (role == UserRole.doctor && doctorRecordId != null) {
            final docModel = Doctor(
              id: doctorRecordId,
              name: name,
              specialty: (specialty != null && specialty.isNotEmpty) ? specialty : 'General Practice',
              email: email,
              phone: '',
              hospitalId: hospitalId ?? '',
              hospitalName: hospitalName,
            );
            dataService.addDoctor(docModel);
          }

          login(profile);
          return true;
        }
      } catch (e) {
        // Fall back to local creation if Supabase signUp fails or already exists
      }
    }

    register(
      name: name,
      email: email,
      role: role,
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      specialty: specialty,
      insuranceCompany: insuranceCompany,
      insurancePlans: insurancePlans,
      insuranceMedicines: insuranceMedicines,
      insuranceHospitals: insuranceHospitals,
    );
    return true;
  }

  void register({
    required String name,
    required String email,
    required UserRole role,
    String? hospitalId,
    String? hospitalName,
    String? specialty,
    String? insuranceCompany,
    List<String> insurancePlans = const [],
    List<String> insuranceMedicines = const [],
    List<String> insuranceHospitals = const [],
  }) {
    final doctorRecordId = role == UserRole.doctor
        ? 'DOC-${DateTime.now().millisecondsSinceEpoch}'
        : null;

    final newUser = User(
      id: 'U_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
      assignedPatientIds: const ['PT-301', 'PT-302'],
      avatarUrl: '',
      title: (specialty != null && specialty.isNotEmpty) ? specialty : _getRoleTitle(role),
      hospitalId: hospitalId,
      hospitalName: hospitalName,
      doctorId: doctorRecordId,
      insuranceCompany: insuranceCompany,
      insurancePlans: insurancePlans,
      insuranceMedicines: insuranceMedicines,
      insuranceHospitals: insuranceHospitals,
    );

    if (role == UserRole.doctor && doctorRecordId != null) {
      final docModel = Doctor(
        id: doctorRecordId,
        name: name,
        specialty: (specialty != null && specialty.isNotEmpty) ? specialty : 'General Practice',
        email: email,
        phone: '',
        hospitalId: hospitalId ?? '',
        hospitalName: hospitalName,
      );
      dataService.addDoctor(docModel);
    }

    dataService.addUser(newUser);
    _currentUser = newUser;
    _isLoggedIn = true;
    _currentNavIndex = 0;
    notifyListeners();
  }

  Future<void> updateInsuranceAgentDetails({
    required String company,
    required List<String> plans,
    List<String> medicines = const [],
    List<String> hospitals = const [],
  }) async {
    _currentUser = _currentUser.copyWith(
      insuranceCompany: company,
      insurancePlans: plans,
      insuranceMedicines: medicines,
      insuranceHospitals: hospitals,
    );
    notifyListeners();

    // 1. Save session to local storage
    await _saveSession(_currentUser);

    // 2. Persist to Supabase DB if client is connected
    try {
      if (dataService.supabaseService.isInitialized && _currentUser.id.isNotEmpty) {
        await dataService.supabaseService.upsertUserProfile(
          id: _currentUser.id,
          email: _currentUser.email,
          name: _currentUser.name,
          role: _currentUser.role,
          insuranceCompany: company,
          insurancePlans: plans,
          insuranceMedicines: medicines,
          insuranceHospitals: hospitals,
        );
      }
    } catch (e) {
      debugPrint('Failed to update insurance agent details in DB: $e');
    }
  }

  String _getRoleTitle(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.insuranceAgent:
        return 'Insurance Specialist';
      case UserRole.doctor:
        return 'Attending Physician';
      case UserRole.pharmacist:
        return 'Clinical Pharmacist';
      case UserRole.patient:
        return 'Patient Account';
    }
  }

  void switchRole(UserRole newRole) {
    String name = newRole.label;
    String email = '';
    String title = _getRoleTitle(newRole);

    _currentUser = User(
      id: 'U_${newRole.name.toUpperCase()}',
      name: name,
      email: email,
      role: newRole,
      assignedPatientIds: const ['PT-301', 'PT-302'],
      avatarUrl: '',
      title: title,
      doctorId: (newRole == UserRole.doctor || newRole == UserRole.pharmacist) ? 'DOC-201' : null,
      patientId: newRole == UserRole.patient ? 'PT-301' : null,
      hospitalId: 'HOSP-101',
      hospitalName: 'MetroHealth Medical Center',
    );
    _currentNavIndex = 0;
    _selectedPrescriptionId = null;
    _saveSession(_currentUser);
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _clearSession();
    notifyListeners();
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    _currentNavIndex = 0;
    _hasInteractedWithNav = false;
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
    _hasInteractedWithNav = true;
    notifyListeners();
  }

  void setActiveSubTabIndex(int index) {
    _activeSubTabIndex = index;
    notifyListeners();
  }

  void setGlobalSearchQuery(String query) {
    _globalSearchQuery = query;
    _formularySearchQuery = query;
    _adherenceSearchQuery = query;
    _frictionSearchQuery = query;
    notifyListeners();
  }

  void setPdcThreshold(double value) {
    _pdcThreshold = value;
    dataService.setPdcThreshold(value);
    notifyListeners();
  }

  void setFormularySearchQuery(String query) {
    _formularySearchQuery = query;
    notifyListeners();
  }

  void setTierFilter(int? tier) {
    _selectedTierFilter = tier;
    notifyListeners();
  }

  void setPlanFilter(String? planId) {
    _selectedPlanFilter = planId;
    notifyListeners();
  }

  void setRestrictionFilter(String? restriction) {
    _selectedRestrictionFilter = restriction;
    notifyListeners();
  }

  List<Drug> get filteredDrugs {
    return dataService.drugs.where((drug) {
      if (_formularySearchQuery.isNotEmpty) {
        final query = _formularySearchQuery.toLowerCase();
        final matches =
            drug.name.toLowerCase().contains(query) ||
            drug.ndc.contains(query) ||
            drug.drugClass.toLowerCase().contains(query);
        if (!matches) return false;
      }
      if (_selectedTierFilter != null && drug.tier != _selectedTierFilter) {
        return false;
      }
      if (_selectedPlanFilter != null &&
          _selectedPlanFilter!.isNotEmpty &&
          drug.planId != _selectedPlanFilter) {
        return false;
      }
      if (_selectedRestrictionFilter != null) {
        if (_selectedRestrictionFilter == 'PA' && !drug.requiresPa) {
          return false;
        }
        if (_selectedRestrictionFilter == 'ST' && !drug.stepTherapy) {
          return false;
        }
        if (_selectedRestrictionFilter == 'QL' && !drug.quantityLimit) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setAdherenceSearchQuery(String query) {
    _adherenceSearchQuery = query;
    notifyListeners();
  }

  void setAdherenceRiskFilter(RiskLevel? risk) {
    _selectedRiskFilter = risk;
    notifyListeners();
  }

  void setAdherenceDrugClassFilter(String? drugClass) {
    _selectedDrugClassFilter = drugClass;
    notifyListeners();
  }

  List<AdherenceFlag> get filteredAdherenceFlags {
    return dataService.getFilteredAdherenceFlags(
      searchQuery: _adherenceSearchQuery,
      selectedRisk: _selectedRiskFilter,
      selectedDrugClass: _selectedDrugClassFilter,
      assignedPatientIds:
          _currentUser.isPharmacist ? _currentUser.assignedPatientIds : null,
    );
  }

  void setFrictionSearchQuery(String query) {
    _frictionSearchQuery = query;
    notifyListeners();
  }

  void setFrictionBarrierFilter(BarrierType? barrier) {
    _selectedBarrierFilter = barrier;
    notifyListeners();
  }

  List<PAFrictionEvent> get filteredFrictionEvents {
    return dataService.paFrictionEvents.where((event) {
      if (_currentUser.isPharmacist &&
          !_currentUser.assignedPatientIds.contains(event.patientId)) {
        return false;
      }
      if (_frictionSearchQuery.isNotEmpty) {
        final query = _frictionSearchQuery.toLowerCase();
        final matches =
            event.patientName.toLowerCase().contains(query) ||
            event.drugName.toLowerCase().contains(query) ||
            (event.suggestedAltName?.toLowerCase().contains(query) ?? false);
        if (!matches) return false;
      }
      if (_selectedBarrierFilter != null &&
          event.barrierType != _selectedBarrierFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  void updateOutreachStatus(
    String flagId,
    OutreachStatus status,
    String? notes,
  ) {
    dataService.updateOutreachStatus(flagId, status, notes);
    notifyListeners();
  }

  void updateFrictionStatus(String frictionId, FrictionStatus status) {
    dataService.updateFrictionStatus(frictionId, status);
    notifyListeners();
  }

  void switchPrescriptionToAlternative({
    required String rxId,
    required String alternativeDrugName,
    required String newDosage,
    required double newCopay,
  }) {
    dataService.switchPrescriptionToAlternative(
      rxId: rxId,
      alternativeDrugName: alternativeDrugName,
      newDosage: newDosage,
      newCopay: newCopay,
    );
    addNotification(
      ClinicalNotification(
        id: 'N-${DateTime.now().millisecondsSinceEpoch}',
        title: 'Alternative Regimen Switched',
        subtitle: 'Prescription #$rxId switched to $alternativeDrugName (Tier 1 Preferred, \$${newCopay.toStringAsFixed(2)} Copay).',
        time: 'Just now',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF10B981),
      ),
    );
    notifyListeners();
  }

  void simulateFileUpload(String filename) {
    dataService.simulateFormularyFileUpload(filename, _currentUser.name);
    notifyListeners();
  }

  void addUser(User newUser) {
    dataService.addUser(newUser);
    notifyListeners();
  }

  void updateTierCopay(int tier, double copay, double coinsurance) {
    dataService.updateTierCopay(tier, copay, coinsurance);
    notifyListeners();
  }

  Future<void> updatePharmacistDoctor(String? doctorId) async {
    final updatedUser = User(
      id: _currentUser.id,
      name: _currentUser.name,
      email: _currentUser.email,
      phone: _currentUser.phone,
      role: _currentUser.role,
      assignedPatientIds: _currentUser.assignedPatientIds,
      avatarUrl: _currentUser.avatarUrl,
      title: _currentUser.title,
      hospitalId: _currentUser.hospitalId,
      hospitalName: _currentUser.hospitalName,
      doctorId: doctorId,
      patientId: _currentUser.patientId,
    );
    _currentUser = updatedUser;
    _saveSession(updatedUser);

    if (dataService.supabaseService.isInitialized) {
      await dataService.supabaseService.upsertUserProfile(
        id: updatedUser.id,
        email: updatedUser.email,
        name: updatedUser.name,
        phone: updatedUser.phone,
        hospitalName: updatedUser.hospitalName,
        hospitalId: updatedUser.hospitalId,
        doctorId: updatedUser.doctorId,
        role: updatedUser.role,
      );
    }

    notifyListeners();
  }

  // --- Alternative Drug Approvals Pipeline (Doctor-to-Pharmacy) ---
  List<AlternativeApprovalRequest> get alternativeApprovalRequests =>
      dataService.alternativeApprovalRequests;

  List<AlternativeApprovalRequest> get pendingAlternativeApprovalRequests =>
      dataService.alternativeApprovalRequests.where((r) => r.isPending).toList();

  List<AlternativeApprovalRequest> get approvedAlternativeHistory =>
      dataService.alternativeApprovalRequests
          .where((r) => r.isApproved || r.isDispensed || r.status == 'approved' || r.status == 'dispensed')
          .toList();

  List<AlternativeApprovalRequest> get allAlternativeHistory =>
      dataService.alternativeApprovalRequests
          .where((r) => !r.isPending)
          .toList();

  AlternativeApprovalRequest? _latestApprovedRequest;
  AlternativeApprovalRequest? get latestApprovedRequest => _latestApprovedRequest;

  void clearLatestApprovedRequest() {
    _latestApprovedRequest = null;
    notifyListeners();
  }

  void sendAlternativeToDoctor({
    required String rxId,
    required String patientId,
    required String patientName,
    required int patientAge,
    required String doctorId,
    required String doctorName,
    required String indication,
    required String originalDrug,
    required int originalTier,
    required double originalCopay,
    required String recommendedAlternative,
    required int alternativeTier,
    required double alternativeCopay,
    required String clinicalClass,
    required String clinicalRationale,
  }) {
    final req = AlternativeApprovalRequest(
      id: 'REQ-${DateTime.now().millisecondsSinceEpoch}',
      prescriptionId: rxId,
      patientId: patientId,
      patientName: patientName,
      patientAge: patientAge,
      doctorId: doctorId,
      doctorName: doctorName,
      indication: indication,
      originalDrug: originalDrug,
      originalTier: originalTier,
      originalCopay: originalCopay,
      recommendedAlternative: recommendedAlternative,
      alternativeTier: alternativeTier,
      alternativeCopay: alternativeCopay,
      clinicalClass: clinicalClass,
      clinicalRationale: clinicalRationale,
      status: 'pending',
      requestedAt: DateTime.now(),
    );

    dataService.addAlternativeApprovalRequest(req);
    dataService.supabaseService.saveAlternativeApproval(req);

    final docVoice =
        'Notification: You have received an alternative drug approval request from the pharmacy for patient $patientName for medication $recommendedAlternative.';
    playWebAudio(null, docVoice);

    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '📋 Alternative Drug Approval Requested',
        subtitle: 'Pharmacist sent AI-recommended alternative ($recommendedAlternative) for $patientName to $doctorName for review.',
        time: 'Just now',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF8B5CF6),
      ),
    );

    notifyListeners();
  }

  void approveAlternativeDrug({
    required String requestId,
    String? doctorNote,
  }) {
    final req = alternativeApprovalRequests.firstWhere(
      (r) => r.id == requestId,
      orElse: () => AlternativeApprovalRequest(
        id: requestId,
        prescriptionId: '',
        patientId: '',
        patientName: 'Patient',
        patientAge: 45,
        doctorId: '',
        doctorName: 'Doctor',
        indication: '',
        originalDrug: '',
        originalTier: 2,
        originalCopay: 45.0,
        recommendedAlternative: '',
        alternativeTier: 1,
        alternativeCopay: 10.0,
        clinicalClass: '',
        clinicalRationale: '',
        requestedAt: DateTime.now(),
      ),
    );

    dataService.updateAlternativeApprovalStatus(requestId, 'approved', note: doctorNote);
    dataService.supabaseService.saveAlternativeApproval(req);
    _latestApprovedRequest = req;

    final voiceMessage =
        'Notification: Dr. ${req.doctorName} has approved the alternative medication, ${req.recommendedAlternative}, for patient ${req.patientName}. Ready for dispense.';

    // Play Voice TTS Announcement across system
    playWebAudio(null, voiceMessage);

    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '✅ Doctor Approved Alternative Regimen',
        subtitle: 'Dr. ${req.doctorName} approved ${req.recommendedAlternative} for ${req.patientName} (\$${req.monthlySavings.toStringAsFixed(2)}/mo savings). Ready to dispense.',
        time: 'Just now',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
      ),
    );

    notifyListeners();
  }

  void denyAlternativeDrug({
    required String requestId,
    String? doctorNote,
  }) {
    final req = alternativeApprovalRequests.firstWhere((r) => r.id == requestId);
    dataService.updateAlternativeApprovalStatus(requestId, 'denied', note: doctorNote);
    dataService.supabaseService.saveAlternativeApproval(req);

    final voiceMessage =
        'Notification: Dr. ${req.doctorName} has denied the alternative medication for patient ${req.patientName}. Please dispense original prescription.';
    playWebAudio(null, voiceMessage);

    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '⚠️ Alternative Regimen Denied by Physician',
        subtitle: 'Dr. ${req.doctorName} requested original prescription ${req.originalDrug} be dispensed for ${req.patientName}.',
        time: 'Just now',
        icon: Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
      ),
    );

    notifyListeners();
  }

  void dispenseApprovedAlternative({
    required String requestId,
  }) {
    final req = alternativeApprovalRequests.firstWhere((r) => r.id == requestId);
    switchPrescriptionToAlternative(
      rxId: req.prescriptionId,
      alternativeDrugName: req.recommendedAlternative,
      newDosage: '1 Tablet (Oral)',
      newCopay: req.alternativeCopay,
    );

    // Dispense in pharmacist ledger
    dataService.updateAlternativeApprovalStatus(requestId, 'dispensed');
    dataService.supabaseService.saveAlternativeApproval(req);
    _latestApprovedRequest = null;

    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '🎉 Approved Alternative Dispensed',
        subtitle: 'Successfully dispensed ${req.recommendedAlternative} for ${req.patientName}. Copay: \$${req.alternativeCopay.toStringAsFixed(2)}.',
        time: 'Just now',
        icon: Icons.local_pharmacy_rounded,
        color: const Color(0xFF10B981),
      ),
    );

    notifyListeners();
  }

  Future<void> generateAndSendAlternatePrescription({
    required AlternativeApprovalRequest req,
    String? pharmacistNote,
  }) async {
    final rxId = req.prescriptionId.isNotEmpty && !req.prescriptionId.startsWith('ALT')
        ? req.prescriptionId
        : 'RX-ALT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final altItem = PrescriptionItem(
      id: 'ITEM-ALT-${DateTime.now().millisecondsSinceEpoch}',
      prescriptionId: rxId,
      medicineName: req.recommendedAlternative,
      dosage: '1 Tablet (Oral)',
      frequency: 'Once Daily',
      durationDays: 30,
      isDispensed: true,
      instructions: 'Take daily as directed. Doctor-approved Tier 1 preferred bioequivalent alternate.',
    );

    final notesMeta = jsonEncode({
      'is_alternate_prescription': true,
      'original_drug': req.originalDrug,
      'original_tier': req.originalTier,
      'original_copay': req.originalCopay,
      'alternate_drug': req.recommendedAlternative,
      'alternate_tier': req.alternativeTier,
      'alternate_copay': req.alternativeCopay,
      'monthly_savings': req.monthlySavings,
      'annual_savings': req.annualSavings,
      'doctor_name': req.doctorName,
      'doctor_id': req.doctorId,
      'doctor_note': req.doctorNote ?? req.clinicalRationale,
      'pharmacist_note': pharmacistNote ?? 'Verified and dispensed by clinical pharmacist.',
      'approved_at': req.respondedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    });

    final altRx = Prescription(
      id: rxId,
      patientId: req.patientId.isNotEmpty ? req.patientId : 'PAT-001',
      patientName: req.patientName.isNotEmpty ? req.patientName : 'Patient',
      drugId: req.recommendedAlternative,
      drugName: req.recommendedAlternative,
      drugClass: req.clinicalClass.isNotEmpty ? req.clinicalClass : 'Approved Alternative',
      diagnosis: req.indication.isNotEmpty ? req.indication : 'Physician Approved Alternative Regimen',
      fillDates: [DateTime.now()],
      fillRecords: [FillRecord(date: DateTime.now(), daysSupply: 30, wasOnTime: true)],
      pdcScore: 0.98,
      status: 'Active (Doctor Approved Alternative)',
      lastFillDate: DateTime.now(),
      nextDueDate: DateTime.now().add(const Duration(days: 30)),
      prescriberName: req.doctorName.isNotEmpty ? req.doctorName : 'Dr. Tariq Martin',
      doctorId: req.doctorId,
      prescribedDate: DateTime.now(),
      notes: notesMeta,
    );

    dataService.addAlternatePrescriptionRecord(rx: altRx, item: altItem);

    // Update approval status to dispensed & persist
    dataService.updateAlternativeApprovalStatus(req.id, 'dispensed');
    dataService.supabaseService.saveAlternativeApproval(req);
    _latestApprovedRequest = null;

    final patVoice =
        'Notification: An approved alternate prescription for ${req.recommendedAlternative} has been issued and sent to patient ${req.patientName}.';
    playWebAudio(null, patVoice);

    addNotification(
      ClinicalNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
        title: '✨ Alternate Prescription Sent to Patient',
        subtitle: '${req.recommendedAlternative} (Doctor Approved) has been issued for ${req.patientName}. Available in patient cabinet for instant PDF download.',
        time: 'Just now',
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
      ),
    );

    notifyListeners();
  }
}
