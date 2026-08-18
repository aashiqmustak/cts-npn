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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.textDark),
                    onPressed: () {
                      appState.setSelectedPrescriptionId(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Prescription Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentNavy,
                        ),
                      ),
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
                    label: const Text('Download', style: TextStyle(fontSize: 12)),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share_outlined, size: 16),
                    label: const Text('Share >', style: TextStyle(fontSize: 12)),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

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

  Widget _buildPrescriptionSummaryHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined,
                    color: AppColors.primaryTeal, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Prescription #${widget.prescriptionId}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.successText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Prescribed by Dr. Rahul Verma • General Physician',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text('May 15, 2025 10:30 AM',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        SizedBox(width: 12),
                        Icon(Icons.medication_outlined,
                            size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text('3 Medicines',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                        SizedBox(width: 12),
                        Icon(Icons.access_time_rounded,
                            size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text('Valid for 30 days',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('Next Follow-up',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  Text('May 29, 2025',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  Text('10:30 AM',
                      style:
                          TextStyle(fontSize: 10, color: AppColors.textMuted)),
                  SizedBox(height: 8),
                  Text('Prescription ID',
                      style:
                          TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  Text('RX58921-250515',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabsBar() {
    final tabs = ['Medicines', 'Instructions', 'Notes', 'Attachments'];

    return Row(
      children: tabs.asMap().entries.map((entry) {
        final idx = entry.key;
        final label = entry.value;
        final isSelected = _activeSubTab == idx;

        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: InkWell(
            onTap: () {
              setState(() {
                _activeSubTab = idx;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryTeal
                      : AppColors.borderLight,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicinesListCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '3 Medicines Prescribed',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.print_outlined,
                      size: 16, color: AppColors.primaryTeal),
                  SizedBox(width: 4),
                  Text('Print Prescription',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryTeal)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSlate,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.borderLight,
            child: Text(num,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.medication_rounded, color: pillColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.purpleBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purpleText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  doseDetails,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Duration',
                  style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              Text(duration,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Time',
                  style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              Text(time,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorNoteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Doctor's Note",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '“ Please take medicines regularly. Maintain a healthy diet and exercise daily. Avoid oily and high sugar foods. Stay hydrated and get enough sleep. ”',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.accentNavy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescription Status',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: const [
                Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.successText, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Active — This prescription is currently active and valid.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.successText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.5,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Valid for 15 more days',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryTeal)),
              Text('15 / 30 days',
                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'e-Prescription Benefits',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(height: 10),
          Text('✓ Secure & digitally verified prescription',
              style: TextStyle(fontSize: 11, color: AppColors.textDark)),
          SizedBox(height: 4),
          Text('✓ Easy access anytime, anywhere',
              style: TextStyle(fontSize: 11, color: AppColors.textDark)),
          SizedBox(height: 4),
          Text('✓ Share with pharmacist in one click',
              style: TextStyle(fontSize: 11, color: AppColors.textDark)),
          SizedBox(height: 4),
          Text('✓ Environment friendly',
              style: TextStyle(fontSize: 11, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescription Timeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimelineNode(
              'Prescription Created', 'May 15, 2025 • 10:30 AM', true),
          _buildTimelineNode(
              'Prescription Active', 'May 15, 2025 • 10:31 AM', true),
          _buildTimelineNode(
              'Follow-up Due', 'May 29, 2025 • 10:30 AM', false),
        ],
      ),
    );
  }

  Widget _buildTimelineNode(String title, String time, bool isDone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isDone ? AppColors.primaryTeal : AppColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              Text(time,
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescribedByDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prescribed By',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?img=60'),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Dr. Rahul Verma',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    'MBBS, MD (General Medicine)',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  Text(
                    'Reg. No. 58214',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
