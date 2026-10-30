import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Receipt Registry
/// Route: /fees/receipts
class ReceiptRegistryScreen extends ConsumerStatefulWidget {
  const ReceiptRegistryScreen({super.key});

  @override
  ConsumerState<ReceiptRegistryScreen> createState() =>
      _ReceiptRegistryScreenState();
}

class _ReceiptRegistryScreenState extends ConsumerState<ReceiptRegistryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Fee Receipts',
      currentRoute: AppRoutes.feeReceipts,
      body: invoicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (invoices) {
          final paidInvoices =
              invoices.where((inv) => inv.paidAmountPaise > 0).toList();
          final students = studentsAsync.value ?? [];
          final studentMap = {for (var s in students) s.studentId: s};

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Official School Fee Receipts & Vouchers',
                subtitle:
                    'Audit and reprint tamper-proof payment receipts for institutional accounting and tax proofs',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search receipts by student name or invoice number...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Receipts Issued (${paidInvoices.length})',
                child: paidInvoices.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No payment receipts found.',
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
                          final student = studentMap[inv.studentId];
                          final name = student?.fullName ?? 'Student #${inv.studentId}';

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(Icons.print, color: AppColors.brandNavy),
                            ),
                            title: Text('Receipt #${inv.invoiceId.replaceAll("INV", "RCP")} — $name',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Invoice: ${inv.title} • Paid Amount: ₹${(inv.paidAmountPaise / 100).toInt()}\n'
                                'Issued on: ${inv.dueDate?.toLocal().toString().split(" ").first ?? "Recent"}'),
                            isThreeLine: true,
                            trailing: OutlinedButton.icon(
                              icon: const Icon(Icons.print_outlined, size: 14),
                              label: const Text('Print Voucher'),
                              onPressed: () {
                                if (student != null) {
                                  final receiptNo =
                                      'REC-2026-${inv.invoiceId.replaceAll('INV_', '')}';
                                  PrintPreviewDialog.showReceipt(
                                    context,
                                    invoice: inv,
                                    paymentAmountPaise: inv.paidAmountPaise,
                                    paymentMethod: 'ONLINE / BANK TRANSFER',
                                    transactionId: receiptNo,
                                    student: student,
                                  );
                                }
                              },
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
