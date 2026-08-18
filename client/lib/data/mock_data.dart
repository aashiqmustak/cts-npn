import '../models/models.dart';

class MockData {
  // Completely empty collections starting from scratch
  static final List<Plan> plans = [];

  static final List<User> users = [];

  static final List<Drug> drugs = [];

  static final List<FormularyAlternative> alternatives = [];

  static final List<Patient> patients = [];

  static final List<Prescription> prescriptions = [];

  static final List<AdherenceFlag> adherenceFlags = [];

  static final List<PAFrictionEvent> paFrictionEvents = [];

  static final List<FormularyIngestion> ingestionRecords = [];

  static final List<TierCopayConfig> defaultTierConfigs = [
    TierCopayConfig(
      tier: 1,
      name: 'Preferred Generic',
      defaultCopay: 0.0,
      coinsurancePct: 0.0,
      isSpecialty: false,
    ),
    TierCopayConfig(
      tier: 2,
      name: 'Generic',
      defaultCopay: 10.0,
      coinsurancePct: 0.0,
      isSpecialty: false,
    ),
    TierCopayConfig(
      tier: 3,
      name: 'Preferred Brand',
      defaultCopay: 47.0,
      coinsurancePct: 0.0,
      isSpecialty: false,
    ),
    TierCopayConfig(
      tier: 4,
      name: 'Non-Preferred Drug',
      defaultCopay: 110.0,
      coinsurancePct: 35.0,
      isSpecialty: false,
    ),
    TierCopayConfig(
      tier: 5,
      name: 'Specialty Tier',
      defaultCopay: 450.0,
      coinsurancePct: 33.0,
      isSpecialty: true,
    ),
  ];
}
