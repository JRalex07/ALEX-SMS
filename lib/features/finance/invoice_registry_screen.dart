import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/payment_modal.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Invoice Registry (All Invoices)
/// Route: /fees/invoices
class InvoiceRegistryScreen extends ConsumerStatefulWidget {
  const InvoiceRegistryScreen({super.key});

  @override
  ConsumerState<InvoiceRegistryScreen> createState() =>
      _InvoiceRegistryScreenState();
}

class _InvoiceRegistryScreenState extends ConsumerState<InvoiceRegistryScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final isParent = user?.role == UserRoles.parentGuardian;

    if (isParent) {
      return _buildParentInvoiceView();
    }

    final invoicesAsync = ref.watch(allInvoicesStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Invoice Registry',
      currentRoute: AppRoutes.feeInvoices,
      actions: [
        ErpButton(
          label: 'Generate Invoice',
          icon: Icons.post_add,
          isDense: true,
          onPressed: () => context.go(AppRoutes.feeInvoicesGenerate),
        ),
      ],
      body: invoicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (invoices) {
          final students = studentsAsync.value ?? [];
          final studentMap = {for (var s in students) s.studentId: s};

          final query = _searchController.text.trim().toLowerCase();
          final filtered = invoices.where((inv) {
            final matchesStatus =
                _statusFilter == 'All' || inv.status == _statusFilter.toLowerCase();
            final s = studentMap[inv.studentId];
            final name = s?.fullName.toLowerCase() ?? '';
            final id = inv.invoiceId.toLowerCase();
            final matchesQuery =
                query.isEmpty || name.contains(query) || id.contains(query);
            return matchesStatus && matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Fee Invoicing Master Register',
                subtitle:
                    'Audit student invoices, payment allocations, and receipt vouchers',
                child: Row(
                  children: [
                    Expanded(
                      child: ErpSearchBar(
                        controller: _searchController,
                        hintText: 'Search by student name or invoice #...',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _statusFilter,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                        DropdownMenuItem(value: 'Issued', child: Text('Issued')),
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'Overdue', child: Text('Overdue')),
                        DropdownMenuItem(value: 'Draft', child: Text('Draft')),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Invoices (${filtered.length} Bills)',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No invoices match query.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final inv = filtered[idx];
                          final student = studentMap[inv.studentId];
                          final studentName =
                              student?.fullName ?? 'Student #${inv.studentId}';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: inv.isPaid
                                  ? AppColors.successGreen.withValues(alpha: 0.12)
                                  : AppColors.warningAmber.withValues(alpha: 0.15),
                              child: Icon(
                                inv.isPaid
                                    ? Icons.check_circle_outline
                                    : Icons.receipt_long,
                                color: inv.isPaid
                                    ? AppColors.successGreen
                                    : AppColors.warningAmber,
                              ),
                            ),
                            title: Text('$studentName — ${inv.title}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Invoice #${inv.invoiceId} • Due: ${inv.dueDate?.toLocal().toString().split(" ").first ?? "Term End"} • Paid: ₹${(inv.paidAmountPaise / 100).toInt()}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CurrencyDisplay(
                                  amountPaise: inv.totalAmountPaise,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  label: inv.status.toUpperCase(),
                                  type: inv.isPaid
                                      ? StatusType.success
                                      : (inv.status == 'overdue'
                                          ? StatusType.danger
                                          : StatusType.warning),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.print_outlined,
                                      size: 18),
                                  tooltip: 'Print Invoice',
                                  onPressed: () {
                                    if (student != null) {
                                      PrintPreviewDialog.showInvoice(
                                        context,
                                        invoice: inv,
                                        student: student,
                                      );
                                    }
                                  },
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
    );
  }

  Widget _buildParentInvoiceView() {
    final selectedChild = ref.watch(selectedChildProvider);
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return ResponsiveScaffold(
      title: 'Fee Invoices',
      currentRoute: AppRoutes.feeInvoices,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          if (selectedChild == null)
            const Center(child: Text('No student linked.'))
          else
            invoicesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.brandNavy)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (invoices) {
                final childInvoices = invoices
                    .where((i) => i.studentId == selectedChild.studentId)
                    .toList();

                return ErpCard(
                  title: 'Invoices for ${selectedChild.fullName}',
                  subtitle:
                      'Official institutional tuition & activity statements',
                  child: childInvoices.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No invoices issued for this student.',
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
                                        fontSize: 15),
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
                );
              },
            ),
        ],
      ),
    );
  }
}
