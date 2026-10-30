import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../models/library_model.dart';
import '../../models/student_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/add_book_dialog.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';

class LibraryResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? loanId;

  const LibraryResourceScreen({
    super.key,
    this.initialTab,
    this.loanId,
  });

  @override
  ConsumerState<LibraryResourceScreen> createState() =>
      _LibraryResourceScreenState();
}

class _LibraryResourceScreenState extends ConsumerState<LibraryResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<String> _librarianTabs = [
    'Catalog',
    'Circulation Desk',
    'Active Loans',
    'Overdue & Fines',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'issue':
        case 'return':
        case 'circulation':
          initialIndex = 1;
          break;
        case 'loans':
          initialIndex = 2;
          break;
        case 'overdue':
        case 'fines':
          initialIndex = 3;
          break;
        case 'reports':
          initialIndex = 4;
          break;
        default:
          initialIndex = 0;
      }
    }
    _tabController = TabController(
      length: _librarianTabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(covariant LibraryResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int targetIndex = 0;
      switch (widget.initialTab) {
        case 'issue':
        case 'return':
        case 'circulation':
          targetIndex = 1;
          break;
        case 'loans':
          targetIndex = 2;
          break;
        case 'overdue':
        case 'fines':
          targetIndex = 3;
          break;
        case 'reports':
          targetIndex = 4;
          break;
        default:
          targetIndex = 0;
      }
      if (_tabController.index != targetIndex) {
        _tabController.animateTo(targetIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isLibrarian =
        role == UserRoles.librarian || role == UserRoles.schoolAdmin;

    final booksAsync = ref.watch(libraryBooksProvider);

    return ResponsiveScaffold(
      title: 'Central Library Catalog & Circulation',
      currentRoute: AppRoutes.library,
      actions: [
        if (isLibrarian) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Print Report'),
            onPressed: () {
              final books = booksAsync.value ?? [];
              final loans =
                  ref.read(allLibraryLoansStreamProvider).value ?? [];
              PrintPreviewDialog.showLibraryReport(context,
                  books: books, loans: loans);
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.assignment_return, size: 16),
            label: const Text('Return Book'),
            onPressed: () => _tabController.animateTo(2),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.bookmark_add, size: 16),
            label: const Text('Add Title'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.librarianViolet,
              foregroundColor: Colors.white,
            ),
            onPressed: () => AddBookDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ],
      body: booksAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error loading library catalogue: $err',
              style: const TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ),
        data: (books) {
          if (!isLibrarian) {
            return _buildGeneralCatalogView(books);
          }

          return Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppColors.librarianViolet,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.librarianViolet,
                  tabs: _librarianTabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderLight),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCatalogTab(books),
                    _buildCirculationTab(books),
                    _buildLoansTab(),
                    _buildOverdueTab(),
                    _buildReportsTab(books),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralCatalogView(List<LibraryBook> books) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildMetricsOverview(books),
        const SizedBox(height: 20),
        _buildCatalogSearchAndList(books, isLibrarian: false),
      ],
    );
  }

  Widget _buildCatalogTab(List<LibraryBook> books) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildMetricsOverview(books),
        const SizedBox(height: 20),
        _buildCatalogSearchAndList(books, isLibrarian: true),
      ],
    );
  }

  Widget _buildCirculationTab(List<LibraryBook> books) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Immediate Circulation Desk',
          subtitle:
              'Check out titles to authorized students and staff or process returns',
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.assignment_return, size: 16),
                    label: const Text('Process Book Return'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _tabController.animateTo(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.assignment_returned, size: 16),
                    label: const Text('Issue Book to Student'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.librarianViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _tabController.animateTo(0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoansTab() {
    final loansAsync = ref.watch(allLibraryLoansStreamProvider);
    final booksAsync = ref.watch(libraryBooksProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading active loans: $err'),
          data: (loans) {
            final activeLoans = loans
                .where((l) => l.status == 'issued' || l.status == 'active')
                .toList();
            final books = booksAsync.value ?? [];
            final students = studentsAsync.value ?? [];

            return ErpCard(
              title: 'Active Borrower Loans (${activeLoans.length})',
              subtitle:
                  'Current borrowings tracked against physical accession copies',
              child: activeLoans.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No active book loans recorded.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeLoans.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final loan = activeLoans[idx];
                        final bookTitle = _bookTitleFor(books, loan.bookId);
                        final borrower =
                            _borrowerLabelFor(students, loan.studentId);

                        return ListTile(
                          title: Text(bookTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Borrower: $borrower • Due: ${loan.dueDate.toLocal().toString().split(" ").first}'),
                          trailing: OutlinedButton(
                            child: const Text('Return'),
                            onPressed: () => ReturnBookDialog.show(
                              context,
                              loanId: loan.loanId,
                              bookId: loan.bookId,
                              bookTitle: bookTitle,
                              studentId: loan.studentId,
                              dueDate: loan.dueDate,
                            ),
                          ),
                        );
                      },
                    ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverdueTab() {
    final loansAsync = ref.watch(allLibraryLoansStreamProvider);
    final booksAsync = ref.watch(libraryBooksProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        loansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text('Error loading loans: $err'),
          data: (loans) {
            final overdue = loans
                .where((l) =>
                    (l.status == 'issued' || l.status == 'active') &&
                    l.dueDate.isBefore(DateTime.now()))
                .toList();
            final books = booksAsync.value ?? [];
            final students = studentsAsync.value ?? [];

            return ErpCard(
              title: 'Overdue Loans & Fine Assessments (${overdue.length})',
              subtitle:
                  'Statutory fine assessed at ₹2.00 per day (200 paise) past due date',
              child: overdue.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No loans currently overdue.',
                            style: TextStyle(color: AppColors.successGreen)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: overdue.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final loan = overdue[idx];
                        final daysPast =
                            DateTime.now().difference(loan.dueDate).inDays;
                        final finePaise = daysPast * 200;
                        final bookTitle = _bookTitleFor(books, loan.bookId);
                        final borrower =
                            _borrowerLabelFor(students, loan.studentId);

                        return ListTile(
                          title: Text(bookTitle,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'Borrower: $borrower • $daysPast days overdue'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${(finePaise / 100).toStringAsFixed(2)} fine',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.dangerRed),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton(
                                child: const Text('Process Return'),
                                onPressed: () => ReturnBookDialog.show(
                                  context,
                                  loanId: loan.loanId,
                                  bookId: loan.bookId,
                                  bookTitle: bookTitle,
                                  studentId: loan.studentId,
                                  dueDate: loan.dueDate,
                                ),
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
    );
  }

  Widget _buildReportsTab(List<LibraryBook> books) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Institutional Library Reports',
          subtitle:
              'Audit summaries for physical volumes, accession, and losses',
          child: Column(
            children: [
              ListTile(
                leading:
                    const Icon(Icons.print, color: AppColors.librarianViolet),
                title: const Text('Export Complete Catalog (CSV)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle:
                    const Text('Includes all ISBNs, volumes, and authors'),
                trailing: OutlinedButton(
                  onPressed: () =>
                      DataExportService.exportLibraryBooksCsv(books),
                  child: const Text('Export CSV'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsOverview(List<LibraryBook> books) {
    final totalVolumes = books.fold<int>(0, (sum, b) => sum + b.totalCopies);
    final availableVolumes =
        books.fold<int>(0, (sum, b) => sum + b.availableCopies);

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Catalog Titles',
            value: '${books.length} Titles',
            subtitle: '$totalVolumes Total Physical Volumes',
            icon: Icons.local_library_outlined,
            iconColor: AppColors.librarianViolet,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Available Volumes',
            value: '$availableVolumes In Stock',
            subtitle: '${totalVolumes - availableVolumes} Currently Issued',
            icon: Icons.assignment_return_outlined,
            iconColor: AppColors.parentBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogSearchAndList(List<LibraryBook> books,
      {required bool isLibrarian}) {
    final filtered = books.where((b) {
      final q = _searchController.text.toLowerCase();
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          (b.isbn?.toLowerCase().contains(q) ?? false);
    }).toList();

    return Column(
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by book title, author, or ISBN...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} Titles Listed',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Export Catalogue (CSV)'),
                      onPressed: () =>
                          DataExportService.exportLibraryBooksCsv(filtered),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'No library books found in catalogue.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (ctx, idx) {
                      final b = filtered[idx];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.librarianViolet
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.book,
                              color: AppColors.librarianViolet, size: 20),
                        ),
                        title: Text(b.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'Author: ${b.author}${b.isbn != null ? " • ISBN: ${b.isbn}" : ""}'),
                        trailing: Text(
                          '${b.availableCopies} / ${b.totalCopies} available',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: b.availableCopies > 0
                                ? AppColors.successGreen
                                : AppColors.dangerRed,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _bookTitleFor(List<LibraryBook> books, String id) {
    for (final book in books) {
      if (book.bookId == id) return book.title;
    }
    return 'Book ID: $id';
  }

  String _borrowerLabelFor(List<Student> students, String id) {
    for (final student in students) {
      if (student.studentId == id) {
        return '${student.fullName} (${student.admissionNumber})';
      }
    }
    return 'Student ID: $id';
  }
}
