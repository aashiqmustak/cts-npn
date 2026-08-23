import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';
import '../widgets/embedded_map_view.dart';

class AuthorizedPharmacyScreen extends StatefulWidget {
  const AuthorizedPharmacyScreen({super.key});

  @override
  State<AuthorizedPharmacyScreen> createState() => _AuthorizedPharmacyScreenState();
}

class _AuthorizedPharmacyScreenState extends State<AuthorizedPharmacyScreen> {
  int _selectedFacilityIndex = 0; // Currently selected facility

  final List<Map<String, dynamic>> _facilities = [
    {
      'id': 'FAC-01',
      'name': 'MetroHealth Medical Center & Pharmacy',
      'type': 'Hospital & Emergency Care',
      'badge': 'Primary Care Center',
      'isHospital': true,
      'address': '124 Health Center Blvd, Winston-Salem, NC 27103',
      'distance': '1.2 miles away',
      'driveTime': '4 mins drive',
      'hours': 'Open 24/7 • Emergency ER Ready',
      'phone': '(336) 555-0192',
      'stockStatus': 'Full Medication & Emergency Supplies In Stock',
      'mapQuery': 'MetroHealth Medical Center, 124 Health Center Blvd, Winston-Salem, NC 27103',
      'latitude': 36.0890,
      'longitude': -80.2520,
    },
    {
      'id': 'FAC-02',
      'name': 'Wake Forest Baptist Medical Center',
      'badge': 'Level 1 Trauma Hospital',
      'type': 'Regional Medical Center',
      'isHospital': true,
      'address': 'Medical Center Blvd, Winston-Salem, NC 27157',
      'distance': '2.5 miles away',
      'driveTime': '7 mins drive',
      'hours': 'Open 24/7 • Trauma Center',
      'phone': '(336) 716-2011',
      'stockStatus': 'In-Network Authorized Hospital Pharmacy',
      'mapQuery': 'Wake Forest Baptist Medical Center, Medical Center Blvd, Winston-Salem, NC 27157',
      'latitude': 36.0955,
      'longitude': -80.2647,
    },
    {
      'id': 'FAC-03',
      'name': 'CVS Pharmacy #402 (In-Network)',
      'badge': 'Insurance Authorized',
      'type': 'Community Pharmacy',
      'isHospital': false,
      'address': '805 Silas Creek Pkwy, Winston-Salem, NC 27107',
      'distance': '1.8 miles away',
      'driveTime': '5 mins drive',
      'hours': 'Open 24 Hours • Drive-Thru',
      'phone': '(336) 555-0402',
      'stockStatus': 'Active Prescriptions Ready for Pickup',
      'mapQuery': 'CVS Pharmacy, 805 Silas Creek Pkwy, Winston-Salem, NC 27107',
      'latitude': 36.0746,
      'longitude': -80.2789,
    },
    {
      'id': 'FAC-04',
      'name': 'Novant Health Forsyth Medical Center',
      'badge': 'In-Network Hospital',
      'type': 'Acute Care Hospital',
      'isHospital': true,
      'address': '3333 Silas Creek Pkwy, Winston-Salem, NC 27103',
      'distance': '3.8 miles away',
      'driveTime': '11 mins drive',
      'hours': 'Open 24/7 • Urgent Care Unit',
      'phone': '(336) 718-5000',
      'stockStatus': 'Full Inpatient & Outpatient Pharmacy',
      'mapQuery': 'Novant Health Forsyth Medical Center, 3333 Silas Creek Pkwy, Winston-Salem, NC 27103',
      'latitude': 36.0758,
      'longitude': -80.2969,
    },
    {
      'id': 'FAC-05',
      'name': 'Walgreens Health & Pharmacy #108',
      'badge': 'Authorized Pharmacy',
      'type': 'Retail Pharmacy',
      'isHospital': false,
      'address': '2290 S Main St, Winston-Salem, NC 27127',
      'distance': '4.2 miles away',
      'driveTime': '12 mins drive',
      'hours': 'Open Today: 8:00 AM - 9:00 PM',
      'phone': '(336) 555-0108',
      'stockStatus': 'Tier 1 & Tier 2 Generics Available',
      'mapQuery': 'Walgreens Pharmacy, 2290 S Main St, Winston-Salem, NC 27127',
      'latitude': 36.0602,
      'longitude': -80.2464,
    },
  ];

  Future<void> _openGoogleMapsDirections(String mapQuery) async {
    final encodedQuery = Uri.encodeComponent(mapQuery);
    final googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedQuery');

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(googleMapsUrl);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Google Maps: https://maps.google.com/?q=$encodedQuery'),
            backgroundColor: const Color(0xFF1244A2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFacility = _facilities[_selectedFacilityIndex];

    return Scaffold(
      backgroundColor: AppColors.bgSlate,
      body: Column(
        children: [
          // 1. Top Control Bar (Hospital & Pharmacy Switcher Pills)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map_rounded, color: Color(0xFF1244A2), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authorized In-Network Hospitals & Google Maps WebView',
                            style: AppFonts.googleSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Select any hospital below to load its live Google Maps WebView & GPS navigation.',
                            style: AppFonts.googleSans(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Horizontal Hospital Selector Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_facilities.length, (index) {
                      final f = _facilities[index];
                      final isSelected = index == _selectedFacilityIndex;
                      final isHospital = f['isHospital'] == true;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFacilityIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1244A2)
                                  : (isHospital ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isHospital
                                        ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                                        : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isHospital ? Icons.local_hospital_rounded : Icons.local_pharmacy_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : (isHospital ? const Color(0xFFDC2626) : const Color(0xFF1244A2)),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${f['name'].toString().split(' ')[0]} (${f['distance']})',
                                  style: AppFonts.googleSans(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // 2. Embedded Google Maps WebView Canvas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: EmbeddedGoogleMapView(
                mapQuery: selectedFacility['mapQuery'],
                facilityName: selectedFacility['name'],
                address: selectedFacility['address'],
                distance: selectedFacility['distance'],
                driveTime: selectedFacility['driveTime'],
                latitude: selectedFacility['latitude'],
                longitude: selectedFacility['longitude'],
              ),
            ),
          ),

          // 3. Bottom Selected Hospital Navigation Control Card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildSelectedHospitalControlCard(selectedFacility),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedHospitalControlCard(Map<String, dynamic> f) {
    final isHospital = f['isHospital'] == true;

    return BentoCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isHospital
                      ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isHospital ? Icons.local_hospital_rounded : Icons.local_pharmacy_rounded,
                  color: isHospital ? const Color(0xFFDC2626) : const Color(0xFF1244A2),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f['name'],
                            style: AppFonts.googleSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            f['badge'],
                            style: AppFonts.googleSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${f['address']} • ${f['distance']} (${f['driveTime']})',
                      style: AppFonts.googleSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openGoogleMapsDirections(f['mapQuery']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1244A2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: Text(
                    '📍 Open Directions in Google Maps',
                    style: AppFonts.googleSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling ${f['name']} at ${f['phone']}...'),
                      backgroundColor: const Color(0xFF1244A2),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFF0F172A)),
                label: Text(
                  'Call Hospital',
                  style: AppFonts.googleSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
