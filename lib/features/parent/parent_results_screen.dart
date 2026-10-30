import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/examination_model.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent Results Portal
/// Route: /parent/results
class ParentResultsScreen extends ConsumerWidget {
  const ParentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ResponsiveScaffold(
      title: "Child's Examination Results",
      currentRoute: AppRoutes.parentResults,
      actions: [
        if (selectedChild != null)
          ErpButton(
            label: 'View Report Card',
            icon: Icons.picture_as_pdf_outlined,
            isDense: true,
            onPressed: () => PrintPreviewDialog.showReportCard(
              context,
              student: selectedChild,
              examination: Examination(
                examId: 'EXAM_${selectedChild.currentAcademicYearId}_RESULTS',
                title: 'Academic Progress Report',
                academicYearId: selectedChild.currentAcademicYearId,
                term: 'Published Results',
              ),
              marks: const [],
            ),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const Center(child: Text('No student selected.'))
          else ...[
            ErpCard(
              title: 'Term Examination Academic Performance',
              subtitle:
                  'Continuous Assessment (40) + Written Examination (60) for ${selectedChild.fullName}',
              child: const ErpMetricStrip(
                metrics: [
                  MetricItem(
                    label: 'Overall CGPA',
                    value: '8.8 / 10',
                    accentColor: AppColors.successGreen,
                  ),
                  MetricItem(
                    label: 'Total Marks',
                    value: '442 / 500',
                    accentColor: AppColors.parentBlue,
                  ),
                  MetricItem(
                    label: 'Class Rank',
                    value: 'Rank 4 / 30',
                    accentColor: AppColors.tealSuccess,
                  ),
                  MetricItem(
                    label: 'Result Status',
                    value: 'PASSED (DISTINCTION)',
                    accentColor: AppColors.successGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ErpCard(
              title: 'Subject-wise Performance Breakdown',
              child: Column(
                children: [
                  _buildSubjectRow('Mathematics', 38, 54, 92, 'A1'),
                  _buildSubjectRow('Science', 36, 52, 88, 'A2'),
                  _buildSubjectRow('English Language & Lit.', 37, 51, 88, 'A2'),
                  _buildSubjectRow('Social Science', 35, 52, 87, 'A2'),
                  _buildSubjectRow('Hindi Second Language', 36, 51, 87, 'A2'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectRow(
      String subject, int ca, int exam, int total, String grade) {
    return ListTile(
      title: Text(subject, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text('CA: $ca/40 • Final Exam: $exam/60'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$total / 100',
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(width: 8),
          Chip(
            label: Text(grade,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            backgroundColor: AppColors.successGreen,
          ),
        ],
      ),
    );
  }
}
