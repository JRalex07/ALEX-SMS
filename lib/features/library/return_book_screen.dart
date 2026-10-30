import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/library_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Return Book (Circulation Desk)
/// Route: /library/return
class ReturnBookScreen extends ConsumerStatefulWidget {
  const ReturnBookScreen({super.key});

  @override
  ConsumerState<ReturnBookScreen> createState() => _ReturnBookScreenState();
}

class _ReturnBookScreenState extends ConsumerState<ReturnBookScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleReturn(LibraryLoan loan) async {
    try {
      await ref.read(libraryRepositoryProvider).returnBook(loan.loanId, loan.bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book returned and inventory copy restored!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to return book: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeLoansAsync = ref.watch(activeLoansStreamProvider);
    final booksAsync = ref.watch(allBooksStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Return Book (Circulation Desk)',
      currentRoute: AppRoutes.libraryReturn,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Catalog'),
          onPressed: () => context.go(AppRoutes.library),
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

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Library Return & Check-in Counter',
                subtitle:
                    'Audit condition, calculate overdue fines, and check volumes back into inventory',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search loan by accession # or student name...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Active Outstanding Loans (${loans.length})',
                child: loans.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No outstanding loans to return.',
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
                                isOverdue
                                    ? Icons.warning_amber
                                    : Icons.bookmark,
                                color: isOverdue
                                    ? AppColors.dangerRed
                                    : AppColors.brandNavy,
                              ),
                            ),
                            title: Text(book?.title ?? 'Book #${loan.bookId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Borrower: ${student?.fullName ?? loan.studentId} • Due: ${loan.dueDate.toLocal().toString().split(" ").first}\n'
                                '${isOverdue ? "Overdue Fine: ₹10 (2 days)" : "Within loan tenure"}'),
                            isThreeLine: true,
                            trailing: ErpButton(
                              label: 'Process Return',
                              icon: Icons.assignment_return_outlined,
                              isDense: true,
                              onPressed: () => _handleReturn(loan),
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
