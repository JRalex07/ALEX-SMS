import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/attendance_register_dialog.dart';
import '../../shared/dialogs/confirm_action_dialog.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_badge.dart';

class AttendanceResourceScreen extends ConsumerStatefulWidget {
  const AttendanceResourceScreen({super.key});

  @override
  ConsumerState<AttendanceResourceScreen> createState() =>
      _AttendanceResourceScreenState();
}

class _AttendanceResourceScreenState
    extends ConsumerState<AttendanceResourceScreen> {
  // Teacher roll-call state
  String _selectedClass = '10';
  String _selectedSection = 'A';
  final Map<String, String> _rollCallMap = {
    'STU_001': 'P',
    'STU_002': 'P',
    'STU_003': 'A',
    'STU_004': 'P',
    'STU_005': 'L',
  };

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    Widget body;
    if (role == UserRoles.parentGuardian) {
      body = _buildParentAttendanceView();
    } else if (role == UserRoles.teacher) {
      body = _buildTeacherAttendanceView();
    } else if (role == UserRoles.schoolAdmin) {
      body = _buildAdminAttendanceView();
    } else {
      body = _buildGeneralAttendanceView();
    }

    return ResponsiveScaffold(
      title: 'Attendance Management',
      currentRoute: '/attendance',
      body: body,
    );
  }

  // --- Parent Attendance View (Scoped to Selected Child) ---
  Widget _buildParentAttendanceView() {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ParentChildSwitcher(),
              SizedBox(height: 24),
              Icon(Icons.child_care, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text('No Student Profile Linked',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final attendanceAsync = ref.watch(activeChildAttendanceProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ParentChildSwitcher(),
        const SizedBox(height: 20),
        const Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Academic Year Rate',
                value: '94.2%',
                subtitle: 'Target: >75% Board Minimum',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.successGreen,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Days Attended',
                value: '146 / 155',
                subtitle: '7 Absences • 2 Excused',
                icon: Icons.calendar_month,
                iconColor: AppColors.parentBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attendance Log — ${selectedChild.fullName}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.print, size: 14),
                          label: const Text('Print Register'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () => AttendanceRegisterDialog.show(
                            context,
                            classId: selectedChild.currentClassId,
                            sectionId: selectedChild.currentSectionId,
                            date: DateTime.now(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Regular Standing',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.successGreen)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                attendanceAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading records: $e'),
                  data: (records) {
                    if (records.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No attendance entries recorded yet.'),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final rec = records[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.parentBlue.withValues(alpha: 0.1),
                            child: Text(
                              rec.status,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.parentBlue),
                            ),
                          ),
                          title: Text('Session: ${rec.sessionId}'),
                          subtitle:
                              rec.remarks != null ? Text(rec.remarks!) : null,
                          trailing: rec.status == 'P'
                              ? StatusBadge.success('Present')
                              : (rec.status == 'A'
                                  ? StatusBadge.danger('Absent')
                                  : StatusBadge.warning('Late')),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Teacher Attendance View (Take Roll Call) ---
  Widget _buildTeacherAttendanceView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.class_, color: AppColors.teacherTeal),
                const SizedBox(width: 12),
                const Text('Select Assigned Class:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedClass,
                  items: const [
                    DropdownMenuItem(value: '10', child: Text('Class 10')),
                    DropdownMenuItem(value: '9', child: Text('Class 9')),
                  ],
                  onChanged: (v) => setState(() => _selectedClass = v!),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedSection,
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('Section A')),
                    DropdownMenuItem(value: 'B', child: Text('Section B')),
                  ],
                  onChanged: (v) => setState(() => _selectedSection = v!),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print Register'),
                  onPressed: () => AttendanceRegisterDialog.show(
                    context,
                    classId: _selectedClass,
                    sectionId: _selectedSection,
                    date: DateTime.now(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Submit Session for Approval'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teacherTeal,
                  ),
                  onPressed: () => ConfirmActionDialog.show(
                    context,
                    title: 'Submit Attendance Roll Call',
                    message:
                        'Are you sure you want to submit the attendance session for Class $_selectedClass-$_selectedSection? Once submitted, it will be forwarded for administrative finalization.',
                    confirmLabel: 'Confirm Submission',
                    confirmColor: AppColors.teacherTeal,
                    onConfirm: (reason) async {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Attendance session submitted! Sent to Administrator for finalization.'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Roll Call — Class $_selectedClass-$_selectedSection (${DateTime.now().toLocal().toString().split(' ')[0]})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ...['STU_001', 'STU_002', 'STU_003', 'STU_004', 'STU_005']
                    .map((stuId) {
                  final status = _rollCallMap[stuId] ?? 'P';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.teacherTeal.withValues(alpha: 0.1),
                          child: Text(stuId.replaceAll('STU_00', ''),
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          stuId == 'STU_001'
                              ? 'Aarav Sharma (Roll 101)'
                              : (stuId == 'STU_002'
                                  ? 'Diya Sharma (Roll 102)'
                                  : 'Student $stuId'),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'P', label: Text('Present')),
                            ButtonSegment(value: 'A', label: Text('Absent')),
                            ButtonSegment(value: 'L', label: Text('Late')),
                          ],
                          selected: {status},
                          onSelectionChanged: (set) {
                            setState(() => _rollCallMap[stuId] = set.first);
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Admin Attendance View (Approvals & Audits) ---
  Widget _buildAdminAttendanceView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'School Attendance Rate Today',
                value: '93.8%',
                subtitle: '1,126 / 1,200 Students Present',
                icon: Icons.check_circle_outline,
                iconColor: AppColors.adminIndigo,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Pending Finalization',
                value: '2 Sessions',
                subtitle: 'Class 8-C, Class 11-A',
                icon: Icons.pending_actions,
                iconColor: AppColors.warningAmber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attendance Approval Queue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                ListTile(
                  leading:
                      const Icon(Icons.school, color: AppColors.adminIndigo),
                  title: const Text('Class 10-A Daily Roll Call'),
                  subtitle: const Text(
                      'Submitted by: Mrs. Sunita Rao • 38 Present, 2 Absent'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Review'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session approved and locked!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        },
                        child: const Text('Approve & Finalize'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- General Read-only Attendance View ---
  Widget _buildGeneralAttendanceView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'Institutional Daily Attendance Registry • AY 2026-27',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
