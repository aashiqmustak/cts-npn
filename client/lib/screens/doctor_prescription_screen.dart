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
    'Every 8 hours',
    'At bedtime',
    'As needed (PRN)',
  ];

  final List<int> _durationOptions = [7, 14, 30, 60, 90];

  @override
  void dispose() {
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
        'dosage': _dosageController.text.trim().isEmpty
            ? '1 Tablet'
            : _dosageController.text.trim(),
        'frequency': _frequencyController.text.trim().isEmpty
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
    String hospitalId = _selectedHospitalId ?? '';

    if (_createNewHospital || hospitalId.isEmpty) {
      if (_hospitalNameController.text.trim().isEmpty ||
          _hospitalAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.dangerText,
            content: Text('Please provide Hospital Facility Name & Address'),
          ),
        );
        return;
      }
      final newHospital = Hospital(
        id: 'HOSP-${DateTime.now().millisecondsSinceEpoch}',
        name: _hospitalNameController.text.trim(),
        address: _hospitalAddressController.text.trim(),
        city: 'New York',
        state: 'NY',
        zip: '10001',
        phone: '(212) 555-0100',
      );
      appState.addHospital(newHospital);
      hospitalId = newHospital.id;
    }

    if (_prescribedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.dangerText,
          content: Text(
              'Please add at least one medication item to the prescription regimen'),
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
        email: _patientEmailController.text.trim().isEmpty
            ? 'patient@alternea.org'
            : _patientEmailController.text.trim(),
        phone: _patientPhoneController.text.trim().isEmpty
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
      diagnosis: _diagnosisController.text.trim().isEmpty
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final hospitals = appState.hospitals;
    final patients = appState.patientRecords;

    if (hospitals.isEmpty) {
      _createNewHospital = true;
    } else {
      _selectedHospitalId ??= hospitals.first.id;
    }

    if (patients.isEmpty) {
      _createNewPatient = true;
    } else {
      _selectedPatientId ??= patients.first.id;
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
                  const Icon(Icons.verified_user_rounded,
                      color: AppColors.electricMint, size: 16),
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
                    _buildFacilityCard(hospitals),
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
  Widget _buildFacilityCard(List<Hospital> hospitals) {
    return BentoCard(
      title: 'Clinical Facility & Hospital Context',
      subtitle: 'Select practice location or authorized medical center',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.local_hospital_rounded,
            color: AppColors.primaryTeal, size: 18),
      ),
      trailing: TextButton.icon(
        onPressed: () {
          setState(() {
            _createNewHospital = !_createNewHospital;
          });
        },
        icon: Icon(
          _createNewHospital
              ? Icons.list_alt_rounded
              : Icons.add_business_outlined,
          size: 15,
          color: AppColors.primaryTeal,
        ),
        label: Text(
          _createNewHospital ? 'Existing' : '+ Add Facility',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryTeal,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hospitals.isNotEmpty && !_createNewHospital) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedHospitalId,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.local_hospital_outlined,
                    size: 16, color: AppColors.primaryTeal),
                labelText: 'Authorized Medical Center',
              ),
              items: hospitals.map((h) {
                return DropdownMenuItem(
                  value: h.id,
                  child: Text('${h.name} (${h.city}, ${h.state})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedHospitalId = val),
            ),
          ] else ...[
            TextField(
              controller: _hospitalNameController,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Hospital / Clinic Name',
                hintText: 'e.g. MetroHealth Medical Center',
                prefixIcon: Icon(Icons.domain_rounded,
                    size: 16, color: AppColors.primaryTeal),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _hospitalAddressController,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Street Address',
                hintText: 'e.g. 100 Hospital Way, Suite 400',
                prefixIcon: Icon(Icons.location_on_outlined,
                    size: 16, color: AppColors.primaryTeal),
              ),
            ),
          ],
        ],
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
        child: const Icon(Icons.person_rounded,
            color: AppColors.primaryTeal, size: 18),
      ),
      trailing: TextButton.icon(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (patients.isNotEmpty && !_createNewPatient) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedPatientId,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.badge_outlined,
                    size: 16, color: AppColors.primaryTeal),
                labelText: 'Select Registered Patient',
              ),
              items: patients.map((p) {
                return DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.name} (Age: ${p.age}) — ${p.currentProblem}'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedPatientId = val),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _patientNameController,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark),
                    decoration: const InputDecoration(
                      labelText: 'Patient Full Name',
                      hintText: 'e.g. Eleanor Vance',
                      prefixIcon: Icon(Icons.badge_outlined,
                          size: 16, color: AppColors.primaryTeal),
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
                        color: AppColors.textDark),
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
                  color: AppColors.textDark),
              decoration: const InputDecoration(
                labelText: 'Chief Medical Complaint',
                hintText: 'e.g. Type 2 Diabetes Management & Blood Pressure',
                prefixIcon: Icon(Icons.healing_outlined,
                    size: 16, color: AppColors.primaryTeal),
              ),
            ),
          ],
          const SizedBox(height: 10),

          TextField(
            controller: _diagnosisController,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Formal ICD-10 Code / Clinical Diagnosis',
              hintText: 'e.g. E11.9 (Type 2 Diabetes Without Complications)',
              prefixIcon: Icon(Icons.medical_information_outlined,
                  size: 16, color: AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _notesController,
            maxLines: 2,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Physician Clinical Regimen Notes',
              hintText:
                  'e.g. Take with food, monitor daily blood glucose, follow up in 30 days',
              prefixIcon: Icon(Icons.notes_rounded,
                  size: 16, color: AppColors.primaryTeal),
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
      subtitle: 'Prescribe active therapeutic items, dosages, and refill limits',
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.medication_rounded,
            color: AppColors.primaryTeal, size: 18),
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
            children: _quickDrugs.map((drug) {
              final isSelected = _medNameController.text == drug;
              return ChoiceChip(
                label: Text(drug),
                selected: isSelected,
                selectedColor: AppColors.primaryLight,
                backgroundColor: AppColors.bgSlate,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.metallicBorder,
                ),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
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

          // Custom Drug Name Field
          TextField(
            controller: _medNameController,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
            decoration: const InputDecoration(
              labelText: 'Drug Name & Strength',
              hintText: 'e.g. Metformin HCL 500mg',
              prefixIcon: Icon(Icons.medication_liquid_rounded,
                  size: 16, color: AppColors.primaryTeal),
            ),
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
                      color: AppColors.textDark),
                  decoration: const InputDecoration(
                    labelText: 'Formulation / Dose',
                    hintText: '1 Tablet (Oral)',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _frequencyController.text,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark),
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                  ),
                  items: _frequencies.map((f) {
                    return DropdownMenuItem(value: f, child: Text(f));
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
                  children: _durationOptions.map((days) {
                    final isSel = _selectedDurationDays == days;
                    return ChoiceChip(
                      label: Text('$days Days'),
                      selected: isSel,
                      selectedColor: AppColors.primaryLight,
                      backgroundColor: AppColors.bgSlate,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      side: BorderSide(
                        color: isSel
                            ? AppColors.primaryTeal
                            : AppColors.metallicBorder,
                      ),
                      labelStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight:
                            isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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
      subtitle:
          'Medications included in this electronic prescription payload',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                size: 13, color: AppColors.successGreen),
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
                  const Icon(Icons.medication_liquid_outlined,
                      size: 28, color: AppColors.textMuted),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        child: const Icon(Icons.medication_rounded,
                            color: AppColors.primaryTeal, size: 16),
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
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.dangerRed, size: 16),
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
                      child: const Icon(Icons.draw_rounded,
                          color: Colors.white, size: 18),
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
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded,
                      size: 15, color: AppColors.primaryDark),
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
