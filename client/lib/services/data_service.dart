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

  // Global collections initialized with rich clinical data
  final List<Plan> _plans = [];
  final List<User> _users = [];
  final List<Drug> _drugs = [];
  final List<FormularyAlternative> _alternatives = [];
  final List<Patient> _patients = [
    const Patient(
      id: 'PAT_00402',
      name: 'Eleanor Vance',
      age: 67,
      gender: 'Female',
      prescriberId: 'DOC_001',
      prescriberName: 'Dr. Sarah Jenkins, MD',
      planId: 'PLAN-MED-01',
      riskScore: 0.78,
      phone: '(555) 234-8901',
      email: 'e.vance@example.com',
    ),
    const Patient(
      id: 'PAT_00318',
      name: 'Robert Hernandez',
      age: 72,
      gender: 'Male',
      prescriberId: 'DOC_002',
      prescriberName: 'Dr. Michael Chang, MD',
      planId: 'PLAN-BCBS-02',
      riskScore: 0.62,
      phone: '(555) 876-5432',
      email: 'r.hernandez@example.com',
    ),
    const Patient(
      id: 'PAT_00194',
      name: 'Margaret Chen',
      age: 64,
      gender: 'Female',
      prescriberId: 'DOC_003',
      prescriberName: 'Dr. David Rodriguez, MD',
      planId: 'PLAN-AETNA-03',
      riskScore: 0.84,
      phone: '(555) 345-6789',
      email: 'm.chen@example.com',
    ),
    const Patient(
      id: 'PAT_00521',
      name: 'David Kim',
      age: 59,
      gender: 'Male',
      prescriberId: 'DOC_001',
      prescriberName: 'Dr. Sarah Jenkins, MD',
      planId: 'PLAN-UHC-04',
      riskScore: 0.38,
      phone: '(555) 987-6543',
      email: 'd.kim@example.com',
    ),
    const Patient(
      id: 'PAT_00287',
      name: 'Sarah Jenkins',
      age: 68,
      gender: 'Female',
      prescriberId: 'DOC_004',
      prescriberName: 'Dr. Emily Watson, MD',
      planId: 'PLAN-HUM-05',
      riskScore: 0.71,
      phone: '(555) 456-7890',
      email: 's.jenkins@example.com',
    ),
    const Patient(
      id: 'PAT_00612',
      name: 'Arthur Pendelton',
      age: 75,
      gender: 'Male',
      prescriberId: 'DOC_002',
      prescriberName: 'Dr. Michael Chang, MD',
      planId: 'PLAN-MED-01',
      riskScore: 0.45,
      phone: '(555) 678-1234',
      email: 'a.pendelton@example.com',
    ),
  ];
  final List<Prescription> _prescriptions = [
    Prescription(
      id: 'RX-1001',
      patientId: 'PAT_00402',
      patientName: 'Eleanor Vance',
      drugId: 'DRUG-LIP-20',
      drugName: 'Lipitor 20 MG Oral Tablet',
      drugClass: 'Statins (Cholesterol)',
      diagnosis: 'Hyperlipidemia & Coronary Artery Disease',
      fillDates: [
        DateTime.now().subtract(const Duration(days: 120)),
        DateTime.now().subtract(const Duration(days: 60)),
      ],
      fillRecords: [
        FillRecord(date: DateTime.now().subtract(const Duration(days: 120)), daysSupply: 30, wasOnTime: true),
        FillRecord(date: DateTime.now().subtract(const Duration(days: 60)), daysSupply: 30, wasOnTime: false),
      ],
      pdcScore: 0.58,
      status: 'Refill Overdue (24 Days)',
      lastFillDate: DateTime.now().subtract(const Duration(days: 60)),
      nextDueDate: DateTime.now().subtract(const Duration(days: 24)),
      prescriberName: 'Dr. Sarah Jenkins, MD',
      doctorId: 'DOC_001',
      notes: 'Tier 3 Brand copay (\$47.00) cited as primary cost barrier. Candidate for Tier 1 Rosuvastatin 10mg.',
    ),
    Prescription(
      id: 'RX-1002',
      patientId: 'PAT_00318',
      patientName: 'Robert Hernandez',
      drugId: 'DRUG-JAN-100',
      drugName: 'Januvia 100 MG Oral Tablet',
      drugClass: 'DPP-4 Inhibitors (Diabetes)',
      diagnosis: 'Type 2 Diabetes Mellitus',
      fillDates: [
        DateTime.now().subtract(const Duration(days: 90)),
        DateTime.now().subtract(const Duration(days: 45)),
      ],
      fillRecords: [
        FillRecord(date: DateTime.now().subtract(const Duration(days: 90)), daysSupply: 30, wasOnTime: true),
        FillRecord(date: DateTime.now().subtract(const Duration(days: 45)), daysSupply: 30, wasOnTime: false),
      ],
      pdcScore: 0.64,
      status: 'Refill Overdue (18 Days)',
      lastFillDate: DateTime.now().subtract(const Duration(days: 45)),
      nextDueDate: DateTime.now().subtract(const Duration(days: 18)),
      prescriberName: 'Dr. Michael Chang, MD',
      doctorId: 'DOC_002',
      notes: 'Complex multi-dose daily regimen. Recommended switching to Tier 1 generic or 90-day supply.',
    ),
    Prescription(
      id: 'RX-1003',
      patientId: 'PAT_00194',
      patientName: 'Margaret Chen',
      drugId: 'DRUG-ENT-97',
      drugName: 'Entresto 97/103 MG Oral Tablet',
      drugClass: 'ARNI / RASA (Heart Failure)',
      diagnosis: 'Heart Failure with Reduced Ejection Fraction (HFrEF)',
      fillDates: [
        DateTime.now().subtract(const Duration(days: 150)),
        DateTime.now().subtract(const Duration(days: 90)),
      ],
      fillRecords: [
        FillRecord(date: DateTime.now().subtract(const Duration(days: 150)), daysSupply: 30, wasOnTime: true),
        FillRecord(date: DateTime.now().subtract(const Duration(days: 90)), daysSupply: 30, wasOnTime: false),
      ],
      pdcScore: 0.52,
      status: 'Refill Overdue (31 Days)',
      lastFillDate: DateTime.now().subtract(const Duration(days: 90)),
      nextDueDate: DateTime.now().subtract(const Duration(days: 31)),
      prescriberName: 'Dr. David Rodriguez, MD',
      doctorId: 'DOC_003',
      notes: 'High abandonment risk (84% from AWS ML). Requires immediate proactive clinical consultation.',
    ),
    Prescription(
      id: 'RX-1004',
      patientId: 'PAT_00521',
      patientName: 'David Kim',
      drugId: 'DRUG-LIS-20',
      drugName: 'Lisinopril 20 MG Oral Tablet',
      drugClass: 'ACE Inhibitors / RASA',
      diagnosis: 'Essential Hypertension',
      fillDates: [
        DateTime.now().subtract(const Duration(days: 60)),
        DateTime.now().subtract(const Duration(days: 25)),
      ],
      fillRecords: [
        FillRecord(date: DateTime.now().subtract(const Duration(days: 60)), daysSupply: 30, wasOnTime: true),
        FillRecord(date: DateTime.now().subtract(const Duration(days: 25)), daysSupply: 30, wasOnTime: true),
      ],
      pdcScore: 0.74,
      status: 'Refill Due (8 Days Gap)',
      lastFillDate: DateTime.now().subtract(const Duration(days: 25)),
      nextDueDate: DateTime.now().add(const Duration(days: 5)),
      prescriberName: 'Dr. Sarah Jenkins, MD',
      doctorId: 'DOC_001',
      notes: 'Eligible for 90-day mail order synchronization program.',
    ),
    Prescription(
      id: 'RX-1005',
      patientId: 'PAT_00287',
      patientName: 'Sarah Jenkins',
      drugId: 'DRUG-JAR-25',
      drugName: 'Jardiance 25 MG Oral Tablet',
      drugClass: 'SGLT2 Inhibitors (Diabetes)',
      diagnosis: 'Type 2 Diabetes & Chronic Kidney Disease',
      fillDates: [
        DateTime.now().subtract(const Duration(days: 100)),
        DateTime.now().subtract(const Duration(days: 50)),
      ],
      fillRecords: [
        FillRecord(date: DateTime.now().subtract(const Duration(days: 100)), daysSupply: 30, wasOnTime: true),
        FillRecord(date: DateTime.now().subtract(const Duration(days: 50)), daysSupply: 30, wasOnTime: false),
      ],
      pdcScore: 0.61,
      status: 'Refill Overdue (21 Days)',
      lastFillDate: DateTime.now().subtract(const Duration(days: 50)),
      nextDueDate: DateTime.now().subtract(const Duration(days: 21)),
      prescriberName: 'Dr. Emily Watson, MD',
      doctorId: 'DOC_004',
      notes: 'Prior Authorization renewal barrier. PA auto-generated by clinical agent.',
    ),
    Prescription(
      id: 'RX-1006',
      patientId: 'PAT_00612',
      patientName: 'Arthur Pendelton',
      drugId: 'DRUG-ELI-5',
      drugName: 'Eliquis 5 MG Oral Tablet',
      drugClass: 'Direct Oral Anticoagulants (DOAC)',
      diagnosis: 'Non-Valvular Atrial Fibrillation',
      fillDates: [
        DateTime.now().subtract(const Duration(days: 75)),
        DateTime.now().subtract(const Duration(days: 35)),
      ],
      fillRecords: [
        FillRecord(date: DateTime.now().subtract(const Duration(days: 75)), daysSupply: 30, wasOnTime: true),
        FillRecord(date: DateTime.now().subtract(const Duration(days: 35)), daysSupply: 30, wasOnTime: false),
      ],
      pdcScore: 0.68,
      status: 'Refill Overdue (14 Days)',
      lastFillDate: DateTime.now().subtract(const Duration(days: 35)),
      nextDueDate: DateTime.now().subtract(const Duration(days: 14)),
      prescriberName: 'Dr. Michael Chang, MD',
      doctorId: 'DOC_002',
      notes: 'Cardiology stroke prophylaxis. Outreach scheduled for 90-day sync refill.',
    ),
  ];
  final List<AdherenceFlag> _adherenceFlags = [
    AdherenceFlag(
      id: 'FLAG-01',
      prescriptionId: 'RX-1001',
      patientId: 'PAT_00402',
      patientName: 'Eleanor Vance',
      drugName: 'Lipitor 20 MG Oral Tablet',
      drugClass: 'Statins (Cholesterol)',
      riskLevel: RiskLevel.high,
      pdcScore: 0.58,
      reason: '24-day refill gap. Cost barrier reported on Tier 3 Brand (\$47 copay). AWS ML Abandonment: 78%.',
      outreachStatus: OutreachStatus.pending,
      notes: 'Recommended: Switch to Tier 1 Rosuvastatin 10mg (\$10 copay, 100% safety match).',
    ),
    AdherenceFlag(
      id: 'FLAG-02',
      prescriptionId: 'RX-1002',
      patientId: 'PAT_00318',
      patientName: 'Robert Hernandez',
      drugName: 'Januvia 100 MG Oral Tablet',
      drugClass: 'DPP-4 Inhibitors (Diabetes)',
      riskLevel: RiskLevel.medium,
      pdcScore: 0.64,
      reason: '18-day refill gap. Missed consecutive daily morning doses. AWS ML Abandonment: 62%.',
      outreachStatus: OutreachStatus.contacted,
      notes: 'Patient contacted via SMS. Scheduled pharmacist medication review.',
    ),
    AdherenceFlag(
      id: 'FLAG-03',
      prescriptionId: 'RX-1003',
      patientId: 'PAT_00194',
      patientName: 'Margaret Chen',
      drugName: 'Entresto 97/103 MG Oral Tablet',
      drugClass: 'ARNI / RASA (Heart Failure)',
      riskLevel: RiskLevel.high,
      pdcScore: 0.52,
      reason: '31-day severe refill gap. Critical heart failure regimen abandonment risk (84% from AWS ML).',
      outreachStatus: OutreachStatus.pending,
      notes: 'High priority clinical case. Requires phone consultation & 90-day refill sync.',
    ),
    AdherenceFlag(
      id: 'FLAG-04',
      prescriptionId: 'RX-1004',
      patientId: 'PAT_00521',
      patientName: 'David Kim',
      drugName: 'Lisinopril 20 MG Oral Tablet',
      drugClass: 'ACE Inhibitors / RASA',
      riskLevel: RiskLevel.medium,
      pdcScore: 0.74,
      reason: '8-day delay between 30-day fills. Candidate for 90-day mail order synchronization.',
      outreachStatus: OutreachStatus.syncScheduled,
      notes: 'Enrolled in 90-Day Med Sync program with home delivery.',
    ),
    AdherenceFlag(
      id: 'FLAG-05',
      prescriptionId: 'RX-1005',
      patientId: 'PAT_00287',
      patientName: 'Sarah Jenkins',
      drugName: 'Jardiance 25 MG Oral Tablet',
      drugClass: 'SGLT2 Inhibitors (Diabetes)',
      riskLevel: RiskLevel.high,
      pdcScore: 0.61,
      reason: '21-day refill delay due to expired Prior Authorization. AWS ML Abandonment: 71%.',
      outreachStatus: OutreachStatus.pending,
      notes: 'Prior Auth submission initiated with clinical rationale pre-populated.',
    ),
    AdherenceFlag(
      id: 'FLAG-06',
      prescriptionId: 'RX-1006',
      patientId: 'PAT_00612',
      patientName: 'Arthur Pendelton',
      drugName: 'Eliquis 5 MG Oral Tablet',
      drugClass: 'Direct Oral Anticoagulants (DOAC)',
      riskLevel: RiskLevel.medium,
      pdcScore: 0.68,
      reason: '14-day gap in critical anticoagulation therapy for Atrial Fibrillation.',
      outreachStatus: OutreachStatus.contacted,
      notes: 'Pharmacist confirmed patient refilled at partner retail location.',
    ),
  ];
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

  // Action: Delete Hospital
  void deleteHospital(String id) {
    _hospitals.removeWhere((h) => h.id == id);
    if (supabaseService.isInitialized) {
      supabaseService.deleteHospital(id);
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
