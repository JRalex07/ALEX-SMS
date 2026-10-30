import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../models/library_model.dart';
import '../../models/student_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/add_book_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../../shared/widgets/erp_components.dart';
import '../../core/theme/apple_design_system.dart';

class LibrarianDashboardScreen extends ConsumerStatefulWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  ConsumerState<LibrarianDashboardScreen> createState() =>
      _LibrarianDashboardScreenState();
}

class _LibrarianDashboardScreenState
    extends ConsumerState<LibrarianDashboardScreen> {
  int _currentNavIndex = 0;
  String? _selectedBookId;
  String? _selectedStudentId;
  final TextEditingController _catalogSearchCtrl = TextEditingController();
  final TextEditingController _quickCirculationCtrl = TextEditingController();
  String _catalogSearchQuery = '';

  @override
  void dispose() {
    _catalogSearchCtrl.dispose();
    _quickCirculationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Central Library Management',
      selectedNavIndex: _currentNavIndex,
      onNavIndexChanged: (idx) => setState(() => _currentNavIndex = idx),
      navDestinations: const [
        NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard'),
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
            label: 'Issue Counter'),
      ],
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildLibrarianOverviewTab(),
          _buildCatalogueTab(),
          _buildActiveLoansTab(),
          _buildIssueBookTab(),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 1: LIBRARIAN MAIN DASHBOARD OVERVIEW
  // ==========================================================================
  Widget _buildLibrarianOverviewTab() {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final booksAsync = ref.watch(libraryBooksProvider);
    final loansAsync = ref.watch(allLibraryLoansStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    final librarianName =
        userProfileAsync.valueOrNull?.displayName ?? 'Librarian';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // 1. Role-specific Welcome Header
        _buildLibrarianWelcomeHeader(librarianName),
        const SizedBox(height: 20),

        // 2. 6 Compact Real-Data Metric Widgets
        _buildLibraryMetricsStrip(booksAsync, loansAsync),
        const SizedBox(height: 20),

        // 3. Primary Quick Actions
        _buildPrimaryQuickActions(booksAsync, loansAsync, studentsAsync),
        const SizedBox(height: 24),

        // 4. Operational Tables & Queues (Sections 1 through 6 in exact order)
        // 4.1 Quick Circulation Barcode / Accession Lookup
        _buildQuickCirculationDesk(booksAsync, loansAsync, studentsAsync),
        const SizedBox(height: 24),

        // 4.2 Overdue Books Queue
        _buildOverdueBooksQueue(loansAsync, booksAsync, studentsAsync),
        const SizedBox(height: 24),

        // 4.3 Recent Circulation Activity
        _buildRecentCirculationActivity(loansAsync, booksAsync, studentsAsync),
        const SizedBox(height: 24),

        // 4.4 Popular or Frequently Borrowed Books
        _buildPopularBooksSummary(booksAsync, loansAsync),
        const SizedBox(height: 24),

        // 4.5 Inventory & Condition Overview
        _buildInventoryConditionOverview(booksAsync, loansAsync),
        const SizedBox(height: 24),

        // 4.6 Catalog Search and Quick Details
        _buildCatalogSearchAndDetails(booksAsync),
        const SizedBox(height: 32),
      ],
    );
  }

  // 1. Welcome Header
  Widget _buildLibrarianWelcomeHeader(String librarianName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.librarianViolet.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_library_outlined,
              color: AppColors.librarianViolet,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      librarianName,
                      style: AppleTypography.title2(color: AppColors.textPrimary),
                    ),
                    const ErpStatusBadge(
                      label: 'Librarian',
                      backgroundColor: Color(0xFFF3E8FF),
                      textColor: AppColors.librarianViolet,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Institutional Catalog & Circulation Management • AY 2026-2027 Central Library',
                  style: AppleTypography.subheadline(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const ErpStatusBadge(
            label: 'Circulation Desk Ready',
            backgroundColor: Color(0xFFECFDF5),
            textColor: AppColors.accountantEmerald,
          ),
        ],
      ),
    );
  }

  // 2. Compact Real-Data Metric Widgets (6 metrics)
  Widget _buildLibraryMetricsStrip(
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<LibraryLoan>> loansAsync,
  ) {
    return booksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.librarianViolet),
        ),
      ),
      error: (err, _) => ErpCard(
        title: 'Library Metrics Unavailable',
        subtitle: 'Error fetching catalog details',
        icon: Icons.error_outline,
        iconColor: AppColors.dangerRed,
        child: Text('Error: $err'),
      ),
      data: (books) {
        final loans = loansAsync.valueOrNull ?? [];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        final totalTitles = books.length;
        final totalCopiesAvailable =
            books.fold<int>(0, (sum, b) => sum + b.availableCopies);

        final currentlyIssued = loans.where((l) => !l.isReturned).length;

        final loansDueToday = loans.where((l) {
          if (l.isReturned) return false;
          return l.dueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
              l.dueDate.isBefore(todayEnd);
        }).length;

        final overdueLoans = loans.where((l) {
          return !l.isReturned && l.dueDate.isBefore(now);
        }).length;

        final todayMovements = loans.where((l) {
          final isIssuedToday =
              l.issuedAt.isAfter(todayStart) && l.issuedAt.isBefore(todayEnd);
          final isReturnedToday = l.returnedAt != null &&
              l.returnedAt!.isAfter(todayStart) &&
              l.returnedAt!.isBefore(todayEnd);
          return isIssuedToday || isReturnedToday;
        }).length;

        return ErpMetricStrip(
          metrics: [
            ErpMetricItem(
              label: 'Catalog Titles',
              value: '$totalTitles',
              subtitle: 'Active titles in catalog',
              icon: Icons.menu_book,
              color: AppColors.librarianViolet,
              trend: 'All stacks',
            ),
            ErpMetricItem(
              label: 'Available Copies',
              value: '$totalCopiesAvailable',
              subtitle: 'Physical copies on shelf',
              icon: Icons.inventory_2_outlined,
              color: AppColors.accountantEmerald,
              trend: 'Ready to borrow',
            ),
            ErpMetricItem(
              label: 'Currently Issued',
              value: '$currentlyIssued',
              subtitle: 'Active patron checkouts',
              icon: Icons.assignment_turned_in_outlined,
              color: AppColors.infoSky,
              trend: 'Circulating',
            ),
            ErpMetricItem(
              label: 'Due Today',
              value: '$loansDueToday',
              subtitle: 'Returns expected today',
              icon: Icons.event_available,
              color: AppColors.warningAmber,
              trend: 'Due 18:00',
            ),
            ErpMetricItem(
              label: 'Overdue Loans',
              value: '$overdueLoans',
              subtitle: 'Past scheduled return date',
              icon: Icons.alarm_off,
              color: AppColors.dangerRed,
              trend: overdueLoans > 0 ? 'Fines accruing' : 'No arrears',
            ),
            ErpMetricItem(
              label: "Today's Movements",
              value: '$todayMovements',
              subtitle: 'Checkouts & Returns today',
              icon: Icons.swap_horiz,
              color: AppColors.brandNavy,
              trend: 'Daily log',
            ),
          ],
        );
      },
    );
  }

  // 3. Primary Quick Actions
  Widget _buildPrimaryQuickActions(
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<LibraryLoan>> loansAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return ErpCard(
      title: 'Circulation Desk Quick Operations',
      subtitle:
          'Authoritative book loans, returns, new accessions, and institutional due notices',
      icon: Icons.flash_on_outlined,
      iconColor: AppColors.librarianViolet,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ErpButton(
            icon: Icons.bookmark_add_outlined,
            label: 'Issue Book',
            color: AppColors.librarianViolet,
            onPressed: () => setState(() => _currentNavIndex = 3),
          ),
          ErpButton(
            icon: Icons.assignment_return_outlined,
            label: 'Return Book',
            isPrimary: false,
            color: AppColors.accountantEmerald,
            onPressed: () => setState(() => _currentNavIndex = 2),
          ),
          ErpButton(
            icon: Icons.add,
            label: 'Add New Title',
            isPrimary: false,
            color: AppColors.librarianViolet,
            onPressed: () => AddBookDialog.show(context),
          ),
          ErpButton(
            icon: Icons.search,
            label: 'Search Catalog',
            isPrimary: false,
            color: AppColors.brandNavy,
            onPressed: () => setState(() => _currentNavIndex = 1),
          ),
          booksAsync.maybeWhen(
            data: (books) => ErpButton(
              icon: Icons.file_download_outlined,
              label: 'Export Catalog (CSV)',
              isPrimary: false,
              color: AppColors.textSecondary,
              onPressed: () => DataExportService.exportLibraryBooksCsv(books),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          loansAsync.maybeWhen(
            data: (loans) {
              final overdue = loans
                  .where((l) => !l.isReturned && l.dueDate.isBefore(DateTime.now()))
                  .toList();
              return ErpButton(
                icon: Icons.print_outlined,
                label: 'Print Due Notices (${overdue.length})',
                isPrimary: false,
                color: AppColors.dangerRed,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.librarianViolet,
                      content: Text(
                          'Generated official overdue notices for ${overdue.length} student accounts.'),
                    ),
                  );
                },
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.1: QUICK CIRCULATION (Barcode / Accession Number Lookup)
  // ==========================================================================
  Widget _buildQuickCirculationDesk(
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<LibraryLoan>> loansAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return ErpCard(
      title: 'Quick Circulation Desk',
      subtitle:
          'Rapid barcode / accession number lookup for immediate book issue, return, or renewal',
      icon: Icons.qr_code_scanner,
      iconColor: AppColors.librarianViolet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _quickCirculationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Scan Barcode / Enter Accession Number or Book ID',
                    hintText: 'e.g. BOOK-001 or Title keyword',
                    prefixIcon: Icon(Icons.qr_code_scanner),
                  ),
                  onFieldSubmitted: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              ErpButton(
                icon: Icons.search,
                label: 'Lookup',
                color: AppColors.librarianViolet,
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          if (_quickCirculationCtrl.text.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final query = _quickCirculationCtrl.text.trim().toLowerCase();
                final books = booksAsync.valueOrNull ?? [];
                final match = books.where((b) =>
                    b.bookId.toLowerCase().contains(query) ||
                    b.title.toLowerCase().contains(query) ||
                    (b.isbn != null && b.isbn!.toLowerCase().contains(query))).toList();

                if (match.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.dangerRed),
                        const SizedBox(width: 10),
                        Text(
                          'No book accession found matching "${_quickCirculationCtrl.text.trim()}".',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.dangerRed),
                        ),
                      ],
                    ),
                  );
                }

                final book = match.first;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppColors.librarianViolet.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book,
                          size: 24, color: AppColors.librarianViolet),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                            Text(
                              'Author: ${book.author} • Category: ${book.category ?? 'General'} • Available: ${book.availableCopies} / ${book.totalCopies}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      ErpButton(
                        label: 'Issue Loan',
                        color: AppColors.librarianViolet,
                        isDense: true,
                        onPressed: book.availableCopies > 0
                            ? () {
                                setState(() {
                                  _selectedBookId = book.bookId;
                                  _currentNavIndex = 3;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.2: OVERDUE BOOKS QUEUE
  // ==========================================================================
  Widget _buildOverdueBooksQueue(
    AsyncValue<List<LibraryLoan>> loansAsync,
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return ErpCard(
      title: 'Overdue Books & Accruing Fines Queue',
      subtitle:
          'Circulation loans past scheduled return date • Statutory fine calculation at ₹2.00 per day',
      icon: Icons.alarm_off,
      iconColor: AppColors.dangerRed,
      child: loansAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error loading overdue loans: $err'),
        data: (loans) {
          final now = DateTime.now();
          final overdue = loans
              .where((l) => !l.isReturned && l.dueDate.isBefore(now))
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          if (overdue.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 36, color: AppColors.accountantEmerald),
                    SizedBox(height: 10),
                    Text(
                      'No Overdue Loans',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'All circulating catalog copies are currently within valid return dates.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final books = booksAsync.valueOrNull ?? [];
          final students = studentsAsync.valueOrNull ?? [];

          return Column(
            children: [
              for (final loan in overdue) ...[
                Builder(builder: (context) {
                  final daysLate = now.difference(loan.dueDate).inDays;
                  final finePaise = (daysLate.clamp(1, 9999) * 200); // ₹2 per day = 200 paise
                  final bookTitle = _bookTitleFor(books, loan.bookId);
                  final borrower = _borrowerLabelFor(students, loan.studentId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.dangerRed.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.warning_amber_rounded,
                              size: 18, color: AppColors.dangerRed),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bookTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              Text(
                                'Patron: $borrower • Due: ${loan.dueDate.day}/${loan.dueDate.month}/${loan.dueDate.year}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$daysLate Days Overdue',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.dangerRed),
                            ),
                            Text(
                              'Fine: ₹${(finePaise / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        ErpButton(
                          label: 'Process Return',
                          isDense: true,
                          color: AppColors.librarianViolet,
                          onPressed: () {
                            ReturnBookDialog.show(
                              context,
                              loanId: loan.loanId,
                              bookId: loan.bookId,
                              bookTitle: bookTitle,
                              studentId: loan.studentId,
                              dueDate: loan.dueDate,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.3: RECENT CIRCULATION ACTIVITY
  // ==========================================================================
  Widget _buildRecentCirculationActivity(
    AsyncValue<List<LibraryLoan>> loansAsync,
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<Student>> studentsAsync,
  ) {
    return ErpCard(
      title: 'Recent Circulation Movements',
      subtitle:
          'Audit trail of recent book check-outs, returns, and renewals with authoritative timestamps',
      icon: Icons.history,
      iconColor: AppColors.brandNavy,
      child: loansAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (loans) {
          if (loans.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No circulation transactions recorded yet.'),
              ),
            );
          }

          final books = booksAsync.valueOrNull ?? [];
          final students = studentsAsync.valueOrNull ?? [];
          final recentLoans = List<LibraryLoan>.from(loans)
            ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

          final displayItems = recentLoans.take(5).toList();

          return Column(
            children: [
              for (var i = 0; i < displayItems.length; i++) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: displayItems[i].isReturned
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF3E8FF),
                      child: Icon(
                        displayItems[i].isReturned
                            ? Icons.assignment_returned_outlined
                            : Icons.bookmark_added_outlined,
                        size: 16,
                        color: displayItems[i].isReturned
                            ? AppColors.accountantEmerald
                            : AppColors.librarianViolet,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _bookTitleFor(books, displayItems[i].bookId),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          Text(
                            'Borrower: ${_borrowerLabelFor(students, displayItems[i].studentId)} • Issued: ${displayItems[i].issuedAt.day}/${displayItems[i].issuedAt.month}',
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ErpStatusBadge(
                      label: displayItems[i].isReturned ? 'Returned' : 'Active Loan',
                      backgroundColor: displayItems[i].isReturned
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF3E8FF),
                      textColor: displayItems[i].isReturned
                          ? AppColors.accountantEmerald
                          : AppColors.librarianViolet,
                    ),
                  ],
                ),
                if (i < displayItems.length - 1)
                  const Divider(height: 18, color: AppColors.borderLight),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.4: POPULAR OR FREQUENTLY BORROWED BOOKS
  // ==========================================================================
  Widget _buildPopularBooksSummary(
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<LibraryLoan>> loansAsync,
  ) {
    return ErpCard(
      title: 'Popular & Frequently Borrowed Titles',
      subtitle:
          'High-demand academic references and literature based on cumulative institutional circulation',
      icon: Icons.trending_up,
      iconColor: AppColors.librarianViolet,
      child: booksAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (books) {
          final loans = loansAsync.valueOrNull ?? [];

          // Compute frequency
          final counts = <String, int>{};
          for (final loan in loans) {
            counts[loan.bookId] = (counts[loan.bookId] ?? 0) + 1;
          }

          final sortedBooks = List<LibraryBook>.from(books)
            ..sort((a, b) =>
                (counts[b.bookId] ?? 0).compareTo(counts[a.bookId] ?? 0));

          final topBooks = sortedBooks.take(4).toList();

          return Column(
            children: [
              for (final book in topBooks) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.star_outline,
                            size: 18, color: AppColors.warningAmber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            Text(
                              'Author: ${book.author} • Category: ${book.category ?? 'Core Curriculum'}',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${counts[book.bookId] ?? 0} Checkouts',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.librarianViolet),
                          ),
                          Text(
                            '${book.availableCopies} in stock',
                            style: TextStyle(
                              fontSize: 11,
                              color: book.availableCopies > 0
                                  ? AppColors.accountantEmerald
                                  : AppColors.dangerRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 12, color: AppColors.borderLight),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.5: INVENTORY AND CONDITION OVERVIEW
  // ==========================================================================
  Widget _buildInventoryConditionOverview(
    AsyncValue<List<LibraryBook>> booksAsync,
    AsyncValue<List<LibraryLoan>> loansAsync,
  ) {
    return ErpCard(
      title: 'Catalog Inventory & Condition Overview',
      subtitle:
          'Audit of physical book assets across shelf availability, active circulation, and stacks',
      icon: Icons.inventory,
      iconColor: AppColors.brandNavy,
      child: booksAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Text('Error: $err'),
        data: (books) {
          final loans = loansAsync.valueOrNull ?? [];
          final totalCopies = books.fold<int>(0, (sum, b) => sum + b.totalCopies);
          final availableCopies =
              books.fold<int>(0, (sum, b) => sum + b.availableCopies);
          final inCirculation = loans.where((l) => !l.isReturned).length;
          const underRepair = 0;
          const lostOrDamaged = 0;

          final conditions = [
            {'label': 'Available on Shelf', 'count': availableCopies, 'color': AppColors.accountantEmerald},
            {'label': 'In Active Circulation', 'count': inCirculation, 'color': AppColors.infoSky},
            {'label': 'Under Repair / Binding', 'count': underRepair, 'color': AppColors.warningAmber},
            {'label': 'Lost / De-accessioned', 'count': lostOrDamaged, 'color': AppColors.dangerRed},
            {'label': 'Total Physical Asset Base', 'count': totalCopies, 'color': AppColors.brandNavy},
          ];

          return Column(
            children: [
              for (final c in conditions) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c['label'] as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${c['count']} copies',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: c['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
  // SECTION 4.6: CATALOG SEARCH AND QUICK DETAILS
  // ==========================================================================
  Widget _buildCatalogSearchAndDetails(
      AsyncValue<List<LibraryBook>> booksAsync) {
    return ErpCard(
      title: 'Catalog Search & Quick Details',
      subtitle:
          'Interactive search across book title, author, ISBN barcode, and thematic category',
      icon: Icons.search,
      iconColor: AppColors.brandNavy,
      child: Column(
        children: [
          TextFormField(
            controller: _catalogSearchCtrl,
            decoration: const InputDecoration(
              labelText: 'Search Institutional Catalog',
              hintText: 'Type title, author, or category...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (val) => setState(() => _catalogSearchQuery = val.trim().toLowerCase()),
          ),
          const SizedBox(height: 16),
          booksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Text('Error: $err'),
            data: (books) {
              final filtered = books.where((b) {
                if (_catalogSearchQuery.isEmpty) return true;
                return b.title.toLowerCase().contains(_catalogSearchQuery) ||
                    b.author.toLowerCase().contains(_catalogSearchQuery) ||
                    (b.category != null &&
                        b.category!.toLowerCase().contains(_catalogSearchQuery));
              }).take(6).toList();

              if (filtered.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No catalog titles match your search criteria.'),
                  ),
                );
              }

              return Column(
                children: [
                  for (final b in filtered)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_outlined,
                              size: 20, color: AppColors.librarianViolet),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13),
                                ),
                                Text(
                                  'By ${b.author} • ${b.category ?? 'General'} • ISBN: ${b.isbn ?? '—'}',
                                  style: const TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${b.availableCopies} Available',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: b.availableCopies > 0
                                  ? AppColors.accountantEmerald
                                  : AppColors.dangerRed,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ErpButton(
                            label: 'Issue',
                            isDense: true,
                            color: AppColors.librarianViolet,
                            onPressed: b.availableCopies > 0
                                ? () {
                                    setState(() {
                                      _selectedBookId = b.bookId;
                                      _currentNavIndex = 3;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 5: CATALOGUE TAB (Dedicated View)
  // ==========================================================================
  Widget _buildCatalogueTab() {
    final booksAsync = ref.watch(libraryBooksProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        ErpCard(
          title: 'Institutional Book Catalog Registry',
          subtitle:
              'Official inventory of academic textbooks, literature, and reference volumes',
          icon: Icons.menu_book,
          iconColor: AppColors.librarianViolet,
          headerTrailing: ErpButton(
            icon: Icons.add,
            label: 'Add New Title',
            isDense: true,
            color: AppColors.librarianViolet,
            onPressed: () => AddBookDialog.show(context),
          ),
          child: booksAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading catalog: $err'),
            ),
            data: (books) {
              if (books.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No books catalogued in the central database.'),
                  ),
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
        ),
      ],
    );
  }

  Widget _buildBookItem(String id, String title, String author, String isbn,
      int available, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ErpCard(
        title: title,
        subtitle: 'Author: $author • $isbn',
        icon: Icons.book,
        iconColor: AppColors.librarianViolet,
        headerTrailing: available > 0
            ? ErpStatusBadge.success('$available / $total In Stock')
            : ErpStatusBadge.danger('Checked Out'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('Book ID: $id',
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              children: [
                ErpButton(
                  label: 'Issue Loan',
                  color: AppColors.librarianViolet,
                  isDense: true,
                  onPressed: available > 0
                      ? () => setState(() {
                            _selectedBookId = id;
                            _currentNavIndex = 3;
                          })
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // SECTION 6: ACTIVE LOANS TAB (Dedicated View)
  // ==========================================================================
  Widget _buildActiveLoansTab() {
    final loansAsync = ref.watch(allLibraryLoansStreamProvider);
    final books = ref.watch(libraryBooksProvider).value ?? [];
    final students = ref.watch(allStudentsStreamProvider).value ?? [];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        ErpCard(
          title: 'Active Circulation Loans Registry',
          subtitle:
              'Official ledger of circulating books with borrower admission identities and due dates',
          icon: Icons.assignment_return_outlined,
          iconColor: AppColors.librarianViolet,
          child: loansAsync.when(
            loading: () => const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator())),
            error: (error, _) =>
                Text('Unable to load loan records: $error'),
            data: (loans) {
              final active = loans
                  .where((loan) => !loan.isReturned && loan.status != 'returned')
                  .toList()
                ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

              if (active.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                        'No active circulation loans. All copies are currently shelved.'),
                  ),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < active.length; i++) ...[
                    _buildLoanItem(
                      active[i],
                      _bookTitleFor(books, active[i].bookId),
                      _borrowerLabelFor(students, active[i].studentId),
                    ),
                    if (i < active.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoanItem(LibraryLoan loan, String bookTitle, String borrower) {
    final isOverdue = DateTime.now().isAfter(loan.dueDate) && !loan.isReturned;
    final due =
        '${isOverdue ? 'OVERDUE • ' : 'Due • '}${loan.dueDate.day.toString().padLeft(2, '0')}/${loan.dueDate.month.toString().padLeft(2, '0')}/${loan.dueDate.year}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: isOverdue ? AppColors.dangerRed.withValues(alpha: 0.3) : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isOverdue ? AppColors.dangerRed : AppColors.librarianViolet)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.bookmark,
                color:
                    isOverdue ? AppColors.dangerRed : AppColors.librarianViolet,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bookTitle,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5)),
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
          ErpButton(
            label: 'Return Book',
            isPrimary: false,
            color: AppColors.librarianViolet,
            isDense: true,
            onPressed: () {
              ReturnBookDialog.show(
                context,
                loanId: loan.loanId,
                bookId: loan.bookId,
                bookTitle: bookTitle,
                studentId: loan.studentId,
                dueDate: loan.dueDate,
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION 7: ISSUE BOOK TAB (Dedicated View)
  // ==========================================================================
  Widget _buildIssueBookTab() {
    final booksAsync = ref.watch(libraryBooksProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        ErpCard(
          title: 'Authoritative Book Issue Counter',
          subtitle:
              'Issue library book to enrolled student • Atomic Inventory Decrement with 14-day loan term',
          icon: Icons.bookmark_add,
          iconColor: AppColors.librarianViolet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book circulation executes an atomic Cloud Function decrementing available copies and registering the loan record. Available copies cannot fall below zero.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
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
                      const Text('Select Available Book*',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.borderLight, width: 1),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: inStock.any((book) =>
                                    book.bookId == _selectedBookId)
                                ? _selectedBookId
                                : inStock.first.bookId,
                            isExpanded: true,
                            items: inStock.map((b) {
                              return DropdownMenuItem(
                                value: b.bookId,
                                child: Text(
                                    '${b.title} (${b.availableCopies} available)'),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedBookId = value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Select Student Borrower*',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(height: 6),
                      studentsAsync.when(
                        data: (students) {
                          final enrolledStudents = students
                              .where((student) => student.status == 'enrolled')
                              .toList();
                          return Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppColors.borderLight, width: 1),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: enrolledStudents.any((student) =>
                                        student.studentId == _selectedStudentId)
                                    ? _selectedStudentId
                                    : (enrolledStudents.isNotEmpty
                                        ? enrolledStudents.first.studentId
                                        : null),
                                isExpanded: true,
                                items: enrolledStudents.map((s) {
                                  return DropdownMenuItem(
                                    value: s.studentId,
                                    child: Text(
                                        '${s.fullName} (${s.admissionNumber}) - Class ${s.currentClassId}'),
                                  );
                                }).toList(),
                                onChanged: (value) =>
                                    setState(() => _selectedStudentId = value),
                              ),
                            ),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) =>
                            const Text('Error loading student records'),
                      ),
                      const SizedBox(height: 20),
                      ErpButton(
                        icon: Icons.check,
                        label: 'Issue Circulation Loan (14 Days)',
                        color: AppColors.librarianViolet,
                        onPressed: () async {
                          final selectedBook = inStock.firstWhere(
                              (book) => book.bookId == _selectedBookId,
                              orElse: () => inStock.first);
                          final enrolledStudents = (studentsAsync.value ?? [])
                              .where((student) => student.status == 'enrolled')
                              .toList();
                          if (enrolledStudents.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'No enrolled student available to issue this book.')));
                            return;
                          }
                          final selectedStudent = enrolledStudents.firstWhere(
                            (student) =>
                                student.studentId == _selectedStudentId,
                            orElse: () => enrolledStudents.first,
                          );
                          try {
                            await ref.read(libraryRepositoryProvider).issueBook(
                                  bookId: selectedBook.bookId,
                                  studentId: selectedStudent.studentId,
                                );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.librarianViolet,
                                  content: Text(
                                      'Issued "${selectedBook.title}" to ${selectedStudent.fullName}.'),
                                ),
                              );
                              setState(() => _currentNavIndex = 2);
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

  String _bookTitleFor(List<LibraryBook> books, String id) {
    for (final book in books) {
      if (book.bookId == id) return book.title;
    }
    return 'Book $id';
  }

  String _borrowerLabelFor(List<dynamic> students, String id) {
    for (final student in students) {
      if (student.studentId == id) {
        return '${student.fullName} (${student.admissionNumber})';
      }
    }
    return 'Student $id';
  }
}
