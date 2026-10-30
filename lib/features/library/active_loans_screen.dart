import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Active Library Loans
/// Route: /library/loans
class ActiveLoansScreen extends ConsumerStatefulWidget {
  const ActiveLoansScreen({super.key});

  @override
  ConsumerState<ActiveLoansScreen> createState() => _ActiveLoansScreenState();
}

class _ActiveLoansScreenState extends ConsumerState<ActiveLoansScreen> {
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
      title: 'Active Library Loans',
      currentRoute: AppRoutes.libraryLoans,
      actions: [
        ErpButton(
          label: 'Issue Book',
          icon: Icons.assignment_returned_outlined,
          isDense: true,
          onPressed: () => context.go(AppRoutes.libraryIssue),
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

          final activeCount = loans.where((l) => l.status == 'active').length;
          final overdueCount = loans
              .where((l) =>
                  l.status == 'active' && DateTime.now().isAfter(l.dueDate))
              .length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Library Circulation Ledger & Borrowing Audit',
                subtitle:
                    'Tracking active loans across student cohorts and faculty borrowers',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Active Loans',
                      value: '$activeCount Volumes',
                      accentColor: AppColors.brandNavy,
                    ),
                    MetricItem(
                      label: 'Overdue Loans',
                      value: '$overdueCount Volumes',
                      accentColor: AppColors.dangerRed,
                    ),
                    const MetricItem(
                      label: 'Circulation Policy',
                      value: '14 Days / 2 Books Max',
                      accentColor: AppColors.tealSuccess,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Circulation Loans Roster (${loans.length})',
                child: loans.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No active loans registered.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: loans.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final loan = loans[idx];
                          final book = bookMap[loan.bookId];
                          final student = studentMap[loan.studentId];

                          final isOverdue =
                              DateTime.now().isAfter(loan.dueDate);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isOverdue
                                  ? AppColors.dangerRed.withValues(alpha: 0.12)
                                  : AppColors.brandNavy.withValues(alpha: 0.1),
                              child: Icon(
                                isOverdue ? Icons.warning : Icons.bookmark,
                                color: isOverdue
                                    ? AppColors.dangerRed
                                    : AppColors.brandNavy,
                              ),
                            ),
                            title: Text(book?.title ?? 'Book #${loan.bookId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Borrower: ${student?.fullName ?? loan.studentId} • Issued: ${loan.issuedDate.toLocal().toString().split(" ").first} • Due: ${loan.dueDate.toLocal().toString().split(" ").first}'),
                            trailing: StatusBadge(
                              label: isOverdue ? 'OVERDUE' : 'ACTIVE',
                              type: isOverdue
                                  ? StatusType.danger
                                  : StatusType.success,
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
