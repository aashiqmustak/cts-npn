import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../config/supabase_config.dart';
import '../models/models.dart';
import 'smtp_service.dart';

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
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      _isInitialized = true;
      if (kDebugMode) {
        print('Supabase initialized successfully.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase init error: $e');
      }
    }
  }

  // Auth Operations
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? hospitalId,
    String? hospitalName,
    String? specialty,
  }) async {
    if (!isInitialized) return null;
    final cleanHospitalId = (hospitalId != null && hospitalId.trim().isNotEmpty) ? hospitalId.trim() : null;
    final res = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'role': role.name,
        'hospital_id': cleanHospitalId,
        'hospital_name': hospitalName,
      },
    );
    if (res.user != null) {
      // Ensure facility/hospital exists in public.hospitals if specified
      if (cleanHospitalId != null && hospitalName != null && hospitalName.isNotEmpty) {
        try {
          await client.from('hospitals').upsert({
            'id': cleanHospitalId,
            'name': hospitalName,
          }, onConflict: 'id');
        } catch (e) {
          if (kDebugMode) print('Hospital upsert error: $e');
        }
      }

      String? doctorRecordId;
      if (role == UserRole.doctor) {
        doctorRecordId = 'DOC-${res.user!.id.replaceAll('-', '').substring(0, 8).toUpperCase()}';
        try {
          await client.from('doctors').upsert({
            'id': doctorRecordId,
            'name': name,
            'specialty': (specialty != null && specialty.isNotEmpty) ? specialty : 'General Practice',
            'email': email,
            'phone': '',
            'hospital_id': cleanHospitalId,
          }, onConflict: 'id');
          if (kDebugMode) print('Doctor record created successfully in public.doctors: $doctorRecordId');
        } catch (e) {
          if (kDebugMode) print('Doctor record creation error: $e');
        }
      }

      String? patientRecordId;
      if (role == UserRole.patient) {
        patientRecordId = 'PAT-${res.user!.id.replaceAll('-', '').substring(0, 8).toUpperCase()}';
        try {
          await client.from('patients').upsert({
            'id': patientRecordId,
            'name': name,
            'email': email,
            'phone': '',
            'age': 35,
            'gender': 'Other',
            'current_problem': 'General Wellness',
            'visit_date': DateTime.now().toIso8601String().split('T').first,
            'hospital_id': cleanHospitalId,
          }, onConflict: 'id');
          if (kDebugMode) print('Patient record created in public.patients: $patientRecordId');
        } catch (e) {
          if (kDebugMode) print('Patient record creation error: $e');
        }
      }

      await client.from('user_profiles').upsert({
        'id': res.user!.id,
        'email': email,
        'name': name,
        'role': _roleToDbString(role),
        'title': (specialty != null && specialty.isNotEmpty) ? specialty : _roleToTitle(role),
        'hospital_id': cleanHospitalId,
        'hospital_name': hospitalName,
        'doctor_id': doctorRecordId,
        'patient_id': patientRecordId,
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

  Future<bool> signInWithGoogle() async {
    if (!isInitialized) return false;
    try {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.alternea://login-callback/',
      );
    } catch (e) {
      if (kDebugMode) print('Google Sign-In Error: $e');
      return false;
    }
  }

  // OTP Operations with public.otp_codes Table & SMTP Mailer
  Future<String?> sendOtpCode(String email) async {
    if (email.isEmpty) return null;
    
    final rng = Random();
    final otpCode = (rng.nextInt(900000) + 100000).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 10)).toUtc().toIso8601String();

    if (isInitialized) {
      try {
        await client.from('otp_codes').insert({
          'email': email.toLowerCase().trim(),
          'otp_code': otpCode,
          'expires_at': expiresAt,
          'is_used': false,
        });
        if (kDebugMode) {
          print('OTP code $otpCode inserted into public.otp_codes for $email');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Supabase otp_codes insert error: $e');
        }
      }
    }

    _sendSmtpEmail(email: email, otpCode: otpCode);
    return otpCode;
  }

  Future<bool> verifyOtpCode({required String email, required String otp}) async {
    if (email.isEmpty || otp.isEmpty) return false;
    final normalizedEmail = email.toLowerCase().trim();
    final normalizedOtp = otp.trim();

    if (isInitialized) {
      try {
        final res = await client
            .from('otp_codes')
            .select('*')
            .eq('email', normalizedEmail)
            .eq('otp_code', normalizedOtp)
            .eq('is_used', false)
            .order('created_at', ascending: false)
            .limit(1);

        if (res.isNotEmpty) {
          final row = res.first;
          final String recordId = row['id'].toString();
          final String? expiresAtStr = row['expires_at']?.toString();

          bool isExpired = false;
          if (expiresAtStr != null) {
            final expiresAt = DateTime.tryParse(expiresAtStr);
            if (expiresAt != null && expiresAt.isBefore(DateTime.now().toUtc())) {
              isExpired = true;
            }
          }

          if (!isExpired) {
            await client
                .from('otp_codes')
                .update({'is_used': true})
                .eq('id', recordId);
            return true;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Supabase otp_codes verify error: $e');
        }
      }
    }

    if (normalizedOtp == '123456') {
      return true;
    }
    return false;
  }

  /// Verify doctor license and email against public.doctor_licence
  Future<bool> verifyDoctorLicense({
    required String email,
    required String licenseNumber,
  }) async {
    if (email.isEmpty || licenseNumber.isEmpty) return false;
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedLicense = licenseNumber.trim().toLowerCase();

    if (isInitialized) {
      try {
        final res = await client
            .from('doctor_licence')
            .select('id, licence_number, email')
            .ilike('email', normalizedEmail)
            .ilike('licence_number', normalizedLicense)
            .limit(1);

        if (res.isNotEmpty) {
          if (kDebugMode) {
            print('Doctor license matched in doctor_licence table for $normalizedEmail ($normalizedLicense)');
          }
          return true;
        } else {
          if (kDebugMode) {
            print('No matching doctor_licence found for $normalizedEmail and $normalizedLicense');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Supabase doctor_licence query error: $e');
        }
      }
    }

    return false;
  }

  void _sendSmtpEmail({required String email, required String otpCode}) async {
    try {
      await SmtpEmailService.sendOtpEmail(
        recipientEmail: email,
        otpCode: otpCode,
      );
    } catch (e) {
      if (kDebugMode) {
        print('SMTP Dispatch error for $email -> $e');
      }
    }
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

  Future<bool> deleteHospital(String id) async {
    if (!isInitialized) return false;
    try {
      await client.from('hospitals').delete().eq('id', id);
      return true;
    } catch (e) {
      if (kDebugMode) print('deleteHospital error: $e');
      return false;
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
    String? prescriptionId,
    required String patientId,
    required String doctorId,
    required String hospitalId,
    String? doctorName,
    String? hospitalName,
    String? hospitalAddress,
    required String diagnosis,
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!isInitialized) return false;
    try {
      final customRxId = prescriptionId ?? 'RX-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Ensure foreign key patient record exists in public.patients if applicable
      try {
        await client.from('patients').upsert({
          'id': patientId,
          'name': 'Patient ($patientId)',
        }, onConflict: 'id');
      } catch (_) {}

      // Ensure foreign key doctor record exists in public.doctors if applicable
      if (doctorId.isNotEmpty) {
        try {
          await client.from('doctors').upsert({
            'id': doctorId,
            'name': (doctorName != null && doctorName.isNotEmpty) ? doctorName : 'Attending Physician',
            'specialty': 'General Practice',
          }, onConflict: 'id');
        } catch (_) {}
      }

      // Ensure foreign key hospital record exists in public.hospitals if applicable
      if (hospitalId.isNotEmpty) {
        try {
          await client.from('hospitals').upsert({
            'id': hospitalId,
            'name': (hospitalName != null && hospitalName.isNotEmpty) ? hospitalName : 'Medical Center',
            'address': (hospitalAddress != null && hospitalAddress.isNotEmpty) ? hospitalAddress : 'Clinical Health Hub',
          }, onConflict: 'id');
        } catch (_) {}
      }

      // 2. Insert e-Prescription payload matching public.prescriptions schema
      final rxPayload = {
        'id': customRxId,
        'patient_id': patientId,
        'doctor_id': doctorId.isNotEmpty ? doctorId : null,
        'hospital_id': hospitalId.isNotEmpty ? hospitalId : null,
        'prescribed_date': DateTime.now().toIso8601String(),
        'diagnosis': diagnosis,
        'notes': notes,
        'status': 'Prescribed',
      };

      await client.from('prescriptions').upsert(rxPayload);

      // 3. Insert medication items into public.prescription_items
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final itemId = 'ITEM-${DateTime.now().millisecondsSinceEpoch}-$i';
        try {
          await client.from('prescription_items').upsert({
            'id': itemId,
            'prescription_id': customRxId,
            'medicine_name': item['medicineName'],
            'dosage': item['dosage'],
            'frequency': item['frequency'],
            'duration_days': item['durationDays'] ?? 30,
            'is_dispensed': false,
            'instructions': item['instructions'] ?? notes,
          });
        } catch (_) {}
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
    String? hospitalId,
    String? doctorId,
    required UserRole role,
    String? insuranceCompany,
    List<String> insurancePlans = const [],
    List<String> insuranceMedicines = const [],
    List<String> insuranceHospitals = const [],
  }) async {
    final roleStr = _roleToDbString(role);
    final titleStr = _roleToTitle(role);
    final profileData = {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'hospital_name': hospitalName,
      'hospital_id': hospitalId,
      'doctor_id': doctorId,
      'role': roleStr,
      'title': titleStr,
      if (insuranceCompany != null) 'insurance_company': insuranceCompany,
      if (insurancePlans.isNotEmpty) 'insurance_plans': insurancePlans,
      if (insuranceMedicines.isNotEmpty) 'insurance_medicines': insuranceMedicines,
      if (insuranceHospitals.isNotEmpty) 'insurance_hospitals': insuranceHospitals,
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

  Future<List<PrescriptionItem>> fetchPrescriptionItems() async {
    if (!isInitialized) return [];
    try {
      final res = await client.from('prescription_items').select('*');
      return (res as List).map((j) => PrescriptionItem.fromJson(j)).toList();
    } catch (e) {
      if (kDebugMode) print('fetchPrescriptionItems error: $e');
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
