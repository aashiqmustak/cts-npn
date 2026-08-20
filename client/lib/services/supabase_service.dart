import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
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

  // Profile Operations
  Future<User?> upsertUserProfile({
    required String id,
    required String email,
    required String name,
    String? phone,
    String? hospitalName,
    required UserRole role,
  }) async {
    final roleStr = _roleToDbString(role);
    final titleStr = _roleToTitle(role);
    final profileData = {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'hospital_name': hospitalName,
      'role': roleStr,
      'title': titleStr,
    };

    if (isInitialized) {
      try {
        await client.from('user_profiles').upsert(profileData);
      } catch (e) {
        if (kDebugMode) print('upsertUserProfile error: $e');
      }
    }

    return User.fromJson(profileData);
  }

  Future<User?> fetchUserProfile(String emailOrId) async {
    if (!isInitialized) return null;
    try {
      final clean = emailOrId.trim().toLowerCase();
      final res = await client
          .from('user_profiles')
          .select('*')
          .or('id.eq.$clean,email.ilike.$clean')
          .maybeSingle();
      if (res != null) {
        return User.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('fetchUserProfile error: $e');
    }
    return null;
  }

  Future<List<User>> fetchUserProfiles() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('user_profiles').select('*').order('name');
      return (res as List).map((j) => User.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchUserProfiles error: $e');
      return [];
    }
  }

  // Plans & Drugs
  Future<List<Plan>> fetchPlans() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('plans').select('*');
      return (res as List).map((j) => Plan.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchPlans error: $e');
      return [];
    }
  }

  Future<List<Drug>> fetchDrugs() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('drugs').select('*').order('name');
      return (res as List).map((j) => Drug.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchDrugs error: $e');
      return [];
    }
  }

  Future<List<FormularyAlternative>> fetchFormularyAlternatives() async {
    if (!isInitialized) return [];
    try {
      // Try formulary_alternatives first, fallback to alternatives
      try {
        final res = await client.from('formulary_alternatives').select('*');
        return (res as List).map((j) => FormularyAlternative.fromJson(j)).toList();
      } catch (_) {
        final res = await client.from('alternatives').select('*');
        return (res as List).map((j) => FormularyAlternative.fromJson(j)).toList();
      }
    } catch (e) {
      // Table does not exist in Supabase schema yet; safely return empty list
      return [];
    }
  }

  Future<List<Prescription>> fetchPrescriptions() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('prescriptions').select('*, patients(name), doctors(name), hospitals(name)');
      return (res as List).map((j) => Prescription.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchPrescriptions error: $e');
      return [];
    }
  }

  Future<List<AdherenceFlag>> fetchAdherenceFlags() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('adherence_flags').select('*');
      return (res as List).map((j) => AdherenceFlag.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchAdherenceFlags error: $e');
      return [];
    }
  }

  Future<List<PAFrictionEvent>> fetchPAFrictionEvents() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('pa_friction_events').select('*');
      return (res as List).map((j) => PAFrictionEvent.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchPAFrictionEvents error: $e');
      return [];
    }
  }

  Future<List<PharmacistDispenseRecord>> fetchPharmacistDispenseRecords() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('pharmacist_dispense_records').select('*');
      return (res as List).map((j) => PharmacistDispenseRecord.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchPharmacistDispenseRecords error: $e');
      return [];
    }
  }

  Future<void> createPharmacistDispenseRecord({
    required String prescriptionId,
    required String prescriptionItemId,
    required String patientId,
    required String patientName,
    required String doctorId,
    required String doctorName,
    required String pharmacistId,
    required String pharmacistName,
    required String medicineName,
    required String dosage,
    required String frequency,
    String? notes,
  }) async {
    if (!isInitialized) return;
    try {
      await client.from('pharmacist_dispense_records').insert({
        'prescription_id': prescriptionId,
        'prescription_item_id': prescriptionItemId,
        'patient_id': patientId,
        'patient_name': patientName,
        'doctor_id': doctorId,
        'doctor_name': doctorName,
        'pharmacist_id': pharmacistId,
        'pharmacist_name': pharmacistName,
        'medicine_name': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'notes': notes,
      });
    } catch (e) {
      if (kDebugMode) print('createPharmacistDispenseRecord error: $e');
    }
  }

  // OTP Operations
  Future<bool> saveOtp({
    required String email,
    required String otpCode,
  }) async {
    if (!isInitialized) {
      if (kDebugMode) print('saveOtp error: Supabase service is not initialized');
      return false;
    }
    try {
      final cleanEmail = email.trim().toLowerCase();

      // 1. Invalidate previous unused OTPs for this email (best-effort)
      try {
        await client
            .from('otp_codes')
            .update({'is_used': true})
            .eq('email', cleanEmail)
            .eq('is_used', false);
      } catch (err) {
        if (kDebugMode) print('saveOtp invalidation warning: $err');
      }

      // 2. Insert new 6-digit OTP code record with 10-minute expiry
      final expiresAt = DateTime.now().toUtc().add(const Duration(minutes: 10)).toIso8601String();
      await client.from('otp_codes').insert({
        'email': cleanEmail,
        'otp_code': otpCode,
        'expires_at': expiresAt,
        'is_used': false,
      });

      if (kDebugMode) {
        print('OTP ($otpCode) saved successfully to Supabase DB for $cleanEmail');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('saveOtp error saving to Supabase DB: $e');
      return false;
    }
  }

  Future<bool> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otpCode.trim();

    if (!isInitialized) {
      if (kDebugMode) print('verifyOtp error: Supabase service is not initialized');
      return false;
    }
    try {
      final res = await client
          .from('otp_codes')
          .select('*')
          .eq('email', cleanEmail)
          .eq('otp_code', cleanOtp)
          .eq('is_used', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        final expiresAtStr = res['expires_at'];
        if (expiresAtStr != null) {
          final str = expiresAtStr.toString();
          DateTime? parsedDate = DateTime.tryParse(str);
          if (parsedDate != null) {
            // Ensure date is treated as UTC for comparison
            final expiresAtUtc = str.endsWith('Z') || str.contains('+')
                ? parsedDate.toUtc()
                : DateTime.tryParse('${str}Z')?.toUtc() ?? parsedDate.toUtc();
            final nowUtc = DateTime.now().toUtc();
            
            if (expiresAtUtc.isBefore(nowUtc)) {
              if (kDebugMode) print('verifyOtp: OTP code expired ($expiresAtUtc is before $nowUtc)');
              return false;
            }
          }
        }

        // Mark OTP as used once verified
        final otpId = res['id'];
        await client
            .from('otp_codes')
            .update({'is_used': true})
            .eq('id', otpId);

        if (kDebugMode) {
          print('OTP verified successfully in Supabase for $cleanEmail');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('verifyOtp: No valid unused OTP matching $cleanOtp for $cleanEmail found in Supabase DB');
        }
      }
    } catch (e) {
      if (kDebugMode) print('verifyOtp error reading from Supabase DB: $e');
    }
    return false;
  }
}
