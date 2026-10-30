import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Student Fee Accounts & Ledgers
/// Route: /fees/accounts
class FeeAccountsScreen extends ConsumerStatefulWidget {
  const FeeAccountsScreen({super.key});

  @override
  ConsumerState<FeeAccountsScreen> createState() => _FeeAccountsScreenState();
}

class _FeeAccountsScreenState extends ConsumerState<FeeAccountsScreen> {
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
      title: 'Student Fee Accounts',
      currentRoute: AppRoutes.feeAccounts,
      actions: [
        ErpButton(
          label: 'Outstanding Dues',
          icon: Icons.money_off,
          isDense: true,
          onPressed: () => context.go(AppRoutes.feeDues),
        ),
      ],
      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            return query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
          }).toList();

          final invoices = invoicesAsync.value ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Student Financial Ledger Index',
                subtitle:
                    'Audit billing balances, collections, and dues across active pupils',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search account by student name or admission number...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Student Accounts Directory (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No student accounts match query.',
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
                          final s = filtered[idx];
                          final studentInvoices = invoices
                              .where((inv) => inv.studentId == s.studentId)
                              .toList();

                          final totalInvoiced = studentInvoices.fold<int>(
                              0, (sum, i) => sum + i.totalAmountPaise);
                          final totalPaid = studentInvoices.fold<int>(
                              0, (sum, i) => sum + i.paidAmountPaise);
                          final outstanding = totalInvoiced - totalPaid;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: outstanding > 0
                                  ? AppColors.dangerRed.withValues(alpha: 0.12)
                                  : AppColors.successGreen.withValues(alpha: 0.12),
                              child: Icon(
                                outstanding > 0
                                    ? Icons.money_off
                                    : Icons.check_circle_outline,
                                color: outstanding > 0
                                    ? AppColors.dangerRed
                                    : AppColors.successGreen,
                              ),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              'Adm #${s.admissionNumber} • Standard: Class ${s.currentClassId}-${s.currentSectionId}\n'
                              'Invoices: ${studentInvoices.length} bills • Collected: ₹${(totalPaid / 100).toInt()}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CurrencyDisplay(
                                  amountPaise: outstanding,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: outstanding > 0
                                        ? AppColors.dangerRed
                                        : AppColors.successGreen,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                StatusBadge(
                                  label: outstanding > 0
                                      ? 'BALANCE DUE'
                                      : 'PAID UP',
                                  type: outstanding > 0
                                      ? StatusType.danger
                                      : StatusType.success,
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
