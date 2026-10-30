import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Result Review & Publication
/// Route: /examinations/publication
class ResultPublicationScreen extends ConsumerStatefulWidget {
  const ResultPublicationScreen({super.key});

  @override
  ConsumerState<ResultPublicationScreen> createState() =>
      _ResultPublicationScreenState();
}

class _ResultPublicationScreenState
    extends ConsumerState<ResultPublicationScreen> {
  bool _isPublishing = false;

  final List<Map<String, dynamic>> _cohorts = [
    {
      'class': 'Class 10 (All Sections)',
      'exam': 'Mid-Term Examinations 2026',
      'papersEvaluated': '5 / 5 Subjects Complete',
      'readyForPublish': true,
      'status': 'ready',
    },
    {
      'class': 'Class 9 (All Sections)',
      'exam': 'Mid-Term Examinations 2026',
      'papersEvaluated': '4 / 5 Subjects Complete',
      'readyForPublish': false,
      'status': 'in_moderation',
    },
    {
      'class': 'Class 8 (All Sections)',
      'exam': 'Mid-Term Examinations 2026',
      'papersEvaluated': '5 / 5 Subjects Complete',
      'readyForPublish': true,
      'status': 'ready',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Result Publication Board',
      currentRoute: AppRoutes.examinationsPublication,
      actions: [
        ErpButton(
          label: 'Report Cards Portal',
          icon: Icons.picture_as_pdf_outlined,
          isDense: true,
          onPressed: () => context.go(AppRoutes.examinationsReportCards),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: 'Institutional Result Publication Authority',
            subtitle:
                'Publishing results seals gradebooks and exposes digital report cards to parents and student dashboards',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Cohorts Cleared',
                  value: '2 Classes Ready',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Pending In Moderation',
                  value: '1 Class',
                  accentColor: AppColors.warningAmber,
                ),
                MetricItem(
                  label: 'Publish Security Rule',
                  value: 'Immutable Once Signed',
                  accentColor: AppColors.brandNavy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Class Cohorts Awaiting Publication Sign-off',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cohorts.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final c = _cohorts[idx];
                final ready = c['readyForPublish'] as bool;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: ready
                        ? AppColors.successGreen.withValues(alpha: 0.12)
                        : AppColors.warningAmber.withValues(alpha: 0.15),
                    child: Icon(
                      ready ? Icons.verified_outlined : Icons.lock_clock,
                      color: ready
                          ? AppColors.successGreen
                          : AppColors.warningAmber,
                    ),
                  ),
                  title: Text('${c['class']} — ${c['exam']}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Audit Status: ${c['papersEvaluated']} • Sign-off: ${ready ? "Approved by Academic Council" : "Waiting for remaining subject marks"}'),
                  trailing: ErpButton(
                    label: ready ? 'Publish to Parents' : 'Locked',
                    icon: Icons.publish,
                    isDense: true,
                    onPressed: !ready || _isPublishing
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            setState(() => _isPublishing = true);
                            await Future.delayed(
                                const Duration(milliseconds: 600));
                            if (!mounted) return;
                            setState(() => _isPublishing = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                    '${c['class']} results officially published! Notifications dispatched to parent portal.'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          },
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
