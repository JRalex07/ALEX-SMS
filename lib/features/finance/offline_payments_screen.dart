import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/dialogs/record_payment_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Cash or Offline Payments Counter
/// Route: /fees/payments/offline
class OfflinePaymentsScreen extends ConsumerStatefulWidget {
  const OfflinePaymentsScreen({super.key});

  @override
  ConsumerState<OfflinePaymentsScreen> createState() =>
      _OfflinePaymentsScreenState();
}

class _OfflinePaymentsScreenState extends ConsumerState<OfflinePaymentsScreen> {
  final List<Map<String, dynamic>> _offlineLedger = [
    {
      'voucherId': 'VCH_OFF_101',
      'studentName': 'Rohan Deshmukh',
      'class': 'Class 10-A',
      'amountPaise': 3500000,
      'mode': 'Demand Draft (DD #884129)',
      'bank': 'State Bank of India',
      'date': '26 Oct 2026',
      'cashier': 'Deepak Verma',
    },
    {
      'voucherId': 'VCH_OFF_102',
      'studentName': 'Aarav Mehta',
      'class': 'Class 9-B',
      'amountPaise': 1500000,
      'mode': 'Account Payee Cheque (#112044)',
      'bank': 'HDFC Bank',
      'date': '24 Oct 2026',
      'cashier': 'Deepak Verma',
    },
    {
      'voucherId': 'VCH_OFF_103',
      'studentName': 'Meera Sen',
      'class': 'Class 8-A',
      'amountPaise': 2800000,
      'mode': 'Cash Deposit at Bursar Counter',
      'bank': 'School Treasury',
      'date': '21 Oct 2026',
      'cashier': 'Deepak Verma',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Offline Payments Counter',
      currentRoute: AppRoutes.feePaymentsOffline,
      actions: [
        ErpButton(
          label: 'Collect Offline Payment',
          icon: Icons.point_of_sale,
          isDense: true,
          onPressed: () => RecordPaymentDialog.show(context),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'School Bursar Offline Counter & Bank Instrument Register',
            subtitle:
                'Cash receipts, demand drafts, and cheque collections reconciled with institutional treasury',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Offline Vouchers',
                  value: '${_offlineLedger.length} Recorded',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Vault Balance',
                  value: '₹78,000 Reconciled',
                  accentColor: AppColors.tealSuccess,
                ),
                const MetricItem(
                  label: 'Clearing Status',
                  value: 'All Cheques Realized',
                  accentColor: AppColors.successGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Offline Instrument Collections (${_offlineLedger.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _offlineLedger.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final v = _offlineLedger[idx];

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceMuted,
                    child: Icon(Icons.receipt, color: AppColors.brandNavy),
                  ),
                  title: Text('${v['studentName']} (${v['class']})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Voucher: ${v['voucherId']} • Instrument: ${v['mode']} • Bank: ${v['bank']}\n'
                      'Receipt Date: ${v['date']} • Cashier: ${v['cashier']}'),
                  isThreeLine: true,
                  trailing: Text(
                    '₹${(v['amountPaise'] / 100).toInt()}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
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
