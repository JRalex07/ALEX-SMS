import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../models/examination_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Student Lookup & Profile Details
/// Route: /students/lookup
class StudentLookupScreen extends ConsumerStatefulWidget {
  final String? studentId;

  const StudentLookupScreen({super.key, this.studentId});

  @override
  ConsumerState<StudentLookupScreen> createState() =>
      _StudentLookupScreenState();
}

class _StudentLookupScreenState extends ConsumerState<StudentLookupScreen> {
  final _searchController = TextEditingController();
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _searchController.text = widget.studentId!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Student Details & Lookup',
      currentRoute: AppRoutes.studentLookup,
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final matches = query.isEmpty
              ? students.take(8).toList()
              : students
                  .where((s) =>
                      s.fullName.toLowerCase().contains(query) ||
                      s.admissionNumber.toLowerCase().contains(query) ||
                      s.studentId.toLowerCase().contains(query))
                  .toList();

          final currentStudent =
              _selectedStudent ?? (matches.isNotEmpty ? matches.first : null);

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Search & Quick List
                SizedBox(
                  width: 340,
                  child: Column(
                    children: [
                      ErpSearchBar(
                        controller: _searchController,
                        hintText: 'Lookup ID, Adm #, or Name...',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ErpCard(
                          title: 'Results (${matches.length})',
                          child: ListView.separated(
                            itemCount: matches.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: AppColors.borderLight),
                            itemBuilder: (ctx, idx) {
                              final s = matches[idx];
                              final isSelected =
                                  currentStudent?.studentId == s.studentId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor:
                                    AppColors.brandNavy.withValues(alpha: 0.08),
                                title: Text(s.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                subtitle: Text(
                                    'Adm: ${s.admissionNumber} • Cls: ${s.currentClassId}-${s.currentSectionId}'),
                                onTap: () =>
                                    setState(() => _selectedStudent = s),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Comprehensive Student Details Card
                Expanded(
                  child: currentStudent == null
                      ? const Center(
                          child: Text('No student selected or found.',
                              style: TextStyle(color: AppColors.textMuted)),
                        )
                      : ErpCard(
                          title: currentStudent.fullName,
                          subtitle:
                              'Admission #${currentStudent.admissionNumber} • Class ${currentStudent.currentClassId}-${currentStudent.currentSectionId}',
                          headerTrailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                icon:
                                    const Icon(Icons.picture_as_pdf, size: 16),
                                label: const Text('Report Card'),
                                onPressed: () =>
                                    PrintPreviewDialog.showReportCard(
                                  context,
                                  student: currentStudent,
                                  examination: Examination(
                                    examId:
                                        'EXAM_${currentStudent.currentAcademicYearId}_RESULTS',
                                    title: 'Academic Progress Report',
                                    academicYearId:
                                        currentStudent.currentAcademicYearId,
                                    term: 'Annual Evaluation',
                                  ),
                                  marks: const [],
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon:
                                    const Icon(Icons.print_outlined, size: 16),
                                label: const Text('Print Profile'),
                                onPressed: () =>
                                    PrintPreviewDialog.showStudentProfile(
                                  context,
                                  student: currentStudent,
                                ),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ErpMetricStrip(
                                metrics: [
                                  MetricItem(
                                    label: 'Status',
                                    value: currentStudent.status.toUpperCase(),
                                    accentColor: AppColors.successGreen,
                                  ),
                                  MetricItem(
                                    label: 'Academic Year',
                                    value: currentStudent.currentAcademicYearId,
                                  ),
                                  MetricItem(
                                    label: 'Guardians Linked',
                                    value:
                                        '${currentStudent.guardianUserIds.length}',
                                  ),
                                  MetricItem(
                                    label: 'Emergency Contact',
                                    value: currentStudent.emergencyContact ??
                                        'N/A',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              const Text('Institutional Records',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              ListTile(
                                leading: const Icon(Icons.badge_outlined,
                                    color: AppColors.brandNavy),
                                title: const Text('Unique Student Identifier'),
                                subtitle: Text(currentStudent.studentId),
                              ),
                              ListTile(
                                leading: const Icon(Icons.school_outlined,
                                    color: AppColors.brandNavy),
                                title: const Text('Current Academic Placement'),
                                subtitle: Text(
                                    'Standard: Class ${currentStudent.currentClassId} | Section: ${currentStudent.currentSectionId}'),
                              ),
                              ListTile(
                                leading: const Icon(Icons.phone_outlined,
                                    color: AppColors.brandNavy),
                                title: const Text('Primary Contact'),
                                subtitle: Text(
                                    currentStudent.emergencyContact ??
                                        'No emergency telephone configured'),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
