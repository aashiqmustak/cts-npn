enum UserRole {
  admin,
  insuranceAgent,
  doctor,
  pharmacist,
  patient,
}

enum RiskLevel { high, medium, low }

enum OutreachStatus { pending, contacted, resolved, declined }

enum FrictionStatus { blocked, inReview, appealed, resolved }

enum BarrierType { paRequired, stepTherapyFailed, quantityLimit }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final List<String> assignedPatientIds;
  final String avatarUrl;
  final String title;
  final String? hospitalId;
  final String? doctorId;
  final String? patientId;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.assignedPatientIds,
    required this.avatarUrl,
    required this.title,
    this.hospitalId,
    this.doctorId,
    this.patientId,
  });

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
  final List<DateTime> fillDates;
  final List<FillRecord> fillRecords;
  final double pdcScore;
  final String status;
  final DateTime lastFillDate;
  final DateTime nextDueDate;
  final String prescriberName;
  final String? hospitalName;
  final String? hospitalAddress;

  const Prescription({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.drugId,
    required this.drugName,
    required this.drugClass,
    required this.fillDates,
    required this.fillRecords,
    required this.pdcScore,
    required this.status,
    required this.lastFillDate,
    required this.nextDueDate,
    required this.prescriberName,
    this.hospitalName,
    this.hospitalAddress,
  });
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
