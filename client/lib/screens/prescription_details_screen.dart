import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class PrescriptionDetailsScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailsScreen({super.key, required this.prescriptionId});

  @override
  State<PrescriptionDetailsScreen> createState() =>
      _PrescriptionDetailsScreenState();
}

class _PrescriptionDetailsScreenState
    extends State<PrescriptionDetailsScreen> {
  int _activeSubTab = 0; // 0: Medicines, 1: Instructions, 2: Notes, 3: Attachments

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textDark, size: 20),
                      onPressed: () {
                        appState.setSelectedPrescriptionId(null);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Prescription Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentNavy,
                          letterSpacing: 0.1,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'View full details of your prescription',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.download_outlined, size: 16),
                    label: const Text('Download',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textDark,
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.ios_share_rounded, size: 16),
                    label: const Text('Share',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700)),
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main 2-Column Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column (Flex 7) — Main Prescription Document Detail
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    // Top Prescription Summary Card
                    _buildPrescriptionSummaryHeaderCard(),

                    const SizedBox(height: 20),

                    // Sub-Tabs Bar
                    _buildSubTabsBar(),

                    const SizedBox(height: 16),

                    // Medicines Prescribed Card
                    _buildMedicinesListCard(context),

                    const SizedBox(height: 20),

                    // Doctor's Note Card
                    _buildDoctorNoteCard(),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Right Column (Flex 4) — Status, Timeline & Prescriber Info
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Widget 1: Prescription Status Card
                    _buildPrescriptionStatusCard(),

                    const SizedBox(height: 20),

                    // Widget 2: e-Prescription Benefits Card
                    _buildBenefitsCard(),

                    const SizedBox(height: 20),

                    // Widget 3: Prescription Timeline Card
                    _buildPrescriptionTimelineCard(),

                    const SizedBox(height: 20),

                    // Widget 4: Prescribed By Doctor Profile Card
                    _buildPrescribedByDoctorCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SUMMARY HEADER CARD
  // ------------------------------------------------------------------
  Widget _buildPrescriptionSummaryHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryTeal.withValues(alpha: 0.18),
                  AppColors.primaryLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.description_rounded,
                color: AppColors.primaryTeal, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Prescription #${widget.prescriptionId}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        letterSpacing: 0.1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle,
                              size: 6, color: AppColors.successText),
                          SizedBox(width: 5),
                          Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.successText,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Prescribed by Dr. Rahul Verma • General Physician',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: const [
                    _MetaChip(
                      icon: Icons.calendar_today_rounded,
                      label: 'May 15, 2025 10:30 AM',
                    ),
                    _MetaChip(
                      icon: Icons.medication_rounded,
                      label: '3 Medicines',
                    ),
                    _MetaChip(
                      icon: Icons.access_time_rounded,
                      label: 'Valid for 30 days',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text('NEXT FOLLOW-UP',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('May 29, 2025',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                Text('10:30 AM',
                    style:
                        TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                SizedBox(height: 10),
                Text('PRESCRIPTION ID',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: AppColors.textMuted)),
                SizedBox(height: 2),
                Text('RX58921-250515',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentNavy)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SUB TABS
  // ------------------------------------------------------------------
  Widget _buildSubTabsBar() {
    final tabs = ['Medicines', 'Instructions', 'Notes', 'Attachments'];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final idx = entry.key;
          final label = entry.value;
          final isSelected = _activeSubTab == idx;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  _activeSubTab = idx;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primaryTeal
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ------------------------------------------------------------------
  // MEDICINES LIST CARD
  // ------------------------------------------------------------------
  Widget _buildMedicinesListCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '3 Medicines Prescribed',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.print_rounded,
                          size: 16, color: AppColors.primaryTeal),
                      SizedBox(width: 5),
                      Text('Print Prescription',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryTeal)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildPrescribedMedicineRow(
            num: '1',
            name: 'Atorvastatin 20mg',
            tag: 'For Cholesterol',
            duration: '30 days',
            time: 'Night',
            doseDetails: '1 tablet • Once daily • After dinner',
            pillColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF3E8FF),
          ),
          const SizedBox(height: 12),
          _buildPrescribedMedicineRow(
            num: '2',
            name: 'Metformin 500mg',
            tag: 'For Diabetes Type 2',
            duration: '30 days',
            time: 'Morning, Evening',
            doseDetails: '1 tablet • Twice daily • After meals',
            pillColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFE0F2FE),
          ),
          const SizedBox(height: 12),
          _buildPrescribedMedicineRow(
            num: '3',
            name: 'Vitamin D3 1000 IU',
            tag: 'Supplement',
            duration: '30 days',
            time: 'Morning',
            doseDetails: '1 tablet • Once daily • After breakfast',
            pillColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFFEF3C7),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescribedMedicineRow({
    required String num,
    required String name,
    required String tag,
    required String duration,
    required String time,
    required String doseDetails,
    required Color pillColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Text(num,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
          ),
          const SizedBox(width: 14),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medication_rounded, color: pillColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purpleText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  doseDetails,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatColumn(label: 'Duration', value: duration),
          const SizedBox(width: 20),
          _StatColumn(label: 'Time', value: time),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DOCTOR NOTE
  // ------------------------------------------------------------------
  Widget _buildDoctorNoteCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEFF6FF),
            const Color(0xFFEFF6FF).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.format_quote_rounded,
                size: 18, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Doctor's Note",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please take medicines regularly. Maintain a healthy diet and exercise daily. Avoid oily and high sugar foods. Stay hydrated and get enough sleep.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.accentNavy,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATUS CARD
  // ------------------------------------------------------------------
  Widget _buildPrescriptionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescription Status',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.successText, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Active — This prescription is currently active and valid.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successText,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 8,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Valid for 15 more days',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryTeal)),
              Text('15 / 30 days',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // BENEFITS CARD
  // ------------------------------------------------------------------
  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'e-Prescription Benefits',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          const _BenefitRow(text: 'Secure & digitally verified prescription'),
          const SizedBox(height: 10),
          const _BenefitRow(text: 'Easy access anytime, anywhere'),
          const SizedBox(height: 10),
          const _BenefitRow(text: 'Share with pharmacist in one click'),
          const SizedBox(height: 10),
          const _BenefitRow(text: 'Environment friendly'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // TIMELINE CARD
  // ------------------------------------------------------------------
  Widget _buildPrescriptionTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescription Timeline',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          _buildTimelineNode(
              'Prescription Created', 'May 15, 2025 • 10:30 AM', true, true),
          _buildTimelineNode(
              'Prescription Active', 'May 15, 2025 • 10:31 AM', true, false),
          _buildTimelineNode(
              'Follow-up Due', 'May 29, 2025 • 10:30 AM', false, false,
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(
      String title, String time, bool isDone, bool isFirst,
      {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isDone
                      ? AppColors.primaryTeal
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone
                        ? AppColors.primaryTeal
                        : AppColors.borderLight,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: isDone
                        ? AppColors.primaryTeal.withValues(alpha: 0.3)
                        : AppColors.borderLight,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(time,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // DOCTOR PROFILE CARD
  // ------------------------------------------------------------------
  Widget _buildPrescribedByDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescribed By',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: AppColors.gradientPill,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text(
                  'RV',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Dr. Rahul Verma',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'MBBS, MD (General Medicine)',
                      style:
                          TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                    Text(
                      'Reg. No. 58214',
                      style:
                          TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// SMALL REUSABLE UI PIECES
// ------------------------------------------------------------------

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark)),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 1),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              size: 11, color: AppColors.successText),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 11.5, color: AppColors.textDark, height: 1.3)),
        ),
      ],
    );
  }
}