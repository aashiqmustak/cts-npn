import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class DoctorPrescriptionScreen extends StatefulWidget {
  const DoctorPrescriptionScreen({super.key});

  @override
  State<DoctorPrescriptionScreen> createState() =>
      _DoctorPrescriptionScreenState();
}

class _DoctorPrescriptionScreenState extends State<DoctorPrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedHospitalId;
  String? _selectedPatientId;

  // On-the-fly Hospital Form Controllers
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  bool _createNewHospital = false;

  // New Patient Form Controllers
  final _patientSearchFilterController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientEmailController = TextEditingController();
  final _patientPhoneController = TextEditingController();
  final _patientAgeController = TextEditingController();
  final _currentProblemController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  // Prescribed items list
  final List<Map<String, dynamic>> _prescribedItems = [];

  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController(text: '1 Tablet (Oral)');
  final _frequencyController = TextEditingController(text: 'Once daily');
  int _selectedDurationDays = 30;

  bool _createNewPatient = false;

  // Quick Preset Drugs
  final List<String> _quickDrugs = [
    'Metformin HCL 500mg',
    'Lisinopril 10mg',
    'Atorvastatin 20mg',
    'Amoxicillin 500mg',
    'Omeprazole 20mg',
    'Levothyroxine 50mcg',
  ];

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'Three times daily',
    'Every 8 hours',
    'At bedtime',
    'Once daily at bedtime',
    'Once daily in morning',
    'As needed (PRN)',
  ];

  final List<int> _durationOptions = [7, 14, 30, 60, 90];

  late final FocusNode _patientFocusNode;
  late final FocusNode _drugFocusNode;

  @override
  void initState() {
    super.initState();
    _patientFocusNode = FocusNode();
    _drugFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _patientFocusNode.dispose();
    _drugFocusNode.dispose();
    _patientSearchFilterController.dispose();
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _patientNameController.dispose();
    _patientEmailController.dispose();
    _patientPhoneController.dispose();
    _patientAgeController.dispose();
    _currentProblemController.dispose();
    _diagnosisController.dispose();
    _notesController.dispose();
    _medNameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  /// Query all formulary drugs from database and combine with clinical presets
  List<String> _getAllCombinedDrugs(AppState appState) {
    final list = <String>[];
    for (final d in appState.dataService.drugs) {
      if (d.name.isNotEmpty && !list.contains(d.name)) {
        list.add(d.name);
      }
    }
    final defaults = [
      'Metformin HCL 500mg',
      'Metformin ER 1000mg',
      'Lisinopril 10mg',
      'Lisinopril 20mg',
      'Atorvastatin 20mg',
      'Atorvastatin 40mg',
      'Amoxicillin 500mg',
      'Omeprazole 20mg',
      'Levothyroxine 50mcg',
      'Amlodipine 5mg',
      'Losartan 50mg',
      'Gabapentin 300mg',
      'Hydrochlorothiazide 25mg',
      'Sertraline 50mg',
      'Montelukast 10mg',
      'Empagliflozin (Jardiance) 10mg',
      'Ozempic (Semaglutide) 0.5mg/mL',
    ];
    for (final d in defaults) {
      if (!list.map((e) => e.toLowerCase()).contains(d.toLowerCase())) {
        list.add(d);
      }
    }
    return list;
  }

  /// Combine and filter patients so Doctor's Active Clients appear first, followed by Other Patients
  List<PatientRecord> _getAllCombinedPatients(AppState appState) {
    final list = List<PatientRecord>.from(appState.patientRecords);
    final existingIds = list.map((p) => p.id.toLowerCase()).toSet();

    // Merge users registered as patients (e.g. PAT_00001)
    for (final u in appState.dataService.users) {
      final pid = u.patientId ?? u.id;
      if (u.isPatient || pid.toUpperCase().startsWith('PAT')) {
        if (!existingIds.contains(pid.toLowerCase())) {
          existingIds.add(pid.toLowerCase());
          list.add(
            PatientRecord(
              id: pid,
              name: u.name,
              email: u.email,
              phone: u.phone ?? '',
              age: 38,
              gender: 'Other',
              currentProblem: 'Routine Clinical Evaluation',
              visitDate: DateTime.now(),
              hospitalName: u.hospitalName,
              assignedDoctorId: u.doctorId ?? appState.currentUser.doctorId,
            ),
          );
        }
      }
    }

    // Ensure default MRN patients PAT_00001 to PAT_00005 are present as active doctor clients
    for (int i = 1; i <= 5; i++) {
      final mrnId = 'PAT_0000$i';
      if (!existingIds.contains(mrnId.toLowerCase())) {
        existingIds.add(mrnId.toLowerCase());
        list.add(
          PatientRecord(
            id: mrnId,
            name: 'Patient $i ($mrnId)',
            email: 'patient$i@health.org',
            phone: '(555) 019-280$i',
            age: 35 + i * 5,
            gender: i % 2 == 0 ? 'Female' : 'Male',
            currentProblem:
                i == 1
                    ? 'Hypertension & Lipid Management'
                    : 'Clinical Evaluation',
            visitDate: DateTime.now(),
            assignedDoctorId: appState.currentUser.doctorId ?? 'DOC-201',
          ),
        );
      }
    }

    final docId =
        (appState.currentUser.doctorId ?? appState.currentUser.id)
            .toLowerCase();
    final docName = (appState.currentUser.name).toLowerCase();

    // Group 1: Doctor's Active Clients (Shown First)
    final myClients = <PatientRecord>[];
    // Group 2: Other In-Network Patients (Shown Second)
    final otherPatients = <PatientRecord>[];

    for (final p in list) {
      final isMine =
          (p.assignedDoctorId != null &&
              p.assignedDoctorId!.toLowerCase() == docId) ||
          (p.assignedDoctorName != null &&
              p.assignedDoctorName!.toLowerCase() == docName) ||
          p.id.toUpperCase().startsWith('PAT_0000') ||
          p.id.toUpperCase().startsWith('PT-');

      if (isMine) {
        myClients.add(p);
      } else {
        otherPatients.add(p);
      }
    }

    return [...myClients, ...otherPatients];
  }

  void _addMedicineItem() {
    if (_medNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.dangerText,
          content: Text('Please select or enter a Medicine Name'),
        ),
      );
      return;
    }
    setState(() {
      _prescribedItems.add({
        'medicineName': _medNameController.text.trim(),
        'dosage':
            _dosageController.text.trim().isEmpty
                ? '1 Tablet'
                : _dosageController.text.trim(),
        'frequency':
            _frequencyController.text.trim().isEmpty
                ? 'Once daily'
                : _frequencyController.text.trim(),
        'durationDays': _selectedDurationDays,
        'instructions': 'Take as prescribed by attending physician',
      });
      _medNameController.clear();
      _dosageController.text = '1 Tablet (Oral)';
      _frequencyController.text = 'Once daily';
    });
  }

  void _submitPrescription(AppState appState) async {
    String hospitalId = _selectedHospitalId ?? (appState.hospitals.isNotEmpty ? appState.hospitals.first.id : '');

    if (hospitalId.isEmpty) {
      if (_createNewHospital &&
          _hospitalNameController.text.trim().isNotEmpty &&
          _hospitalAddressController.text.trim().isNotEmpty) {
        final newHospital = Hospital(
          id: 'HOSP-${DateTime.now().millisecondsSinceEpoch}',
          name: _hospitalNameController.text.trim(),
          address: _hospitalAddressController.text.trim(),
          city: 'Phoenix',
          state: 'AZ',
          zip: '85054',
          phone: '(602) 301-8000',
        );
        appState.addHospital(newHospital);
        hospitalId = newHospital.id;
      } else {
        final defaultHosp = Hospital(
          id: 'HOSP-MAYO-AZ',
          name: appState.currentUser.hospitalName ?? 'Mayo Clinic Hospital - Phoenix',
          address: '5777 E Mayo Blvd, Phoenix, AZ 85054',
          city: 'Phoenix',
          state: 'AZ',
          zip: '85054',
          phone: '(602) 301-8000',
        );
        appState.addHospital(defaultHosp);
        hospitalId = defaultHosp.id;
      }
    }

    if (_prescribedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.dangerText,
          content: Text(
            'Please add at least one medication item to the prescription regimen',
          ),
        ),
      );
      return;
    }

    String patientId = _selectedPatientId ?? '';

    if (_createNewPatient || patientId.isEmpty) {
      if (_patientNameController.text.trim().isEmpty ||
          _currentProblemController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.dangerText,
            content: Text('Please provide Patient Name & Medical Diagnosis'),
          ),
        );
        return;
      }
      final newPatient = PatientRecord(
        id: 'PT-${DateTime.now().millisecondsSinceEpoch}',
        name: _patientNameController.text.trim(),
        email: _patientEmailController.text.trim(),
        phone:
            _patientPhoneController.text.trim().isEmpty
                ? '(555) 019-2834'
                : _patientPhoneController.text.trim(),
        age: int.tryParse(_patientAgeController.text) ?? 45,
        gender: 'Other',
        currentProblem: _currentProblemController.text.trim(),
        visitDate: DateTime.now(),
        assignedDoctorId: appState.currentUser.doctorId ?? 'DOC-201',
        hospitalId: hospitalId,
      );
      appState.dataService.addPatientRecord(newPatient);
      patientId = newPatient.id;
    }

    await appState.createDoctorPrescription(
      patientId: patientId,
      doctorId: appState.currentUser.doctorId ?? 'DOC-201',
      hospitalId: hospitalId,
      diagnosis:
          _diagnosisController.text.trim().isEmpty
              ? 'Clinical Evaluation'
              : _diagnosisController.text.trim(),
      notes: _notesController.text.trim(),
      items: List.from(_prescribedItems),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primaryTeal,
          content: Text(
            'e-Prescription Issued Successfully! Broadcast to in-network Dispense Queue.',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
        ),
      );
      setState(() {
        _prescribedItems.clear();
        _diagnosisController.clear();
        _notesController.clear();
        _patientNameController.clear();
        _patientAgeController.clear();
        _currentProblemController.clear();
        _hospitalNameController.clear();
        _hospitalAddressController.clear();
      });
    }
  }

  /// Interactive Pop-up Dialog to Add any custom Patient ID or Name to Doctor's Caseload
  void _showAddNewClientDialog(
    BuildContext context,
    String initialQuery,
    AppState appState,
  ) {
    final nameCtrl = TextEditingController(text: initialQuery);
    final ageCtrl = TextEditingController(text: '45');
    final problemCtrl = TextEditingController(
      text: 'General Clinical Evaluation',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Color(0xFF1244A2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Add New Patient Client to Roster',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient ID/Name "$initialQuery" is not in your current caseload. Register this patient as your active client?',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  labelText: 'Patient Full Name / ID',
                  prefixIcon: Icon(
                    Icons.badge_rounded,
                    size: 16,
                    color: Color(0xFF1244A2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ageCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  labelText: 'Patient Age',
                  prefixIcon: Icon(
                    Icons.cake_rounded,
                    size: 16,
                    color: Color(0xFF1244A2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: problemCtrl,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
                decoration: const InputDecoration(
                  labelText: 'Chief Complaint / Medical Indication',
                  prefixIcon: Icon(
                    Icons.healing_rounded,
                    size: 16,
                    color: Color(0xFF1244A2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1244A2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              icon: const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              ),
              label: Text(
                'Add & Select Client',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                final inputVal =
                    nameCtrl.text.trim().isEmpty
                        ? initialQuery
                        : nameCtrl.text.trim();
                final newId =
                    inputVal.toUpperCase().startsWith('PAT') ||
                            inputVal.toUpperCase().startsWith('PT')
                        ? inputVal.toUpperCase()
                        : 'PAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

                final newPatient = PatientRecord(
                  id: newId,
                  name: inputVal,
                  email: 'patient@health.org',
                  phone: '(555) 019-2834',
                  age: int.tryParse(ageCtrl.text) ?? 45,
                  gender: 'Other',
                  currentProblem:
                      problemCtrl.text.trim().isEmpty
                          ? 'General Consultation'
                          : problemCtrl.text.trim(),
                  visitDate: DateTime.now(),
                  assignedDoctorId: appState.currentUser.doctorId ?? 'DOC-201',
                  assignedDoctorName: appState.currentUser.name,
                );
                appState.dataService.addPatientRecord(newPatient);

                setState(() {
                  _selectedPatientId = newPatient.id;
                  _patientNameController.text = newPatient.name;
                  _patientAgeController.text = newPatient.age.toString();
                  _currentProblemController.text = newPatient.currentProblem;
                  _createNewPatient = false;
                });

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF1244A2),
                    content: Text(
                      'Successfully registered ${newPatient.name} (ID: ${newPatient.id}) to your active client roster!',
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final hospitals = appState.hospitals;
    final patients = _getAllCombinedPatients(appState);

    if (hospitals.isEmpty) {
      _createNewHospital = false;
    } else {
      _selectedHospitalId ??= hospitals.first.id;
    }

    if (patients.isEmpty) {
      _createNewPatient = true;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Physician e-Prescription Studio',
            subtitle:
                'Generate compliant e-prescriptions, evaluate diagnosis codes, and broadcast live to in-network pharmacy.',
            icon: Icons.edit_note_rounded,
            statusLabel: 'DEA & NPI Certified',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.electricMint,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dr. Verified Session',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 2. Asymmetric Bento 2-Column Clinical Studio
          Form(
            key: _formKey,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 940;

                final leftColumn = Column(
                  children: [
                    // Facility Origin Bento Card
                    _buildFacilityCard(appState.currentUser, hospitals),
                    const SizedBox(height: 16),
                    // Patient Context & Diagnosis Bento Card
                    _buildPatientDiagnosisCard(patients),
                  ],
                );

                final rightColumn = Column(
                  children: [
                    // Medication Regimen Builder Studio Card
                    _buildRegimenBuilderCard(),
                    const SizedBox(height: 16),
                    // Active Prescription Items List & Issue Bar Card
                    _buildActivePrescriptionItemsCard(appState),
                  ],
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: leftColumn),
                      const SizedBox(width: 18),
                      Expanded(flex: 6, child: rightColumn),
                    ],
                  );
                }

                return Column(
                  children: [
                    leftColumn,
                    const SizedBox(height: 16),
                    rightColumn,
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Facility Origin Bento Card ---
  Widget _buildFacilityCard(User user, List<Hospital> hospitals) {
    final assignedHospitalName =
        user.hospitalName ??
        (hospitals.isNotEmpty
            ? '${hospitals.first.name} (${hospitals.first.city}, ${hospitals.first.state})'
            : 'Wake Forest Baptist Medical Center (Winston-Salem, NC)');

    return BentoCard(
      title: 'Clinical Facility & Hospital Context',
      subtitle: 'Primary practice location assigned to doctor session',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.local_hospital_rounded,
          color: AppColors.primaryTeal,
          size: 18,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'Verified Location',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgSlate,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.metallicBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.domain_rounded,
              size: 18,
              color: AppColors.primaryTeal,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AUTHORIZED MEDICAL CENTER',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    assignedHospitalName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.verified_rounded,
              size: 16,
              color: Color(0xFF10B981),
            ),
          ],
        ),
      ),
    );
  }

  // --- Patient Context & Diagnosis Bento Card ---
  Widget _buildPatientDiagnosisCard(List<PatientRecord> patients) {
    return BentoCard(
      title: 'Patient Profile & Clinical Diagnosis',
      subtitle: 'Identify patient recipient and diagnostic indication',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.primaryTeal,
          size: 18,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1244A2),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(
              Icons.person_add_rounded,
              size: 14,
              color: Colors.white,
            ),
            label: Text(
              '+ Register Custom ID',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            onPressed: () {
              final appState = Provider.of<AppState>(context, listen: false);
              _showAddNewClientDialog(
                context,
                _patientNameController.text.trim(),
                appState,
              );
            },
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _createNewPatient = !_createNewPatient;
              });
            },
            icon: Icon(
              _createNewPatient
                  ? Icons.people_alt_rounded
                  : Icons.person_add_rounded,
              size: 15,
              color: AppColors.primaryTeal,
            ),
            label: Text(
              _createNewPatient ? 'Select Existing' : '+ New Patient',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patients.isNotEmpty && !_createNewPatient) ...[
            // Primary Searchable Dropdown (with Search Bar INSIDE the dropdown popup menu)
            _SearchablePatientDropdown(
              patients: patients,
              selectedPatientId: _selectedPatientId,
              onPatientSelected: (sel) {
                setState(() {
                  _selectedPatientId = sel.id;
                  _patientNameController.text = sel.name;
                  _patientAgeController.text = sel.age.toString();
                  _currentProblemController.text = sel.currentProblem;
                });
              },
            ),
          ] else ...[
            // 2. Direct Text Input Form for New Patient Registration
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _patientNameController,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Patient Full Name / ID',
                      hintText: 'e.g. Eleanor Vance or PAT_00001',
                      prefixIcon: Icon(
                        Icons.badge_outlined,
                        size: 16,
                        color: Color(0xFF1244A2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _patientAgeController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      hintText: '45',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currentProblemController,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              decoration: const InputDecoration(
                labelText: 'Chief Medical Complaint',
                hintText: 'e.g. Type 2 Diabetes Management & Blood Pressure',
                prefixIcon: Icon(
                  Icons.healing_outlined,
                  size: 16,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),

          TextField(
            controller: _diagnosisController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: const InputDecoration(
              labelText: 'Formal ICD-10 Code / Clinical Diagnosis',
              hintText: 'e.g. E11.9 (Type 2 Diabetes Without Complications)',
              prefixIcon: Icon(
                Icons.medical_information_outlined,
                size: 16,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
            decoration: const InputDecoration(
              labelText: 'Physician Clinical Regimen Notes',
              hintText:
                  'e.g. Take with food, monitor daily blood glucose, follow up in 30 days',
              prefixIcon: Icon(
                Icons.notes_rounded,
                size: 16,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Medication Regimen Builder Studio Card ---
  Widget _buildRegimenBuilderCard() {
    return BentoCard(
      title: 'Medication Regimen Builder Studio',
      subtitle:
          'Prescribe active therapeutic items, dosages, and refill limits',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.medication_rounded,
          color: AppColors.primaryTeal,
          size: 18,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Drug Chips
          Text(
            'Quick Prescribe Presets:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                _quickDrugs.map((drug) {
                  final isSelected = _medNameController.text == drug;
                  return ChoiceChip(
                    label: Text(drug),
                    selected: isSelected,
                    selectedColor: AppColors.primaryLight,
                    backgroundColor: AppColors.bgSlate,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    side: BorderSide(
                      color:
                          isSelected
                              ? AppColors.primaryTeal
                              : AppColors.metallicBorder,
                    ),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isSelected
                              ? AppColors.primaryTeal
                              : AppColors.textDark,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _medNameController.text = selected ? drug : '';
                      });
                    },
                  );
                }).toList(),
          ),

          const SizedBox(height: 10),

          // Drug Name Autocomplete Field with Database Suggestions
          Builder(
            builder: (context) {
              final appState = Provider.of<AppState>(context);
              return RawAutocomplete<String>(
                textEditingController: _medNameController,
                focusNode: _drugFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim().toLowerCase();
                  final allDrugs = _getAllCombinedDrugs(appState);
                  if (query.isEmpty) {
                    return allDrugs;
                  }
                  return allDrugs.where((d) => d.toLowerCase().contains(query));
                },
                onSelected: (String drug) {
                  setState(() {
                    _medNameController.text = drug;
                    if (drug.contains('Metformin')) {
                      _dosageController.text = '1 Tablet (Oral)';
                      _frequencyController.text = 'Once daily';
                    } else if (drug.contains('Atorvastatin')) {
                      _dosageController.text = '1 Tablet (Oral)';
                      _frequencyController.text = 'Once daily at bedtime';
                    } else if (drug.contains('Lisinopril')) {
                      _dosageController.text = '1 Tablet (Oral)';
                      _frequencyController.text = 'Once daily in morning';
                    } else if (drug.contains('Amoxicillin')) {
                      _dosageController.text = '1 Capsule (Oral)';
                      _frequencyController.text = 'Three times daily';
                    }
                  });
                },
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Drug Name & Strength',
                      hintText: 'Type drug name (Database suggestions auto-dropdown)...',
                      prefixIcon: Icon(Icons.medication_liquid_rounded, size: 16, color: Color(0xFF1244A2)),
                      suffixIcon: Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF1244A2)),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  final optionList = options.toList();
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220, maxWidth: 380),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.metallicBorder),
                        ),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: optionList.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final drug = optionList[index];
                            return ListTile(
                              dense: true,
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1244A2).withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.medication_rounded, size: 14, color: Color(0xFF1244A2)),
                              ),
                              title: Text(
                                drug,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textDark),
                              ),
                              subtitle: Text(
                                'Formulary Database Verified Drug',
                                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
                              ),
                              onTap: () => onSelected(drug),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dosageController,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Formulation / Dose',
                    hintText: '1 Tablet (Oral)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _frequencies.contains(_frequencyController.text)
                      ? _frequencyController.text
                      : _frequencies.first,
                  isExpanded: true,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items:
                      _frequencies.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(
                            f,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                  onChanged: (val) {
                    if (val != null) _frequencyController.text = val;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Duration Presets Row
          Row(
            children: [
              Text(
                'Supply Duration:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 5,
                  children:
                      _durationOptions.map((days) {
                        final isSel = _selectedDurationDays == days;
                        return ChoiceChip(
                          label: Text('$days Days'),
                          selected: isSel,
                          selectedColor: AppColors.primaryLight,
                          backgroundColor: AppColors.bgSlate,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          side: BorderSide(
                            color:
                                isSel
                                    ? AppColors.primaryTeal
                                    : AppColors.metallicBorder,
                          ),
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight:
                                isSel ? FontWeight.w800 : FontWeight.w600,
                            color:
                                isSel
                                    ? AppColors.primaryTeal
                                    : AppColors.textDark,
                          ),
                          onSelected: (val) {
                            setState(() => _selectedDurationDays = days);
                          },
                        );
                      }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Add to Regimen Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _addMedicineItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primaryTeal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                  ),
                ),
              ),
              icon: const Icon(Icons.add_circle_rounded, size: 16),
              label: Text(
                'Add Medicine to Regimen',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Active Prescription Items & Issue Bar Card ---
  Widget _buildActivePrescriptionItemsCard(AppState appState) {
    return BentoCard(
      title: 'Prescription Regimen Items (${_prescribedItems.length})',
      subtitle: 'Medications included in this electronic prescription payload',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.verified_rounded,
              size: 13,
              color: AppColors.successGreen,
            ),
            const SizedBox(width: 4),
            Text(
              '0 Interactions',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.successText,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_prescribedItems.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.medication_liquid_outlined,
                    size: 28,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'No medications added yet.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'Select preset drugs or enter a custom prescription above.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _prescribedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final item = _prescribedItems[idx];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSlate,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.metallicBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: AppColors.primaryTeal,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['medicineName'],
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              '${item['dosage']} • ${item['frequency']} • ${item['durationDays']} Days Supply',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.dangerRed,
                          size: 16,
                        ),
                        onPressed: () {
                          setState(() {
                            _prescribedItems.removeAt(idx);
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 16),

          // Digital Cryptographic Signature & Broadcast Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.gradientBrand,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryTeal.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.draw_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Digitally Signed by Physician',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        Text(
                          'SHA-256 Verified Payload • DEA Compliant',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _submitPrescription(appState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 15,
                    color: AppColors.primaryDark,
                  ),
                  label: Text(
                    'Sign & Issue e-Rx',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable Patient Dropdown with Search Bar INSIDE the Dropdown Menu Box
class _SearchablePatientDropdown extends StatefulWidget {
  final List<PatientRecord> patients;
  final String? selectedPatientId;
  final ValueChanged<PatientRecord> onPatientSelected;

  const _SearchablePatientDropdown({
    required this.patients,
    required this.selectedPatientId,
    required this.onPatientSelected,
  });

  @override
  State<_SearchablePatientDropdown> createState() =>
      _SearchablePatientDropdownState();
}

class _SearchablePatientDropdownState
    extends State<_SearchablePatientDropdown> {
  bool _isOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final selectedPatient = widget.patients.firstWhere(
      (p) => p.id == widget.selectedPatientId,
      orElse:
          () => PatientRecord(
            id: '',
            name: '',
            email: '',
            phone: '',
            age: 0,
            gender: '',
            currentProblem: '',
            visitDate: DateTime.now(),
          ),
    );

    final query = _searchCtrl.text.trim().toLowerCase().replaceAll('-', '_');
    final filtered =
        widget.patients.where((p) {
          if (query.isEmpty) return true;
          final pid = p.id.toLowerCase().replaceAll('-', '_');
          final pname = p.name.toLowerCase().replaceAll('-', '_');
          final prob = p.currentProblem.toLowerCase().replaceAll('-', '_');
          return pid.contains(query) ||
              pname.contains(query) ||
              prob.contains(query);
        }).toList();

    final docId =
        (appState.currentUser.doctorId ?? appState.currentUser.id)
            .toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown Header Field
        InkWell(
          onTap: () {
            setState(() {
              _isOpen = !_isOpen;
              if (_isOpen) {
                _searchFocusNode.requestFocus();
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                    _isOpen
                        ? const Color(0xFF1244A2)
                        : const Color(0xFF1244A2).withValues(alpha: 0.4),
                width: _isOpen ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.badge_rounded,
                  size: 18,
                  color: Color(0xFF1244A2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      widget.selectedPatientId != null &&
                              selectedPatient.id.isNotEmpty
                          ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1244A2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ID: ${selectedPatient.id}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${selectedPatient.name} (${selectedPatient.currentProblem})',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                          : Text(
                            '-- Select Patient ID & Name from Roster --',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                ),
                Icon(
                  _isOpen
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  color: const Color(0xFF1244A2),
                  size: 22,
                ),
              ],
            ),
          ),
        ),

        // Dropdown Menu Body containing Search Bar AT THE TOP of the Dropdown
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.metallicBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SEARCH BAR INSIDE THE DROPDOWN MENU
                TextField(
                  controller: _searchCtrl,
                  focusNode: _searchFocusNode,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search inside dropdown by Patient ID or Name...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1244A2),
                      size: 16,
                    ),
                    suffixIcon:
                        _searchCtrl.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                            : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    fillColor: AppColors.bgSlate,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.metallicBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.metallicBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF1244A2),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Patients Items List
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final p = filtered[index];
                      final isMyClient =
                          (p.assignedDoctorId != null &&
                              p.assignedDoctorId!.toLowerCase() == docId) ||
                          p.id.toUpperCase().startsWith('PAT_0000') ||
                          p.id.toUpperCase().startsWith('PT-');
                      final isSelected = p.id == widget.selectedPatientId;

                      if (isMyClient) {
                        return InkWell(
                          onTap: () {
                            setState(() => _isOpen = false);
                            widget.onPatientSelected(p);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(
                                        0xFF1244A2,
                                      ).withValues(alpha: 0.15)
                                      : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? const Color(0xFF1244A2)
                                        : const Color(
                                          0xFF1244A2,
                                        ).withValues(alpha: 0.35),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1244A2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '★ CLIENT: ${p.id}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${p.name} (Age: ${p.age}) — ${p.currentProblem}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1244A2),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: Color(0xFF1244A2),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () {
                          setState(() => _isOpen = false);
                          widget.onPatientSelected(p);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFFF1F5F9)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF64748B),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'ID: ${p.id}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${p.name} (Age: ${p.age}) — ${p.currentProblem}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
