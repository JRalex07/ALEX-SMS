import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Refund Management
/// Route: /fees/refunds
class RefundManagementScreen extends ConsumerStatefulWidget {
  const RefundManagementScreen({super.key});

  @override
  ConsumerState<RefundManagementScreen> createState() =>
      _RefundManagementScreenState();
}

class _RefundManagementScreenState extends ConsumerState<RefundManagementScreen> {
  final List<Map<String, dynamic>> _refunds = [
    {
      'refundId': 'REF_2026_01',
      'studentName': 'Rohan Deshmukh',
      'class': 'Class 10-A',
      'amountPaise': 500000,
      'reason': 'Excess laboratory caution deposit reimbursement',
      'status': 'processed',
      'date': '24 Oct 2026',
    },
    {
      'refundId': 'REF_2026_02',
      'studentName': 'Kunal Singhania',
      'class': 'Class 9-A',
      'amountPaise': 3500000,
      'reason': 'Inter-state transfer fee refund after TC issuance',
      'status': 'under_review',
      'date': '26 Oct 2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Refund Management',
      currentRoute: AppRoutes.feeRefunds,
      actions: [
        ErpButton(
          label: 'Initiate Refund',
          icon: Icons.currency_exchange,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refund initiation modal active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: 'Institutional Refund & Reversal Register',
            subtitle:
                'Audited caution deposits, security funds, and excess payment reversals',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Pending Requests',
                  value: '1 Review',
                  accentColor: AppColors.warningAmber,
                ),
                MetricItem(
                  label: 'Disbursed This AY',
                  value: '₹5,000 Settled',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Approval Dual-Key',
                  value: 'Principal + Bursar',
                  accentColor: AppColors.brandNavy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Refund Claims (${_refunds.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _refunds.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final ref = _refunds[idx];
                final isProcessed = ref['status'] == 'processed';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isProcessed
                        ? AppColors.successGreen.withValues(alpha: 0.12)
                        : AppColors.warningAmber.withValues(alpha: 0.15),
                    child: Icon(
                      isProcessed
                          ? Icons.check_circle_outline
                          : Icons.pending_actions,
                      color: isProcessed
                          ? AppColors.successGreen
                          : AppColors.warningAmber,
                    ),
                  ),
                  title: Text('${ref['studentName']} (${ref['class']})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Claim #${ref['refundId']} • Reason: ${ref['reason']}\n'
                      'Requested Date: ${ref['date']}'),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CurrencyDisplay(
                        amountPaise: ref['amountPaise'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        label: isProcessed ? 'SETTLED' : 'UNDER REVIEW',
                        type: isProcessed
                            ? StatusType.success
                            : StatusType.warning,
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
