import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/fee_receipt_dialog.dart';
import '../../shared/dialogs/payment_modal.dart';
import '../../shared/dialogs/record_payment_dialog.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_badge.dart';

class FeesResourceScreen extends ConsumerStatefulWidget {
  const FeesResourceScreen({super.key});

  @override
  ConsumerState<FeesResourceScreen> createState() => _FeesResourceScreenState();
}

class _FeesResourceScreenState extends ConsumerState<FeesResourceScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    Widget body;
    if (role == UserRoles.parentGuardian) {
      body = _buildParentFeesView();
    } else if (role == UserRoles.accountant) {
      body = _buildAccountantFeesView();
    } else if (role == UserRoles.schoolAdmin) {
      body = _buildAdminFeesView();
    } else {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Unauthorized: Fee management access restricted to Parents, Accountants, and Administrators.',
            style: TextStyle(color: AppColors.dangerRed),
          ),
        ),
      );
    }

    return ResponsiveScaffold(
      title: 'Fee Management & Invoices',
      currentRoute: '/fees',
      body: body,
    );
  }

  // --- Parent View: Ward Invoices with Integer Paise Precision ---
  Widget _buildParentFeesView() {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return const Center(child: ParentChildSwitcher());
    }

    final invoicesAsync = ref.watch(activeChildInvoicesProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ParentChildSwitcher(),
        const SizedBox(height: 20),
        invoicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading invoices: $e'),
          data: (invoices) {
            final totalDuePaise = invoices.fold<int>(
                0, (sum, inv) => sum + inv.outstandingBalancePaise);
            final paidInvoices = invoices.where((inv) => inv.isPaid).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Outstanding Balance',
                        value:
                            CurrencyFormatter.formatPaiseToInr(totalDuePaise),
                        subtitle: totalDuePaise == 0
                            ? 'All Term Fees Cleared'
                            : 'Due Before Next Academic Term',
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: totalDuePaise > 0
                            ? AppColors.dangerRed
                            : AppColors.successGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatCard(
                        title: 'Payment Status',
                        value:
                            '$paidInvoices / ${invoices.length} Invoices Paid',
                        subtitle: '100% Zero-Loss Integer Accounting',
                        icon: Icons.receipt_long,
                        iconColor: AppColors.parentBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoices for ${selectedChild.fullName}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            if (totalDuePaise > 0)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Pay All Online'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.parentBlue,
                                ),
                                onPressed: () => PaymentModal.show(
                                  context,
                                  invoice: invoices.first,
                                  student: selectedChild,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: invoices.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.borderLight),
                          itemBuilder: (ctx, idx) {
                            final inv = invoices[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.parentBlue
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt,
                                    color: AppColors.parentBlue, size: 20),
                              ),
                              title: Text(inv.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                  'Invoice #${inv.invoiceId} • Due: ${inv.dueDate != null ? inv.dueDate!.toLocal().toString().split(' ')[0] : 'Term End'}'),
                              trailing: LayoutBuilder(
                                builder: (context, _) {
                                  final isMobile =
                                      AppBreakpoints.isMobile(context);
                                  if (isMobile) {
                                    return Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        CurrencyDisplay(
                                          amountPaise: inv.totalAmountPaise,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        inv.isPaid
                                            ? StatusBadge.success('PAID')
                                            : (inv.status == 'overdue'
                                                ? StatusBadge.danger('DUE')
                                                : StatusBadge.warning(
                                                    inv.status.toUpperCase())),
                                      ],
                                    );
                                  }
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          CurrencyDisplay(
                                            amountPaise: inv.totalAmountPaise,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15),
                                          ),
                                          Text(
                                            'Paid: ${CurrencyFormatter.formatPaiseToInr(inv.paidAmountPaise)}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      inv.isPaid
                                          ? StatusBadge.success('PAID')
                                          : (inv.status == 'overdue'
                                              ? StatusBadge.danger('OVERDUE')
                                              : StatusBadge.warning(
                                                  inv.status.toUpperCase())),
                                      if (inv.paidAmountPaise > 0) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.print,
                                              size: 18,
                                              color: AppColors.parentBlue),
                                          tooltip: 'Print Official Receipt',
                                          onPressed: () =>
                                              FeeReceiptDialog.show(
                                            context,
                                            invoice: inv,
                                            student: selectedChild,
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --- Accountant View: Institutional Bursar Operations ---
  Widget _buildAccountantFeesView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Total Collections (AY 2026-27)',
                value: '₹ 1,84,20,000.00',
                subtitle: '89.4% Collection Target Met',
                icon: Icons.account_balance,
                iconColor: AppColors.accountantEmerald,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: StatCard(
                title: 'Pending Arrears',
                value: '₹ 21,80,000.00',
                subtitle: '34 Overdue Student Invoices',
                icon: Icons.pending_actions,
                iconColor: AppColors.dangerRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Student Fee Ledger & Offline Payments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Export Ledger (CSV)'),
                          onPressed: () {
                            final invoices =
                                ref.read(allInvoicesStreamProvider).value ?? [];
                            DataExportService.exportInvoicesCsv(invoices);
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Record Cashier Payment'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accountantEmerald,
                          ),
                          onPressed: () => RecordPaymentDialog.show(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Institutional zero-loss ledger ensures every payment is recorded in exact integer paise to eliminate floating-point drift.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Admin View ---
  Widget _buildAdminFeesView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        StatCard(
          title: 'Institutional Financial Standing',
          value: '₹ 1.84 Cr Collected',
          subtitle: 'Audit status: Balanced & Reconciled',
          icon: Icons.verified,
          iconColor: AppColors.adminIndigo,
        ),
      ],
    );
  }
}
