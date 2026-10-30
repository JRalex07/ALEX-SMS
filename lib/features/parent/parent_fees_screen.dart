import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/payment_modal.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Parent Fees Summary & Statements
/// Route: /parent/fees
class ParentFeesScreen extends ConsumerWidget {
  const ParentFeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return ResponsiveScaffold(
      title: "Child's Fee Statement",
      currentRoute: AppRoutes.parentFees,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.print_outlined, size: 16),
          label: const Text('Receipts'),
          onPressed: () => context.go(AppRoutes.parentReceipts),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const Center(child: Text('No student selected.'))
          else
            invoicesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.parentBlue)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (invoices) {
                final childInvoices = invoices
                    .where((i) => i.studentId == selectedChild.studentId)
                    .toList();

                final totalBilled = childInvoices.fold<int>(
                    0, (sum, i) => sum + i.totalAmountPaise);
                final totalPaid = childInvoices.fold<int>(
                    0, (sum, i) => sum + i.paidAmountPaise);
                final totalDue = totalBilled - totalPaid;

                return Column(
                  children: [
                    ErpCard(
                      title: 'Fee Summary — ${selectedChild.fullName}',
                      subtitle:
                          'Zero-loss integer ledger for AY 2026-2027 tuition & facilities',
                      child: ErpMetricStrip(
                        metrics: [
                          MetricItem(
                            label: 'Total Outstanding',
                            value: '₹${(totalDue / 100).toInt()}',
                            accentColor: totalDue > 0
                                ? AppColors.dangerRed
                                : AppColors.successGreen,
                          ),
                          MetricItem(
                            label: 'Total Paid to Date',
                            value: '₹${(totalPaid / 100).toInt()}',
                            accentColor: AppColors.successGreen,
                          ),
                          MetricItem(
                            label: 'Total Annual Billing',
                            value: '₹${(totalBilled / 100).toInt()}',
                            accentColor: AppColors.brandNavy,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ErpCard(
                      title: 'Issued Invoices (${childInvoices.length})',
                      child: childInvoices.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No fee invoices issued.',
                                    style: TextStyle(color: AppColors.textMuted)),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: childInvoices.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: AppColors.borderLight),
                              itemBuilder: (ctx, idx) {
                                final inv = childInvoices[idx];

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: inv.isPaid
                                        ? AppColors.successGreen.withValues(alpha: 0.12)
                                        : AppColors.warningAmber.withValues(alpha: 0.15),
                                    child: Icon(
                                      inv.isPaid
                                          ? Icons.check
                                          : Icons.receipt_long,
                                      color: inv.isPaid
                                          ? AppColors.successGreen
                                          : AppColors.warningAmber,
                                    ),
                                  ),
                                  title: Text(inv.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  subtitle: Text(
                                      'Invoice #${inv.invoiceId} • Due: ${inv.dueDate?.toLocal().toString().split(" ").first ?? "Term End"}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CurrencyDisplay(
                                        amountPaise: inv.totalAmountPaise,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16),
                                      ),
                                      const SizedBox(width: 8),
                                      StatusBadge(
                                        label: inv.status.toUpperCase(),
                                        type: inv.isPaid
                                            ? StatusType.success
                                            : StatusType.warning,
                                      ),
                                      const SizedBox(width: 8),
                                      if (!inv.isPaid)
                                        FilledButton(
                                          onPressed: () => PaymentModal.show(
                                            context,
                                            invoice: inv,
                                            student: selectedChild,
                                          ),
                                          child: const Text('Pay Online'),
                                        ),
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
        ],
      ),
    );
  }
}
