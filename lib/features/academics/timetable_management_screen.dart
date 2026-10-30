import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Timetable Management
/// Route: /academics/timetable
class TimetableManagementScreen extends ConsumerStatefulWidget {
  const TimetableManagementScreen({super.key});

  @override
  ConsumerState<TimetableManagementScreen> createState() =>
      _TimetableManagementScreenState();
}

class _TimetableManagementScreenState
    extends ConsumerState<TimetableManagementScreen> {
  String _selectedClass = '10-A';
  String _selectedDay = 'Monday';

  @override
  Widget build(BuildContext context) {
    final timetableAsync = ref.watch(childTimetableProvider);
    final user = ref.watch(currentUserProfileProvider).value;
    final isParent = user?.role == UserRoles.parentGuardian;

    return ResponsiveScaffold(
      title: isParent ? "Child's Timetable" : 'Timetable Management',
      currentRoute: AppRoutes.academicsTimetable,
      actions: [
        if (!isParent)
          ErpButton(
            label: 'Add Period Slot',
            icon: Icons.add,
            isDense: true,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Timetable slot configuration active.')),
              );
            },
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: isParent
                ? 'Academic Schedule & Timing'
                : 'Master Timetable Grid & Period Allocation',
            subtitle:
                'Subject periods, classroom assignments, and teaching faculty allocation',
            child: Row(
              children: [
                if (!isParent) ...[
                  DropdownButton<String>(
                    value: _selectedClass,
                    items: const [
                      DropdownMenuItem(value: '10-A', child: Text('Class 10-A')),
                      DropdownMenuItem(value: '10-B', child: Text('Class 10-B')),
                      DropdownMenuItem(value: '9-A', child: Text('Class 9-A')),
                      DropdownMenuItem(value: '9-B', child: Text('Class 9-B')),
                    ],
                    onChanged: (v) => setState(() => _selectedClass = v!),
                  ),
                  const SizedBox(width: 16),
                ],
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
              child: CircularProgressIndicator(color: AppColors.brandNavy),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
            data: (slots) {
              return ErpCard(
                title: '$_selectedDay Schedule (${isParent ? "Current Term" : _selectedClass})',
                subtitle: '${slots.length} Academic Periods Scheduled',
                child: slots.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No periods scheduled for this day.',
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
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: Text('${idx + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandNavy)),
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
