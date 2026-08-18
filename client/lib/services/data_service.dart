import '../data/mock_data.dart';
import '../models/models.dart';

class DataService {
  // Configurable PDC threshold (default: 80% per CMS Part D benchmark)
  double pdcThreshold = 0.80;

  // Global collections
  final List<Plan> _plans = List.from(MockData.plans);
  final List<User> _users = List.from(MockData.users);
  final List<Drug> _drugs = List.from(MockData.drugs);
  final List<FormularyAlternative> _alternatives =
      List.from(MockData.alternatives);
  final List<Patient> _patients = List.from(MockData.patients);
  final List<Prescription> _prescriptions = List.from(MockData.prescriptions);
  final List<AdherenceFlag> _adherenceFlags =
      List.from(MockData.adherenceFlags);
  final List<PAFrictionEvent> _paFrictionEvents =
      List.from(MockData.paFrictionEvents);
  final List<FormularyIngestion> _ingestionRecords =
      List.from(MockData.ingestionRecords);
  final List<TierCopayConfig> _tierConfigs =
      List.from(MockData.defaultTierConfigs);

  // Getters
  List<Plan> get plans => List.unmodifiable(_plans);
  List<User> get users => List.unmodifiable(_users);
  List<Drug> get drugs => List.unmodifiable(_drugs);
  List<FormularyAlternative> get alternatives =>
      List.unmodifiable(_alternatives);
  List<Patient> get patients => List.unmodifiable(_patients);
  List<Prescription> get prescriptions => List.unmodifiable(_prescriptions);
  List<AdherenceFlag> get adherenceFlags => List.unmodifiable(_adherenceFlags);
  List<PAFrictionEvent> get paFrictionEvents =>
      List.unmodifiable(_paFrictionEvents);
  List<FormularyIngestion> get ingestionRecords =>
      List.unmodifiable(_ingestionRecords);
  List<TierCopayConfig> get tierConfigs => List.unmodifiable(_tierConfigs);

  // PDC Threshold configuration
  void setPdcThreshold(double threshold) {
    pdcThreshold = threshold;
  }

  // Calculate dynamic adherence flags based on current PDC threshold
  List<AdherenceFlag> getFilteredAdherenceFlags({
    String? searchQuery,
    RiskLevel? selectedRisk,
    String? selectedDrugClass,
    String? prescriberFilter,
    List<String>? assignedPatientIds,
  }) {
    return _adherenceFlags.where((flag) {
      // Role scoping check
      if (assignedPatientIds != null &&
          !assignedPatientIds.contains(flag.patientId)) {
        return false;
      }

      // Dynamic PDC Threshold check
      final isBelowThreshold = flag.pdcScore < pdcThreshold;
      if (!isBelowThreshold && flag.riskLevel != RiskLevel.high) {
        return false;
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matches = flag.patientName.toLowerCase().contains(query) ||
            flag.drugName.toLowerCase().contains(query) ||
            flag.reason.toLowerCase().contains(query);
        if (!matches) return false;
      }

      if (selectedRisk != null && flag.riskLevel != selectedRisk) {
        return false;
      }

      if (selectedDrugClass != null &&
          selectedDrugClass.isNotEmpty &&
          flag.drugClass != selectedDrugClass) {
        return false;
      }

      if (prescriberFilter != null && prescriberFilter.isNotEmpty) {
        final rx = _prescriptions.firstWhere(
          (p) => p.id == flag.prescriptionId,
          orElse: () => _prescriptions.first,
        );
        if (rx.prescriberName != prescriberFilter) return false;
      }

      return true;
    }).toList();
  }

  // Get Drug Alternatives for a specific drug
  List<FormularyAlternative> getAlternativesForDrug(String drugId) {
    return _alternatives.where((alt) => alt.targetDrugId == drugId).toList();
  }

  // Get Drug by ID
  Drug? getDrugById(String id) {
    try {
      return _drugs.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  // High-cost opportunity metrics (Admin and Pharmacist)
  double get totalEstimatedAnnualSavingsOpportunity {
    double total = 0.0;
    for (final alt in _alternatives) {
      total += alt.estAnnualSavings;
    }
    for (final fric in _paFrictionEvents) {
      total += fric.estAnnualSavings;
    }
    return total;
  }

  // Total patients at adherence risk
  int getAtRiskPatientCount({List<String>? assignedPatientIds}) {
    return _adherenceFlags.where((flag) {
      if (assignedPatientIds != null &&
          !assignedPatientIds.contains(flag.patientId)) {
        return false;
      }
      return flag.pdcScore < pdcThreshold;
    }).length;
  }

  // Total active PA / ST friction alerts
  int getActiveFrictionCount({List<String>? assignedPatientIds}) {
    return _paFrictionEvents.where((f) {
      if (assignedPatientIds != null &&
          !assignedPatientIds.contains(f.patientId)) {
        return false;
      }
      return f.status != FrictionStatus.resolved;
    }).length;
  }

  // Action: Initiate patient outreach
  void updateOutreachStatus(
      String flagId, OutreachStatus status, String? notes) {
    final index = _adherenceFlags.indexWhere((f) => f.id == flagId);
    if (index != -1) {
      _adherenceFlags[index].outreachStatus = status;
      if (notes != null && notes.isNotEmpty) {
        _adherenceFlags[index].notes = notes;
      }
    }
  }

  // Action: Resolve PA Friction event
  void updateFrictionStatus(String frictionId, FrictionStatus newStatus) {
    final index = _paFrictionEvents.indexWhere((f) => f.id == frictionId);
    if (index != -1) {
      _paFrictionEvents[index].status = newStatus;
    }
  }

  // Admin Action: Simulate CMS Formulary File Upload / Ingestion
  FormularyIngestion simulateFormularyFileUpload(
      String filename, String uploadedBy) {
    final newIngestion = FormularyIngestion(
      id: 'ING-${DateTime.now().millisecondsSinceEpoch}',
      filename: filename,
      uploadDate: DateTime.now(),
      status: 'Completed',
      totalRecords: 18500 + (filename.length * 350),
      updatedTiers: 1420 + (filename.length * 25),
      errorCount: 0,
      uploadedBy: uploadedBy,
    );
    _ingestionRecords.insert(0, newIngestion);

    // Update tier cost-shares in drug catalog as part of ingestion demo
    for (int i = 0; i < _drugs.length; i++) {
      if (_drugs[i].tier >= 4) {
        // Mock adjustments
      }
    }
    return newIngestion;
  }

  // Admin Action: Add new user
  void addUser(User newUser) {
    _users.add(newUser);
  }

  // Admin Action: Update tier copay
  void updateTierCopay(int tier, double copay, double coinsurance) {
    final index = _tierConfigs.indexWhere((t) => t.tier == tier);
    if (index != -1) {
      _tierConfigs[index].defaultCopay = copay;
      _tierConfigs[index].coinsurancePct = coinsurance;
    }
  }
}
