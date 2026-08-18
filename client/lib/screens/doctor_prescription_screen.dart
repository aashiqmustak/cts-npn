import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

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
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();

  bool _createNewPatient = true;

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
    if (_medNameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Medicine Name & Dosage')),
      );
      return;
    }
    setState(() {
      _prescribedItems.add({
        'medicineName': _medNameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'frequency': _frequencyController.text.trim().isEmpty
            ? 'Once daily'
            : _frequencyController.text.trim(),
        'durationDays': 30,
        'instructions': 'As prescribed by physician',
      });
      _medNameController.clear();
      _dosageController.clear();
      _frequencyController.clear();
    });
  }

  void _submitPrescription(AppState appState) async {
    String hospitalId = _selectedHospitalId ?? '';

    if (_createNewHospital || hospitalId.isEmpty) {
      if (_hospitalNameController.text.trim().isEmpty ||
          _hospitalAddressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter Hospital Name & Address Alone')),
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
        const SnackBar(content: Text('Please add at least one medicine item')),
      );
      return;
    }

    String patientId = _selectedPatientId ?? '';

    if (_createNewPatient || patientId.isEmpty) {
      if (_patientNameController.text.trim().isEmpty ||
          _currentProblemController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter Patient Name & Current Problem')),
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
            ? '(555) 000-1122'
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
        const SnackBar(
          backgroundColor: AppColors.primaryTeal,
          content: Text(
              'Prescription Issued Successfully! Saved & ready for Pharmacist Dispensing.'),
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
    } else if (_selectedHospitalId == null) {
      _selectedHospitalId = hospitals.first.id;
    }

    if (patients.isEmpty) {
      _createNewPatient = true;
    } else if (_selectedPatientId == null) {
      _selectedPatientId = patients.first.id;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accentNavy, AppColors.accentNavy.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Doctor Prescription Portal',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Enter patient visit details, map hospital info from scratch, and issue digital prescriptions to Pharmacist.',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Main Form Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '1. Hospital & Clinic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                        ),
                      ),
                      if (hospitals.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _createNewHospital = !_createNewHospital;
                            });
                          },
                          icon: Icon(_createNewHospital
                              ? Icons.list_alt
                              : Icons.add_business_outlined),
                          label: Text(_createNewHospital
                              ? 'Select Existing Hospital'
                              : 'Add New Hospital'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (hospitals.isNotEmpty && !_createNewHospital) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedHospitalId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
                        labelText: 'Select Hospital',
                      ),
                      items: hospitals.map((h) {
                        return DropdownMenuItem(
                          value: h.id,
                          child: Text('${h.name} — ${h.address}, ${h.city}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedHospitalId = val;
                        });
                      },
                    ),
                  ] else ...[
                    TextField(
                      controller: _hospitalNameController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital / Clinic Name',
                        hintText: 'e.g. St. Jude General Hospital',
                        prefixIcon: Icon(Icons.local_hospital, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hospitalAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Hospital Address Alone',
                        hintText: 'e.g. 124 Healthcare Boulevard, New York',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '2. Patient Visit Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                        ),
                      ),
                      if (patients.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _createNewPatient = !_createNewPatient;
                            });
                          },
                          icon: Icon(_createNewPatient
                              ? Icons.person_search_outlined
                              : Icons.person_add_alt_outlined),
                          label: Text(_createNewPatient
                              ? 'Select Existing Patient'
                              : 'Add New Patient Visit'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (patients.isNotEmpty && !_createNewPatient) ...[
                    DropdownButtonFormField<String>(
                      value: _selectedPatientId,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, size: 20),
                        labelText: 'Select Registered Patient',
                      ),
                      items: patients.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                              '${p.name} (Age: ${p.age}) — ${p.currentProblem}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPatientId = val;
                        });
                      },
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _patientNameController,
                            decoration: const InputDecoration(
                              labelText: 'Patient Full Name',
                              hintText: 'e.g. Eleanor Vance',
                              prefixIcon: Icon(Icons.person, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _patientAgeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age',
                              hintText: 'e.g. 67',
                              prefixIcon: Icon(Icons.cake_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _currentProblemController,
                      decoration: const InputDecoration(
                        labelText: 'Current Problem / Medical Issue & Visit Date',
                        hintText: 'e.g. Hypertension & Type 2 Diabetes Checkup (Visit Date: Today)',
                        prefixIcon: Icon(Icons.sick_outlined, size: 18),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  TextField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Diagnosis',
                      hintText: 'e.g. Essential Primary Hypertension',
                      prefixIcon: Icon(Icons.assignment_outlined, size: 18),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    '3. Prescribe Medicines',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentNavy,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Add Medicine Form Row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgSlate,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _medNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Medicine Name',
                                  hintText: 'e.g. Metformin 500mg',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _dosageController,
                                decoration: const InputDecoration(
                                  labelText: 'Dosage',
                                  hintText: 'e.g. 500 mg',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _frequencyController,
                                decoration: const InputDecoration(
                                  labelText: 'Frequency',
                                  hintText: 'Twice daily',
                                  isDense: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _addMedicineItem,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Rx'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Prescribed Items List Table
                  if (_prescribedItems.isNotEmpty) ...[
                    const Text('Prescription Items Ready to Issue:',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _prescribedItems.map((item) {
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.bgSlate,
                              child: Icon(Icons.medication,
                                  color: AppColors.primaryTeal),
                            ),
                            title: Text(
                              '${item['medicineName']} (${item['dosage']})',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Frequency: ${item['frequency']} | Instructions: ${item['instructions']}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: AppColors.dangerRed),
                              onPressed: () {
                                setState(() {
                                  _prescribedItems.remove(item);
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Doctor Notes for Pharmacist & Patient',
                      hintText: 'e.g. Take after meals with full glass of water',
                    ),
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _submitPrescription(appState),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text(
                        'Issue Prescription to Pharmacist',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
