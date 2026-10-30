import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Admission Reports & Intake Funnel
/// Route: /admissions/reports
class AdmissionsReportsScreen extends ConsumerStatefulWidget {
  const AdmissionsReportsScreen({super.key});

  @override
  ConsumerState<AdmissionsReportsScreen> createState() =>
      _AdmissionsReportsScreenState();
}

class _AdmissionsReportsScreenState
    extends ConsumerState<AdmissionsReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    return ResponsiveScaffold(
      title: 'Admission Reports',
      currentRoute: AppRoutes.admissionsReports,
      body: enquiriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.admissionsTeal),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (enquiries) {
          final total = enquiries.length;
          final applied = enquiries
              .where((e) =>
                  e['status'] == 'applied' || e['status'] == 'under_review')
              .length;
          final verified = enquiries
              .where((e) => e['status'] == 'documents_verified')
              .length;
          final approved =
              enquiries.where((e) => e['status'] == 'approved').length;
          final enrolled =
              enquiries.where((e) => e['status'] == 'enrolled').length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Admissions Funnel Conversion Analysis (AY 2026-2027)',
                subtitle:
                    'Step-by-step conversion analytics from initial enquiry to active enrolled pupil',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Total Inquiries',
                      value: '$total',
                      accentColor: AppColors.admissionsTeal,
                    ),
                    MetricItem(
                      label: 'In Review',
                      value: '$applied',
                      accentColor: AppColors.warningAmber,
                    ),
                    MetricItem(
                      label: 'Verified',
                      value: '$verified',
                      accentColor: AppColors.infoBlue,
                    ),
                    MetricItem(
                      label: 'Approved Offers',
                      value: '$approved',
                      accentColor: AppColors.brandNavy,
                    ),
                    MetricItem(
                      label: 'Fully Enrolled',
                      value: '$enrolled',
                      accentColor: AppColors.successGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Class-Wise Intake Breakdown',
                subtitle: 'Demand and capacity indicators across grade standards',
                child: Column(
                  children: [
                    for (final cls in ['10', '9', '8', '7', '6']) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text('Class $cls',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: (enquiries
                                            .where((e) =>
                                                (e['targetClass'] ?? '')
                                                    .toString() ==
                                                cls)
                                            .length /
                                        (total > 0 ? total : 1))
                                    .clamp(0.0, 1.0),
                                backgroundColor: AppColors.surfaceBackground,
                                color: AppColors.admissionsTeal,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${enquiries.where((e) => (e['targetClass'] ?? '').toString() == cls).length} applicants',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

