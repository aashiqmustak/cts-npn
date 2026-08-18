import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/models.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized && SupabaseConfig.isConfigured;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        print('Supabase credentials not configured in SupabaseConfig.');
      }
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      );
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Supabase: $e');
      }
    }
  }

  // Auth Operations
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    if (!isInitialized) return null;
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
      },
    );
    if (res.user != null) {
      await client.from('user_profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'name': name,
        'role': _roleToDbString(role),
        'title': _roleToTitle(role),
      });
    }
    return res;
  }

  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    if (!isInitialized) return null;
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    if (isInitialized) {
      await client.auth.signOut();
    }
  }

  UserRole dbStringToRole(String roleStr) {
    switch (roleStr) {
      case 'admin':
        return UserRole.admin;
      case 'insurance_agent':
        return UserRole.insuranceAgent;
      case 'doctor':
        return UserRole.doctor;
      case 'pharmacist':
        return UserRole.pharmacist;
      case 'patient':
        return UserRole.patient;
      default:
        return UserRole.pharmacist;
    }
  }

  String _roleToDbString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.insuranceAgent:
        return 'insurance_agent';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.pharmacist:
        return 'pharmacist';
      case UserRole.patient:
        return 'patient';
    }
  }

  String _roleToTitle(UserRole role) {
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

  // Hospitals Operations
  Future<List<Hospital>> fetchHospitals() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('hospitals').select('*').order('name');
      return (res as List).map((json) => Hospital.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchHospitals error: $e');
      return [];
    }
  }

  Future<Hospital?> addHospital(Hospital hospital) async {
    if (!isInitialized) return null;
    try {
      final res = await client
          .from('hospitals')
          .insert(hospital.toJson())
          .select()
          .single();
      return Hospital.fromJson(res);
    } catch (e) {
      if (kDebugMode) print('addHospital error: $e');
      return null;
    }
  }

  // Doctors Operations
  Future<List<Doctor>> fetchDoctors() async {
    if (!isInitialized) return [];
    try {
      final res = await client
          .from('doctors')
          .select('*, hospitals(name)')
          .order('name');
      return (res as List).map((json) => Doctor.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchDoctors error: $e');
      return [];
    }
  }

  // Patients Operations
  Future<List<PatientRecord>> fetchPatients() async {
    if (!isInitialized) return [];
    try {
      final res = await client
          .from('patients')
          .select('*, doctors(name), hospitals(name)')
          .order('name');
      return (res as List).map((json) => PatientRecord.fromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchPatients error: $e');
      return [];
    }
  }

  Future<PatientRecord?> addPatient(PatientRecord patient) async {
    if (!isInitialized) return null;
    try {
      final res = await client
          .from('patients')
          .insert(patient.toJson())
          .select('*, doctors(name), hospitals(name)')
          .single();
      return PatientRecord.fromJson(res);
    } catch (e) {
      if (kDebugMode) print('addPatient error: $e');
      return null;
    }
  }

  // Prescriptions & Items
  Future<List<Map<String, dynamic>>> fetchPrescriptionsForPatient(
      String patientIdOrName) async {
    if (!isInitialized) return [];
    try {
      // Lookup by patient_id or patient name filter
      final res = await client
          .from('prescriptions')
          .select(
            '*, patients!inner(*), doctors!inner(*), hospitals!inner(*), prescription_items(*)',
          )
          .or('patient_id.eq.$patientIdOrName,patients.name.ilike.%$patientIdOrName%');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      if (kDebugMode) print('fetchPrescriptionsForPatient error: $e');
      return [];
    }
  }

  Future<bool> createPrescriptionWithItems({
    required String patientId,
    required String doctorId,
    required String hospitalId,
    required String diagnosis,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!isInitialized) return false;
    try {
      final rxRes = await client
          .from('prescriptions')
          .insert({
            'patient_id': patientId,
            'doctor_id': doctorId,
            'hospital_id': hospitalId,
            'diagnosis': diagnosis,
            'notes': notes,
            'status': 'Prescribed',
          })
          .select()
          .single();

      final rxId = rxRes['id'];
      for (final item in items) {
        await client.from('prescription_items').insert({
          'prescription_id': rxId,
          'medicine_name': item['medicineName'],
          'dosage': item['dosage'],
          'frequency': item['frequency'],
          'duration_days': item['durationDays'] ?? 30,
          'is_dispensed': false,
          'instructions': item['instructions'] ?? '',
        });
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('createPrescriptionWithItems error: $e');
      return false;
    }
  }

  Future<bool> dispensePrescriptionItem(String itemId) async {
    if (!isInitialized) return false;
    try {
      await client.from('prescription_items').update({
        'is_dispensed': true,
        'dispensed_at': DateTime.now().toIso8601String(),
      }).eq('id', itemId);
      return true;
    } catch (e) {
      if (kDebugMode) print('dispensePrescriptionItem error: $e');
      return false;
    }
  }

  // Patient Interactive Logs
  Future<List<PatientMedicineLog>> fetchPatientMedicineLogs(
      String patientId) async {
    if (!isInitialized) return [];
    try {
      final res = await client
          .from('patient_medicine_logs')
          .select('*')
          .eq('patient_id', patientId)
          .order('log_date', ascending: false);
      return (res as List)
          .map((json) => PatientMedicineLog.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) print('fetchPatientMedicineLogs error: $e');
      return [];
    }
  }

  Future<bool> togglePatientMedicineLog(
      String logId, bool isTaken, String? notes) async {
    if (!isInitialized) return false;
    try {
      await client.from('patient_medicine_logs').update({
        'is_taken': isTaken,
        'notes': notes,
      }).eq('id', logId);
      return true;
    } catch (e) {
      if (kDebugMode) print('togglePatientMedicineLog error: $e');
      return false;
    }
  }

  Future<PatientMedicineLog?> addPatientMedicineLog({
    required String patientId,
    required String medicineName,
    required String scheduledTime,
    String? notes,
  }) async {
    if (!isInitialized) return null;
    try {
      final res = await client
          .from('patient_medicine_logs')
          .insert({
            'patient_id': patientId,
            'medicine_name': medicineName,
            'scheduled_time': scheduledTime,
            'is_taken': false,
            'log_date': DateTime.now().toIso8601String().split('T')[0],
            'notes': notes,
          })
          .select()
          .single();
      return PatientMedicineLog.fromJson(res);
    } catch (e) {
      if (kDebugMode) print('addPatientMedicineLog error: $e');
      return null;
    }
  }
}
