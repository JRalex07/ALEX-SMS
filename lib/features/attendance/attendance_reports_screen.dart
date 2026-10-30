import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Attendance Reports & Monthly Analysis
/// Route: /attendance/reports
class AttendanceReportsScreen extends ConsumerStatefulWidget {
  const AttendanceReportsScreen({super.key});

  @override
  ConsumerState<AttendanceReportsScreen> createState() =>
      _AttendanceReportsScreenState();
}

class _AttendanceReportsScreenState
    extends ConsumerState<AttendanceReportsScreen> {
  String _selectedMonth = 'October 2026';

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Attendance Reports',
      currentRoute: AppRoutes.attendanceReports,
      actions: [
        ErpButton(
          label: 'Export Monthly CSV',
          icon: Icons.download,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Exporting institutional monthly attendance register (CSV)...'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Attendance Aggregations & Statutory Compliance Reports',
            subtitle:
                'Monthly turnouts, holiday exclusions, and class-wise percentages for CBSE submission',
            child: Row(
              children: [
                const Text('Report Cycle: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedMonth,
                  items: const [
                    DropdownMenuItem(
                        value: 'October 2026', child: Text('October 2026')),
                    DropdownMenuItem(
                        value: 'September 2026', child: Text('September 2026')),
                    DropdownMenuItem(
                        value: 'August 2026', child: Text('August 2026')),
                    DropdownMenuItem(
                        value: 'July 2026', child: Text('July 2026')),
                  ],
                  onChanged: (v) => setState(() => _selectedMonth = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Monthly Summary — $_selectedMonth',
            child: const ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Total Working Days',
                  value: '22 Days',
                  accentColor: AppColors.brandNavy,
                ),
                MetricItem(
                  label: 'Average Turnout',
                  value: '94.8%',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Total Pupil-Days',
                  value: '6,688 Recorded',
                  accentColor: AppColors.infoBlue,
                ),
                MetricItem(
                  label: 'Below 75% Ratio',
                  value: '1.8% of Pupils',
                  accentColor: AppColors.warningAmber,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
