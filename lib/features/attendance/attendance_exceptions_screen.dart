import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Attendance Exceptions & Chronic Absenteeism
/// Route: /attendance/exceptions
class AttendanceExceptionsScreen extends ConsumerStatefulWidget {
  const AttendanceExceptionsScreen({super.key});

  @override
  ConsumerState<AttendanceExceptionsScreen> createState() =>
      _AttendanceExceptionsScreenState();
}

class _AttendanceExceptionsScreenState
    extends ConsumerState<AttendanceExceptionsScreen> {
  final List<Map<String, dynamic>> _exceptions = [
    {
      'student': 'Rohan Deshmukh',
      'class': 'Class 10-A',
      'consecutiveAbsences': 4,
      'attendanceRate': '68.2%',
      'guardianContact': '+91 98230 11223',
      'alert': 'Severe Chronic Absence (<75% threshold)',
    },
    {
      'student': 'Aarav Mehta',
      'class': 'Class 9-B',
      'consecutiveAbsences': 3,
      'attendanceRate': '72.1%',
      'guardianContact': '+91 98451 44332',
      'alert': 'CBSE Board Examination Hall Ticket At Risk',
    },
    {
      'student': 'Meera Sen',
      'class': 'Class 8-A',
      'consecutiveAbsences': 2,
      'attendanceRate': '74.0%',
      'guardianContact': '+91 98112 55667',
      'alert': 'Medical Certificate Pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Attendance Exceptions & Alerts',
      currentRoute: AppRoutes.attendanceExceptions,
      actions: [
        ErpButton(
          label: 'Corrections Desk',
          icon: Icons.rule,
          isDense: true,
          onPressed: () => context.go(AppRoutes.attendanceCorrections),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Critical Attendance Exceptions & Statutory Thresholds',
            subtitle:
                'Students failing to maintain CBSE mandatory 75% attendance threshold',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Flagged Pupils',
                  value: '${_exceptions.length} Pupils',
                  accentColor: AppColors.dangerRed,
                ),
                const MetricItem(
                  label: 'Statutory Threshold',
                  value: '75.0% Required',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Automated SMS Alerts',
                  value: 'Dispatched to Parents',
                  accentColor: AppColors.tealSuccess,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Flagged Exception Records (${_exceptions.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exceptions.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final ex = _exceptions[idx];

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceMuted,
                    child: Icon(Icons.warning_amber_rounded,
                        color: AppColors.dangerRed),
                  ),
                  title: Text(ex['student'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${ex['class']} • Overall Presence: ${ex['attendanceRate']} • ${ex['consecutiveAbsences']} days consecutive absence\n'
                      'Alert: ${ex['alert']} • Guardian Tel: ${ex['guardianContact']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StatusBadge(
                          label: 'CRITICAL', type: StatusType.danger),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Guardian contact notice queued for ${ex['student']}')),
                          );
                        },
                        child: const Text('Contact Parent'),
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

