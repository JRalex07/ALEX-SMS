import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Class-wise Attendance
/// Route: /attendance/classwise
class ClasswiseAttendanceScreen extends ConsumerStatefulWidget {
  const ClasswiseAttendanceScreen({super.key});

  @override
  ConsumerState<ClasswiseAttendanceScreen> createState() =>
      _ClasswiseAttendanceScreenState();
}

class _ClasswiseAttendanceScreenState
    extends ConsumerState<ClasswiseAttendanceScreen> {
  final List<Map<String, dynamic>> _classStats = [
    {
      'class': 'Class 10-A',
      'teacher': 'Tarun Sharma',
      'strength': 30,
      'present': 28,
      'absent': 2,
      'percentage': 93.3,
    },
    {
      'class': 'Class 10-B',
      'teacher': 'Dr. Anita Joshi',
      'strength': 28,
      'present': 27,
      'absent': 1,
      'percentage': 96.4,
    },
    {
      'class': 'Class 9-A',
      'teacher': 'Sunita Rao',
      'strength': 30,
      'present': 29,
      'absent': 1,
      'percentage': 96.7,
    },
    {
      'class': 'Class 9-B',
      'teacher': 'Rajesh Gupta',
      'strength': 29,
      'present': 26,
      'absent': 3,
      'percentage': 89.6,
    },
    {
      'class': 'Class 8-A',
      'teacher': 'Priya Nair',
      'strength': 29,
      'present': 28,
      'absent': 1,
      'percentage': 96.5,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Class-wise Attendance',
      currentRoute: AppRoutes.attendanceClasswise,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: 'Cohort Presence Breakdown — Today',
            subtitle:
                'Comparative roll-call compliance and daily turnout across all class sections',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Campus Mean Turnout',
                  value: '94.5%',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Highest Attendance',
                  value: 'Class 9-A (96.7%)',
                  accentColor: AppColors.tealSuccess,
                ),
                MetricItem(
                  label: 'Lowest Attendance',
                  value: 'Class 9-B (89.6%)',
                  accentColor: AppColors.warningAmber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Class Section Registers (${_classStats.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _classStats.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final c = _classStats[idx];
                final pct = c['percentage'] as double;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: pct >= 92
                        ? AppColors.successGreen.withValues(alpha: 0.12)
                        : AppColors.warningAmber.withValues(alpha: 0.15),
                    child: Text(
                      '${pct.toInt()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: pct >= 92
                            ? AppColors.successGreen
                            : AppColors.warningAmber,
                      ),
                    ),
                  ),
                  title: Text(c['class'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Class Supervisor: ${c['teacher']} • Present: ${c['present']} / ${c['strength']} • Absent: ${c['absent']}'),
                  trailing: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.attendanceRegister),
                    child: const Text('Open Register'),
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
