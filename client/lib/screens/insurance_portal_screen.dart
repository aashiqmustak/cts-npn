import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class InsurancePortalScreen extends StatefulWidget {
  const InsurancePortalScreen({super.key});

  @override
  State<InsurancePortalScreen> createState() => _InsurancePortalScreenState();
}

class _InsurancePortalScreenState extends State<InsurancePortalScreen> {
  static const Map<String, List<String>> _companyPlansMap = {
    'Blue Cross Blue Shield': [
      'Blue Cross PPO Premier',
      'Blue Cross Advantage Plus',
      'Blue Cross Rx Comprehensive',
      'Blue Care HMO Gold',
    ],
    'UnitedHealthcare (UHC)': [
      'UHC Choice Plus Comprehensive',
      'UHC Medicare Part D Standard',
      'UHC Dual Complete (HMO-POS)',
      'Optum Rx Preferred',
    ],
    'Medicare Part D (CMS)': [
      'SilverScript Choice (PDP)',
      'Medicare Advantage Part D Gold',
      'WellCare Value Script (PDP)',
      'Humana Premier Rx (PDP)',
    ],
    'Aetna Health': [
      'Aetna Medicare Part D Value',
      'Aetna Open Access PPO',
      'Aetna Premier Rx Tier 1-5',
    ],
    'Cigna Healthcare': [
      'Cigna Secure Rx (PDP)',
      'Cigna Total Care Plus',
      'Cigna Essential Rx Plan',
    ],
    'Humana Rx': [
      'Humana Walmart Value Rx',
      'Humana Gold Plus (HMO)',
      'Humana Premier Part D',
    ],
    'Kaiser Permanente': [
      'Kaiser Senior Advantage',
      'Kaiser Permanente Deductible Plan',
      'Kaiser Specialty Rx',
    ],
  };

  static const List<String> _availableMedicinesList = [
    'Atorvastatin (Lipitor) 20mg',
    'Metformin HCl 500mg',
    'Lisinopril 10mg',
    'Ozempic (Semaglutide) 2mg/3mL',
    'Eliquis (Apixaban) 5mg',
    'Levothyroxine 50mcg',
    'Amlodipine Besylate 5mg',
    'Omeprazole 20mg',
    'Losartan Potassium 50mg',
    'Jardiance (Empagliflozin) 10mg',
    'Gabapentin 300mg',
    'Hydrochlorothiazide 25mg',
    'Montelukast Sodium 10mg',
    'Rosuvastatin (Crestor) 10mg',
    'Pantoprazole Sodium 40mg',
    'Duloxetine (Cymbalta) 30mg',
    'Sertraline HCl 50mg',
  ];

  static const List<String> _availableHospitalsList = [
    'MetroHealth Medical Center (Cleveland, OH)',
    'St. Jude Memorial Hospital (Fullerton, CA)',
    'Johns Hopkins Hospital (Baltimore, MD)',
    'Cleveland Clinic Main Campus (Cleveland, OH)',
    'Duke University Hospital (Durham, NC)',
    'Mayo Clinic Hospital (Rochester, MN)',
    'Massachusetts General Hospital (Boston, MA)',
    'Northwestern Memorial Hospital (Chicago, IL)',
    'Mount Sinai Hospital (New York, NY)',
    'Stanford Health Care (Stanford, CA)',
  ];

  String? _selectedCompany;
  final Set<String> _selectedPlans = {};
  final Set<String> _selectedMedicines = {};
  final Set<String> _selectedHospitals = {};
  bool _isInitialized = false;
  bool _isSaving = false;

  void _initFromAppState(AppState appState) {
    if (_isInitialized) return;
    _isInitialized = true;

    final user = appState.currentUser;
    _selectedCompany = (user.insuranceCompany != null && user.insuranceCompany!.isNotEmpty)
        ? user.insuranceCompany!
        : 'Blue Cross Blue Shield';

    if (user.insurancePlans.isNotEmpty) {
      _selectedPlans.addAll(user.insurancePlans);
    } else {
      _selectedPlans.addAll(_companyPlansMap[_selectedCompany]?.take(2) ?? ['Blue Cross PPO Premier']);
    }

    if (user.insuranceMedicines.isNotEmpty) {
      _selectedMedicines.addAll(user.insuranceMedicines);
    } else {
      _selectedMedicines.addAll([
        'Atorvastatin (Lipitor) 20mg',
        'Metformin HCl 500mg',
        'Eliquis (Apixaban) 5mg',
      ]);
    }

    if (user.insuranceHospitals.isNotEmpty) {
      _selectedHospitals.addAll(user.insuranceHospitals);
    } else {
      _selectedHospitals.addAll([
        'MetroHealth Medical Center (Cleveland, OH)',
        'Cleveland Clinic Main Campus (Cleveland, OH)',
      ]);
    }
  }

  Future<void> _handleSaveConfiguration(AppState appState) async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final company = _selectedCompany ?? 'Blue Cross Blue Shield';
    final plans = _selectedPlans.isNotEmpty
        ? _selectedPlans.toList()
        : (_companyPlansMap[company]?.take(1).toList() ?? ['Standard Benefit Plan']);

    appState.updateInsuranceAgentDetails(
      company: company,
      plans: plans,
      medicines: _selectedMedicines.toList(),
      hospitals: _selectedHospitals.toList(),
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Formulary and In-Network Hospital settings updated successfully!',
                  style: AppFonts.googleSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    _initFromAppState(appState);

    final plans = appState.dataService.plans;
    final drugs = appState.dataService.drugs;
    final availablePlansForCurrentCompany = _companyPlansMap[_selectedCompany] ?? _companyPlansMap['Blue Cross Blue Shield']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Insurance Plan & Formulary Portal',
            subtitle: 'Review CMS Part D plan formularies, prior authorization claims, and cost optimization opportunities.',
            icon: Icons.verified_user_rounded,
            statusLabel: 'CMS Certified Portal',
          ),

          const SizedBox(height: 20),

          // 2. Interactive Formulary & In-Network Directory Manager
          BentoCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Formulary & In-Network Directory Manager',
                            style: AppFonts.googleSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Configure covered medicines, in-network hospital facilities, and benefit plans managed by your payer account.',
                            style: AppFonts.googleSans(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 18),

                // 1. SELECT INSURANCE PAYER COMPANY
                Text(
                  '1. SELECT INSURANCE PAYER COMPANY',
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF334155),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCompany,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF1D4ED8)),
                      style: AppFonts.googleSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                      items: _companyPlansMap.keys.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 16, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCompany = val;
                            _selectedPlans.clear();
                            final defaults = _companyPlansMap[val];
                            if (defaults != null && defaults.isNotEmpty) {
                              _selectedPlans.addAll(defaults.take(2));
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // 2. BENEFIT PLANS MANAGED
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '2. BENEFIT PLANS MANAGED (${_selectedPlans.length} Selected)',
                      style: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF334155),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Select plan to toggle on/off...',
                        style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      icon: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF1D4ED8), size: 18),
                      items: availablePlansForCurrentCompany.map((plan) {
                        final isSelected = _selectedPlans.contains(plan);
                        return DropdownMenuItem<String>(
                          value: plan,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(plan, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                size: 16,
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (_selectedPlans.contains(val)) {
                              _selectedPlans.remove(val);
                            } else {
                              _selectedPlans.add(val);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedPlans.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedPlans.map((plan) {
                      return Chip(
                        label: Text(plan),
                        backgroundColor: const Color(0xFFDBEAFE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                        labelStyle: AppFonts.googleSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E40AF),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF1E40AF)),
                        onDeleted: () => setState(() => _selectedPlans.remove(plan)),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 18),

                // 3. COVERED MEDICINES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '3. COVERED MEDICINES (${_selectedMedicines.length} Selected)',
                      style: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF334155),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Select medicine to add to covered formulary...',
                        style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      icon: const Icon(Icons.medication_rounded, color: Color(0xFF1D4ED8), size: 18),
                      items: _availableMedicinesList.map((med) {
                        final isSelected = _selectedMedicines.contains(med);
                        return DropdownMenuItem<String>(
                          value: med,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(med, style: AppFonts.googleSans(fontSize: 12, fontWeight: FontWeight.w600)),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                size: 16,
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (_selectedMedicines.contains(val)) {
                              _selectedMedicines.remove(val);
                            } else {
                              _selectedMedicines.add(val);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedMedicines.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedMedicines.map((med) {
                      return Chip(
                        label: Text(med),
                        backgroundColor: const Color(0xFFE0F2FE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF38BDF8)),
                        ),
                        labelStyle: AppFonts.googleSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0369A1),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF0369A1)),
                        onDeleted: () => setState(() => _selectedMedicines.remove(med)),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 18),

                // 4. IN-NETWORK HOSPITALS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '4. IN-NETWORK HOSPITALS (${_selectedHospitals.length} Selected)',
                      style: AppFonts.googleSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF334155),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: Text(
                        'Select in-network hospital facility...',
                        style: AppFonts.googleSans(fontSize: 12, color: const Color(0xFF94A3B8)),
                      ),
                      icon: const Icon(Icons.local_hospital_rounded, color: Color(0xFF1D4ED8), size: 18),
                      items: _availableHospitalsList.map((hosp) {
                        final isSelected = _selectedHospitals.contains(hosp);
                        return DropdownMenuItem<String>(
                          value: hosp,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  hosp,
                                  style: AppFonts.googleSans(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                size: 16,
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            if (_selectedHospitals.contains(val)) {
                              _selectedHospitals.remove(val);
                            } else {
                              _selectedHospitals.add(val);
                            }
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_selectedHospitals.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedHospitals.map((hosp) {
                      return Chip(
                        label: Text(hosp),
                        backgroundColor: const Color(0xFFECFDF5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF34D399)),
                        ),
                        labelStyle: AppFonts.googleSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF047857),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF047857)),
                        onDeleted: () => setState(() => _selectedHospitals.remove(hosp)),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 22),

                // Save Action Button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : () => _handleSaveConfiguration(appState),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18, color: Colors.white),
                    label: Text(
                      _isSaving ? 'SAVING CHANGES...' : 'SAVE FORMULARY & NETWORK CONFIGURATION',
                      style: AppFonts.googleSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. High-Density Metric Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final tiles = [
                BentoMetricTile(
                  label: 'Active Covered Plans',
                  value: '${plans.length} Plans',
                  trendText: 'Medicare Part D',
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: AppColors.primaryTeal,
                  iconBgColor: AppColors.primaryLight,
                ),
                BentoMetricTile(
                  label: 'Formulary Drug Catalog',
                  value: '${drugs.length} Drugs',
                  trendText: '5 Tiers Active',
                  icon: Icons.medication_liquid_rounded,
                  iconColor: AppColors.jewelTechCyan,
                  iconBgColor: AppColors.infoBg,
                ),
                BentoMetricTile(
                  label: 'Annual Savings Target',
                  value: '\$${appState.dataService.totalEstimatedAnnualSavingsOpportunity.toStringAsFixed(0)}',
                  trendText: '+14.2% YoY',
                  icon: Icons.savings_rounded,
                  iconColor: AppColors.jewelEmerald,
                  iconBgColor: AppColors.successBg,
                ),
              ];

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: tiles[0]),
                    const SizedBox(width: 14),
                    Expanded(child: tiles[1]),
                    const SizedBox(width: 14),
                    Expanded(child: tiles[2]),
                  ],
                );
              }
              return Column(
                children: [
                  tiles[0],
                  const SizedBox(height: 10),
                  tiles[1],
                  const SizedBox(height: 10),
                  tiles[2],
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // 4. Covered Plans Bento Card
          BentoCard(
            title: 'Configured CMS Part D & Advantage Plans',
            subtitle: 'Formulary design guidelines, deductible brackets, and member enrollment',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plans.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              itemBuilder: (context, index) {
                final plan = plans[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_outlined, color: AppColors.primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              style: AppFonts.googleSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'CMS ID: ${plan.cmsPlanId} • Formulary Year: ${plan.formularyYear} • Enrollees: ${plan.totalEnrollees}',
                              style: AppFonts.googleSans(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${plan.deductible.toInt()} Deductible',
                            style: AppFonts.googleSans(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Text(
                            'Medicare Standard',
                            style: AppFonts.googleSans(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
