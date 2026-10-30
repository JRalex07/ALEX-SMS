import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/examination_model.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Examinations Setup & Catalog
/// Route: /examinations
class ExaminationsCatalogScreen extends ConsumerStatefulWidget {
  const ExaminationsCatalogScreen({super.key});

  @override
  ConsumerState<ExaminationsCatalogScreen> createState() =>
      _ExaminationsCatalogScreenState();
}

class _ExaminationsCatalogScreenState
    extends ConsumerState<ExaminationsCatalogScreen> {
  final List<Examination> _exams = const [
    Examination(
      examId: 'EXAM_MIDTERM_2026',
      title: 'Mid-Term Examinations 2026',
      academicYearId: 'AY-2026-2027',
      term: 'Term 1',
    ),
    Examination(
      examId: 'EXAM_PREBOARD_2027',
      title: 'Pre-Board Mock Examinations 2027',
      academicYearId: 'AY-2026-2027',
      term: 'Term 2',
    ),
    Examination(
      examId: 'EXAM_ANNUAL_2027',
      title: 'Annual Board Examination 2027',
      academicYearId: 'AY-2026-2027',
      term: 'Term 3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Examinations Setup',
      currentRoute: AppRoutes.examinations,
      actions: [
        ErpButton(
          label: 'Create Examination',
          icon: Icons.add,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Examination setup wizard active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Institutional Examination Framework (AY 2026-2027)',
            subtitle:
                'Statutory term exams, continuous assessments, and grading scheme definitions',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Registered Exams',
                  value: '${_exams.length}',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Grading Scale',
                  value: 'CBSE 9-Point Scale',
                  accentColor: AppColors.tealSuccess,
                ),
                const MetricItem(
                  label: 'Current Cycle',
                  value: 'Mid-Term Evaluation',
                  accentColor: AppColors.infoBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Examinations Registry (${_exams.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _exams.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final ex = _exams[idx];
                final isCurrent = idx == 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? AppColors.brandNavy.withValues(alpha: 0.12)
                        : AppColors.surfaceMuted,
                    child: Icon(
                      Icons.quiz_outlined,
                      color: isCurrent
                          ? AppColors.brandNavy
                          : AppColors.textSecondary,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(ex.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        const StatusBadge(
                            label: 'ACTIVE', type: StatusType.success),
                      ],
                    ],
                  ),
                  subtitle: Text(
                      'Exam ID: ${ex.examId} • Academic Session: ${ex.academicYearId} • ${ex.term}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () =>
                            context.go(AppRoutes.examinationsSchedule),
                        child: const Text('Schedule'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () =>
                            context.go(AppRoutes.examinationsMarks),
                        child: const Text('Enter Marks'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
