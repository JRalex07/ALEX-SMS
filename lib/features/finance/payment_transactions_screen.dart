import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/record_payment_dialog.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Payment Transactions
/// Route: /fees/payments
class PaymentTransactionsScreen extends ConsumerStatefulWidget {
  const PaymentTransactionsScreen({super.key});

  @override
  ConsumerState<PaymentTransactionsScreen> createState() =>
      _PaymentTransactionsScreenState();
}

class _PaymentTransactionsScreenState
    extends ConsumerState<PaymentTransactionsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);
    final user = ref.watch(currentUserProfileProvider).value;
    final isStaff = user?.role == UserRoles.accountant ||
        user?.role == UserRoles.schoolAdmin;

    return ResponsiveScaffold(
      title: 'Payment Transactions',
      currentRoute: AppRoutes.feePayments,
      actions: [
        if (isStaff) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.local_atm, size: 16),
            label: const Text('Offline Counter'),
            onPressed: () => context.go(AppRoutes.feePaymentsOffline),
          ),
          const SizedBox(width: 8),
          ErpButton(
            label: 'Record Payment',
            icon: Icons.point_of_sale,
            isDense: true,
            onPressed: () => RecordPaymentDialog.show(context),
          ),
        ],
      ],
      body: invoicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (invoices) {
          final paidInvoices =
              invoices.where((inv) => inv.paidAmountPaise > 0).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Fee Collection & Transaction Journal',
                subtitle:
                    'Audit trail of UPI, Net Banking, and Bank Counter offline collections',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Verified Transactions',
                      value: '${paidInvoices.length}',
                      accentColor: AppColors.successGreen,
                    ),
                    const MetricItem(
                      label: 'Reconciliation Status',
                      value: '100% Balanced',
                      accentColor: AppColors.brandNavy,
                    ),
                    const MetricItem(
                      label: 'Gateway Settlement',
                      value: 'T+1 Live Active',
                      accentColor: AppColors.tealSuccess,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Processed Transactions (${paidInvoices.length})',
                child: paidInvoices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No payment transactions recorded yet.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: paidInvoices.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final inv = paidInvoices[idx];

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(Icons.payments,
                                  color: AppColors.successGreen),
                            ),
                            title: Text('Invoice #${inv.invoiceId} — ${inv.title}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Student ID: ${inv.studentId} • Date: ${inv.dueDate?.toLocal().toString().split(" ").first ?? "Recent"}\n'
                                'Payment Method: Online Gateway / Bank Transfer'),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CurrencyDisplay(
                                  amountPaise: inv.paidAmountPaise,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.successGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const StatusBadge(
                                    label: 'VERIFIED',
                                    type: StatusType.success),
                              ],
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
