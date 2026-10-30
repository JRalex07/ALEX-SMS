import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_routes.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/fee_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/dialogs/payment_modal.dart';
import '../../shared/dialogs/record_payment_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/status_badge.dart';

class FeesResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? invoiceId;

  const FeesResourceScreen({super.key, this.initialTab, this.invoiceId});

  @override
  ConsumerState<FeesResourceScreen> createState() => _FeesResourceScreenState();
}

class _FeesResourceScreenState extends ConsumerState<FeesResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _staffTabs = [
    'Invoices',
    'Fee Structures',
    'Payments Desk',
    'Refunds',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'structures':
          initialIndex = 1;
          break;
        case 'payments':
        case 'receipts':
          initialIndex = 2;
          break;
        case 'refunds':
          initialIndex = 3;
          break;
        case 'reports':
          initialIndex = 4;
          break;
        default:
          initialIndex = 0;
      }
    }
    _tabController = TabController(
      length: _staffTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(covariant FeesResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int targetIndex = 0;
      switch (widget.initialTab) {
        case 'structures':
          targetIndex = 1;
          break;
        case 'payments':
        case 'receipts':
          targetIndex = 2;
          break;
        case 'refunds':
          targetIndex = 3;
          break;
        case 'reports':
          targetIndex = 4;
          break;
        default:
          targetIndex = 0;
      }
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    Widget body;
    if (role == UserRoles.parentGuardian) {
      body = _buildParentFeesView();
    } else if (role == UserRoles.accountant || role == UserRoles.schoolAdmin) {
      body = _buildStaffFeesView(isAccountant: role == UserRoles.accountant);
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
      currentRoute: AppRoutes.fees,
      actions: [
        if (role == UserRoles.accountant || role == UserRoles.schoolAdmin) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.add_chart, size: 16),
            label: const Text('New Fee Structure'),
            onPressed: () => CreateFeeStructureDialog.show(context),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.post_add, size: 16),
            label: const Text('Generate Invoice'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accountantAmber,
              foregroundColor: Colors.black,
            ),
            onPressed: () => CreateInvoiceDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ],
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
              0,
              (sum, inv) => sum + inv.outstandingBalancePaise,
            );
            final paidInvoices = invoices.where((inv) => inv.isPaid).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        title: 'Total Outstanding Balance',
                        value: CurrencyFormatter.formatPaiseToInr(
                          totalDuePaise,
                        ),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (totalDuePaise > 0)
                              ElevatedButton.icon(
                                icon: const Icon(Icons.payment, size: 16),
                                label: const Text('Pay All Online'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.parentBlue,
                                  foregroundColor: Colors.white,
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
                        if (invoices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No invoices issued for this student.',
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: invoices.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppColors.borderLight,
                            ),
                            itemBuilder: (ctx, idx) {
                              final inv = invoices[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.parentBlue.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.receipt,
                                    color: AppColors.parentBlue,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  inv.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  'Invoice #${inv.invoiceId} • Due: ${inv.dueDate != null ? inv.dueDate!.toLocal().toString().split(' ')[0] : 'Term End'}',
                                ),
                                trailing: LayoutBuilder(
                                  builder: (context, _) {
                                    final isMobile = AppBreakpoints.isMobile(
                                      context,
                                    );
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
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          inv.isPaid
                                              ? StatusBadge.success('PAID')
                                              : (inv.status == 'overdue'
                                                    ? StatusBadge.danger('DUE')
                                                    : StatusBadge.warning(
                                                        inv.status
                                                            .toUpperCase(),
                                                      )),
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
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              'Paid: ${CurrencyFormatter.formatPaiseToInr(inv.paidAmountPaise)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        inv.isPaid
                                            ? StatusBadge.success('PAID')
                                            : (inv.status == 'overdue'
                                                  ? StatusBadge.danger(
                                                      'OVERDUE',
                                                    )
                                                  : StatusBadge.warning(
                                                      inv.status.toUpperCase(),
                                                    )),
                                        if (inv.paidAmountPaise > 0) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.print,
                                              size: 18,
                                              color: AppColors.parentBlue,
                                            ),
                                            tooltip: 'Print Official Receipt',
                                            onPressed: () {
                                              final receiptNo =
                                                  'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                                              PrintPreviewDialog.showReceipt(
                                                context,
                                                invoice: inv,
                                                paymentAmountPaise:
                                                    inv.paidAmountPaise,
                                                paymentMethod:
                                                    'ONLINE / BANK TRANSFER',
                                                transactionId: receiptNo,
                                                student: selectedChild,
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.description_outlined,
                                              size: 18,
                                              color: AppColors.brandNavy,
                                            ),
                                            tooltip: 'Print Invoice Preview',
                                            onPressed: () =>
                                                PrintPreviewDialog.showInvoice(
                                                  context,
                                                  invoice: inv,
                                                  student: selectedChild,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.description_outlined,
                                                size: 18,
                                                color: AppColors.brandNavy),
                                            tooltip: 'Print Invoice Preview',
                                            onPressed: () =>
                                                PrintPreviewDialog.showInvoice(
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

  // --- Staff View: Tabbed Ledger, Structures, Payments, Refunds, Reports ---
  Widget _buildStaffFeesView({required bool isAccountant}) {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.accountantAmber,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accountantAmber,
            tabs: _staffTabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        const Divider(height: 1, color: AppColors.borderLight),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load invoice ledger: $err',
                  style: const TextStyle(color: AppColors.dangerRed),
                ),
              ),
            ),
            data: (invoices) {
              final active = invoices.where((inv) => !inv.isArchived).toList();
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildStaffInvoicesTab(active, isAccountant),
                  _buildStaffStructuresTab(),
                  _buildStaffPaymentsTab(active, isAccountant),
                  _buildStaffRefundsTab(),
                  _buildStaffReportsTab(active),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStaffInvoicesTab(
    List<StudentInvoice> invoices,
    bool isAccountant,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFeeMetrics(invoices),
        const SizedBox(height: 20),
        _buildInvoiceRegistry(invoices, allowPayments: isAccountant),
      ],
    );
  }

  Widget _buildStaffStructuresTab() {
    final structuresAsync = ref.watch(
      allFeeStructuresStreamProvider('AY_2026_2027'),
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Approved Fee Structures (AY 2026-2027)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Fee Structure'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accountantAmber,
                foregroundColor: Colors.black,
              ),
              onPressed: () => CreateFeeStructureDialog.show(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        structuresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading structures: $err'),
          data: (structures) {
            return ErpCard(
              title: 'Active Fee Schedules (${structures.length})',
              subtitle: 'Immutable fee heads and term amounts computed in integer paise',
              child: structures.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No fee structures recorded for current academic year.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: structures.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        color: AppColors.borderLight,
                      ),
                      itemBuilder: (ctx, idx) {
                        final s = structures[idx];
                        return ListTile(
                          title: Text(
                            s.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            s.classId != null
                                ? 'Class: ${s.classId} • Year: ${s.academicYearId}'
                                : 'School-Wide General • Year: ${s.academicYearId}',
                          ),
                          trailing: CurrencyDisplay(
                            amountPaise: s.totalAmountPaise,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStaffPaymentsTab(
    List<StudentInvoice> invoices,
    bool isAccountant,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Counter Payment Desk & Gateway Reconciliation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (isAccountant)
              FilledButton.icon(
                icon: const Icon(Icons.point_of_sale, size: 16),
                label: const Text('Record Counter Payment'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accountantEmerald,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _showPaymentDialog(),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Recent Verified Transactions',
          subtitle: 'Authoritative offline receipts and gateway reconciliation records',
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: invoices.where((i) => i.paidAmountPaise > 0).length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.borderLight),
            itemBuilder: (ctx, idx) {
              final paidInvoices = invoices
                  .where((i) => i.paidAmountPaise > 0)
                  .toList();
              final inv = paidInvoices[idx];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.successGreen.withValues(
                    alpha: 0.15,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.successGreen,
                    size: 18,
                  ),
                ),
                title: Text(
                  inv.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('Invoice: ${inv.invoiceId} • Paid Online/Cash'),
                trailing: CurrencyDisplay(
                  amountPaise: inv.paidAmountPaise,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.successGreen,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStaffRefundsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        ErpCard(
          title: 'Fee Adjustments & Refund Approvals',
          subtitle: 'Authorized bursar refund processing with institutional separation of duties',
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No pending refund claims or credit notes requiring action.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffReportsTab(List<StudentInvoice> invoices) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFeeMetrics(invoices),
        const SizedBox(height: 20),
        ErpCard(
          title: 'Institutional Financial Reports',
          subtitle: 'Daily, date-wise, and class-wise collection reconciliation summaries',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.today, color: AppColors.brandNavy),
                title: const Text(
                  'Daily Collection Summary',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Verified receipts recorded for today'),
                trailing: OutlinedButton(
                  onPressed: () =>
                      DataExportService.exportInvoicesCsv(invoices),
                  child: const Text('Export Daily CSV'),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.assessment,
                  color: AppColors.brandNavy,
                ),
                title: const Text(
                  'Outstanding Dues Register',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Ledger of overdue accounts across all cohorts',
                ),
                trailing: OutlinedButton(
                  onPressed: () => DataExportService.exportInvoicesCsv(
                    invoices
                        .where((i) => i.outstandingBalancePaise > 0)
                        .toList(),
                  ),
                  child: const Text('Export Dues CSV'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeMetrics(List<StudentInvoice> invoices) {
    final billed = invoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.totalAmountPaise,
    );
    final paid = invoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.paidAmountPaise,
    );
    final outstanding = invoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.outstandingBalancePaise,
    );
    final overdue = invoices.where((invoice) => invoice.isOverdue).length;
    final collectionRate = billed == 0
        ? '—'
        : '${(paid * 100 / billed).toStringAsFixed(1)}%';
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 280,
          child: StatCard(
            title: 'Total Invoiced',
            value: CurrencyFormatter.formatPaiseToInr(billed),
            subtitle: '${invoices.length} active invoices',
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.parentBlue,
          ),
        ),
        SizedBox(
          width: 280,
          child: StatCard(
            title: 'Payments Recorded',
            value: CurrencyFormatter.formatPaiseToInr(paid),
            subtitle: '$collectionRate of invoiced value',
            icon: Icons.account_balance_wallet_outlined,
            iconColor: AppColors.successGreen,
          ),
        ),
        SizedBox(
          width: 280,
          child: StatCard(
            title: 'Outstanding Balance',
            value: CurrencyFormatter.formatPaiseToInr(outstanding),
            subtitle: '$overdue overdue invoices',
            icon: Icons.pending_actions,
            iconColor: AppColors.dangerRed,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceRegistry(
    List<StudentInvoice> invoices, {
    required bool allowPayments,
  }) {
    return Card(
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
                  allowPayments
                      ? 'Student Fee Ledger & Invoices (${invoices.length})'
                      : 'Institutional Invoice Registry (${invoices.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export Invoices (CSV)'),
                  onPressed: () =>
                      DataExportService.exportInvoicesCsv(invoices),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Balances and statuses are derived from invoice ledger records; payment writes go through the trusted backend workflow.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No active invoices are available.')),
              )
            else
              ...invoices.map((invoice) {
                final statusLabel = invoice.isPaid
                    ? 'PAID'
                    : (invoice.isOverdue
                          ? 'OVERDUE'
                          : invoice.status.toUpperCase());
                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        invoice.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Invoice ${invoice.invoiceId} • Student ${invoice.studentId}\n$statusLabel • Paid ${CurrencyFormatter.formatPaiseToInr(invoice.paidAmountPaise)} • Due ${invoice.dueDate == null ? 'not set' : invoice.dueDate!.toLocal().toString().split(' ').first}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            CurrencyFormatter.formatPaiseToInr(
                              invoice.outstandingBalancePaise,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          if (allowPayments &&
                              invoice.outstandingBalancePaise > 0)
                            IconButton(
                              tooltip: 'Record payment against this invoice',
                              icon: const Icon(
                                Icons.point_of_sale,
                                color: AppColors.accountantEmerald,
                              ),
                              onPressed: () =>
                                  _showPaymentDialog(invoice: invoice),
                            ),
                        ],
                      ),
                    ),
                    if (invoice != invoices.last) const Divider(height: 1),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _showPaymentDialog({StudentInvoice? invoice}) async {
    await RecordPaymentDialog.show(
      context,
      defaultInvoice: invoice,
      onPaymentRecorded:
          ({
            required invoiceId,
            required studentId,
            required payerUserId,
            required amountPaise,
            required paymentMethod,
            required notes,
          }) async {
            await ref
                .read(feeRepositoryProvider)
                .recordOfflinePayment(
                  invoiceId: invoiceId,
                  studentId: studentId,
                  payerUserId: payerUserId,
                  amountPaise: amountPaise,
                  paymentMethod: paymentMethod,
                  notes: notes,
                );
          },
    );
  }
}
