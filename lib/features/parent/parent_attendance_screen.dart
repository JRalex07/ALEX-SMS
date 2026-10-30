import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Parent Attendance Portal
/// Route: /parent/attendance
class ParentAttendanceScreen extends ConsumerWidget {
  const ParentAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final attendanceAsync = ref.watch(activeChildAttendanceProvider);

    return ResponsiveScaffold(
      title: "Child's Attendance Record",
      currentRoute: AppRoutes.parentAttendance,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const Center(child: Text('No student selected.'))
          else
            attendanceAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.parentBlue)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (records) {
                final total = records.length;
                final present = records.where((r) => r.status == 'P').length;
                final late = records.where((r) => r.status == 'L').length;
                final absent = records.where((r) => r.status == 'A').length;
                final excused = records.where((r) => r.status == 'E').length;

                final rate = total == 0
                    ? '100%'
                    : '${(((present + late) / total) * 100).toStringAsFixed(1)}%';

                return Column(
                  children: [
                    ErpCard(
                      title: 'Attendance Record — ${selectedChild.fullName}',
                      subtitle:
                          'Standard: Class ${selectedChild.currentClassId}-${selectedChild.currentSectionId} • AY 2026-2027',
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
                            accentColor: AppColors.warningAmber,
                          ),
                          MetricItem(
                            label: 'Days Absent',
                            value: '$absent Days',
                            accentColor: AppColors.dangerRed,
                          ),
                          MetricItem(
                            label: 'Excused Absences',
                            value: '$excused Days',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ErpCard(
                      title:
                          'Daily Attendance Ledger (${records.length} Sessions)',
                      child: records.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                    'No attendance entries recorded yet.',
                                    style:
                                        TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: records.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: AppColors.borderLight),
                              itemBuilder: (ctx, idx) {
                                final r = records[idx];
                                final isPresent = r.status == 'P';
                                final isLate = r.status == 'L';

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isPresent
                                        ? AppColors.successGreen
                                            .withValues(alpha: 0.12)
                                        : (isLate
                                            ? AppColors.warningAmber
                                                .withValues(alpha: 0.15)
                                            : AppColors.dangerRed
                                                .withValues(alpha: 0.12)),
                                    child: Icon(
                                      isPresent
                                          ? Icons.check
                                          : (isLate
                                              ? Icons.access_time
                                              : Icons.close),
                                      color: isPresent
                                          ? AppColors.successGreen
                                          : (isLate
                                              ? AppColors.warningAmber
                                              : AppColors.dangerRed),
                                    ),
                                  ),
                                  title: Text(
                                    'Session: ${r.date.toLocal().toString().split(" ").first}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                      'Recorded: ${isPresent ? "Present in Class" : (isLate ? "Late Arrival" : "Marked Absent")}'),
                                  trailing: StatusBadge(
                                    label: isPresent
                                        ? 'PRESENT'
                                        : (isLate ? 'LATE' : 'ABSENT'),
                                    type: isPresent
                                        ? StatusType.success
                                        : (isLate
                                            ? StatusType.warning
                                            : StatusType.danger),
                                  ),
                                );
                              },
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
