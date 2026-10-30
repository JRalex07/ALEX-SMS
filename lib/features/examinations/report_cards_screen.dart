import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/examination_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Report Cards & Transcripts
/// Route: /examinations/report-cards
class ReportCardsScreen extends ConsumerStatefulWidget {
  const ReportCardsScreen({super.key});

  @override
  ConsumerState<ReportCardsScreen> createState() => _ReportCardsScreenState();
}

class _ReportCardsScreenState extends ConsumerState<ReportCardsScreen> {
  final _searchController = TextEditingController();
  String _selectedClass = '10';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Report Cards & Academic Transcripts',
      currentRoute: AppRoutes.examinationsReportCards,
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            final matchesClass =
                _selectedClass == 'All' || s.currentClassId == _selectedClass;
            final matchesQuery = query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
            return matchesClass && matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Official Academic Transcript Generation',
                subtitle:
                    'Generate print-ready CBSE term report cards with school crest, grading legend, and attendance summary',
                child: Row(
                  children: [
                    Expanded(
                      child: ErpSearchBar(
                        controller: _searchController,
                        hintText: 'Search student by name or admission number...',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedClass,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Classes')),
                        DropdownMenuItem(value: '10', child: Text('Class 10')),
                        DropdownMenuItem(value: '9', child: Text('Class 9')),
                        DropdownMenuItem(value: '8', child: Text('Class 8')),
                        DropdownMenuItem(value: '7', child: Text('Class 7')),
                        DropdownMenuItem(value: '6', child: Text('Class 6')),
                      ],
                      onChanged: (v) => setState(() => _selectedClass = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Student Roster for Report Cards (${filtered.length})',
                subtitle: 'Mid-Term Examinations 2026',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No student records found.',
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
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(Icons.picture_as_pdf,
                                  color: AppColors.dangerRed),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Adm #${s.admissionNumber} • Standard: Class ${s.currentClassId}-${s.currentSectionId} • Status: Complete'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.visibility_outlined,
                                      size: 14),
                                  label: const Text('View Card'),
                                  onPressed: () =>
                                      PrintPreviewDialog.showReportCard(
                                    context,
                                    student: s,
                                    examination: const Examination(
                                      examId: 'EXAM_MIDTERM_2026',
                                      title: 'Mid-Term Examinations 2026',
                                      academicYearId: 'AY-2026-2027',
                                      term: 'Term 1',
                                    ),
                                    marks: const [],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.print_outlined,
                                      size: 14),
                                  label: const Text('Print Preview'),
                                  onPressed: () {
                                    PrintPreviewDialog.showReportCard(
                                      context,
                                      student: s,
                                      examination: const Examination(
                                        examId: 'EXAM_MIDTERM_2026',
                                        title: 'Mid-Term Examinations 2026',
                                        academicYearId: 'AY-2026-2027',
                                        term: 'Term 1',
                                      ),
                                      marks: const [],
                                    );
                                  },
                                ),
                              ],
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
