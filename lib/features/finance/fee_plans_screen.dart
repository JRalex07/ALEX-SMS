import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Class-wise Fee Plans
/// Route: /fees/plans
class FeePlansScreen extends ConsumerStatefulWidget {
  const FeePlansScreen({super.key});

  @override
  ConsumerState<FeePlansScreen> createState() => _FeePlansScreenState();
}

class _FeePlansScreenState extends ConsumerState<FeePlansScreen> {
  final List<Map<String, dynamic>> _plans = [
    {
      'class': 'Class 10 (Secondary High School)',
      'tuitionPerTermPaise': 3500000,
      'labFeePaise': 500000,
      'examinationFeePaise': 250000,
      'annualTotalPaise': 12750000,
      'installments': 3,
    },
    {
      'class': 'Class 9 (High School Junior)',
      'tuitionPerTermPaise': 3200000,
      'labFeePaise': 450000,
      'examinationFeePaise': 200000,
      'annualTotalPaise': 11550000,
      'installments': 3,
    },
    {
      'class': 'Class 8 (Middle School Senior)',
      'tuitionPerTermPaise': 2800000,
      'labFeePaise': 350000,
      'examinationFeePaise': 150000,
      'annualTotalPaise': 9900000,
      'installments': 3,
    },
    {
      'class': 'Class 7 (Middle School)',
      'tuitionPerTermPaise': 2600000,
      'labFeePaise': 300000,
      'examinationFeePaise': 150000,
      'annualTotalPaise': 9150000,
      'installments': 3,
    },
    {
      'class': 'Class 6 (Middle School Entry)',
      'tuitionPerTermPaise': 2400000,
      'labFeePaise': 250000,
      'examinationFeePaise': 150000,
      'annualTotalPaise': 8400000,
      'installments': 3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Class-wise Fee Plans',
      currentRoute: AppRoutes.feePlans,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Standardized Grade-Tier Fee Schedules (AY 2026-2027)',
            subtitle:
                'Breakdown of annual tuition, computer/science laboratory, and board examination heads',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Configured Grades',
                  value: '${_plans.length} Standards',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Billing Model',
                  value: '3 Term Installments',
                  accentColor: AppColors.tealSuccess,
                ),
                const MetricItem(
                  label: 'Concessions',
                  value: 'Sibling & Merit Enabled',
                  accentColor: AppColors.warningAmber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Grade Fee Schedules (${_plans.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _plans.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final plan = _plans[idx];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandNavy.withValues(alpha: 0.1),
                    child: Text(
                      '${idx + 1}',
                      style: const TextStyle(
                          color: AppColors.brandNavy,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(plan['class'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    'Term Tuition: ₹${(plan['tuitionPerTermPaise'] / 100).toInt()} • Lab: ₹${(plan['labFeePaise'] / 100).toInt()} • Exam: ₹${(plan['examinationFeePaise'] / 100).toInt()}\n'
                    'Schedule: ${plan['installments']} equal installments per session',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CurrencyDisplay(
                        amountPaise: plan['annualTotalPaise'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      const Text('Annual Total',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
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
