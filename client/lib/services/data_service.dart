import '../models/models.dart';
import 'supabase_service.dart';

class DataService {
  final SupabaseService supabaseService = SupabaseService();

  // Configurable PDC threshold
  double pdcThreshold = 0.80;

  // Domain collections starting empty
  final List<Hospital> _hospitals = [];
  final List<Doctor> _doctors = [];
  final List<PatientRecord> _patientRecords = [];
  final List<PrescriptionItem> _prescriptionItems = [];
  final List<PatientMedicineLog> _patientLogs = [];

  // Global collections starting empty from Supabase
  final List<Plan> _plans = [];
  final List<User> _users = [];
  final List<Drug> _drugs = [];
  final List<FormularyAlternative> _alternatives = [];
  final List<Patient> _patients = [];
  final List<Prescription> _prescriptions = [];
  final List<AdherenceFlag> _adherenceFlags = [];
  final List<PAFrictionEvent> _paFrictionEvents = [];
  final List<PharmacistDispenseRecord> _dispenseRecords = [];
  final List<FormularyIngestion> _ingestionRecords = [];
  final List<TierCopayConfig> _tierConfigs = [
    TierCopayConfig(tier: 1, name: 'Tier 1 - Preferred Generic', defaultCopay: 10, coinsurancePct: 0, isSpecialty: false),
    TierCopayConfig(tier: 2, name: 'Tier 2 - Generic', defaultCopay: 20, coinsurancePct: 0, isSpecialty: false),
    TierCopayConfig(tier: 3, name: 'Tier 3 - Preferred Brand', defaultCopay: 45, coinsurancePct: 0, isSpecialty: false),
    TierCopayConfig(tier: 4, name: 'Tier 4 - Non-Preferred', defaultCopay: 90, coinsurancePct: 0, isSpecialty: false),
    TierCopayConfig(tier: 5, name: 'Tier 5 - Specialty', defaultCopay: 0, coinsurancePct: 33, isSpecialty: true),
  ];

  Future<void> loadAllFromSupabase() async {
    if (!supabaseService.isInitialized) return;
    try {
      final h = await supabaseService.fetchHospitals();
      _hospitals.clear();
      _hospitals.addAll(h);

      final d = await supabaseService.fetchDoctors();
      _doctors.clear();
      _doctors.addAll(d);

      final pr = await supabaseService.fetchPatients();
      _patientRecords.clear();
      _patientRecords.addAll(pr);

      final List<User> u = await supabaseService.fetchUserProfiles();
      _users.clear();
      _users.addAll(u);

      final p = await supabaseService.fetchPlans();
      _plans.clear();
      _plans.addAll(p);

      final dr = await supabaseService.fetchDrugs();
      _drugs.clear();
      _drugs.addAll(dr);

      final alt = await supabaseService.fetchFormularyAlternatives();
      _alternatives.clear();
      _alternatives.addAll(alt);

      final rx = await supabaseService.fetchPrescriptions();
      _prescriptions.clear();
      _prescriptions.addAll(rx);

      final rxItems = await supabaseService.fetchPrescriptionItems();
      _prescriptionItems.clear();
      _prescriptionItems.addAll(rxItems);

      final af = await supabaseService.fetchAdherenceFlags();
      _adherenceFlags.clear();
      _adherenceFlags.addAll(af);

      final pa = await supabaseService.fetchPAFrictionEvents();
      _paFrictionEvents.clear();
      _paFrictionEvents.addAll(pa);

      final recs = await supabaseService.fetchPharmacistDispenseRecords();
      _dispenseRecords.clear();
      _dispenseRecords.addAll(recs);
    } catch (e) {
      // Gracefully handle empty or non-existent rows
    }
  }

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
  List<PharmacistDispenseRecord> get dispenseRecords =>
      List.unmodifiable(_dispenseRecords);
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
  }

  // Pharmacist Action: Dispense item and log record
  Future<bool> dispenseItem(
    String itemId, {
    String? pharmacistId,
    String? pharmacistName,
  }) async {
    PrescriptionItem? foundItem;
    final index = _prescriptionItems.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _prescriptionItems[index].isDispensed = true;
      foundItem = _prescriptionItems[index];
    }

    if (foundItem != null) {
      final rx = _prescriptions.firstWhere(
        (r) => r.id == foundItem!.prescriptionId,
        orElse: () => Prescription(
          id: foundItem!.prescriptionId,
          patientId: '',
          patientName: 'Patient',
          drugId: '',
          drugName: foundItem.medicineName,
          drugClass: 'General',
          fillDates: [],
          fillRecords: [],
          pdcScore: 0.85,
          status: 'Prescribed',
          lastFillDate: DateTime.now(),
          nextDueDate: DateTime.now(),
          prescriberName: 'Doctor',
          doctorId: null,
        ),
      );

      final patientObj = _patientRecords.firstWhere(
        (p) => p.id == rx.patientId,
        orElse: () => PatientRecord(
          id: rx.patientId,
          name: rx.patientName,
          email: '',
          phone: '',
          age: 40,
          gender: 'Other',
          currentProblem: '',
          visitDate: DateTime.now(),
        ),
      );

      final record = PharmacistDispenseRecord(
        id: 'DISP-${DateTime.now().millisecondsSinceEpoch}',
        prescriptionId: rx.id,
        prescriptionItemId: foundItem.id,
        patientId: patientObj.id,
        patientName: patientObj.name,
        doctorId: rx.prescriberName,
        doctorName: rx.prescriberName,
        pharmacistId: pharmacistId ?? 'U_pharmacist',
        pharmacistName: pharmacistName ?? 'Logged Pharmacist',
        medicineName: foundItem.medicineName,
        dosage: foundItem.dosage,
        frequency: foundItem.frequency,
        dispensedAt: DateTime.now(),
        notes: foundItem.instructions,
      );

      _dispenseRecords.add(record);

      if (supabaseService.isInitialized) {
        await supabaseService.dispensePrescriptionItem(itemId);
        await supabaseService.createPharmacistDispenseRecord(
          prescriptionId: rx.id,
          prescriptionItemId: foundItem.id,
          patientId: patientObj.id,
          patientName: patientObj.name,
          doctorId: rx.prescriberName,
          doctorName: rx.prescriberName,
          pharmacistId: pharmacistId ?? 'U_pharmacist',
          pharmacistName: pharmacistName ?? 'Logged Pharmacist',
          medicineName: foundItem.medicineName,
          dosage: foundItem.dosage,
          frequency: foundItem.frequency,
          notes: foundItem.instructions,
        );
      }
    } else {
      if (supabaseService.isInitialized) {
        await supabaseService.dispensePrescriptionItem(itemId);
      }
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

    // 1. Create main Prescription record
    final firstDrugName = items.isNotEmpty ? items.first['medicineName'] : 'Prescription Payload';
    final doc = _doctors.firstWhere(
      (d) => d.id == doctorId,
      orElse: () => Doctor(
        id: doctorId,
        name: 'Dr. Tariq Martin',
        specialty: 'Attending Physician',
        email: '',
        phone: '',
        hospitalId: hospitalId,
      ),
    );

    final rxRecord = Prescription(
      id: newRxId,
      patientId: patientId,
      patientName: _getPatientNameById(patientId),
      drugId: firstDrugName,
      drugName: firstDrugName,
      drugClass: 'General',
      diagnosis: diagnosis,
      fillDates: [DateTime.now()],
      fillRecords: [],
      pdcScore: 0.95,
      status: 'Active',
      lastFillDate: DateTime.now(),
      nextDueDate: DateTime.now().add(const Duration(days: 30)),
      prescriberName: doc.name,
      doctorId: doctorId,
      prescribedDate: DateTime.now(),
      notes: notes,
    );
    _prescriptions.add(rxRecord);

    // 2. Add PrescriptionItems & convert into active PatientMedicineLogs for the Patient's Medicine Cabinet
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final medName = item['medicineName'] ?? 'Prescribed Drug';
      final dosage = item['dosage'] ?? '1 Tablet (Oral)';
      final frequency = item['frequency'] ?? 'Once daily';

      _prescriptionItems.add(
        PrescriptionItem(
          id: 'ITEM-${DateTime.now().millisecondsSinceEpoch}-$i',
          prescriptionId: newRxId,
          medicineName: medName,
          dosage: dosage,
          frequency: frequency,
          durationDays: item['durationDays'] ?? 30,
          isDispensed: false,
          instructions: item['instructions'] ?? notes,
        ),
      );

      // Instantly add to Patient Medicine Cabinet Logs
      _patientLogs.add(
        PatientMedicineLog(
          id: 'LOG-${DateTime.now().millisecondsSinceEpoch}-$i',
          patientId: patientId,
          medicineName: medName,
          scheduledTime: frequency.contains('bedtime')
              ? '09:00 PM'
              : (frequency.contains('morning') ? '08:00 AM' : '09:00 AM'),
          isTaken: false,
          logDate: DateTime.now(),
          notes: '$dosage • $frequency • e-Rx Prescribed',
        ),
      );
    }

    if (supabaseService.isInitialized) {
      await supabaseService.createPrescriptionWithItems(
        prescriptionId: newRxId,
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

  String _getPatientNameById(String pid) {
    final match = _patientRecords.firstWhere(
      (p) => p.id.toLowerCase() == pid.toLowerCase(),
      orElse: () => PatientRecord(
        id: pid,
        name: 'Patient ($pid)',
        email: '',
        phone: '',
        age: 45,
        gender: 'Other',
        currentProblem: 'General Consultation',
        visitDate: DateTime.now(),
      ),
    );
    return match.name;
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
