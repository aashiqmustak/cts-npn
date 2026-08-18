import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final totalSavings = appState.dataService.totalEstimatedAnnualSavingsOpportunity;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Executive Analytics & Impact Reports',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Aggregate financial cost-savings opportunities, adherence distribution, and PA friction trends.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.table_chart_rounded, size: 16),
                    label: const Text('Export CSV Data'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Exported Formulary_Optimization_Report_2026.csv to downloads!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Download Executive PDF'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generated Executive_Formulary_Summary_2026.pdf!'),
                          backgroundColor: AppColors.primaryTeal,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // High Level Summary Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accentNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL IDENTIFIED FORMULARY COST SAVINGS OPPORTUNITY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fmt.format(totalSavings),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Derived from bioequivalent Tier 1-2 generic swaps & biosimilar conversions across plan enrollees.',
                      style: TextStyle(color: AppColors.primaryLight, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.trending_down_rounded, color: AppColors.primaryLight, size: 36),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Analytics Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart 1: Bar Chart of Savings by Drug Class
              Expanded(
                flex: 6,
                child: _buildChartContainer(
                  title: 'Cost-Savings Opportunities by Drug Class (\$k)',
                  child: SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: true, drawVerticalLine: false),
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 25,
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [BarChartRodData(toY: 18.5, color: AppColors.primaryTeal, width: 26)],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [BarChartRodData(toY: 21.4, color: AppColors.accentNavy, width: 26)],
                          ),
                          BarChartGroupData(
                            x: 2,
                            barRods: [BarChartRodData(toY: 12.8, color: AppColors.infoText, width: 26)],
                          ),
                          BarChartGroupData(
                            x: 3,
                            barRods: [BarChartRodData(toY: 16.2, color: AppColors.purpleText, width: 26)],
                          ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) => Text('\$${val.toInt()}k', style: const TextStyle(fontSize: 11)),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                switch (val.toInt()) {
                                  case 0:
                                    return const Text('Statins', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                  case 1:
                                    return const Text('DOACs', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                  case 2:
                                    return const Text('SGLT2', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                  case 3:
                                    return const Text('Biologics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold));
                                  default:
                                    return const Text('');
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Chart 2: Adherence Risk Pie Chart
              Expanded(
                flex: 5,
                child: _buildChartContainer(
                  title: 'Patient Panel Adherence Distribution',
                  child: SizedBox(
                    height: 260,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: 65,
                            color: AppColors.successText,
                            title: '65%\nHigh PDC (>80%)',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: 22,
                            color: AppColors.warningText,
                            title: '22%\nAt-Risk (65-79%)',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          PieChartSectionData(
                            value: 13,
                            color: AppColors.dangerText,
                            title: '13%\nCritical (<65%)',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Chart 3: PA Delay Reduction Over Time
          _buildChartContainer(
            title: 'Prior Authorization Claim Delay Resolution Trend (Avg Days)',
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Text('${val.toInt()}d', style: const TextStyle(fontSize: 11)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          switch (val.toInt()) {
                            case 0:
                              return const Text('Jan');
                            case 1:
                              return const Text('Feb');
                            case 2:
                              return const Text('Mar');
                            case 3:
                              return const Text('Apr');
                            case 4:
                              return const Text('May');
                            case 5:
                              return const Text('Jun');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 18),
                        FlSpot(1, 15),
                        FlSpot(2, 16),
                        FlSpot(3, 12),
                        FlSpot(4, 9),
                        FlSpot(5, 7),
                      ],
                      isCurved: true,
                      color: AppColors.primaryTeal,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
