import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Marks Entry Desk
/// Route: /examinations/marks
class MarksEntryScreen extends ConsumerStatefulWidget {
  const MarksEntryScreen({super.key});

  @override
  ConsumerState<MarksEntryScreen> createState() => _MarksEntryScreenState();
}

class _MarksEntryScreenState extends ConsumerState<MarksEntryScreen> {
  final _searchController = TextEditingController();
  String _selectedClass = '10';
  String _selectedSubject = 'Mathematics';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Marks Entry Desk',
      currentRoute: AppRoutes.examinationsMarks,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_document, size: 16),
          label: const Text('Drafts'),
          onPressed: () => context.go(AppRoutes.examinationsDrafts),
        ),
        const SizedBox(width: 8),
        ErpButton(
          label: 'Publish Results',
          icon: Icons.publish_outlined,
          isDense: true,
          onPressed: () => context.go(AppRoutes.examinationsPublication),
        ),
      ],
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            final matchesClass = s.currentClassId == _selectedClass;
            final matchesQuery = query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
            return matchesClass && matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Subject Marks Evaluation Ledger',
                subtitle:
                    'Record continuous assessment (CA1: 20, CA2: 20) and terminal written exam (60) scores',
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
                          DropdownMenuItem(
                              value: '10', child: Text('Class 10')),
                          DropdownMenuItem(value: '9', child: Text('Class 9')),
                          DropdownMenuItem(value: '8', child: Text('Class 8')),
                          DropdownMenuItem(value: '7', child: Text('Class 7')),
                          DropdownMenuItem(value: '6', child: Text('Class 6')),
                        ],
                        onChanged: (v) => setState(() => _selectedClass = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.menu_book_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Mathematics', child: Text('Mathematics')),
                          DropdownMenuItem(
                              value: 'Science', child: Text('Science')),
                          DropdownMenuItem(
                              value: 'English', child: Text('English')),
                          DropdownMenuItem(
                              value: 'Social Science',
                              child: Text('Social Science')),
                        ],
                        onChanged: (v) => setState(() => _selectedSubject = v!),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Students in Class $_selectedClass (${filtered.length})',
                subtitle: 'Mid-Term Examinations 2026',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No students found for this class.',
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
                          final s = filtered[idx];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: Text(
                                s.fullName.isNotEmpty ? s.fullName[0] : 'S',
                                style: const TextStyle(
                                    color: AppColors.brandNavy,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Adm #${s.admissionNumber} • Section: ${s.currentSectionId} • Subject: $_selectedSubject'),
                            trailing: ErpButton(
                              label: 'Score Candidate',
                              icon: Icons.grading,
                              isDense: true,
                              onPressed: () => SubmitMarksDialog.show(
                                context,
                                student: s,
                                subject: _selectedSubject,
                                examId: 'EXAM_MIDTERM_2026',
                                subjectId:
                                    'SUB_${_selectedSubject.toUpperCase().substring(0, 4)}',
                              ),
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
