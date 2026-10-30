import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../models/attendance_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/attendance_register_dialog.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_badge.dart';

class AttendanceResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  const AttendanceResourceScreen({super.key, this.initialTab});

  @override
  ConsumerState<AttendanceResourceScreen> createState() =>
      _AttendanceResourceScreenState();
}

class _AttendanceResourceScreenState
    extends ConsumerState<AttendanceResourceScreen> {
  // Teacher roll-call state
  String _selectedClass = '10';
  String _selectedSection = 'A';
  // Stores only statuses explicitly selected for the currently loaded roster.
  final Map<String, String> _rollCallMap = {};

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
        attendanceAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('Unable to calculate attendance summary: $error'),
          data: (records) {
            final total = records.length;
            final present = records.where((r) => r.status == 'P').length;
            final late = records.where((r) => r.status == 'L').length;
            final absent = records.where((r) => r.status == 'A').length;
            final excused = records.where((r) => r.status == 'E').length;
            final rate = total == 0 ? '—' : '${(((present + late) / total) * 100).toStringAsFixed(1)}%';
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(width: 280, child: StatCard(
                  title: 'Recorded Attendance Rate', value: rate,
                  subtitle: total == 0 ? 'No attendance records yet' : '$present present • $late late',
                  icon: Icons.check_circle_outline, iconColor: AppColors.successGreen,
                )),
                SizedBox(width: 280, child: StatCard(
                  title: 'Attendance Records', value: '$total',
                  subtitle: total == 0 ? 'No recorded days' : '$absent absent • $excused excused',
                  icon: Icons.calendar_month, iconColor: AppColors.parentBlue,
                )),
              ],
            );
          },
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
                          onPressed: () =>
                              PrintPreviewDialog.showAttendanceRegister(
                            context,
                            classId: selectedChild.currentClassId,
                            sectionId: selectedChild.currentSectionId,
                            date: DateTime.now()
                                .toLocal()
                                .toString()
                                .split(' ')
                                .first,
                            sessions: const [],
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
                          child: const Text('Attendance records',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.successGreen)),
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
    final profile = ref.watch(currentUserProfileProvider).value;
    final assignedClasses = profile?.assignedClasses ?? const <String>[];
    final assignedSections = profile?.assignedSections ?? const <String>[];
    if (profile == null || assignedClasses.isEmpty || assignedSections.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Text(
            'No class and section assignment is available for this staff profile. Ask the school administrator to assign your teaching scope.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedClass = assignedClasses.contains(_selectedClass)
        ? _selectedClass
        : assignedClasses.first;
    final selectedSection = assignedSections.contains(_selectedSection)
        ? _selectedSection
        : assignedSections.first;
    final studentsAsync = ref.watch(classStudentsStreamProvider(
      (classId: selectedClass, sectionId: selectedSection),
    ));
    final sessionsAsync = ref.watch(attendanceSessionsStreamProvider(
      (classId: selectedClass, sectionId: selectedSection),
    ));
    final today = DateTime.now().toLocal().toIso8601String().split('T').first;

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
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.class_, color: AppColors.teacherTeal),
                const Text('Assigned class:', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<String>(
                  value: selectedClass,
                  items: assignedClasses.map((value) => DropdownMenuItem(value: value, child: Text('Class $value'))).toList(),
                  onChanged: (value) => setState(() {
                    if (value != null) {
                      _selectedClass = value;
                      _rollCallMap.clear();
                    }
                  }),
                ),
                const Text('Section:', style: TextStyle(fontWeight: FontWeight.w600)),
                DropdownButton<String>(
                  value: selectedSection,
                  items: assignedSections.map((value) => DropdownMenuItem(value: value, child: Text('Section $value'))).toList(),
                  onChanged: (value) => setState(() {
                    if (value != null) {
                      _selectedSection = value;
                      _rollCallMap.clear();
                    }
                  }),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print Register'),
                  onPressed: () => studentsAsync.whenOrNull(
                    data: (students) =>
                        PrintPreviewDialog.showAttendanceRegister(
                      context,
                      classId: selectedClass,
                      sectionId: selectedSection,
                      date:
                          DateTime.now().toLocal().toString().split(' ').first,
                      sessions: const [],
                      students: students
                          .where((student) => student.status == 'enrolled')
                          .toList(),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save roll call'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teacherTeal, foregroundColor: Colors.white),
                  onPressed: () async {
                    final students = studentsAsync.value?.where((student) => student.status == 'enrolled').toList() ?? [];
                    if (students.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No enrolled students exist in this assigned cohort.')));
                      return;
                    }
                    if (students.any((student) => !_rollCallMap.containsKey(student.studentId))) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select Present, Absent, Late or Excused for every enrolled student before saving.')));
                      return;
                    }
                    final sessions = sessionsAsync.value ?? [];
                    final sessionId = 'SES_${selectedClass}_${selectedSection}_${today.replaceAll('-', '')}_${profile.uid}';
                    AttendanceSession? existing;
                    for (final session in sessions) {
                      if (session.sessionId == sessionId) { existing = session; break; }
                    }
                    if (existing != null && (existing.isApproved || existing.isFinalized)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This attendance session is already approved or finalized and cannot be edited.')));
                      return;
                    }
                    try {
                      if (existing == null) {
                        await ref.read(attendanceRepositoryProvider).createDraftSession(AttendanceSession(
                          sessionId: sessionId,
                          classId: selectedClass,
                          sectionId: selectedSection,
                          date: today,
                          academicYearId: 'AY_2026_2027',
                          markedBy: profile.uid,
                        ));
                      }
                      for (final student in students) {
                        await ref.read(attendanceRepositoryProvider).saveAttendanceRecord(
                          sessionId: sessionId,
                          studentId: student.studentId,
                          status: _rollCallMap[student.studentId]!,
                        );
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance draft saved. It is awaiting administrative approval.')));
                      }
                    } catch (error) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance was not fully saved: $error')));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderLight)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily roll call — Class $selectedClass / Section $selectedSection', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Date: $today', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 16),
                studentsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Text('Unable to load assigned roster: $error'),
                  data: (allStudents) {
                    final students = allStudents.where((student) => student.status == 'enrolled').toList();
                    if (students.isEmpty) return const Text('No enrolled students are assigned to this cohort.');
                    return Column(children: [
                      for (final student in students)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              CircleAvatar(radius: 16, child: Text(student.fullName.isEmpty ? '?' : student.fullName.substring(0, 1).toUpperCase())),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('${student.admissionNumber} • ${student.studentId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ])),
                              const SizedBox(width: 8),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(value: 'P', label: Text('Present')),
                                  ButtonSegment(value: 'A', label: Text('Absent')),
                                  ButtonSegment(value: 'L', label: Text('Late')),
                                  ButtonSegment(value: 'E', label: Text('Excused')),
                                ],
                                selected: _rollCallMap.containsKey(student.studentId) ? {_rollCallMap[student.studentId]!} : const <String>{},
                                onSelectionChanged: (values) => setState(() => _rollCallMap[student.studentId] = values.first),
                              ),
                            ],
                          ),
                        ),
                    ]);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Admin Attendance View (Approvals & Audits) ---
  Widget _buildAdminAttendanceView() {
    final sessionsAsync = ref.watch(allAttendanceSessionsStreamProvider);
    final today = DateTime.now().toLocal().toIso8601String().split('T').first;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Attendance governance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Review teacher-submitted attendance and finalize sessions through the secured backend workflow.', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        sessionsAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
          error: (error, _) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('Unable to load attendance sessions: $error'))),
          data: (sessions) {
            final todays = sessions.where((session) => session.date == today).toList();
            final pending = sessions.where((session) => !session.isFinalized).toList();
            final completedSummarySessions = todays.where((session) => session.summary != null).toList();
            final total = completedSummarySessions.fold<int>(0, (sum, session) => sum + (session.summary?.totalStudents ?? 0));
            final present = completedSummarySessions.fold<int>(0, (sum, session) => sum + (session.summary?.presentCount ?? 0));
            final rate = total == 0 ? '—' : '${(present / total * 100).toStringAsFixed(1)}%';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(spacing: 16, runSpacing: 16, children: [
                  SizedBox(width: 280, child: StatCard(title: 'Today’s Recorded Rate', value: rate, subtitle: total == 0 ? 'No finalized daily summary yet' : '$present present out of $total recorded', icon: Icons.check_circle_outline, iconColor: AppColors.adminIndigo)),
                  SizedBox(width: 280, child: StatCard(title: 'Awaiting Finalization', value: '${pending.length}', subtitle: 'Sessions not finalized', icon: Icons.pending_actions, iconColor: AppColors.warningAmber)),
                  SizedBox(width: 280, child: StatCard(title: 'Sessions Today', value: '${todays.length}', subtitle: 'Based on registered sessions', icon: Icons.calendar_month, iconColor: AppColors.parentBlue)),
                ]),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.borderLight)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Attendance approval queue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      if (pending.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No attendance sessions are awaiting finalization.')),
                      for (final session in pending) ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(child: Icon(Icons.how_to_reg_outlined)),
                          title: Text('Class ${session.classId} • Section ${session.sectionId}'),
                          subtitle: Text('Date: ${session.date} • Submitted by: ${session.markedBy}\nStatus: ${session.isApproved ? 'Approved — ready to finalize' : 'Awaiting approval'}'),
                          isThreeLine: true,
                          trailing: Wrap(spacing: 8, children: [
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  final students = await ref.read(studentRepositoryProvider).getStudentsStream(classId: session.classId, sectionId: session.sectionId).first;
                                  final records = await ref.read(attendanceRepositoryProvider).getSessionRecordsStream(session.sessionId).first;
                                  final map = {for (final record in records) record.studentId: record.status};
                                  if (mounted) await AttendanceRegisterDialog.show(context, classId: session.classId, sectionId: session.sectionId, date: DateTime.tryParse(session.date) ?? DateTime.now(), students: students.where((student) => student.status == 'enrolled').toList(), attendanceMap: map);
                                } catch (error) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open attendance register: $error')));
                                }
                              },
                              child: const Text('Review'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: session.isApproved ? AppColors.successGreen : AppColors.adminIndigo, foregroundColor: Colors.white),
                              onPressed: () async {
                                try {
                                  final repository = ref.read(attendanceRepositoryProvider);
                                  if (!session.isApproved) {
                                    await repository.approveAttendanceSession(session.sessionId);
                                  } else {
                                    await repository.finalizeAttendanceSession(session.sessionId);
                                  }
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(session.isApproved ? 'Finalization requested for ${session.sessionId}.' : 'Approval requested for ${session.sessionId}.')));
                                } catch (error) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Attendance workflow failed: $error')));
                                }
                              },
                              child: Text(session.isApproved ? 'Finalize' : 'Approve'),
                            ),
                          ]),
                        ),
                        const Divider(height: 1),
                      ],
                    ]),
                  ),
                ),
              ],
            );
          },
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
