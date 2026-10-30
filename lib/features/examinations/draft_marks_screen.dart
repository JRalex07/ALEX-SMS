import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Draft Marks Review & Moderation
/// Route: /examinations/drafts
class DraftMarksScreen extends ConsumerStatefulWidget {
  const DraftMarksScreen({super.key});

  @override
  ConsumerState<DraftMarksScreen> createState() => _DraftMarksScreenState();
}

class _DraftMarksScreenState extends ConsumerState<DraftMarksScreen> {
  final List<Map<String, dynamic>> _draftBatches = [
    {
      'class': 'Class 10-A',
      'subject': 'Mathematics',
      'faculty': 'Tarun Sharma',
      'studentsCount': 30,
      'evaluatedCount': 30,
      'averageScore': 78.4,
      'status': 'moderation_pending',
    },
    {
      'class': 'Class 10-A',
      'subject': 'Science',
      'faculty': 'Dr. Anita Joshi',
      'studentsCount': 30,
      'evaluatedCount': 28,
      'averageScore': 81.2,
      'status': 'draft',
    },
    {
      'class': 'Class 10-B',
      'subject': 'Mathematics',
      'faculty': 'K. V. Raman',
      'studentsCount': 28,
      'evaluatedCount': 28,
      'averageScore': 74.0,
      'status': 'moderation_pending',
    },
    {
      'class': 'Class 9-A',
      'subject': 'English',
      'faculty': 'Priya Nair',
      'studentsCount': 29,
      'evaluatedCount': 29,
      'averageScore': 82.5,
      'status': 'approved_for_publication',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Draft Marks Moderation',
      currentRoute: AppRoutes.examinationsDrafts,
      actions: [
        ErpButton(
          label: 'Proceed to Publication',
          icon: Icons.publish,
          isDense: true,
          onPressed: () => context.go(AppRoutes.examinationsPublication),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: 'Faculty Marks Moderation & Verification Ledger',
            subtitle:
                'Review instructor continuous assessment drafts and sign off for publication',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Pending Moderation',
                  value: '2 Batches',
                  accentColor: AppColors.warningAmber,
                ),
                MetricItem(
                  label: 'Ready for Publication',
                  value: '1 Batch',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Drafting Incomplete',
                  value: '1 Batch',
                  accentColor: AppColors.dangerRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Submitted Draft Marksheets (${_draftBatches.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _draftBatches.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final b = _draftBatches[idx];
                final status = b['status'] as String;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandNavy.withValues(alpha: 0.1),
                    child: const Icon(Icons.description_outlined,
                        color: AppColors.brandNavy, size: 20),
                  ),
                  title: Text('${b['class']} — ${b['subject']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Instructor: ${b['faculty']} • Scored: ${b['evaluatedCount']}/${b['studentsCount']} pupils • Mean: ${b['averageScore']}/100'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: status.replaceAll('_', ' ').toUpperCase(),
                        type: status == 'approved_for_publication'
                            ? StatusType.success
                            : StatusType.warning,
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Moderating batch for ${b['class']} ${b['subject']}')),
                          );
                        },
                        child: const Text('Audit Marks'),
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
