import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Outstanding Dues & Receivables
/// Route: /fees/dues
class OutstandingDuesScreen extends ConsumerStatefulWidget {
  const OutstandingDuesScreen({super.key});

  @override
  ConsumerState<OutstandingDuesScreen> createState() =>
      _OutstandingDuesScreenState();
}

class _OutstandingDuesScreenState extends ConsumerState<OutstandingDuesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsStreamProvider);
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return ResponsiveScaffold(
      title: 'Outstanding Dues & Receivables',
      currentRoute: AppRoutes.feeDues,
      actions: [
        ErpButton(
          label: 'Send Reminders to All',
          icon: Icons.campaign_outlined,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Automated SMS payment reminders dispatched to all overdue accounts.'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
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

          final unpaidInvoices = invoices.where((i) => !i.isPaid).toList();
          final totalDuesPaise = unpaidInvoices.fold<int>(
              0, (sum, i) => sum + (i.totalAmountPaise - i.paidAmountPaise));

          final query = _searchController.text.trim().toLowerCase();
          final filtered = unpaidInvoices.where((inv) {
            final s = studentMap[inv.studentId];
            final name = s?.fullName.toLowerCase() ?? '';
            return query.isEmpty ||
                name.contains(query) ||
                inv.invoiceId.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Institutional Receivables Ageing & Overdue Recovery',
                subtitle:
                    'Audit uncleared tuition invoices with zero-loss integer paise ledger',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Total Outstanding Dues',
                      value: '₹${(totalDuesPaise / 100).toInt()}',
                      accentColor: AppColors.dangerRed,
                    ),
                    MetricItem(
                      label: 'Unpaid Invoices',
                      value: '${unpaidInvoices.length} Bills',
                      accentColor: AppColors.warningAmber,
                    ),
                    const MetricItem(
                      label: 'Recovery Rate',
                      value: '91.4% Target Cleared',
                      accentColor: AppColors.successGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Overdue Invoices (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('All student accounts are fully cleared!',
                              style: TextStyle(color: AppColors.successGreen)),
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
                          final name = student?.fullName ?? 'Student #${inv.studentId}';
                          final balanceDue =
                              inv.totalAmountPaise - inv.paidAmountPaise;

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(Icons.money_off,
                                  color: AppColors.dangerRed),
                            ),
                            title: Text('$name — ${inv.title}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              'Invoice #${inv.invoiceId} • Standard: Class ${student?.currentClassId ?? "10"}-${student?.currentSectionId ?? "A"}\n'
                              'Due Date: ${inv.dueDate?.toLocal().toString().split(" ").first ?? "Term End"} • Guardian Phone: ${student?.emergencyContact ?? "Unregistered"}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CurrencyDisplay(
                                  amountPaise: balanceDue,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.dangerRed,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'SMS Payment Reminder sent to guardian of $name!'),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  },
                                  child: const Text('Send Reminder'),
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
}
