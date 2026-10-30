import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Child's Timetable
/// Route: /parent/timetable
class ParentTimetableScreen extends ConsumerStatefulWidget {
  const ParentTimetableScreen({super.key});

  @override
  ConsumerState<ParentTimetableScreen> createState() =>
      _ParentTimetableScreenState();
}

class _ParentTimetableScreenState extends ConsumerState<ParentTimetableScreen> {
  String _selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);
    final timetableAsync = ref.watch(childTimetableProvider);

    return ResponsiveScaffold(
      title: "Child's Timetable",
      currentRoute: AppRoutes.parentTimetable,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          ErpCard(
            title: 'Weekly Academic Schedule',
            subtitle: selectedChild != null
                ? 'Timetable for ${selectedChild.fullName} (Class ${selectedChild.currentClassId}-${selectedChild.currentSectionId})'
                : 'Select child above',
            child: Row(
              children: [
                const Text('Day of Week: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedDay,
                  items: const [
                    DropdownMenuItem(value: 'Monday', child: Text('Monday')),
                    DropdownMenuItem(value: 'Tuesday', child: Text('Tuesday')),
                    DropdownMenuItem(value: 'Wednesday', child: Text('Wednesday')),
                    DropdownMenuItem(value: 'Thursday', child: Text('Thursday')),
                    DropdownMenuItem(value: 'Friday', child: Text('Friday')),
                    DropdownMenuItem(value: 'Saturday', child: Text('Saturday')),
                  ],
                  onChanged: (v) => setState(() => _selectedDay = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          timetableAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.parentBlue),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (slots) {
              return ErpCard(
                title: '$_selectedDay Classes',
                subtitle: '${slots.length} Subject Periods Scheduled',
                child: slots.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No classes scheduled for this day.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: slots.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final slot = slots[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.parentBlue.withValues(alpha: 0.1),
                              child: Text('${idx + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.parentBlue)),
                            ),
                            title: Text(slot.subjectName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Teacher: ${slot.teacherName} • Room: ${slot.roomNumber}'),
                            trailing: Text(
                              '${slot.startTime} – ${slot.endTime}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }
}
