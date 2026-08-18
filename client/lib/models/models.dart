enum UserRole { pharmacist, admin }

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

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.assignedPatientIds,
    required this.avatarUrl,
    required this.title,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isPharmacist => role == UserRole.pharmacist;
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
  final int tier; // 1: Preferred Generic, 2: Generic, 3: Preferred Brand, 4: Non-Preferred, 5: Specialty
  final String planId;
  final String drugClass;
  final double costShare; // monthly copay or coinsurance amount
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
  final double pdcScore; // 0.0 to 1.0 (e.g. 0.72 = 72%)
  final String status;
  final DateTime lastFillDate;
  final DateTime nextDueDate;
  final String prescriberName;

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
  final double frictionScore; // 0 to 10
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
  String status; // 'Processing', 'Completed', 'Failed'
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
