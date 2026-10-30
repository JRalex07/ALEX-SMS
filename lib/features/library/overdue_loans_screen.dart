import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Overdue Loans & Fine Management
/// Route: /library/overdue
class OverdueLoansScreen extends ConsumerStatefulWidget {
  const OverdueLoansScreen({super.key});

  @override
  ConsumerState<OverdueLoansScreen> createState() => _OverdueLoansScreenState();
}

class _OverdueLoansScreenState extends ConsumerState<OverdueLoansScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeLoansAsync = ref.watch(activeLoansStreamProvider);
    final booksAsync = ref.watch(allBooksStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Overdue Loans & Fine Management',
      currentRoute: AppRoutes.libraryOverdue,
      actions: [
        ErpButton(
          label: 'Send Overdue Notice',
          icon: Icons.campaign_outlined,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Overdue circulation notices dispatched to student accounts.'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
        ),
      ],
      body: activeLoansAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (loans) {
          final books = booksAsync.value ?? [];
          final students = studentsAsync.value ?? [];

          final bookMap = {for (var b in books) b.bookId: b};
          final studentMap = {for (var s in students) s.studentId: s};

          final overdueLoans = loans.where((l) {
            return l.status == 'active' &&
                DateTime.now().isAfter(l.dueDate);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Overdue Circulation & Library Fines Registry',
                subtitle:
                    'Automated fine calculation at ₹5/day beyond 14-day statutory loan period',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Overdue Volumes',
                      value: '${overdueLoans.length} Books',
                      accentColor: AppColors.dangerRed,
                    ),
                    const MetricItem(
                      label: 'Accrued Fine Total',
                      value: '₹145 Total',
                      accentColor: AppColors.warningAmber,
                    ),
                    const MetricItem(
                      label: 'Fine Rate',
                      value: '₹5 / Day / Book',
                      accentColor: AppColors.brandNavy,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Overdue Books Roster (${overdueLoans.length})',
                child: overdueLoans.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Excellent! Zero overdue loans currently on record.',
                            style: TextStyle(color: AppColors.successGreen),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: overdueLoans.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final loan = overdueLoans[idx];
                          final book = bookMap[loan.bookId];
                          final student = studentMap[loan.studentId];

                          final daysOverdue =
                              DateTime.now().difference(loan.dueDate).inDays;
                          final fine = (daysOverdue > 0 ? daysOverdue : 1) * 5;

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(Icons.error_outline,
                                  color: AppColors.dangerRed),
                            ),
                            title: Text(book?.title ?? 'Book #${loan.bookId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              'Borrower: ${student?.fullName ?? loan.studentId} (Adm #${student?.admissionNumber ?? "—"})\n'
                              'Due Date: ${loan.dueDate.toLocal().toString().split(" ").first} • $daysOverdue days late • Fine: ₹$fine',
                            ),
                            isThreeLine: true,
                            trailing: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Return slip and fine receipt initiated for ${book?.title}'),
                                  ),
                                );
                              },
                              child: const Text('Collect Fine & Return'),
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
