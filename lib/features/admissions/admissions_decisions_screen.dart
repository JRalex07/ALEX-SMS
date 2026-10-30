import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Admission Decisions Desk
/// Route: /admissions/decisions
class AdmissionsDecisionsScreen extends ConsumerStatefulWidget {
  const AdmissionsDecisionsScreen({super.key});

  @override
  ConsumerState<AdmissionsDecisionsScreen> createState() =>
      _AdmissionsDecisionsScreenState();
}

class _AdmissionsDecisionsScreenState
    extends ConsumerState<AdmissionsDecisionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    return ResponsiveScaffold(
      title: 'Admission Decisions Desk',
      currentRoute: AppRoutes.admissionsDecisions,
      body: enquiriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.admissionsTeal),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (enquiries) {
          final approved =
              enquiries.where((e) => e['status'] == 'approved').toList();
          final rejected =
              enquiries.where((e) => e['status'] == 'rejected').toList();
          final waitlist =
              enquiries.where((e) => e['status'] == 'waitlist').toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Institutional Admissions Governance Board',
                subtitle:
                    'Formal offer letters, waitlist rankings, and rejection notices',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Approved Offers',
                      value: '${approved.length}',
                      accentColor: AppColors.successGreen,
                    ),
                    MetricItem(
                      label: 'Waitlisted',
                      value: '${waitlist.length}',
                      accentColor: AppColors.warningAmber,
                    ),
                    MetricItem(
                      label: 'Declined/Rejected',
                      value: '${rejected.length}',
                      accentColor: AppColors.dangerRed,
                    ),
                    MetricItem(
                      label: 'Total Decided',
                      value: '${approved.length + waitlist.length + rejected.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Approved Applicants Awaiting Registration (${approved.length})',
                child: approved.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No approved applications at this time.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: approved.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final app = approved[idx];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.successGreen,
                              child: Icon(Icons.check,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(
                              app['applicantName'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                                'Class: ${app['targetClass']} • Guardian: ${app['guardianName']}'),
                            trailing: ErpButton(
                              label: 'Enroll to School',
                              icon: Icons.how_to_reg,
                              isDense: true,
                              onPressed: () =>
                                  context.go(AppRoutes.admissionsEnrollment),
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
