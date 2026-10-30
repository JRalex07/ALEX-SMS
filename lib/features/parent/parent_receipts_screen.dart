import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent Fee Receipts Portal
/// Route: /parent/receipts
class ParentReceiptsScreen extends ConsumerWidget {
  const ParentReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return ResponsiveScaffold(
      title: 'Fee Receipts',
      currentRoute: AppRoutes.parentReceipts,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const ErpCard(
              title: 'No Student Profile Linked',
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Please select a linked child from the switcher above to view verified fee receipts.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
            )
          else
            invoicesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(color: AppColors.brandNavy),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading receipts: $err',
                      style: const TextStyle(color: AppColors.dangerRed)),
                ),
              ),
              data: (invoices) {
                final receipts = invoices
                    .where((inv) =>
                        inv.studentId == selectedChild.studentId &&
                        inv.paidAmountPaise > 0)
                    .toList();

                return ErpCard(
                  title: 'Verified Receipts — ${selectedChild.fullName}',
                  subtitle:
                      'Official PDF receipts for 80C tax deduction and accounting records',
                  child: receipts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 48, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text(
                                  'No Payment Receipts Recorded',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'When fee payments are confirmed, verified receipts will be archived here.',
                                  style:
                                      TextStyle(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: receipts.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.borderLight),
                          itemBuilder: (ctx, idx) {
                            final inv = receipts[idx];
                            final paidDate = inv.dueDate != null
                                ? '${inv.dueDate!.day}/${inv.dueDate!.month}/${inv.dueDate!.year}'
                                : 'AY 2026-27';

                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt,
                                    color: AppColors.successGreen, size: 22),
                              ),
                              title: Text(inv.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                'Receipt #${inv.invoiceId.replaceAll("INV", "RCP")} • Paid: ₹${(inv.paidAmountPaise / 100).toInt()} • Date: $paidDate',
                                style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12),
                              ),
                              trailing: ElevatedButton.icon(
                                icon:
                                    const Icon(Icons.print_outlined, size: 14),
                                label: const Text('Download PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandNavy,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                ),
                                onPressed: () {
                                  final receiptNo =
                                      'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                                  PrintPreviewDialog.showReceipt(
                                    context,
                                    invoice: inv,
                                    paymentAmountPaise: inv.paidAmountPaise,
                                    paymentMethod: 'ONLINE / BANK TRANSFER',
                                    transactionId: receiptNo,
                                    student: selectedChild,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                );
              },
            ),
        ],
      ),
    );
  }
}
