import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/data_service.dart';

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
  int _activeSubTabIndex = 0;
  String? _selectedPrescriptionId;

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

  void dismissNotification(String id) {
    final idx = _userNotifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _userNotifications[idx].isDismissed = true;
      _userNotifications[idx].isRead = true;
      notifyListeners();
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
        _currentUser = User.fromJson(map);
        _isLoggedIn = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error restoring user session: $e');
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

  void addHospital(Hospital hospital) {
    dataService.addHospital(hospital);
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
  }) async {
    if (dataService.supabaseService.isInitialized && password.isNotEmpty) {
      try {
        final authRes = await dataService.supabaseService.signUp(
          email: email,
          password: password,
          name: name,
          role: role,
        );
        if (authRes?.user != null) {
          final profile = User(
            id: authRes!.user!.id,
            name: name,
            email: email,
            role: role,
            assignedPatientIds: const ['PT-301', 'PT-302'],
            avatarUrl: '',
            title: _getRoleTitle(role),
          );
          login(profile);
          return true;
        }
      } catch (e) {
        // Fall back to local creation if Supabase signUp fails or already exists
      }
    }

    register(name: name, email: email, role: role);
    return true;
  }

  void register({
    required String name,
    required String email,
    required UserRole role,
  }) {
    final newUser = User(
      id: 'U_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: role,
      assignedPatientIds: const ['PT-301', 'PT-302'],
      avatarUrl: '',
      title: _getRoleTitle(role),
    );
    dataService.addUser(newUser);
    _currentUser = newUser;
    _isLoggedIn = true;
    _currentNavIndex = 0;
    notifyListeners();
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
    notifyListeners();
  }

  void setNavIndex(int index) {
    _currentNavIndex = index;
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
}
