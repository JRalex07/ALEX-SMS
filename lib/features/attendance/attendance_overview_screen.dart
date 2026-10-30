import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Attendance Overview
/// Route: /attendance
class AttendanceOverviewScreen extends ConsumerStatefulWidget {
  const AttendanceOverviewScreen({super.key});

  @override
  ConsumerState<AttendanceOverviewScreen> createState() =>
      _AttendanceOverviewScreenState();
}

class _AttendanceOverviewScreenState
    extends ConsumerState<AttendanceOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isParent = role == UserRoles.parentGuardian;

    if (isParent) {
      return _buildParentOverview();
    }

    return ResponsiveScaffold(
      title: 'Attendance Overview',
      currentRoute: AppRoutes.attendance,
      actions: [
        ErpButton(
          label: 'Take Attendance',
          icon: Icons.how_to_reg,
          isDense: true,
          onPressed: () => context.go(AppRoutes.attendanceRegister),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: "Today's Institutional Attendance Overview",
            subtitle:
                'Real-time student & faculty presence tracking for AY 2026-2027',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Campus Attendance',
                  value: '94.2%',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Students Present',
                  value: '286 / 304',
                  accentColor: AppColors.brandNavy,
                ),
                MetricItem(
                  label: 'Unexcused Absences',
                  value: '12 Students',
                  accentColor: AppColors.dangerRed,
                ),
                MetricItem(
                  label: 'Late Check-ins',
                  value: '6 Students',
                  accentColor: AppColors.warningAmber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ErpCard(
                  title: 'Grade-wise Presence Today',
                  child: Column(
                    children: [
                      _buildClassRow('Class 10-A', '28 / 30', 0.93),
                      _buildClassRow('Class 10-B', '27 / 28', 0.96),
                      _buildClassRow('Class 9-A', '29 / 30', 0.97),
                      _buildClassRow('Class 9-B', '26 / 29', 0.90),
                      _buildClassRow('Class 8-A', '28 / 29', 0.96),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ErpCard(
                  title: 'Quick Navigation',
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.how_to_reg,
                            color: AppColors.brandNavy),
                        title: const Text('Mark Class Attendance'),
                        subtitle: const Text('Record today roll-call register'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.attendanceRegister),
                      ),
                      ListTile(
                        leading: const Icon(Icons.view_list,
                            color: AppColors.brandNavy),
                        title: const Text('Class-wise Attendance'),
                        subtitle: const Text('Inspect by grade & section'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.attendanceClasswise),
                      ),
                      ListTile(
                        leading: const Icon(Icons.warning_amber,
                            color: AppColors.warningAmber),
                        title: const Text('Attendance Exceptions'),
                        subtitle: const Text('Frequent absentees & alerts'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.attendanceExceptions),
                      ),
                      ListTile(
                        leading: const Icon(Icons.assessment,
                            color: AppColors.tealSuccess),
                        title: const Text('Attendance Reports'),
                        subtitle: const Text('Monthly aggregations & export'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(AppRoutes.attendanceReports),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassRow(String label, String fraction, double progress) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceBackground,
              color: AppColors.successGreen,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Text(fraction,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildParentOverview() {
    final selectedChild = ref.watch(selectedChildProvider);
    final attendanceAsync = ref.watch(activeChildAttendanceProvider);

    return ResponsiveScaffold(
      title: 'Attendance Overview',
      currentRoute: AppRoutes.attendance,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const Center(child: Text('No student linked.'))
          else
            attendanceAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.brandNavy)),
              error: (e, _) => Text('Error: $e'),
              data: (records) {
                final total = records.length;
                final present = records.where((r) => r.status == 'P').length;
                final late = records.where((r) => r.status == 'L').length;
                final rate = total == 0
                    ? '100%'
                    : '${(((present + late) / total) * 100).toStringAsFixed(1)}%';

                return Column(
                  children: [
                    ErpCard(
                      title: 'Academic Year Attendance — ${selectedChild.fullName}',
                      subtitle: 'Cumulative presence summary',
                      child: ErpMetricStrip(
                        metrics: [
                          MetricItem(
                            label: 'Attendance Rate',
                            value: rate,
                            accentColor: AppColors.successGreen,
                          ),
                          MetricItem(
                            label: 'Days Present',
                            value: '$present Days',
                          ),
                          MetricItem(
                            label: 'Days Late',
                            value: '$late Days',
                          ),
                          MetricItem(
                            label: 'Total Sessions',
                            value: '$total Days',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
