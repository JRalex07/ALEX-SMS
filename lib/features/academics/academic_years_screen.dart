import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Academic Years Configuration
/// Route: /academics/years
class AcademicYearsScreen extends ConsumerStatefulWidget {
  const AcademicYearsScreen({super.key});

  @override
  ConsumerState<AcademicYearsScreen> createState() =>
      _AcademicYearsScreenState();
}

class _AcademicYearsScreenState extends ConsumerState<AcademicYearsScreen> {
  final List<Map<String, dynamic>> _years = [
    {
      'id': 'AY_2026_2027',
      'title': 'Academic Year 2026 – 2027',
      'startDate': '01 Jun 2026',
      'endDate': '30 Apr 2027',
      'isCurrent': true,
      'termsCount': 3,
      'status': 'active',
    },
    {
      'id': 'AY_2025_2026',
      'title': 'Academic Year 2025 – 2026',
      'startDate': '01 Jun 2025',
      'endDate': '30 Apr 2026',
      'isCurrent': false,
      'termsCount': 3,
      'status': 'closed',
    },
    {
      'id': 'AY_2027_2028',
      'title': 'Academic Year 2027 – 2028',
      'startDate': '01 Jun 2027',
      'endDate': '30 Apr 2028',
      'isCurrent': false,
      'termsCount': 3,
      'status': 'upcoming',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Academic Years',
      currentRoute: AppRoutes.academicsYears,
      actions: [
        ErpButton(
          label: 'Create Academic Year',
          icon: Icons.add,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Academic Year configuration dialog initiated.'),
              ),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: 'Institutional Academic Calendar Cycles',
            subtitle:
                'Active and archival academic terms for curriculum and gradebook synchronization',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Current Academic Year',
                  value: '2026 – 2027',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Configured Terms',
                  value: '3 Terms',
                  accentColor: AppColors.brandNavy,
                ),
                MetricItem(
                  label: 'Active Cycle Status',
                  value: 'Term 1 Ongoing',
                  accentColor: AppColors.infoBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Academic Year Registry (${_years.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _years.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final yr = _years[idx];
                final isCurrent = yr['isCurrent'] as bool;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent
                        ? AppColors.successGreen.withValues(alpha: 0.12)
                        : AppColors.surfaceMuted,
                    child: Icon(
                      Icons.calendar_today,
                      color: isCurrent
                          ? AppColors.successGreen
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(yr['title'],
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (isCurrent) ...[
                        const SizedBox(width: 8),
                        const StatusBadge(
                            label: 'CURRENT', type: StatusType.success),
                      ],
                    ],
                  ),
                  subtitle: Text(
                      'Duration: ${yr['startDate']} to ${yr['endDate']} • ${yr['termsCount']} Terms Configured'),
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Inspecting terms for ${yr['title']}')),
                      );
                    },
                    child: const Text('Manage Terms'),
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
