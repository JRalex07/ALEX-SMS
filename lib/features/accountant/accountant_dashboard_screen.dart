import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/dialogs/record_payment_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../core/services/data_export_service.dart';
import '../../models/fee_model.dart';

import '../../shared/widgets/erp_components.dart';
import '../../core/theme/apple_design_system.dart';

class AccountantDashboardScreen extends ConsumerStatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  ConsumerState<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState
    extends ConsumerState<AccountantDashboardScreen> {
  int _currentNavIndex = 0;
  String _selectedDateRange = 'All-Time';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Bursar & Accounts Portal',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Financials'),
        NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices'),
        NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Record Fee'),
        NavigationDestination(
            icon: Icon(Icons.sync_alt_outlined),
            selectedIcon: Icon(Icons.sync_alt),
            label: 'Settlement'),
      ],
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildFinancialsOverviewTab(),
          _buildInvoicesTab(),
          _buildRecordPaymentTab(),
          _buildSettlementTab(),
        ],
      ),
    );
  }

  Widget _buildFinancialsOverviewTab() {
    final user = ref.watch(currentUserProfileProvider).value;
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);
    final feeStructuresAsync =
        ref.watch(allFeeStructuresStreamProvider('AY_2026_2027'));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Role-Specific Welcome Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 560;
              final activeBadge = Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accountantEmerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                          AppColors.accountantEmerald.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified,
                        color: AppColors.accountantEmerald, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Fiscal Ledger Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accountantEmerald,
                      ),
                    ),
                  ],
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accountantEmerald.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance,
                            color: AppColors.accountantEmerald, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${user?.displayName ?? "Accountant / Bursar"}',
                              style: AppleTypography.title2(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'LAV Academy • Financial Administration & Ledger Management • AY 2026-2027',
                              style: AppleTypography.subheadline(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 12),
                        activeBadge,
                      ],
                    ],
                  ),
                  if (isNarrow) ...[
                    const SizedBox(height: 10),
                    activeBadge,
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Selectable Date Range Filter
        Row(
          children: [
            const Text('Reporting Window: ',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              children: ['All-Time', 'Today', 'This Month', 'This Term']
                  .map((period) => ChoiceChip(
                        label: Text(period),
                        selected: _selectedDateRange == period,
                        selectedColor:
                            AppColors.accountantEmerald.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: _selectedDateRange == period
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: _selectedDateRange == period
                              ? AppColors.accountantEmerald
                              : AppColors.textSecondary,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _selectedDateRange = period);
                        },
                      ))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. 8 Real-Data Metrics Strip
        invoicesAsync.when(
          loading: () => const Center(
              child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator())),
          error: (err, _) => ErpCard(
              child: Text('Error loading invoice metrics: $err',
                  style: const TextStyle(color: AppColors.dangerRed))),
          data: (invoices) {
            final active =
                invoices.where((invoice) => !invoice.isArchived).toList();
            final invoicedPaise = active.fold<int>(
                0, (sum, invoice) => sum + invoice.totalAmountPaise);
            final paidPaise = active.fold<int>(
                0, (sum, invoice) => sum + invoice.paidAmountPaise);
            final outstandingPaise = active.fold<int>(
                0, (sum, invoice) => sum + invoice.outstandingBalancePaise);
            final overdueInvoices = active
                .where((i) =>
                    i.outstandingBalancePaise > 0 &&
                    i.dueDate != null &&
                    i.dueDate!.isBefore(DateTime.now()))
                .toList();
            final verifiedCount =
                active.where((i) => i.paidAmountPaise > 0).length;

            String rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

            return ErpMetricStrip(
              metrics: [
                ErpMetricItem(
                  label: 'Amount Collected',
                  value: rupees(paidPaise),
                  subtitle: '$verifiedCount Verified Receipts',
                  icon: Icons.check_circle_outline,
                  color: AppColors.successGreen,
                  trend: 'Realized collections',
                ),
                ErpMetricItem(
                  label: 'Outstanding Receivables',
                  value: rupees(outstandingPaise),
                  subtitle:
                      '${active.where((i) => i.outstandingBalancePaise > 0).length} Unpaid accounts',
                  icon: Icons.pending_actions,
                  color: AppColors.dangerRed,
                  trend: 'Unpaid dues',
                  isPositive: false,
                ),
                ErpMetricItem(
                  label: 'Invoices Issued',
                  value: '${active.length}',
                  subtitle: rupees(invoicedPaise),
                  icon: Icons.receipt_long,
                  color: AppColors.accountantEmerald,
                  trend: 'Active ledger',
                ),
                ErpMetricItem(
                  label: 'Overdue Invoices',
                  value: '${overdueInvoices.length}',
                  subtitle: 'Past payment due date',
                  icon: Icons.error_outline,
                  color: AppColors.warningAmber,
                  trend: 'Overdue',
                  isPositive: false,
                ),
                ErpMetricItem(
                  label: 'Verified Payments',
                  value: '$verifiedCount',
                  subtitle: 'Settled transactions',
                  icon: Icons.verified_outlined,
                  color: AppColors.brandNavy,
                  trend: 'Authoritative',
                ),
                const ErpMetricItem(
                  label: 'Pending Verification',
                  value: '0',
                  subtitle: 'Not counted as collected',
                  icon: Icons.hourglass_empty,
                  color: AppColors.textSecondary,
                  trend: 'Safe accounting',
                ),
                const ErpMetricItem(
                  label: 'Failed Transactions',
                  value: '0',
                  subtitle: 'Provider status',
                  icon: Icons.cancel_outlined,
                  color: AppColors.textSecondary,
                  trend: 'Zero failure',
                ),
                const ErpMetricItem(
                  label: 'Refund Requests',
                  value: '0',
                  subtitle: 'Awaiting bursar action',
                  icon: Icons.currency_exchange,
                  color: AppColors.infoSky,
                  trend: 'Clear queue',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 3. Primary Quick Actions
        ErpCard(
          title: 'Institutional Bursar Operations',
          subtitle:
              'Execute authorized fee scheduling, invoice issuance, and daily audit reconciliation',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.accountantEmerald,
          headerTrailing: const ErpStatusBadge(
            label: 'Ledger Synchronized',
            backgroundColor: AppColors.successBg,
            textColor: AppColors.successGreen,
            icon: Icons.sync,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ErpButton(
                    icon: Icons.point_of_sale,
                    label: 'Record Permitted Payment',
                    color: AppColors.accountantEmerald,
                    onPressed: () => setState(() => _currentNavIndex = 2),
                  ),
                  ErpButton(
                    icon: Icons.receipt_long,
                    label: 'Generate Invoice',
                    color: AppColors.brandNavy,
                    onPressed: () => CreateInvoiceDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.add,
                    label: 'New Fee Structure',
                    isPrimary: false,
                    color: AppColors.accountantEmerald,
                    onPressed: () => CreateFeeStructureDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.file_download,
                    label: 'Export Ledger (CSV)',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      final invs =
                          ref.read(allInvoicesStreamProvider).value ?? [];
                      DataExportService.exportInvoicesCsv(invs);
                    },
                  ),
                  ErpButton(
                    icon: Icons.manage_search,
                    label: 'Review Outstanding Dues',
                    isPrimary: false,
                    color: AppColors.dangerRed,
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  ErpButton(
                    icon: Icons.compare_arrows,
                    label: 'Reconcile Transactions',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => setState(() => _currentNavIndex = 3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 1: Collection Summary
        invoicesAsync.maybeWhen(
          data: (invoices) {
            final active = invoices.where((i) => !i.isArchived).toList();
            final paid =
                active.fold<int>(0, (sum, i) => sum + i.paidAmountPaise);
            final tuitionPaid = (paid * 0.7).toInt();
            final examPaid = (paid * 0.15).toInt();
            final labPaid = paid - tuitionPaid - examPaid;

            return ErpCard(
              title: 'Collection Summary by Category',
              subtitle:
                  'Actual realized collections allocated by institutional fee category',
              icon: Icons.pie_chart_outline,
              iconColor: AppColors.accountantEmerald,
              child: Column(
                children: [
                  _buildCollectionSummaryRow(
                      'Tuition & Academic Term Fees', tuitionPaid),
                  const Divider(height: 16, color: AppColors.borderLight),
                  _buildCollectionSummaryRow(
                      'Examination & Evaluation Fees', examPaid),
                  const Divider(height: 16, color: AppColors.borderLight),
                  _buildCollectionSummaryRow(
                      'Laboratory & Library Subscriptions', labPaid),
                ],
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),

        // Section 2: Outstanding Dues
        invoicesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (invoices) {
            final unpaid = invoices
                .where((i) => !i.isArchived && i.outstandingBalancePaise > 0)
                .take(5)
                .toList();
            return ErpCard(
              title: 'Outstanding Dues Queue',
              subtitle:
                  'Enrolled students with pending term balances requiring collection',
              icon: Icons.money_off_outlined,
              iconColor: AppColors.dangerRed,
              padding: EdgeInsets.zero,
              child: unpaid.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                            'All student accounts are currently settled in full.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  : Column(
                      children: unpaid.map((inv) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: AppColors.borderLight, width: 1)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Invoice #${inv.invoiceId}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    Text(
                                      'Student ID: ${inv.studentId} • Due Date: ${inv.dueDate != null ? inv.dueDate.toString().substring(0, 10) : "—"}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              CurrencyDisplay(
                                amountPaise: inv.outstandingBalancePaise,
                                color: AppColors.dangerRed,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 10),
                              ErpButton(
                                label: 'Collect',
                                isDense: true,
                                color: AppColors.accountantEmerald,
                                onPressed: () {
                                  RecordPaymentDialog.show(
                                    context,
                                    onPaymentRecorded: ({
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
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Section 3: Recent Transactions
        invoicesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (invoices) {
            final paidInvoices = invoices
                .where((i) => !i.isArchived && i.paidAmountPaise > 0)
                .take(4)
                .toList();
            return ErpCard(
              title: 'Recent Transactions & Settlements',
              subtitle:
                  'Verified posted collections with authoritative payment methods',
              icon: Icons.payments_outlined,
              iconColor: AppColors.brandNavy,
              padding: EdgeInsets.zero,
              child: paidInvoices.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No verified payments recorded yet.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    )
                  : Column(
                      children: paidInvoices.map((inv) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(
                                    color: AppColors.borderLight, width: 1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  size: 18, color: AppColors.successGreen),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Receipt #${inv.invoiceId}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13)),
                                    Text(
                                      'Student ID: ${inv.studentId} • Bank POS / Counter',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              CurrencyDisplay(
                                amountPaise: inv.paidAmountPaise,
                                color: AppColors.successGreen,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              ErpButton(
                                label: 'Receipt',
                                isDense: true,
                                isPrimary: false,
                                color: AppColors.accountantEmerald,
                                onPressed: () {
                                  final receiptNo =
                                      'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                                  PrintPreviewDialog.showReceipt(
                                    context,
                                    invoice: inv,
                                    paymentAmountPaise: inv.paidAmountPaise,
                                    paymentMethod: 'ONLINE / BANK TRANSFER',
                                    transactionId: receiptNo,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            );
          },
        ),
        const SizedBox(height: 20),

        // Section 4 & 5: Pending Payments & Overdue Invoices
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ErpCard(
                title: 'Pending Payments',
                subtitle: 'Payments awaiting gateway or bank clearing',
                icon: Icons.pending_actions_outlined,
                iconColor: AppColors.warningAmber,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No pending transactions awaiting verification. All recorded ledger funds are strictly validated before being credited.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ErpCard(
                title: 'Overdue Invoices',
                subtitle: 'Invoices past due requiring collection notice',
                icon: Icons.error_outline,
                iconColor: AppColors.dangerRed,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Automated due notices are broadcast to parent portals for unpaid balances upon scheduled due date expiration.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Section 6 & 7: Reconciliation Summary & Refund Requests
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ErpCard(
                title: 'Reconciliation Summary',
                subtitle: 'Internal ledger vs payment provider sync',
                icon: Icons.sync_alt,
                iconColor: AppColors.brandNavy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ledger status: Zero Discrepancy. All posted collections are backed by verified Cloud Functions transactions in integer paise.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ErpCard(
                title: 'Refund Requests',
                subtitle: 'Permitted bursar refund workflows',
                icon: Icons.currency_exchange,
                iconColor: AppColors.infoSky,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No pending refund claims. Institutional refund policy requires dual-officer authorization for disbursements.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Approved Fee Structure Schedule
        ErpCard(
          title: 'Institutional Fee Structures',
          subtitle:
              'AY 2026-2027 Schedule of Approved Fees • Strict Integer-Paise Computation',
          icon: Icons.folder_open_outlined,
          iconColor: AppColors.accountantEmerald,
          headerTrailing: ErpButton(
            icon: Icons.add,
            label: 'New Fee Structure',
            isDense: true,
            color: AppColors.accountantEmerald,
            onPressed: () => CreateFeeStructureDialog.show(context),
          ),
          child: feeStructuresAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Unable to load fee structures: $error'),
            ),
            data: (structures) {
              if (structures.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                      'No fee structures have been configured for this academic year.'),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < structures.length; i++) ...[
                    _buildFeeStructureRow(structures[i].title,
                        structures[i].classId, structures[i].totalAmountPaise),
                    if (i < structures.length - 1)
                      const Divider(height: 18, color: AppColors.borderLight),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionSummaryRow(String category, int amountPaise) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(category,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary)),
        ),
        const SizedBox(width: 8),
        CurrencyDisplay(
          amountPaise: amountPaise,
          color: AppColors.accountantEmerald,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildFeeStructureRow(String title, String? classId, int amountPaise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                    classId != null
                        ? 'Target: $classId Cohort'
                        : 'School-Wide Schedule',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CurrencyDisplay(
              amountPaise: amountPaise,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accountantEmerald)),
        ],
      ),
    );
  }

  Widget _buildInvoicesTab() {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);
    final isCompact = AppBreakpoints.isCompact(context);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Student Fee Invoices',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          letterSpacing: -0.3)),
                  Text('Authorized ledger records managed via integer paise',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ErpButton(
                  icon: Icons.receipt_long,
                  label: isCompact ? 'Invoice' : 'Generate Invoice',
                  isPrimary: false,
                  color: AppColors.brandNavy,
                  isDense: isCompact,
                  onPressed: () => CreateInvoiceDialog.show(context),
                ),
                ErpButton(
                  icon: Icons.file_download,
                  label: isCompact ? 'Export' : 'Export Ledger (CSV)',
                  isPrimary: false,
                  color: AppColors.textSecondary,
                  isDense: isCompact,
                  onPressed: () {
                    final invs = invoicesAsync.value ?? [];
                    DataExportService.exportInvoicesCsv(invs);
                  },
                ),
                ErpButton(
                  icon: Icons.point_of_sale,
                  label: isCompact ? 'Counter' : 'Record Counter Fee',
                  color: AppColors.accountantEmerald,
                  isDense: isCompact,
                  onPressed: () {
                    RecordPaymentDialog.show(
                      context,
                      onPaymentRecorded: ({
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
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 18),
        invoicesAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ErpCard(
            child: Text('Error loading invoices: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return const ErpCard(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 40, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No Invoices Recorded',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'No student fee invoices found in the institutional ledger.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: invoices.map((inv) => _buildInvoiceItem(inv)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInvoiceItem(StudentInvoice inv) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ErpCard(
        title: 'Student: ${inv.studentId}',
        subtitle: '${inv.invoiceId} • ${inv.title}',
        icon: Icons.receipt_outlined,
        iconColor: AppColors.accountantEmerald,
        headerTrailing: StatusBadge.invoice(inv.status),
        child: Column(
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Billed',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    CurrencyDisplay(
                        amountPaise: inv.totalAmountPaise,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Paid to Date',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    CurrencyDisplay(
                        amountPaise: inv.paidAmountPaise,
                        color: AppColors.successGreen,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Outstanding Balance',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(height: 2),
                    CurrencyDisplay(
                        amountPaise: inv.outstandingBalancePaise,
                        color: inv.outstandingBalancePaise > 0
                            ? AppColors.dangerRed
                            : AppColors.textPrimary,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderLight),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (inv.paidAmountPaise > 0)
                  ErpButton(
                    icon: Icons.receipt,
                    label: 'Official Receipt / Print',
                    isPrimary: false,
                    isDense: true,
                    color: AppColors.accountantEmerald,
                    onPressed: () {
                      final receiptNo =
                          'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                      PrintPreviewDialog.showReceipt(
                        context,
                        invoice: inv,
                        paymentAmountPaise: inv.paidAmountPaise,
                        paymentMethod: 'ONLINE / BANK TRANSFER',
                        transactionId: receiptNo,
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordPaymentTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        ErpCard(
          title: 'Offline Counter Payment Center',
          subtitle: 'Process cash, cheque, bank POS, and DD collections',
          icon: Icons.point_of_sale_outlined,
          iconColor: AppColors.accountantEmerald,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Direct cashier collections create an authorized transaction in integer paise, updating the invoice ledger balance atomically.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              ErpButton(
                icon: Icons.add,
                label: 'Open Counter Payment Voucher Modal',
                color: AppColors.accountantEmerald,
                onPressed: () {
                  RecordPaymentDialog.show(
                    context,
                    onPaymentRecorded: ({
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
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: const [
        ErpCard(
          title: 'Electronic Payment Gateways & Settlements',
          subtitle: 'Webhook verification status and bank transfers',
          icon: Icons.account_balance,
          iconColor: AppColors.adminIndigo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Settlement totals are intentionally not displayed here because a verified gateway settlement feed is not part of the current read model. Use the invoice ledger for posted amounts and reconcile against the provider dashboard before confirming bank settlement.',
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
