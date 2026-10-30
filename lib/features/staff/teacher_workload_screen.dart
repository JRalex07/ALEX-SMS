import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Teacher Workload & Scope Assignments
/// Route: /staff/workload
class TeacherWorkloadScreen extends ConsumerStatefulWidget {
  const TeacherWorkloadScreen({super.key});

  @override
  ConsumerState<TeacherWorkloadScreen> createState() =>
      _TeacherWorkloadScreenState();
}

class _TeacherWorkloadScreenState extends ConsumerState<TeacherWorkloadScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffMembersStreamProvider);

    return ResponsiveScaffold(
      title: 'Teacher Workload & Assignments',
      currentRoute: AppRoutes.staffWorkload,
      actions: [
        ErpButton(
          label: 'Assign Class Scope',
          icon: Icons.assignment_ind,
          isDense: true,
          onPressed: () => AssignTeacherDialog.show(context),
        ),
      ],
      body: staffAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (staff) {
          final teachers =
              staff.where((u) => u.role == UserRoles.teacher).toList();
          final query = _searchController.text.trim().toLowerCase();
          final filtered = teachers.where((u) {
            return query.isEmpty ||
                u.displayName.toLowerCase().contains(query) ||
                u.email.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Teaching Faculty Workload & Classroom Scope Allocation',
                subtitle:
                    'Manage subject responsibilities, class-teacher supervisor roles, and teaching hours',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search faculty by name or email...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Teaching Faculty Roster (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No teachers found.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final teacher = filtered[idx];
                          final assigned = teacher.assignedClasses;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.teacherTeal.withValues(alpha: 0.12),
                              child: const Icon(Icons.school,
                                  color: AppColors.teacherTeal),
                            ),
                            title: Text(teacher.displayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text('${teacher.email}\n'
                                'Assigned Cohorts: ${assigned.isEmpty ? "No active classrooms assigned" : assigned.join(", ")}'),
                            isThreeLine: true,
                            trailing: OutlinedButton.icon(
                              icon: const Icon(Icons.edit, size: 14),
                              label: const Text('Edit Scope'),
                              onPressed: () =>
                                  AssignTeacherDialog.show(context),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
