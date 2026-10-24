import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../providers/feature_providers.dart';
import '../../shared/clay/clay.dart';
import '../../shared/dialogs/add_book_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/app_scaffold.dart';

import '../../shared/widgets/erp_components.dart';

class LibrarianDashboardScreen extends ConsumerStatefulWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  ConsumerState<LibrarianDashboardScreen> createState() =>
      _LibrarianDashboardScreenState();
}

class _LibrarianDashboardScreenState
    extends ConsumerState<LibrarianDashboardScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'School Library System',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Catalogue'),
        NavigationDestination(
            icon: Icon(Icons.assignment_return_outlined),
            selectedIcon: Icon(Icons.assignment_return),
            label: 'Active Loans'),
        NavigationDestination(
            icon: Icon(Icons.bookmark_add_outlined),
            selectedIcon: Icon(Icons.bookmark_add),
            label: 'Issue Book'),
      ],
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildCatalogueTab(),
          _buildActiveLoansTab(),
          _buildIssueBookTab(),
        ],
      ),
    );
  }

  Widget _buildCatalogueTab() {
    final booksAsync = ref.watch(libraryBooksProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Library Circulation Metric Strip
        booksAsync.maybeWhen(
          data: (books) {
            final totalTitles = books.length;
            final totalCopies =
                books.fold<int>(0, (sum, b) => sum + b.totalCopies);
            final availableCopies =
                books.fold<int>(0, (sum, b) => sum + b.availableCopies);
            final activeLoans = totalCopies - availableCopies;

            return ErpMetricStrip(
              metrics: [
                ErpMetricItem(
                  label: 'Total Titles',
                  value: '$totalTitles',
                  subtitle: '$totalCopies Total Catalogued Copies',
                  icon: Icons.menu_book,
                  color: AppColors.librarianViolet,
                  trend: 'Catalog Active',
                ),
                ErpMetricItem(
                  label: 'Active Checkouts',
                  value: '$activeLoans',
                  subtitle: '$availableCopies Copies Available',
                  icon: Icons.assignment_turned_in,
                  color: AppColors.librarianViolet,
                  trend: 'Circulating',
                ),
                ErpMetricItem(
                  label: 'Available Copies',
                  value: '$availableCopies',
                  subtitle: 'On Shelf Ready to Issue',
                  icon: Icons.inventory_2_outlined,
                  color: AppColors.successGreen,
                  trend: 'In Stock',
                ),
                const ErpMetricItem(
                  label: 'Circulation Status',
                  value: 'Live Desk',
                  subtitle: 'Terminal 1 • Barcode Ready',
                  icon: Icons.qr_code_scanner,
                  color: AppColors.brandNavy,
                  trend: 'Online',
                ),
              ],
            );
          },
          orElse: () => const ErpMetricStrip(
            metrics: [
              ErpMetricItem(
                label: 'Total Titles',
                value: '3',
                subtitle: 'Institutional Reference Books',
                icon: Icons.menu_book,
                color: AppColors.librarianViolet,
                trend: 'Catalog',
              ),
              ErpMetricItem(
                label: 'Active Checkouts',
                value: '14',
                subtitle: 'Circulating across classes',
                icon: Icons.assignment_turned_in,
                color: AppColors.librarianViolet,
                trend: 'Loans Active',
              ),
              ErpMetricItem(
                label: 'Available Copies',
                value: '42',
                subtitle: 'Copies on Shelf',
                icon: Icons.inventory_2_outlined,
                color: AppColors.successGreen,
                trend: 'In Stock',
              ),
              ErpMetricItem(
                label: 'Circulation Desk',
                value: 'Live',
                subtitle: 'Barcode & RFID Scanner',
                icon: Icons.qr_code_scanner,
                color: AppColors.brandNavy,
                trend: 'Active',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Library Circulation Desk Action Ribbon
        ErpCard(
          title: 'Library Circulation Operations',
          subtitle:
              'Search titles, manage catalog accession numbers, and process student book borrowing',
          icon: Icons.local_library_outlined,
          iconColor: AppColors.librarianViolet,
          headerTrailing: const ErpStatusBadge(
            label: 'Circulation Active',
            backgroundColor: AppColors.successBg,
            textColor: AppColors.successGreen,
            icon: Icons.check_circle_outline,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ErpButton(
                    icon: Icons.add,
                    label: 'Add New Title',
                    color: AppColors.librarianViolet,
                    onPressed: () => AddBookDialog.show(context),
                  ),
                  ErpButton(
                    icon: Icons.bookmark_add_outlined,
                    label: 'Issue Book to Student',
                    isPrimary: false,
                    color: AppColors.librarianViolet,
                    onPressed: () => setState(() => _currentNavIndex = 2),
                  ),
                  ErpButton(
                    icon: Icons.assignment_return_outlined,
                    label: 'View Active Loans & Returns',
                    isPrimary: false,
                    color: AppColors.brandNavy,
                    onPressed: () => setState(() => _currentNavIndex = 1),
                  ),
                  booksAsync.maybeWhen(
                    data: (books) => ErpButton(
                      icon: Icons.download,
                      label: 'Export Catalogue (CSV)',
                      isPrimary: false,
                      color: AppColors.textSecondary,
                      onPressed: () =>
                          DataExportService.exportLibraryBooksCsv(books),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        booksAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => ClayCard(
            child: Text('Error loading library catalogue: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
          data: (books) {
            if (books.isEmpty) {
              return const ClayEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No Books Catalogued',
                message: 'No books found in the library catalogue.',
              );
            }

            return Column(
              children: books.map((b) {
                final isbnStr =
                    b.isbn != null ? 'ISBN: ${b.isbn}' : (b.category ?? '');
                return _buildBookItem(
                  b.bookId,
                  b.title,
                  b.author,
                  isbnStr,
                  b.availableCopies,
                  b.totalCopies,
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBookItem(String id, String title, String author, String isbn,
      int available, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClayCard(
        title: title,
        subtitle: 'Author: $author • $isbn',
        icon: Icons.book,
        iconColor: AppColors.librarianViolet,
        headerAction: ClayStatusBadge(
          status: available > 0 ? 'In Stock' : 'Checked Out',
          customLabel:
              available > 0 ? '$available / $total In Stock' : 'Checked Out',
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Book ID: $id',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Wrap(
              spacing: 8,
              children: [
                ClayButton(
                  height: 34,
                  label: 'Issue Loan',
                  variant: ClayButtonVariant.primary,
                  customColor: AppColors.librarianViolet,
                  onPressed: available > 0
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Issuing "$title" to student...')),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveLoansTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        const Text('Active Student Loans',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3)),
        const SizedBox(height: 18),
        _buildLoanItem('LOAN_2026_01', 'Concepts of Physics (Vol 1)',
            'Aarav Sharma (STU_001)', 'Due: Oct 30, 2026', false),
        const SizedBox(height: 12),
        _buildLoanItem('LOAN_2026_02', 'Higher Algebra', 'Diya Patel (STU_002)',
            'Due: Nov 05, 2026', false),
        const SizedBox(height: 12),
        _buildLoanItem('LOAN_2026_03', 'Chemistry Fundamentals',
            'Karan Singh (STU_003)', 'OVERDUE: Oct 18, 2026', true),
      ],
    );
  }

  Widget _buildLoanItem(String loanId, String bookTitle, String borrower,
      String due, bool isOverdue) {
    return ClayCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClayContainer(
            depth: ClayDepth.low,
            borderRadius: ClayTheme.radiusSm,
            surfaceColor:
                (isOverdue ? AppColors.dangerRed : AppColors.librarianViolet)
                    .withValues(alpha: 0.1),
            borderColor:
                (isOverdue ? AppColors.dangerRed : AppColors.librarianViolet)
                    .withValues(alpha: 0.25),
            padding: const EdgeInsets.all(10),
            child: Icon(Icons.bookmark,
                color:
                    isOverdue ? AppColors.dangerRed : AppColors.librarianViolet,
                size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$borrower • $due',
                    style: TextStyle(
                        fontSize: 12,
                        color: isOverdue
                            ? AppColors.dangerRed
                            : AppColors.textSecondary,
                        fontWeight:
                            isOverdue ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
          ClayButton(
            height: 36,
            label: 'Return Book',
            variant: ClayButtonVariant.subtle,
            customColor: AppColors.librarianViolet,
            onPressed: () {
              final dueParsed = isOverdue
                  ? DateTime.now().subtract(const Duration(days: 6))
                  : DateTime.now().add(const Duration(days: 6));
              ReturnBookDialog.show(
                context,
                loanId: loanId,
                bookId: 'BOOK_001',
                bookTitle: bookTitle,
                studentId: borrower,
                dueDate: dueParsed,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIssueBookTab() {
    final booksAsync = ref.watch(libraryBooksProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        ClayCard(
          title: 'Direct Circulation Counter',
          subtitle:
              'Issue book loan to enrolled student • Atomic Inventory Check',
          icon: Icons.bookmark_add,
          iconColor: AppColors.librarianViolet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book circulation triggers an atomic Firestore transaction decrementing available copies and recording the active loan. Available copies cannot fall below zero.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 18),
              booksAsync.when(
                data: (books) {
                  final inStock =
                      books.where((b) => b.availableCopies > 0).toList();
                  if (inStock.isEmpty) {
                    return const Text(
                        'All catalogued books are currently checked out.',
                        style: TextStyle(color: AppColors.textSecondary));
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Select Available Book',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      ClayContainer(
                        depth: ClayDepth.inset,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: inStock.first.bookId,
                            isExpanded: true,
                            items: inStock.map((b) {
                              return DropdownMenuItem(
                                value: b.bookId,
                                child: Text(
                                    '${b.title} (${b.availableCopies} available)'),
                              );
                            }).toList(),
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Select Student Borrower',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      studentsAsync.when(
                        data: (students) {
                          return ClayContainer(
                            depth: ClayDepth.inset,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: students.isNotEmpty
                                    ? students.first.studentId
                                    : null,
                                isExpanded: true,
                                items: students.map((s) {
                                  return DropdownMenuItem(
                                    value: s.studentId,
                                    child: Text(
                                        '${s.fullName} (${s.admissionNumber})'),
                                  );
                                }).toList(),
                                onChanged: (_) {},
                              ),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Error loading students'),
                      ),
                      const SizedBox(height: 20),
                      ClayButton(
                        icon: Icons.check,
                        label: 'Issue Circulation Loan (14 Days)',
                        variant: ClayButtonVariant.primary,
                        customColor: AppColors.librarianViolet,
                        onPressed: () async {
                          final selectedBook = inStock.first;
                          final selectedStudent =
                              studentsAsync.value?.isNotEmpty == true
                                  ? studentsAsync.value!.first.studentId
                                  : 'STU_2026_001';
                          try {
                            await ref.read(libraryRepositoryProvider).issueBook(
                                  bookId: selectedBook.bookId,
                                  studentId: selectedStudent,
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.librarianViolet,
                                  content: Text(
                                      'Issued "${selectedBook.title}" to $selectedStudent.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    backgroundColor: AppColors.dangerRed,
                                    content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
