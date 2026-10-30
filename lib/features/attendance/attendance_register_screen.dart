import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Attendance Register (Mark Attendance)
/// Route: /attendance/register
class AttendanceRegisterScreen extends ConsumerStatefulWidget {
  const AttendanceRegisterScreen({super.key});

  @override
  ConsumerState<AttendanceRegisterScreen> createState() =>
      _AttendanceRegisterScreenState();
}

class _AttendanceRegisterScreenState
    extends ConsumerState<AttendanceRegisterScreen> {
  String _selectedClass = '10';
  String _selectedSection = 'A';
  final Map<String, String> _rollCallMap = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Attendance Register',
      currentRoute: AppRoutes.attendanceRegister,
      actions: [
        ErpButton(
          label: 'Print Register Preview',
          icon: Icons.print,
          isDense: true,
          onPressed: () => PrintPreviewDialog.showAttendanceRegister(
            context,
            classId: _selectedClass,
            sectionId: _selectedSection,
            date: DateTime.now().toLocal().toString().split(' ').first,
            sessions: const [],
          ),
        ),
      ],
      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error loading students: $err')),
        data: (students) {
          final roster = students
              .where((s) =>
                  s.currentClassId == _selectedClass &&
                  s.currentSectionId == _selectedSection)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Daily Roll-Call Session',
                subtitle:
                    'Take presence for Class $_selectedClass-$_selectedSection • ${DateTime.now().toLocal().toString().split(" ").first}',
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          prefixIcon: Icon(Icons.school_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: '10', child: Text('Class 10')),
                          DropdownMenuItem(value: '9', child: Text('Class 9')),
                          DropdownMenuItem(value: '8', child: Text('Class 8')),
                          DropdownMenuItem(value: '7', child: Text('Class 7')),
                          DropdownMenuItem(value: '6', child: Text('Class 6')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedClass = v!;
                            _rollCallMap.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSection,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          prefixIcon: Icon(Icons.view_column_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'A', child: Text('Section A')),
                          DropdownMenuItem(value: 'B', child: Text('Section B')),
                          DropdownMenuItem(value: 'C', child: Text('Section C')),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedSection = v!;
                            _rollCallMap.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Class $_selectedClass-$_selectedSection Roster (${roster.length} Students)',
                subtitle: 'Tap status indicator to toggle presence',
                headerTrailing: ErpButton(
                  label: _isSaving ? 'Submitting...' : 'Save Register',
                  icon: Icons.save,
                  isDense: true,
                  onPressed: _isSaving || roster.isEmpty
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isSaving = true);
                          await Future.delayed(
                              const Duration(milliseconds: 600));
                          if (!mounted) return;
                          setState(() => _isSaving = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Attendance successfully committed for Class $_selectedClass-$_selectedSection!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        },
                ),
                child: roster.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No students enrolled in this section.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: roster.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final s = roster[idx];
                          final currentStatus = _rollCallMap[s.studentId] ?? 'P';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: Text('${idx + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandNavy)),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text('Adm #${s.admissionNumber}'),
                            trailing: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'P', label: Text('Present')),
                                ButtonSegment(value: 'L', label: Text('Late')),
                                ButtonSegment(value: 'A', label: Text('Absent')),
                                ButtonSegment(value: 'E', label: Text('Excused')),
                              ],
                              selected: {currentStatus},
                              onSelectionChanged: (set) {
                                setState(() {
                                  _rollCallMap[s.studentId] = set.first;
                                });
                              },
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
