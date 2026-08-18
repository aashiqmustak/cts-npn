import '../data/mock_data.dart';
import '../models/models.dart';
import 'supabase_service.dart';

class DataService {
  final SupabaseService supabaseService = SupabaseService();

  // Configurable PDC threshold
  double pdcThreshold = 0.80;

  // Domain collections starting completely empty from scratch
  final List<Hospital> _hospitals = [];
  final List<Doctor> _doctors = [];
  final List<PatientRecord> _patientRecords = [];
  final List<PrescriptionItem> _prescriptionItems = [];
  final List<PatientMedicineLog> _patientLogs = [];

  // Global collections starting completely empty from scratch
  final List<Plan> _plans = List.from(MockData.plans);
  final List<User> _users = List.from(MockData.users);
  final List<Drug> _drugs = List.from(MockData.drugs);
  final List<FormularyAlternative> _alternatives =
      List.from(MockData.alternatives);
  final List<Patient> _patients = List.from(MockData.patients);
  final List<Prescription> _prescriptions = List.from(MockData.prescriptions);
  final List<AdherenceFlag> _adherenceFlags =
      List.from(MockData.adherenceFlags);
  final List<PAFrictionEvent> _paFrictionEvents =
      List.from(MockData.paFrictionEvents);
  final List<FormularyIngestion> _ingestionRecords =
      List.from(MockData.ingestionRecords);
  final List<TierCopayConfig> _tierConfigs =
      List.from(MockData.defaultTierConfigs);

  // Getters
  List<Hospital> get hospitals => List.unmodifiable(_hospitals);
  List<Doctor> get doctors => List.unmodifiable(_doctors);
  List<PatientRecord> get patientRecords => List.unmodifiable(_patientRecords);
  List<PrescriptionItem> get prescriptionItems =>
      List.unmodifiable(_prescriptionItems);
  List<PatientMedicineLog> get patientLogs => List.unmodifiable(_patientLogs);

  List<Plan> get plans => List.unmodifiable(_plans);
  List<User> get users => List.unmodifiable(_users);
  List<Drug> get drugs => List.unmodifiable(_drugs);
  List<FormularyAlternative> get alternatives =>
      List.unmodifiable(_alternatives);
  List<Patient> get patients => List.unmodifiable(_patients);
  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);
  List<AdherenceFlag> get adherenceFlags => List.unmodifiable(_adherenceFlags);
  List<PAFrictionEvent> get paFrictionEvents =>
      List.unmodifiable(_paFrictionEvents);
  List<FormularyIngestion> get ingestionRecords =>
      List.unmodifiable(_ingestionRecords);
  List<TierCopayConfig> get tierConfigs => List.unmodifiable(_tierConfigs);

  // Action: Add Hospital from scratch
  void addHospital(Hospital hospital) {
    _hospitals.add(hospital);
    if (supabaseService.isInitialized) {
      supabaseService.addHospital(hospital);
    }
  }

  // Action: Add Doctor from scratch
  void addDoctor(Doctor doctor) {
    _doctors.add(doctor);
  }

  // Action: Add Patient from scratch
  void addPatientRecord(PatientRecord patient) {
    _patientRecords.add(patient);
    if (supabaseService.isInitialized) {
      supabaseService.addPatient(patient);
    }
  }

  // Pharmacist Action: Dispense item
  Future<bool> dispenseItem(String itemId) async {
    final index = _prescriptionItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _prescriptionItems[index].isDispensed = true;
    }
    if (supabaseService.isInitialized) {
      await supabaseService.dispensePrescriptionItem(itemId);
    }
    return true;
  }

  // Doctor Action: Create new prescription from scratch
  Future<bool> createDoctorPrescription({
    required String patientId,
    required String doctorId,
    required String hospitalId,
    required String diagnosis,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final newRxId = 'RX-${DateTime.now().millisecondsSinceEpoch}';
    for (final item in items) {
      _prescriptionItems.add(
        PrescriptionItem(
          id: 'ITEM-${DateTime.now().millisecondsSinceEpoch}-${items.indexOf(item)}',
          prescriptionId: newRxId,
          medicineName: item['medicineName'],
          dosage: item['dosage'],
          frequency: item['frequency'],
          durationDays: item['durationDays'] ?? 30,
          isDispensed: false,
          instructions: item['instructions'],
        ),
      );
    }

    if (supabaseService.isInitialized) {
      await supabaseService.createPrescriptionWithItems(
        patientId: patientId,
        doctorId: doctorId,
        hospitalId: hospitalId,
        diagnosis: diagnosis,
        notes: notes,
        items: items,
      );
    }
    return true;
  }

  // Patient Action: Log medicine from scratch
  Future<void> togglePatientLog(String logId, bool isTaken) async {
    final index = _patientLogs.indexWhere((l) => l.id == logId);
    if (index != -1) {
      _patientLogs[index].isTaken = isTaken;
    }
    if (supabaseService.isInitialized) {
      await supabaseService.togglePatientMedicineLog(logId, isTaken, null);
    }
  }

  void addPatientMedicineLog(PatientMedicineLog log) {
    _patientLogs.add(log);
  }

  void setPdcThreshold(double threshold) {
    pdcThreshold = threshold;
  }

  List<AdherenceFlag> getFilteredAdherenceFlags({
    String? searchQuery,
    RiskLevel? selectedRisk,
    String? selectedDrugClass,
    String? prescriberFilter,
    List<String>? assignedPatientIds,
  }) {
    return _adherenceFlags.where((flag) {
      if (assignedPatientIds != null &&
          !assignedPatientIds.contains(flag.patientId)) {
        return false;
      }

      final isBelowThreshold = flag.pdcScore < pdcThreshold;
      if (!isBelowThreshold && flag.riskLevel != RiskLevel.high) {
        return false;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matches = flag.patientName.toLowerCase().contains(query) ||
            flag.drugName.toLowerCase().contains(query) ||
            flag.reason.toLowerCase().contains(query);
        if (!matches) return false;
      }

      if (selectedRisk != null && flag.riskLevel != selectedRisk) {
        return false;
      }

      if (selectedDrugClass != null &&
          selectedDrugClass.isNotEmpty &&
          flag.drugClass != selectedDrugClass) {
        return false;
      }

      return true;
    }).toList();
  }

  List<FormularyAlternative> getAlternativesForDrug(String drugId) {
    return _alternatives.where((alt) => alt.targetDrugId == drugId).toList();
  }

  Drug? getDrugById(String id) {
    try {
      return _drugs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  double get totalEstimatedAnnualSavingsOpportunity {
    double total = 0.0;
    for (final alt in _alternatives) {
      total += alt.estAnnualSavings;
    }
    for (final fric in _paFrictionEvents) {
      total += fric.estAnnualSavings;
    }
    return total;
  }

  int getAtRiskPatientCount({List<String>? assignedPatientIds}) {
    return _adherenceFlags.where((flag) {
      if (assignedPatientIds != null &&
          !assignedPatientIds.contains(flag.patientId)) {
        return false;
      }
      return flag.pdcScore < pdcThreshold;
    }).length;
  }

  int getActiveFrictionCount({List<String>? assignedPatientIds}) {
    return _paFrictionEvents.where((f) {
      if (assignedPatientIds != null &&
          !assignedPatientIds.contains(f.patientId)) {
        return false;
      }
      return f.status != FrictionStatus.resolved;
    }).length;
  }

  void updateOutreachStatus(
      String flagId, OutreachStatus status, String? notes) {
    final index = _adherenceFlags.indexWhere((f) => f.id == flagId);
    if (index != -1) {
      _adherenceFlags[index].outreachStatus = status;
      if (notes != null && notes.isNotEmpty) {
        _adherenceFlags[index].notes = notes;
      }
    }
  }

  void updateFrictionStatus(String frictionId, FrictionStatus newStatus) {
    final index = _paFrictionEvents.indexWhere((f) => f.id == frictionId);
    if (index != -1) {
      _paFrictionEvents[index].status = newStatus;
    }
  }

  FormularyIngestion simulateFormularyFileUpload(
      String filename, String uploadedBy) {
    final newIngestion = FormularyIngestion(
      id: 'ING-${DateTime.now().millisecondsSinceEpoch}',
      filename: filename,
      uploadDate: DateTime.now(),
      status: 'Completed',
      totalRecords: 18500 + (filename.length * 350),
      updatedTiers: 1420 + (filename.length * 25),
      errorCount: 0,
      uploadedBy: uploadedBy,
    );
    _ingestionRecords.insert(0, newIngestion);
    return newIngestion;
  }

  void addUser(User newUser) {
    _users.add(newUser);
  }

  void updateTierCopay(int tier, double copay, double coinsurance) {
    final index = _tierConfigs.indexWhere((t) => t.tier == tier);
    if (index != -1) {
      _tierConfigs[index].defaultCopay = copay;
      _tierConfigs[index].coinsurancePct = coinsurance;
    }
  }
}
