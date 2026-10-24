import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/clay/clay.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/dialogs/fee_receipt_dialog.dart';
import '../../shared/dialogs/record_payment_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../core/services/data_export_service.dart';
import '../../models/fee_model.dart';

import '../../shared/widgets/erp_components.dart';

class AccountantDashboardScreen extends ConsumerStatefulWidget {
  const AccountantDashboardScreen({super.key});

  @override
  ConsumerState<AccountantDashboardScreen> createState() =>
      _AccountantDashboardScreenState();
}

class _AccountantDashboardScreenState
    extends ConsumerState<AccountantDashboardScreen> {
  int _currentNavIndex = 0;

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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. High-Precision Financial Metric Strip
        const ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Total Invoiced (Term 1)',
              value: '₹42,50,000',
              subtitle: 'Integer paise ledger balance',
              icon: Icons.receipt_long,
              color: AppColors.accountantEmerald,
              trend: 'AY 2026-27',
            ),
            ErpMetricItem(
              label: 'Realized Collections',
              value: '₹36,12,500',
              subtitle: '85% collected across modes',
              icon: Icons.check_circle_outline,
              color: AppColors.successGreen,
              trend: '85% Target',
            ),
            ErpMetricItem(
              label: 'Pending / Outstanding',
              value: '₹6,37,500',
              subtitle: 'Across 64 student accounts',
              icon: Icons.pending_actions,
              color: AppColors.dangerRed,
              trend: '64 Accounts',
              isPositive: false,
            ),
            ErpMetricItem(
              label: 'Gateway Settlements',
              value: 'T+1 Live',
              subtitle: 'Razorpay & Cashfree nodes',
              icon: Icons.account_balance,
              color: AppColors.adminIndigo,
              trend: 'Auto-Sweep',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Financial Workflow Action Ribbon
        ErpCard(
          title: 'Institutional Bursar Operations',
          subtitle: 'Execute authorized fee scheduling, offline payments, and daily audit reconciliation',
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
                    label: 'Record Counter Fee',
                    color: AppColors.accountantEmerald,
                    onPressed: () => setState(() => _currentNavIndex = 2),
                  ),
                  ErpButton(
                    icon: Icons.add,
                    label: 'New Fee Structure',
                    isPrimary: false,
                    color: AppColors.accountantEmerald,
                    onPressed: () => CreateFeeStructureDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.receipt_long,
                    label: 'Generate Invoice',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => CreateInvoiceDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.file_download,
                    label: 'Export Ledger (CSV)',
                    isPrimary: false,
                    color: AppColors.textSecondary,
                    onPressed: () {
                      final invs = ref.read(allInvoicesStreamProvider).value ?? [];
                      DataExportService.exportInvoicesCsv(invs);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3. Approved Fee Structure Schedule
        ErpCard(
          title: 'Institutional Fee Structures',
          subtitle: 'AY 2026-2027 Schedule of Approved Fees • Strict Integer-Paise Computation',
          icon: Icons.folder_open_outlined,
          iconColor: AppColors.accountantEmerald,
          headerTrailing: ErpButton(
            icon: Icons.add,
            label: 'New Fee Structure',
            isDense: true,
            color: AppColors.accountantEmerald,
            onPressed: () => CreateFeeStructureDialog.show(context),
          ),
          child: Column(
            children: [
              _buildFeeStructureRow(
                  'Composite Annual School Fee', null, 4500000),
              const Divider(height: 18, color: AppColors.borderLight),
              _buildFeeStructureRow(
                  'Secondary Science & Laboratory Fee', 'Class 10', 1200000),
              const Divider(height: 18, color: AppColors.borderLight),
              _buildFeeStructureRow(
                  'Primary Activity & Learning Kit', 'Class 5', 850000),
            ],
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(
                  classId != null
                      ? 'Target: $classId Cohort'
                      : 'School-Wide Schedule',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          CurrencyDisplay(
              amountPaise: amountPaise,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.accountantEmerald)),
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
                ClayButton(
                  height: 38,
                  icon: Icons.receipt_long,
                  label: isCompact ? 'Invoice' : 'Generate Invoice',
                  variant: ClayButtonVariant.secondary,
                  onPressed: () => CreateInvoiceDialog.show(context),
                ),
                ClayButton(
                  height: 38,
                  icon: Icons.file_download,
                  label: isCompact ? 'Export' : 'Export Ledger (CSV)',
                  variant: ClayButtonVariant.subtle,
                  onPressed: () {
                    final invs = invoicesAsync.value ?? [];
                    DataExportService.exportInvoicesCsv(invs);
                  },
                ),
                ClayButton(
                  height: 38,
                  icon: Icons.point_of_sale,
                  label: isCompact ? 'Counter' : 'Record Counter Fee',
                  variant: ClayButtonVariant.primary,
                  customColor: AppColors.accountantEmerald,
                  onPressed: () {
                    RecordPaymentDialog.show(
                      context,
                      onPaymentRecorded: ({
                        required invoiceId,
                        required studentId,
                        required payerUserId,
                        required amountPaise,
                        required notes,
                      }) async {
                        await ref
                            .read(feeRepositoryProvider)
                            .recordOfflinePayment(
                              invoiceId: invoiceId,
                              studentId: studentId,
                              payerUserId: payerUserId,
                              amountPaise: amountPaise,
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
          error: (err, _) => ClayCard(
            child: Text('Error loading invoices: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (invoices) {
            if (invoices.isEmpty) {
              return const ClayEmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No Invoices Recorded',
                message: 'No student fee invoices found in Firestore.',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                      FeeReceiptDialog.show(
                        context,
                        invoice: inv,
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
        ClayCard(
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
              ClayButton(
                icon: Icons.add,
                label: 'Open Counter Payment Voucher Modal',
                variant: ClayButtonVariant.primary,
                customColor: AppColors.accountantEmerald,
                onPressed: () {
                  RecordPaymentDialog.show(
                    context,
                    onPaymentRecorded: ({
                      required invoiceId,
                      required studentId,
                      required payerUserId,
                      required amountPaise,
                      required notes,
                    }) async {
                      await ref
                          .read(feeRepositoryProvider)
                          .recordOfflinePayment(
                            invoiceId: invoiceId,
                            studentId: studentId,
                            payerUserId: payerUserId,
                            amountPaise: amountPaise,
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
      children: [
        ClayCard(
          title: 'Electronic Payment Gateways & Settlements',
          subtitle: 'Webhook verification status and bank transfers',
          icon: Icons.account_balance,
          iconColor: AppColors.adminIndigo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSettlementTile(
                  'Razorpay Payment Gateway (UPI / Cards)',
                  'Active • T+1 Settlement • Webhook Verified',
                  '₹ 14,20,000 Realized',
                  AppColors.successGreen),
              const Divider(height: 20),
              _buildSettlementTile(
                  'Cashfree Payments Engine',
                  'Active • Daily Sweep Enabled',
                  '₹ 8,90,000 Realized',
                  AppColors.successGreen),
              const Divider(height: 20),
              _buildSettlementTile(
                  'Direct Cash / POS Bank Deposit',
                  'Manual Entry • Verified by Bursar',
                  '₹ 13,02,500 Realized',
                  AppColors.accountantEmerald),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettlementTile(
      String title, String subtitle, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Text(amount,
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 14, color: color)),
      ],
    );
  }
}
