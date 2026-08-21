import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/bento_card.dart';

class MyMedicinesScreen extends StatefulWidget {
  const MyMedicinesScreen({super.key});

  @override
  State<MyMedicinesScreen> createState() => _MyMedicinesScreenState();
}

class _MyMedicinesScreenState extends State<MyMedicinesScreen> {
  int _activeFilterTab = 0; // 0: All, 1: Active, 2: Completed, 3: On Hold

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Enterprise Bento Hero Banner
          BentoHeroBanner(
            title: 'My Medication Cabinet',
            subtitle: 'Track active dosages, refill countdowns, and adherence compliance.',
            icon: Icons.medication_rounded,
            statusLabel: 'Cabinet Active',
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
                onPressed: () => _showAddMedicineModal(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: Text(
                  '+ Add Medicine',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Filter Sub-Tabs Bar
          BentoCard(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSubTabButton(0, 'All Medications (4)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(1, 'Active Daily (3)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(2, 'Completed (1)'),
                  const SizedBox(width: 8),
                  _buildSubTabButton(3, 'As Needed / PRN (0)'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 3. Asymmetric Bento 2-Column Workspace
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 920;

              final medsColumn = Column(
                children: [
                  _buildMedicineCabinetCard(
                    title: 'Metformin Hydrochloride (Glucophage)',
                    dosage: '500 mg • 1 Tablet Twice Daily',
                    purpose: 'Type 2 Diabetes Blood Glucose Regulation',
                    prescriber: 'Dr. Rahul Verma',
                    daysLeft: 18,
                    complianceScore: 0.94,
                    icon: Icons.medication_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMedicineCabinetCard(
                    title: 'Lisinopril (Zestril)',
                    dosage: '10 mg • 1 Tablet Once Daily (Morning)',
                    purpose: 'Hypertension & Blood Pressure Support',
                    prescriber: 'Dr. Neha Kapoor',
                    daysLeft: 6,
                    complianceScore: 0.88,
                    icon: Icons.favorite_border_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMedicineCabinetCard(
                    title: 'Atorvastatin Calcium (Lipitor)',
                    dosage: '20 mg • 1 Tablet Bedtime',
                    purpose: 'Cholesterol & Lipid Management',
                    prescriber: 'Dr. Neha Kapoor',
                    daysLeft: 24,
                    complianceScore: 0.96,
                    icon: Icons.monitor_heart_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildMedicineCabinetCard(
                    title: 'Amoxicillin Trihydrate',
                    dosage: '500 mg • 1 Capsule Every 8h (10 Days)',
                    purpose: 'Bacterial Infection (Completed Course)',
                    prescriber: 'Dr. Rahul Verma',
                    daysLeft: 0,
                    complianceScore: 1.0,
                    isCompleted: true,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              );

              final sideColumn = Column(
                children: [
                  _buildRefillAlertBento(),
                  const SizedBox(height: 16),
                  _buildAdherenceSummaryCard(appState),
                ],
              );

              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: medsColumn),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: sideColumn),
                  ],
                );
              }

              return Column(
                children: [
                  sideColumn,
                  const SizedBox(height: 20),
                  medsColumn,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabButton(int index, String label) {
    final isSelected = _activeFilterTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeFilterTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryTeal : AppColors.bgSlate,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.metallicBorder,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCabinetCard({
    required String title,
    required String dosage,
    required String purpose,
    required String prescriber,
    required int daysLeft,
    required double complianceScore,
    required IconData icon,
    bool isCompleted = false,
  }) {
    return BentoCard(
      enableHover: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.bgSlate : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? AppColors.textMuted : AppColors.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.purpleBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Completed Course',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.purpleText,
                              ),
                            ),
                          )
                        else if (daysLeft <= 7)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.dangerBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Refill in $daysLeft Days',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.dangerText,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dosage,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
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
          Text(
            'Indication: $purpose • Prescriber: $prescriber',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adherence Score: ${(complianceScore * 100).toInt()}%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          isCompleted ? 'Course Finished' : '$daysLeft Days Remaining',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: complianceScore,
                        minHeight: 6,
                        backgroundColor: AppColors.bgSlate,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          complianceScore >= 0.8 ? AppColors.successGreen : AppColors.warningOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (!isCompleted)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refill Request Sent to Pharmacist!'),
                        backgroundColor: AppColors.primaryTeal,
                      ),
                    );
                  },
                  child: Text('Request Refill', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefillAlertBento() {
    return BentoCard(
      title: 'Upcoming Refill Countdown',
      subtitle: 'Action needed within 7 days',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warningOrange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: AppColors.warningOrange, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lisinopril 10mg (6 Days Left)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warningText,
                    ),
                  ),
                  Text(
                    'Tap Request Refill to notify your clinical pharmacy before supply runs out.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceSummaryCard(AppState appState) {
    return BentoCard(
      title: 'Overall Compliance Rating',
      subtitle: 'Based on 30-day continuous logging',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly PDC Score', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
              Text('94.2% (Optimal)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.successText)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.942,
              minHeight: 8,
              backgroundColor: AppColors.bgSlate,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Keep up the great work! Consistent adherence protects you from cardiovascular and metabolic complications.',
            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Add Medication to Cabinet',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Medication Name', hintText: 'e.g. CoQ10 200mg'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageCtrl,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
                decoration: const InputDecoration(labelText: 'Dosage & Frequency', hintText: 'e.g. 1 Softgel with lunch'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryTeal),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Medication Added to Cabinet!'),
                  backgroundColor: AppColors.primaryTeal,
                ),
              );
            },
            child: Text('Add Medication', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
