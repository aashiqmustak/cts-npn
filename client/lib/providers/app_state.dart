import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/data_service.dart';

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

  AppState() {
    _currentUser = const User(
      id: 'U_INIT',
      name: 'User Account',
      email: 'user@alternea.org',
      role: UserRole.pharmacist,
      assignedPatientIds: [],
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      title: 'Clinical Pharmacist',
    );
    refreshData();
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
  List<PharmacistDispenseRecord> get dispenseRecords => dataService.dispenseRecords;
  List<Prescription> get prescriptions => dataService.prescriptions;

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

  // Auth Actions
  void login(User user) {
    _currentUser = user;
    _isLoggedIn = true;
    _currentNavIndex = 0;
    notifyListeners();
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
      assignedPatientIds: ['PT-301', 'PT-302'],
      avatarUrl: 'https://i.pravatar.cc/150?img=32',
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

  void logout() {
    _isLoggedIn = false;
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
        final matches = drug.name.toLowerCase().contains(query) ||
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
        if (_selectedRestrictionFilter == 'PA' && !drug.requiresPa) return false;
        if (_selectedRestrictionFilter == 'ST' && !drug.stepTherapy) return false;
        if (_selectedRestrictionFilter == 'QL' && !drug.quantityLimit) return false;
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
        final matches = event.patientName.toLowerCase().contains(query) ||
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
      String flagId, OutreachStatus status, String? notes) {
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
}
