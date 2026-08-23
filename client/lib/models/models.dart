import 'package:flutter/material.dart';
import 'dart:convert';

enum UserRole {
  admin,
  insuranceAgent,
  doctor,
  pharmacist,
  patient,
}

/// Extension for user-friendly presentation of the 5 system roles.
extension UserRoleAuthMeta on UserRole {
  String get label {
    switch (this) {
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.patient:
        return 'Patient';
      case UserRole.insuranceAgent:
        return 'Insurance Agent';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get subtitle {
    switch (this) {
      case UserRole.doctor:
        return 'Prescribe & Consult';
      case UserRole.pharmacist:
        return 'Dispense & Adherence';
      case UserRole.patient:
        return 'Meds & Health Hub';
      case UserRole.insuranceAgent:
        return 'Policies & Claims';
      case UserRole.admin:
        return 'System Governance';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.doctor:
        return Icons.medical_services_rounded;
      case UserRole.pharmacist:
        return Icons.local_pharmacy_rounded;
      case UserRole.patient:
        return Icons.favorite_rounded;
      case UserRole.insuranceAgent:
        return Icons.verified_user_rounded;
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
    }
  }

  String get defaultEmail => '';
}

enum RiskLevel { high, medium, low }

enum OutreachStatus { pending, contacted, resolved, declined }

enum FrictionStatus { blocked, inReview, appealed, resolved }

enum BarrierType { paRequired, stepTherapyFailed, quantityLimit }

class PatientProfile {
  final String patientId;
  final String name;
  final DateTime? dateOfBirth;
  final int age;
  final String gender;
  final String phone;
  final String email;
  final String height;
  final String weight;
  final String address;
  final String city;
  final String bloodGroup;
  final String allergies;
  final String chronicConditions;

  const PatientProfile({
    required this.patientId,
    required this.name,
    this.dateOfBirth,
    required this.age,
    required this.gender,
    required this.phone,
    required this.email,
    required this.height,
    required this.weight,
    required this.address,
    required this.city,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final dobString = json['dob']?.toString();
    return PatientProfile(
      patientId: json['patient_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      dateOfBirth: dobString != null && dobString.isNotEmpty ? DateTime.tryParse(dobString) : null,
      age: int.tryParse(json['age']?.toString() ?? '') ?? 0,
      gender: json['gender']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      bloodGroup: json['blood_group']?.toString() ?? '',
      allergies: json['allergies']?.toString() ?? '',
      chronicConditions: json['chronic_conditions']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'name': name,
        'dob': dateOfBirth?.toIso8601String(),
        'age': age,
        'gender': gender,
        'phone': phone,
        'email': email,
        'height': height,
        'weight': weight,
        'address': address,
        'city': city,
        'blood_group': bloodGroup,
        'allergies': allergies,
        'chronic_conditions': chronicConditions,
      };

  bool get isComplete =>
      patientId.isNotEmpty &&
      name.isNotEmpty &&
      (dateOfBirth != null || age > 0) &&
      gender.isNotEmpty;
}

class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? googleAccountId;
  final String? googleEmail;
  final String? googleAvatarUrl;
  final UserRole role;
  final List<String> assignedPatientIds;
  final String avatarUrl;
  final String title;
  final String? hospitalId;
  final String? hospitalName;
  final String? doctorId;
  final String? patientId;
  final PatientProfile? patientProfile;
  final String? insuranceCompany;
  final List<String> insurancePlans;
  final List<String> insuranceMedicines;
  final List<String> insuranceHospitals;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.googleAccountId,
    this.googleEmail,
    this.googleAvatarUrl,
    required this.role,
    this.assignedPatientIds = const [],
    this.avatarUrl = '',
    required this.title,
    this.hospitalId,
    this.hospitalName,
    this.doctorId,
    this.patientId,
    this.patientProfile,
    this.insuranceCompany,
    this.insurancePlans = const [],
    this.insuranceMedicines = const [],
    this.insuranceHospitals = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    List<String>? assignedPatientIds,
    String? avatarUrl,
    String? title,
    String? hospitalId,
    String? hospitalName,
    String? doctorId,
    String? patientId,
    PatientProfile? patientProfile,
    String? insuranceCompany,
    List<String>? insurancePlans,
    List<String>? insuranceMedicines,
    List<String>? insuranceHospitals,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedPatientIds: assignedPatientIds ?? this.assignedPatientIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      title: title ?? this.title,
      hospitalId: hospitalId ?? this.hospitalId,
      hospitalName: hospitalName ?? this.hospitalName,
      doctorId: doctorId ?? this.doctorId,
      patientId: patientId ?? this.patientId,
      patientProfile: patientProfile ?? this.patientProfile,
      insuranceCompany: insuranceCompany ?? this.insuranceCompany,
      insurancePlans: insurancePlans ?? this.insurancePlans,
      insuranceMedicines: insuranceMedicines ?? this.insuranceMedicines,
      insuranceHospitals: insuranceHospitals ?? this.insuranceHospitals,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.pharmacist;
    final rStr = (json['role'] ?? '').toString().toLowerCase();
    if (rStr == 'doctor') parsedRole = UserRole.doctor;
    if (rStr == 'patient') parsedRole = UserRole.patient;
    if (rStr == 'insurance_agent' || rStr == 'insuranceagent') parsedRole = UserRole.insuranceAgent;
    if (rStr == 'admin') parsedRole = UserRole.admin;
    if (rStr == 'pharmacist') parsedRole = UserRole.pharmacist;

    final patientProfileJson = json['patient_profile'];

    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone']?.toString(),
      googleAccountId: json['google_account_id']?.toString(),
      googleEmail: json['google_email']?.toString() ?? json['email']?.toString(),
      googleAvatarUrl: json['google_avatar_url']?.toString(),
      role: parsedRole,
      assignedPatientIds: (json['assigned_patient_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      avatarUrl: json['avatar_url'] ?? '',
      title: json['title'] ?? '',
      hospitalId: json['hospital_id']?.toString(),
      hospitalName: json['hospital_name']?.toString() ?? json['hospitals']?['name']?.toString(),
      doctorId: json['doctor_id']?.toString(),
      patientId: json['patient_id']?.toString(),
        patientProfile: patientProfileJson is Map<String, dynamic>
          ? PatientProfile.fromJson(patientProfileJson)
          : null,
      insuranceCompany: json['insurance_company']?.toString(),
      insurancePlans: (json['insurance_plans'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      insuranceMedicines: (json['insurance_medicines'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      insuranceHospitals: (json['insurance_hospitals'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
      'google_account_id': googleAccountId,
      'google_email': googleEmail ?? email,
      'google_avatar_url': googleAvatarUrl,
        'role': role.name,
        'title': title,
        'hospital_id': hospitalId,
        'hospital_name': hospitalName,
        'doctor_id': doctorId,
        'patient_id': patientId,
        'patient_profile': patientProfile?.toJson(),
        'insurance_company': insuranceCompany,
        'insurance_plans': insurancePlans,
        'insurance_medicines': insuranceMedicines,
        'insurance_hospitals': insuranceHospitals,
      };

  bool get isAdmin => role == UserRole.admin;
  bool get isInsuranceAgent => role == UserRole.insuranceAgent;
  bool get isDoctor => role == UserRole.doctor;
  bool get isPharmacist => role == UserRole.pharmacist;
  bool get isPatient => role == UserRole.patient;

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Software System Administrator';
      case UserRole.insuranceAgent:
        return 'Insurance Agent';
      case UserRole.doctor:
        return 'Doctor / Physician';
      case UserRole.pharmacist:
        return 'Pharmacist';
      case UserRole.patient:
        return 'Patient';
    }
  }
}

class Hospital {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String phone;

  const Hospital({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.phone,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? 'NY',
      zip: json['zip'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'phone': phone,
      };
}

class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String email;
  final String phone;
  final String hospitalId;
  final String? hospitalName;

  const Doctor({
    required this.id,
    required this.name,
    required this.specialty,
    required this.email,
    required this.phone,
    required this.hospitalId,
    this.hospitalName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      specialty: json['specialty'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      hospitalId: json['hospital_id'] ?? '',
      hospitalName: json['hospitals']?['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'specialty': specialty,
        'email': email,
        'phone': phone,
        'hospital_id': hospitalId,
      };
}

class PatientRecord {
  final String id;
  final String name;
  final String email;
  final String phone;
  final int age;
  final String gender;
  final String currentProblem;
  final DateTime visitDate;
  final String? assignedDoctorId;
  final String? assignedDoctorName;
  final String? hospitalId;
  final String? hospitalName;
  final double riskScore;

  const PatientRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.age,
    required this.gender,
    required this.currentProblem,
    required this.visitDate,
    this.assignedDoctorId,
    this.assignedDoctorName,
    this.hospitalId,
    this.hospitalName,
    this.riskScore = 0.25,
  });

  factory PatientRecord.fromJson(Map<String, dynamic> json) {
    return PatientRecord(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      age: json['age'] ?? 40,
      gender: json['gender'] ?? 'Other',
      currentProblem: json['current_problem'] ?? '',
      visitDate: json['visit_date'] != null
          ? DateTime.tryParse(json['visit_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedDoctorId: json['assigned_doctor_id'],
      assignedDoctorName: json['doctors']?['name'],
      hospitalId: json['hospital_id'],
      hospitalName: json['hospitals']?['name'],
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.25,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'age': age,
        'gender': gender,
        'current_problem': currentProblem,
        'visit_date': visitDate.toIso8601String().split('T')[0],
        'assigned_doctor_id': assignedDoctorId,
        'hospital_id': hospitalId,
        'risk_score': riskScore,
      };
}

class PrescriptionItem {
  final String id;
  final String prescriptionId;
  final String medicineName;
  final String dosage;
  final String frequency;
  final int durationDays;
  bool isDispensed;
  final DateTime? dispensedAt;
  final String? instructions;

  PrescriptionItem({
    required this.id,
    required this.prescriptionId,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    required this.isDispensed,
    this.dispensedAt,
    this.instructions,
  });

  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      id: json['id'] ?? '',
      prescriptionId: json['prescription_id'] ?? '',
      medicineName: json['medicine_name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      durationDays: json['duration_days'] ?? 30,
      isDispensed: json['is_dispensed'] ?? false,
      dispensedAt: json['dispensed_at'] != null
          ? DateTime.tryParse(json['dispensed_at'].toString())
          : null,
      instructions: json['instructions'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prescription_id': prescriptionId,
        'medicine_name': medicineName,
        'dosage': dosage,
        'frequency': frequency,
        'duration_days': durationDays,
        'is_dispensed': isDispensed,
        'dispensed_at': dispensedAt?.toIso8601String(),
        'instructions': instructions,
      };
}

class PatientMedicineLog {
  final String id;
  final String patientId;
  final String medicineName;
  final String scheduledTime;
  bool isTaken;
  final DateTime logDate;
  final String? notes;

  PatientMedicineLog({
    required this.id,
    required this.patientId,
    required this.medicineName,
    required this.scheduledTime,
    required this.isTaken,
    required this.logDate,
    this.notes,
  });

  factory PatientMedicineLog.fromJson(Map<String, dynamic> json) {
    return PatientMedicineLog(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      medicineName: json['medicine_name'] ?? '',
      scheduledTime: json['scheduled_time'] ?? '08:00',
      isTaken: json['is_taken'] ?? false,
      logDate: json['log_date'] != null
          ? DateTime.tryParse(json['log_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'medicine_name': medicineName,
        'scheduled_time': scheduledTime,
        'is_taken': isTaken,
        'log_date': logDate.toIso8601String().split('T')[0],
        'notes': notes,
      };
}

class Plan {
  final String id;
  final String name;
  final String cmsPlanId;
  final int totalEnrollees;
  final int formularyYear;
  final double deductible;

  const Plan({
    required this.id,
    required this.name,
    required this.cmsPlanId,
    required this.totalEnrollees,
    required this.formularyYear,
    required this.deductible,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    return Plan(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      cmsPlanId: json['cms_plan_id'] ?? '',
      totalEnrollees: json['total_enrollees'] ?? 0,
      formularyYear: json['formulary_year'] ?? 2026,
      deductible: (json['deductible'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Drug {
  final String id;
  final String name;
  final String ndc;
  final int tier;
  final String planId;
  final String drugClass;
  final double costShare;
  final bool requiresPa;
  final bool stepTherapy;
  final bool quantityLimit;
  final double estMonthlyCost;

  const Drug({
    required this.id,
    required this.name,
    required this.ndc,
    required this.tier,
    required this.planId,
    required this.drugClass,
    required this.costShare,
    required this.requiresPa,
    required this.stepTherapy,
    required this.quantityLimit,
    required this.estMonthlyCost,
  });

  factory Drug.fromJson(Map<String, dynamic> json) {
    return Drug(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      ndc: json['ndc'] ?? '',
      tier: json['tier'] ?? 1,
      planId: json['plan_id']?.toString() ?? '',
      drugClass: json['drug_class'] ?? '',
      costShare: (json['cost_share'] as num?)?.toDouble() ?? 0.0,
      requiresPa: json['requires_pa'] ?? false,
      stepTherapy: json['step_therapy'] ?? false,
      quantityLimit: json['quantity_limit'] ?? false,
      estMonthlyCost: (json['est_monthly_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get tierLabel {
    switch (tier) {
      case 1:
        return 'Tier 1 - Preferred Generic';
      case 2:
        return 'Tier 2 - Generic';
      case 3:
        return 'Tier 3 - Preferred Brand';
      case 4:
        return 'Tier 4 - Non-Preferred';
      case 5:
        return 'Tier 5 - Specialty';
      default:
        return 'Tier $tier';
    }
  }

  String get restrictionsText {
    final list = <String>[];
    if (requiresPa) list.add('PA');
    if (stepTherapy) list.add('ST');
    if (quantityLimit) list.add('QL');
    return list.isEmpty ? 'None' : list.join(', ');
  }
}

class FormularyAlternative {
  final String id;
  final String targetDrugId;
  final String altDrugId;
  final String altDrugName;
  final int altTier;
  final double estMonthlySavings;
  final double estAnnualSavings;
  final String clinicalNotes;
  final double copayDiff;

  const FormularyAlternative({
    required this.id,
    required this.targetDrugId,
    required this.altDrugId,
    required this.altDrugName,
    required this.altTier,
    required this.estMonthlySavings,
    required this.estAnnualSavings,
    required this.clinicalNotes,
    required this.copayDiff,
  });

  factory FormularyAlternative.fromJson(Map<String, dynamic> json) {
    return FormularyAlternative(
      id: json['id']?.toString() ?? '',
      targetDrugId: json['target_drug_id']?.toString() ?? '',
      altDrugId: json['alt_drug_id']?.toString() ?? '',
      altDrugName: json['alt_drug_name'] ?? '',
      altTier: json['alt_tier'] ?? 1,
      estMonthlySavings: (json['est_monthly_savings'] as num?)?.toDouble() ?? 0.0,
      estAnnualSavings: (json['est_annual_savings'] as num?)?.toDouble() ?? 0.0,
      clinicalNotes: json['clinical_notes'] ?? '',
      copayDiff: (json['copay_diff'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String prescriberId;
  final String prescriberName;
  final String planId;
  final double riskScore;
  final String phone;
  final String email;

  const Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.prescriberId,
    required this.prescriberName,
    required this.planId,
    required this.riskScore,
    required this.phone,
    required this.email,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      age: json['age'] ?? 40,
      gender: json['gender'] ?? 'Other',
      prescriberId: json['prescriber_id']?.toString() ?? '',
      prescriberName: json['prescriber_name'] ?? json['doctors']?['name'] ?? '',
      planId: json['plan_id']?.toString() ?? '',
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.25,
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

class FillRecord {
  final DateTime date;
  final int daysSupply;
  final bool wasOnTime;

  const FillRecord({
    required this.date,
    required this.daysSupply,
    required this.wasOnTime,
  });
}

class Prescription {
  final String id;
  final String patientId;
  final String patientName;
  final String drugId;
  final String drugName;
  final String drugClass;
  final String? diagnosis;
  final List<DateTime> fillDates;
  final List<FillRecord> fillRecords;
  final double pdcScore;
  final String status;
  final DateTime lastFillDate;
  final DateTime nextDueDate;
  final String prescriberName;
  final String? hospitalName;
  final String? hospitalAddress;
  final String? doctorId;
  final DateTime? prescribedDate;
  final String? notes;

  const Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.drugId,
    required this.drugName,
    required this.drugClass,
    this.diagnosis,
    required this.fillDates,
    required this.fillRecords,
    required this.pdcScore,
    required this.status,
    required this.lastFillDate,
    required this.nextDueDate,
    required this.prescriberName,
    this.hospitalName,
    this.hospitalAddress,
    this.doctorId,
    this.prescribedDate,
    this.notes,
  });

  bool get hasPdf => notes != null && notes!.trim().startsWith('{') && notes!.contains('pdf_base64');
  
  String? get pdfBase64 {
    if (!hasPdf) return null;
    try {
      final data = jsonDecode(notes!);
      return data['pdf_base64'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? get pdfName {
    if (!hasPdf) return null;
    try {
      final data = jsonDecode(notes!);
      return data['pdf_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  String get cleanNotes {
    if (notes == null) return '';
    if (hasPdf) {
      try {
        final data = jsonDecode(notes!);
        return data['notes']?.toString() ?? '';
      } catch (_) {
        return notes!;
      }
    }
    return notes!;
  }

  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name'] ?? json['patients']?['name'] ?? '',
      drugId: json['drug_id']?.toString() ?? '',
      drugName: json['drug_name'] ?? '',
      drugClass: json['drug_class'] ?? 'Cardiovascular',
      diagnosis: json['diagnosis']?.toString(),
      fillDates: [],
      fillRecords: [],
      pdcScore: (json['pdc_score'] as num?)?.toDouble() ?? 0.85,
      status: json['status'] ?? 'Active',
      lastFillDate: json['last_fill_date'] != null
          ? DateTime.tryParse(json['last_fill_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.tryParse(json['next_due_date'].toString()) ?? DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      prescriberName: json['prescriber_name'] ?? json['doctors']?['name'] ?? 'Attending Doctor',
      hospitalName: json['hospitals']?['name'],
      hospitalAddress: json['hospitals']?['address'],
      doctorId: json['doctor_id']?.toString(),
      prescribedDate: json['prescribed_date'] != null
          ? DateTime.tryParse(json['prescribed_date'].toString())
          : null,
      notes: json['notes']?.toString(),
    );
  }

  Prescription copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? drugId,
    String? drugName,
    String? drugClass,
    String? diagnosis,
    List<DateTime>? fillDates,
    List<FillRecord>? fillRecords,
    double? pdcScore,
    String? status,
    DateTime? lastFillDate,
    DateTime? nextDueDate,
    String? prescriberName,
    String? hospitalName,
    String? hospitalAddress,
    String? doctorId,
    DateTime? prescribedDate,
    String? notes,
  }) {
    return Prescription(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      drugId: drugId ?? this.drugId,
      drugName: drugName ?? this.drugName,
      drugClass: drugClass ?? this.drugClass,
      diagnosis: diagnosis ?? this.diagnosis,
      fillDates: fillDates ?? this.fillDates,
      fillRecords: fillRecords ?? this.fillRecords,
      pdcScore: pdcScore ?? this.pdcScore,
      status: status ?? this.status,
      lastFillDate: lastFillDate ?? this.lastFillDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      prescriberName: prescriberName ?? this.prescriberName,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      doctorId: doctorId ?? this.doctorId,
      prescribedDate: prescribedDate ?? this.prescribedDate,
      notes: notes ?? this.notes,
    );
  }

  bool get isBought => status.toLowerCase() == 'bought';
  bool get isNotBought => status.toLowerCase() == 'not bought';
}

class AdherenceFlag {
  final String id;
  final String prescriptionId;
  final String patientId;
  final String patientName;
  final String drugName;
  final String drugClass;
  final RiskLevel riskLevel;
  final double pdcScore;
  final String reason;
  OutreachStatus outreachStatus;
  String? notes;

  AdherenceFlag({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.patientName,
    required this.drugName,
    required this.drugClass,
    required this.riskLevel,
    required this.pdcScore,
    required this.reason,
    required this.outreachStatus,
    this.notes,
  });

  factory AdherenceFlag.fromJson(Map<String, dynamic> json) {
    RiskLevel r = RiskLevel.medium;
    final rStr = (json['risk_level'] ?? '').toString().toLowerCase();
    if (rStr == 'high') r = RiskLevel.high;
    if (rStr == 'low') r = RiskLevel.low;

    return AdherenceFlag(
      id: json['id']?.toString() ?? '',
      prescriptionId: json['prescription_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name'] ?? '',
      drugName: json['drug_name'] ?? '',
      drugClass: json['drug_class'] ?? '',
      riskLevel: r,
      pdcScore: (json['pdc_score'] as num?)?.toDouble() ?? 0.5,
      reason: json['reason'] ?? '',
      outreachStatus: OutreachStatus.pending,
      notes: json['notes'],
    );
  }
}

class PAFrictionEvent {
  final String id;
  final String prescriptionId;
  final String patientId;
  final String patientName;
  final String drugName;
  final int daysDelayed;
  final double frictionScore;
  FrictionStatus status;
  final BarrierType barrierType;
  final String? suggestedAltId;
  final String? suggestedAltName;
  final double estAnnualSavings;

  PAFrictionEvent({
    required this.id,
    required this.prescriptionId,
    required this.patientId,
    required this.patientName,
    required this.drugName,
    required this.daysDelayed,
    required this.frictionScore,
    required this.status,
    required this.barrierType,
    this.suggestedAltId,
    this.suggestedAltName,
    required this.estAnnualSavings,
  });

  factory PAFrictionEvent.fromJson(Map<String, dynamic> json) {
    BarrierType b = BarrierType.paRequired;
    final bStr = (json['barrier_type'] ?? '').toString().toLowerCase();
    if (bStr.contains('step')) b = BarrierType.stepTherapyFailed;
    if (bStr.contains('quantity')) b = BarrierType.quantityLimit;

    return PAFrictionEvent(
      id: json['id']?.toString() ?? '',
      prescriptionId: json['prescription_id']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name'] ?? '',
      drugName: json['drug_name'] ?? '',
      daysDelayed: json['days_delayed'] ?? 0,
      frictionScore: (json['friction_score'] as num?)?.toDouble() ?? 0.5,
      status: FrictionStatus.blocked,
      barrierType: b,
      suggestedAltId: json['suggested_alt_id']?.toString(),
      suggestedAltName: json['suggested_alt_name'],
      estAnnualSavings: (json['est_annual_savings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String get barrierLabel {
    switch (barrierType) {
      case BarrierType.paRequired:
        return 'Prior Authorization';
      case BarrierType.stepTherapyFailed:
        return 'Step Therapy Friction';
      case BarrierType.quantityLimit:
        return 'Quantity Exceeded';
    }
  }
}

class FormularyIngestion {
  final String id;
  final String filename;
  final DateTime uploadDate;
  String status;
  int totalRecords;
  int updatedTiers;
  int errorCount;
  final String uploadedBy;

  FormularyIngestion({
    required this.id,
    required this.filename,
    required this.uploadDate,
    required this.status,
    required this.totalRecords,
    required this.updatedTiers,
    required this.errorCount,
    required this.uploadedBy,
  });
}

class TierCopayConfig {
  final int tier;
  final String name;
  double defaultCopay;
  double coinsurancePct;
  bool isSpecialty;

  TierCopayConfig({
    required this.tier,
    required this.name,
    required this.defaultCopay,
    required this.coinsurancePct,
    required this.isSpecialty,
  });
}

class PharmacistDispenseRecord {
  final String id;
  final String? prescriptionId;
  final String? prescriptionItemId;
  final String patientId;
  final String patientName;
  final String doctorId;
  final String doctorName;
  final String pharmacistId;
  final String pharmacistName;
  final String medicineName;
  final String dosage;
  final String frequency;
  final DateTime dispensedAt;
  final String? notes;

  const PharmacistDispenseRecord({
    required this.id,
    this.prescriptionId,
    this.prescriptionItemId,
    required this.patientId,
    required this.patientName,
    required this.doctorId,
    required this.doctorName,
    required this.pharmacistId,
    required this.pharmacistName,
    required this.medicineName,
    required this.dosage,
    required this.frequency,
    required this.dispensedAt,
    this.notes,
  });

  factory PharmacistDispenseRecord.fromJson(Map<String, dynamic> json) {
    return PharmacistDispenseRecord(
      id: json['id']?.toString() ?? '',
      prescriptionId: json['prescription_id']?.toString(),
      prescriptionItemId: json['prescription_item_id']?.toString(),
      patientId: json['patient_id']?.toString() ?? '',
      patientName: json['patient_name'] ?? 'Patient',
      doctorId: json['doctor_id']?.toString() ?? '',
      doctorName: json['doctor_name'] ?? 'Doctor',
      pharmacistId: json['pharmacist_id']?.toString() ?? '',
      pharmacistName: json['pharmacist_name'] ?? 'Pharmacist',
      medicineName: json['medicine_name'] ?? '',
      dosage: json['dosage'] ?? '',
      frequency: json['frequency'] ?? '',
      dispensedAt: json['dispensed_at'] != null
          ? DateTime.tryParse(json['dispensed_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
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
        'dispensed_at': dispensedAt.toIso8601String(),
        'notes': notes,
      };
}
