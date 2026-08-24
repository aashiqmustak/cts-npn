import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

// ============================================================================
// DATA MODELS FOR COMPACT HOSPITAL DIRECTORY
// ============================================================================

class HospitalServiceItem {
  final String name;
  final String description;
  final IconData icon;
  final String departmentHead;
  final String waitTime;
  final bool isAvailable;

  const HospitalServiceItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.departmentHead,
    required this.waitTime,
    this.isAvailable = true,
  });
}

class HospitalFacility {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String phone;
  final String networkStatus; // 'In-Network (Preferred)', 'In-Network', 'Out-of-Network'
  final bool isPreferred;
  final String networkTier;
  final double rating;
  final int bedCapacity;
  final String operatingHours;
  final List<String> specialties;
  final List<HospitalServiceItem> services;

  const HospitalFacility({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.phone,
    required this.networkStatus,
    required this.isPreferred,
    required this.networkTier,
    required this.rating,
    required this.bedCapacity,
    required this.operatingHours,
    required this.specialties,
    required this.services,
  });

  Hospital toHospital() {
    return Hospital(
      id: id,
      name: name,
      address: address,
      city: city,
      state: state,
      zip: zip,
      phone: phone,
    );
  }
}

// ============================================================================
// COMPACT HOSPITALS SCREEN
// ============================================================================

class HospitalsScreen extends StatefulWidget {
  const HospitalsScreen({super.key});

  @override
  State<HospitalsScreen> createState() => _HospitalsScreenState();
}

class _HospitalsScreenState extends State<HospitalsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedSpecialty = 'All Specialties';
  String _selectedNetwork = 'All Networks';

  final List<String> _specialtyOptions = [
    'All Specialties',
    'Cardiology',
    'Diabetes Care',
    'Oncology',
    'Pharmacy',
    'Specialist Consultation',
    'Emergency Care',
    'Pediatrics',
    'Neurology',
  ];

  final List<String> _networkOptions = [
    'All Networks',
    'In-Network (Preferred)',
    'In-Network',
    'Out-of-Network',
  ];

  // Master facilities dataset
  late List<HospitalFacility> _facilities;

  @override
  void initState() {
    super.initState();
    _initializeFacilities();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _initializeFacilities() {
    _facilities = [
      const HospitalFacility(
        id: 'HOSP-001',
        name: 'Mayo Clinic Hospital - Phoenix',
        address: '5777 E Mayo Blvd',
        city: 'Phoenix',
        state: 'AZ',
        zip: '85054',
        phone: '(602) 301-8000',
        networkStatus: 'In-Network (Preferred)',
        isPreferred: true,
        networkTier: 'Tier 1 Preferred Academic Center',
        rating: 4.9,
        bedCapacity: 520,
        operatingHours: '24/7 Full Emergency & Clinical Services',
        specialties: ['Cardiology', 'Oncology', 'Specialist Consultation', 'Emergency Care', 'Pharmacy'],
        services: [
          HospitalServiceItem(
            name: 'Cardiology & Heart Center',
            description: 'Advanced interventional catheterization, electrophysiology, and lipid management.',
            icon: Icons.favorite_rounded,
            departmentHead: 'Dr. Marcus Vance, MD, FACC',
            waitTime: '< 15 mins (Emergency) / 2 days (Consult)',
          ),
          HospitalServiceItem(
            name: 'Comprehensive Oncology Pavilion',
            description: 'Precision biomarker chemotherapy, immunotherapy infusions, and surgical oncology.',
            icon: Icons.biotech_rounded,
            departmentHead: 'Dr. Katherine Price, MD',
            waitTime: 'Same-day triage',
          ),
          HospitalServiceItem(
            name: 'Specialist Consultation Network',
            description: 'Multidisciplinary physician consults covering endocrinology, nephrology, and pulmonology.',
            icon: Icons.person_search_rounded,
            departmentHead: 'Dr. Sarah Jenkins, MD',
            waitTime: '1-3 days',
          ),
          HospitalServiceItem(
            name: 'Emergency & Trauma Level 1',
            description: 'Rapid response acute resuscitation, stroke neurology, and chest pain center.',
            icon: Icons.emergency_rounded,
            departmentHead: 'Dr. David Wilson, MD, FACEP',
            waitTime: 'Immediate triage',
          ),
          HospitalServiceItem(
            name: 'Formulary & Specialty Pharmacy Hub',
            description: 'On-site clinical pharmacotherapy, prior authorization resolution, and biologic dispensing.',
            icon: Icons.local_pharmacy_rounded,
            departmentHead: 'Dr. Emily Watson, PharmD, BCPS',
            waitTime: '< 10 mins dispense',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-002',
        name: 'Mount Sinai Medical Center',
        address: 'One Gustave L. Levy Place',
        city: 'New York',
        state: 'NY',
        zip: '10029',
        phone: '(212) 241-6500',
        networkStatus: 'In-Network (Preferred)',
        isPreferred: true,
        networkTier: 'Tier 1 Preferred Health System',
        rating: 4.8,
        bedCapacity: 1134,
        operatingHours: '24/7 Level 1 Trauma & Multi-specialty',
        specialties: ['Cardiology', 'Diabetes Care', 'Oncology', 'Emergency Care', 'Specialist Consultation'],
        services: [
          HospitalServiceItem(
            name: 'Diabetes & Endocrinology Institute',
            description: 'Continuous glucose telemetry, insulin pump titration, and metabolic syndrome clinics.',
            icon: Icons.bloodtype_rounded,
            departmentHead: 'Dr. Robert Miller, MD, FACE',
            waitTime: 'Next-day appointments',
          ),
          HospitalServiceItem(
            name: 'Mount Sinai Heart & Vascular',
            description: 'Non-invasive cardiac imaging, transcatheter aortic valve replacement, and cardiac rehab.',
            icon: Icons.favorite_rounded,
            departmentHead: 'Dr. Valentin Fuster, MD, PhD',
            waitTime: '< 20 mins urgent',
          ),
          HospitalServiceItem(
            name: 'Emergency Medicine Center',
            description: 'Full-capacity emergency suite with dedicated pediatric and geriatric crisis units.',
            icon: Icons.emergency_rounded,
            departmentHead: 'Dr. Lynne Richardson, MD',
            waitTime: 'Immediate triage',
          ),
          HospitalServiceItem(
            name: 'Specialist Consultation Suites',
            description: 'Integrated subspecialty outpatient clinics with direct electronic EHR referral loops.',
            icon: Icons.medical_services_rounded,
            departmentHead: 'Dr. Michael Chang, MD',
            waitTime: '2-4 days',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-003',
        name: 'Cleveland Clinic Main Campus',
        address: '9500 Euclid Ave',
        city: 'Cleveland',
        state: 'OH',
        zip: '44195',
        phone: '(216) 444-2200',
        networkStatus: 'In-Network (Preferred)',
        isPreferred: true,
        networkTier: 'Tier 1 Global Destination Network',
        rating: 4.9,
        bedCapacity: 1400,
        operatingHours: '24/7 Comprehensive Medical & Surgical Center',
        specialties: ['Cardiology', 'Diabetes Care', 'Pharmacy', 'Specialist Consultation', 'Emergency Care'],
        services: [
          HospitalServiceItem(
            name: 'Sydell and Arnold Miller Heart Center',
            description: 'Nationally #1 ranked cardiovascular care, robotic heart surgery, and valve repair.',
            icon: Icons.favorite_rounded,
            departmentHead: 'Dr. Lars Svensson, MD, PhD',
            waitTime: 'Direct physician transfer',
          ),
          HospitalServiceItem(
            name: 'Endocrinology & Diabetes Institute',
            description: 'Glycemic optimization, diabetes technology training, and prevention programs.',
            icon: Icons.bloodtype_rounded,
            departmentHead: 'Dr. Adi Mehta, MD',
            waitTime: '2-3 days',
          ),
          HospitalServiceItem(
            name: 'Integrated Health-System Pharmacy',
            description: 'Automated sterile compounding, bedside discharge delivery, and clinical medication reviews.',
            icon: Icons.local_pharmacy_rounded,
            departmentHead: 'Dr. Scott Knoer, PharmD',
            waitTime: '< 15 mins',
          ),
          HospitalServiceItem(
            name: 'Emergency Care & Acute Services',
            description: 'Advanced emergency resuscitation center with integrated air medical transport.',
            icon: Icons.emergency_rounded,
            departmentHead: 'Dr. Thomas Waters, MD',
            waitTime: 'Immediate triage',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-004',
        name: 'Johns Hopkins Hospital',
        address: '1800 Orleans St',
        city: 'Baltimore',
        state: 'MD',
        zip: '21287',
        phone: '(410) 955-5000',
        networkStatus: 'In-Network',
        isPreferred: false,
        networkTier: 'Tier 2 Coordinated Academic Network',
        rating: 4.9,
        bedCapacity: 1192,
        operatingHours: '24/7 Tertiary Referral Center',
        specialties: ['Oncology', 'Neurology', 'Pediatrics', 'Specialist Consultation', 'Emergency Care'],
        services: [
          HospitalServiceItem(
            name: 'Sidney Kimmel Comprehensive Cancer Center',
            description: 'Clinical trial therapeutics, proton beam radiation, and bone marrow transplantation.',
            icon: Icons.biotech_rounded,
            departmentHead: 'Dr. William Nelson, MD, PhD',
            waitTime: '24-48 hours',
          ),
          HospitalServiceItem(
            name: 'Neurology & Neurosurgery Center',
            description: 'Comprehensive epilepsy monitoring, stroke intervention, and movement disorder clinic.',
            icon: Icons.psychology_rounded,
            departmentHead: 'Dr. Justin McArthur, MBBS, MPH',
            waitTime: '3-5 days',
          ),
          HospitalServiceItem(
            name: 'Pediatric Specialty Pavilion',
            description: 'Dedicated neonatal ICU, pediatric surgery, and rare disease genetic diagnostics.',
            icon: Icons.child_care_rounded,
            departmentHead: 'Dr. Margaret Moon, MD, MPH',
            waitTime: 'Same-day urgent',
          ),
          HospitalServiceItem(
            name: 'Emergency & Critical Care',
            description: 'Adult and pediatric emergency departments equipped with hyperbaric chambers.',
            icon: Icons.emergency_rounded,
            departmentHead: 'Dr. Gabor Kelen, MD',
            waitTime: 'Immediate triage',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-005',
        name: 'Massachusetts General Hospital',
        address: '55 Fruit St',
        city: 'Boston',
        state: 'MA',
        zip: '02114',
        phone: '(617) 726-2000',
        networkStatus: 'In-Network (Preferred)',
        isPreferred: true,
        networkTier: 'Tier 1 Preferred Health System',
        rating: 4.8,
        bedCapacity: 1011,
        operatingHours: '24/7 Emergency & Acute Hospitalization',
        specialties: ['Cardiology', 'Diabetes Care', 'Oncology', 'Emergency Care', 'Pharmacy'],
        services: [
          HospitalServiceItem(
            name: 'Corrigan Minehan Heart Center',
            description: 'Preventive cardiology, advanced heart failure therapies, and ventricular assist devices.',
            icon: Icons.favorite_rounded,
            departmentHead: 'Dr. Anthony Rosenzweig, MD',
            waitTime: '< 15 mins emergency',
          ),
          HospitalServiceItem(
            name: 'MGH Diabetes Research & Clinical Center',
            description: 'Type 1 and Type 2 clinical pathways, continuous monitoring, and renal-protective regimens.',
            icon: Icons.bloodtype_rounded,
            departmentHead: 'Dr. David Nathan, MD',
            waitTime: '1-2 days',
          ),
          HospitalServiceItem(
            name: 'Clinical Specialty Pharmacy',
            description: 'Specialty medication prior auth support and direct patient copay assistance coordination.',
            icon: Icons.local_pharmacy_rounded,
            departmentHead: 'Dr. Christopher Fortier, PharmD',
            waitTime: '< 15 mins',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-006',
        name: 'MetroHealth Medical Center',
        address: '2500 MetroHealth Dr',
        city: 'Cleveland',
        state: 'OH',
        zip: '44109',
        phone: '(216) 778-7800',
        networkStatus: 'In-Network',
        isPreferred: false,
        networkTier: 'Tier 1 Community Health Network',
        rating: 4.7,
        bedCapacity: 731,
        operatingHours: '24/7 Level 1 Trauma & Burn Center',
        specialties: ['Emergency Care', 'Pharmacy', 'Diabetes Care', 'Specialist Consultation'],
        services: [
          HospitalServiceItem(
            name: 'Level 1 Trauma & Comprehensive Burn Center',
            description: 'State-certified emergency trauma bay with dedicated rooftop helipad and burn ICU.',
            icon: Icons.emergency_rounded,
            departmentHead: 'Dr. Bernard Boulanger, MD',
            waitTime: 'Immediate triage',
          ),
          HospitalServiceItem(
            name: 'Community Diabetes & Preventive Health',
            description: 'Chronic disease management, nutritional counseling, and medication adherence programs.',
            icon: Icons.bloodtype_rounded,
            departmentHead: 'Dr. Eileen Seeholzer, MD',
            waitTime: 'Same-week appointments',
          ),
          HospitalServiceItem(
            name: 'Ambulatory Care Pharmacy Services',
            description: 'Full outpatient formulary dispensing with 340B prescription discount support.',
            icon: Icons.local_pharmacy_rounded,
            departmentHead: 'Dr. Joseph Marchiano, PharmD',
            waitTime: '< 10 mins',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-007',
        name: 'Northwestern Memorial Hospital',
        address: '251 E Huron St',
        city: 'Chicago',
        state: 'IL',
        zip: '60611',
        phone: '(312) 926-2000',
        networkStatus: 'In-Network',
        isPreferred: false,
        networkTier: 'Tier 2 Regional Academic Center',
        rating: 4.7,
        bedCapacity: 894,
        operatingHours: '24/7 Emergency & Specialized Surgery',
        specialties: ['Cardiology', 'Neurology', 'Specialist Consultation', 'Pharmacy'],
        services: [
          HospitalServiceItem(
            name: 'Bluhm Cardiovascular Institute',
            description: 'Comprehensive coronary care, heart failure disease management, and cardiac imaging.',
            icon: Icons.favorite_rounded,
            departmentHead: 'Dr. Patrick McCarthy, MD',
            waitTime: '1-3 days',
          ),
          HospitalServiceItem(
            name: 'Neurological Institute & Comprehensive Stroke',
            description: 'Acute stroke thrombectomy, neurocritical care, and neuro-oncology consultations.',
            icon: Icons.psychology_rounded,
            departmentHead: 'Dr. Howard Bernstein, MD',
            waitTime: '< 20 mins stroke triage',
          ),
        ],
      ),
      const HospitalFacility(
        id: 'HOSP-008',
        name: 'Cedars-Sinai Medical Center',
        address: '8700 Beverly Blvd',
        city: 'Los Angeles',
        state: 'CA',
        zip: '90048',
        phone: '(310) 423-3277',
        networkStatus: 'Out-of-Network',
        isPreferred: false,
        networkTier: 'Out-of-Network Specialized Referral',
        rating: 4.8,
        bedCapacity: 886,
        operatingHours: '24/7 Emergency & Quaternary Care',
        specialties: ['Cardiology', 'Oncology', 'Specialist Consultation', 'Emergency Care'],
        services: [
          HospitalServiceItem(
            name: 'Smidt Heart Institute',
            description: 'Robotic valve repairs, hypertension therapies, and advanced cardiovascular research.',
            icon: Icons.favorite_rounded,
            departmentHead: 'Dr. Eduardo Marban, MD, PhD',
            waitTime: 'Referral required',
          ),
          HospitalServiceItem(
            name: 'Samuel Oschin Comprehensive Cancer Institute',
            description: 'Targeted cell therapies, precision genomics, and immunotherapy clinical trials.',
            icon: Icons.biotech_rounded,
            departmentHead: 'Dr. Dan Theodorescu, MD, PhD',
            waitTime: 'Referral review required',
          ),
        ],
      ),
    ];
  }

  // ==========================================================================
  // FILTERING LOGIC
  // ==========================================================================

  List<HospitalFacility> get _filteredFacilities {
    final query = _searchController.text.trim().toLowerCase();

    return _facilities.where((h) {
      // 1. Search Query Filter
      if (query.isNotEmpty) {
        final matchName = h.name.toLowerCase().contains(query);
        final matchCity = h.city.toLowerCase().contains(query);
        final matchState = h.state.toLowerCase().contains(query);
        final matchAddress = h.address.toLowerCase().contains(query);
        final matchSpecialty = h.specialties.any((s) => s.toLowerCase().contains(query));
        if (!matchName && !matchCity && !matchState && !matchAddress && !matchSpecialty) {
          return false;
        }
      }

      // 2. Specialty Filter
      if (_selectedSpecialty != 'All Specialties') {
        if (!h.specialties.contains(_selectedSpecialty)) {
          return false;
        }
      }

      // 3. Network Filter
      if (_selectedNetwork != 'All Networks') {
        if (_selectedNetwork == 'In-Network (Preferred)') {
          if (!h.isPreferred || h.networkStatus != 'In-Network (Preferred)') return false;
        } else if (_selectedNetwork == 'In-Network') {
          if (!h.networkStatus.contains('In-Network')) return false;
        } else if (_selectedNetwork == 'Out-of-Network') {
          if (h.networkStatus != 'Out-of-Network') return false;
        }
      }

      return true;
    }).toList();
  }

  // ==========================================================================
  // BUILD METHOD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final filtered = _filteredFacilities;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'Hospitals & Healthcare Directory',
            subtitle: 'Authorized medical centers, specialty hospital networks, and clinical referral systems across Alternea.',
            icon: Icons.local_hospital_rounded,
            statusLabel: 'EHR & FHIR Connected',
            trailing: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientPill),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _addHospitalDialog(appState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.add_business_rounded, size: 18, color: Colors.white),
                label: Text(
                  'Register Facility',
                  style: AppFonts.googleSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 2. Interactive Search & Filters Control Card
          BentoCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Search Input + Network Dropdown + Active Count
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: AppFonts.googleSans(fontSize: 12.5, color: AppColors.textDark),
                          decoration: InputDecoration(
                            hintText: 'Search hospitals by name, specialty, city, or address...',
                            hintStyle: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.primaryTeal),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 15, color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
                            filled: true,
                            fillColor: AppColors.bgSlate,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Network Selector Dropdown
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.bgSlate,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedNetwork,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primaryTeal),
                            style: AppFonts.googleSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            items: _networkOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt,
                                child: Text(opt, overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedNetwork = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Active Count Badge
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '${filtered.length} Facilities',
                        style: AppFonts.googleSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Specialty Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _specialtyOptions.map((specialty) {
                      final isActive = _selectedSpecialty == specialty;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(specialty),
                          selected: isActive,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSpecialty = selected ? specialty : 'All Specialties';
                            });
                          },
                          labelStyle: AppFonts.googleSans(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.textDark,
                          ),
                          selectedColor: const Color(0xFF0A1931),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isActive ? const Color(0xFF0A1931) : const Color(0xFFE2E8F0),
                              width: 1.1,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Compact 2-Column Hospitals Bento Grid
          if (filtered.isEmpty)
            BentoCard(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.domain_disabled_rounded, size: 42, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text(
                      'No Medical Centers Found',
                      style: AppFonts.googleSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try adjusting your search keywords, specialty filters, or network criteria.',
                      style: AppFonts.googleSans(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 178, // Compact height, no dead vertical space
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final h = filtered[index];
                    return _buildCompactHospitalCard(h);
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // COMPACT & INFORMATION-DENSE HOSPITAL CARD
  // ==========================================================================
  Widget _buildCompactHospitalCard(HospitalFacility h) {
    final isPreferred = h.isPreferred;
    final isOutNetwork = h.networkStatus == 'Out-of-Network';

    return BentoCard(
      enableHover: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showHospitalDetailsModal(h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Row 1: Icon + Name + Tier + Rating + Network Badge + 3-Dot Menu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Facility Icon Container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isPreferred ? const Color(0xFFEFF6FF) : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isPreferred ? const Color(0xFF93C5FD) : AppColors.primaryTeal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: isPreferred ? const Color(0xFF0062FF) : AppColors.primaryTeal,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),

                // Name & Sub-tier
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              h.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.googleSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          if (isPreferred) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0062FF)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${h.id} • ${h.networkTier}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.googleSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Star Rating Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 2),
                      Text(
                        '${h.rating}',
                        style: AppFonts.googleSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Three-dot action menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 17, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'details') {
                      _showHospitalDetailsModal(h);
                    } else if (val == 'services') {
                      _showHospitalServicesModal(h);
                    } else if (val == 'refer') {
                      _showReferPatientModal(h);
                    } else if (val == 'phone') {
                      Clipboard.setData(ClipboardData(text: h.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF0A1931),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          content: Text('Copied phone "${h.phone}" to clipboard.'),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'details',
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF0062FF)),
                          const SizedBox(width: 8),
                          Text('View Details', style: GoogleFonts.inter(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'services',
                      child: Row(
                        children: [
                          const Icon(Icons.medical_information_rounded, size: 15, color: AppColors.primaryTeal),
                          const SizedBox(width: 8),
                          Text('View Services', style: GoogleFonts.inter(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'refer',
                      child: Row(
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 8),
                          Text('Refer Patient', style: GoogleFonts.inter(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'phone',
                      child: Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 15, color: Color(0xFFD97706)),
                          const SizedBox(width: 8),
                          Text('Copy Phone (${h.phone})', style: GoogleFonts.inter(fontSize: 12.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Row 2: Location + Phone + Bed Count (Inline condensed)
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    '${h.city}, ${h.state}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.phone_outlined, size: 12, color: AppColors.primaryTeal),
                const SizedBox(width: 3),
                Text(
                  h.phone,
                  style: AppFonts.googleSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.bed_rounded, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text(
                  '${h.bedCapacity} Beds',
                  style: AppFonts.googleSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),

            // Row 3: Specialties Tags (Single line compact)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: h.specialties.take(3).map((spec) {
                  return Container(
                    margin: const EdgeInsets.only(right: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      spec,
                      style: AppFonts.googleSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  );
                }).toList()
                  ..addAll(
                    h.specialties.length > 3
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '+${h.specialties.length - 3}',
                                style: AppFonts.googleSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ]
                        : [],
                  ),
              ),
            ),

            // Row 4: Network Badge + Action Buttons (Compact height)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Network Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOutNetwork
                        ? const Color(0xFFFEE2E2)
                        : (isPreferred ? const Color(0xFFEFF6FF) : AppColors.successBg),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOutNetwork
                          ? const Color(0xFFFCA5A5)
                          : (isPreferred ? const Color(0xFF93C5FD) : const Color(0xFF86EFAC)),
                    ),
                  ),
                  child: Text(
                    h.networkStatus,
                    style: AppFonts.googleSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isOutNetwork
                          ? const Color(0xFFDC2626)
                          : (isPreferred ? const Color(0xFF0062FF) : AppColors.successText),
                    ),
                  ),
                ),

                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // View Services Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryTeal, width: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.medical_information_rounded, size: 12),
                      label: Text(
                        'View Services',
                        style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showHospitalServicesModal(h),
                    ),
                    const SizedBox(width: 6),

                    // Refer Patient Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1931),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 12),
                      label: Text(
                        'Refer Patient',
                        style: AppFonts.googleSans(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showReferPatientModal(h),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // MODAL 1: VIEW SERVICES & SPECIALTIES MODAL
  // ==========================================================================
  void _showHospitalServicesModal(HospitalFacility h) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Container(
            width: 720,
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0A1931),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Specialties & Available Clinical Services (${h.services.length} Departments Active)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),

                // Modal Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview Banner
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetaItem('Network Tier', h.networkTier),
                              _buildMetaItem('Bed Capacity', '${h.bedCapacity} Inpatient Beds'),
                              _buildMetaItem('Rating', '${h.rating} / 5.0 (Center of Excellence)'),
                              _buildMetaItem('EHR Integration', 'HL7 / FHIR Connected'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Clinical Departments & Services',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // List of Services
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: h.services.length,
                          separatorBuilder: (context, idx) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final s = h.services[idx];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(s.icon, color: const Color(0xFF0062FF), size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              s.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                s.waitTime,
                                                style: GoogleFonts.inter(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF16A34A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          s.description,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Department Head: ${s.departmentHead}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1E40AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Modal Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Operating Hours: ${h.operatingHours}',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                            label: Text('Refer Patient Here', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              _showReferPatientModal(h);
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // MODAL 2: REFER PATIENT MODAL (WITH HOSPITAL SELECTOR & CONFIRMATION)
  // ==========================================================================
  void _showReferPatientModal(HospitalFacility h) {
    String selectedPatient = 'PAT_001 - John Smith';
    String selectedHospitalId = h.id;
    String selectedDepartment = h.specialties.isNotEmpty ? h.specialties.first : 'Cardiology';
    String selectedUrgency = 'Standard Referral (Routine)';
    final notesController = TextEditingController(
      text: 'Specialist referral for evaluation, management optimization, and continued clinical monitoring.',
    );

    final patients = [
      'PAT_001 - John Smith',
      'PAT_002 - Sarah Jenkins',
      'PAT_003 - Michael Chang',
      'PAT_004 - Emily Davis',
      'PAT_005 - David Wilson',
    ];

    final urgencyLevels = [
      'Standard Referral (Routine)',
      'Urgent (Within 48-72 Hours)',
      'Immediate / Emergency Transfer',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final activeFacility = _facilities.firstWhere(
              (fac) => fac.id == selectedHospitalId,
              orElse: () => h,
            );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: 640,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 24, offset: Offset(0, 10)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0A1931),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Refer Patient to ${activeFacility.name}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Direct physician-to-facility electronic referral loop',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: Hospital Selector + Patient Selector
                          Row(
                            children: [
                              // Hospital Selector
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedHospitalId,
                                  decoration: InputDecoration(
                                    labelText: 'Destination Medical Center',
                                    prefixIcon: const Icon(Icons.local_hospital_rounded, color: AppColors.primaryTeal, size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: _facilities.map((fac) {
                                    return DropdownMenuItem(
                                      value: fac.id,
                                      child: Text(fac.name, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() {
                                        selectedHospitalId = val;
                                        final newFac = _facilities.firstWhere((f) => f.id == val);
                                        if (!newFac.specialties.contains(selectedDepartment)) {
                                          selectedDepartment = newFac.specialties.isNotEmpty ? newFac.specialties.first : 'General';
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Patient Selector
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedPatient,
                                  decoration: InputDecoration(
                                    labelText: 'Select Patient to Refer',
                                    prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF0062FF), size: 18),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: patients.map((p) {
                                    return DropdownMenuItem(value: p, child: Text(p));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedPatient = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Row 2: Specialty / Department + Urgency
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: activeFacility.specialties.contains(selectedDepartment)
                                      ? selectedDepartment
                                      : (activeFacility.specialties.isNotEmpty ? activeFacility.specialties.first : 'General'),
                                  decoration: InputDecoration(
                                    labelText: 'Department / Specialty',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: activeFacility.specialties.map((s) {
                                    return DropdownMenuItem(value: s, child: Text(s));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedDepartment = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedUrgency,
                                  decoration: InputDecoration(
                                    labelText: 'Referral Urgency',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: urgencyLevels.map((u) {
                                    return DropdownMenuItem(
                                      value: u,
                                      child: Text(u, overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setModalState(() => selectedUrgency = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Referral Reason & Notes
                          TextField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Clinical Indication & Referral Reason',
                              hintText: 'Enter clinical rationale, recent diagnostic findings, and specific questions...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Actions
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0062FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(
                              'Confirm Referral',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              final refId = 'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: const Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  content: Row(
                                    children: [
                                      const Icon(Icons.verified_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Referral #$refId confirmed: $selectedPatient referred to ${activeFacility.name} ($selectedDepartment).',
                                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================================================
  // MODAL 3: HOSPITAL DETAILS MODAL (CLICKING CARD)
  // ==========================================================================
  void _showHospitalDetailsModal(HospitalFacility h) {
    _showHospitalServicesModal(h);
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // MODAL 4: REGISTER FACILITY DIALOG
  // ==========================================================================
  void _addHospitalDialog(AppState appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Register Hospital / Medical Center',
            style: AppFonts.googleSans(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.textDark,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    style: AppFonts.googleSans(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Hospital Name',
                      hintText: 'e.g. Mount Sinai Medical Center',
                      prefixIcon: Icon(Icons.local_hospital_rounded, color: AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressController,
                    style: AppFonts.googleSans(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      hintText: 'e.g. One Gustave L. Levy Place',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primaryTeal),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cityController,
                          style: AppFonts.googleSans(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'City',
                            hintText: 'New York',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _zipController,
                          style: AppFonts.googleSans(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'ZIP Code',
                            hintText: '10029',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    style: AppFonts.googleSans(fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Phone Contact',
                      hintText: '(212) 241-6500',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppFonts.googleSans(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
                  return;
                }
                final newFacility = HospitalFacility(
                  id: 'HOSP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  name: _nameController.text.trim(),
                  address: _addressController.text.trim(),
                  city: _cityController.text.isEmpty ? 'New York' : _cityController.text.trim(),
                  state: 'NY',
                  zip: _zipController.text.isEmpty ? '10001' : _zipController.text.trim(),
                  phone: _phoneController.text.isEmpty ? '(212) 555-0100' : _phoneController.text.trim(),
                  networkStatus: 'In-Network (Preferred)',
                  isPreferred: true,
                  networkTier: 'Tier 1 Registered Facility',
                  rating: 4.8,
                  bedCapacity: 450,
                  operatingHours: '24/7 Clinical Services',
                  specialties: ['Specialist Consultation', 'Emergency Care', 'Pharmacy'],
                  services: const [
                    HospitalServiceItem(
                      name: 'General & Specialist Consultation',
                      description: 'Comprehensive outpatient multi-specialty clinical care.',
                      icon: Icons.person_search_rounded,
                      departmentHead: 'Attending Physician',
                      waitTime: '1-2 days',
                    ),
                    HospitalServiceItem(
                      name: 'Emergency & Urgent Services',
                      description: '24/7 triage and acute intervention services.',
                      icon: Icons.emergency_rounded,
                      departmentHead: 'Emergency Department Director',
                      waitTime: 'Immediate',
                    ),
                  ],
                );

                setState(() {
                  _facilities.insert(0, newFacility);
                });

                appState.addHospital(newFacility.toHospital());

                _nameController.clear();
                _addressController.clear();
                _cityController.clear();
                _zipController.clear();
                _phoneController.clear();

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.primaryTeal,
                    content: Text(
                      'Hospital Registered Successfully!',
                      style: AppFonts.googleSans(fontWeight: FontWeight.w600),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                'Save Hospital',
                style: AppFonts.googleSans(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }
}
