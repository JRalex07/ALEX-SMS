import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/add_book_dialog.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';

class LibraryResourceScreen extends ConsumerStatefulWidget {
  const LibraryResourceScreen({super.key});

  @override
  ConsumerState<LibraryResourceScreen> createState() =>
      _LibraryResourceScreenState();
}

class _LibraryResourceScreenState extends ConsumerState<LibraryResourceScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isLibrarian =
        role == UserRoles.librarian || role == UserRoles.schoolAdmin;

    final booksAsync = ref.watch(libraryBooksProvider);

    return ResponsiveScaffold(
      title: 'Institutional Library Catalog',
      currentRoute: '/library',
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
          final filteredBooks = books.where((b) {
            final q = _searchQuery.toLowerCase();
            return b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q) ||
                (b.isbn?.toLowerCase().contains(q) ?? false);
          }).toList();

          final totalVolumes =
              books.fold<int>(0, (sum, b) => sum + b.totalCopies);
          final availableVolumes =
              books.fold<int>(0, (sum, b) => sum + b.availableCopies);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
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
                      subtitle:
                          '${totalVolumes - availableVolumes} Currently Issued',
                      icon: Icons.assignment_return_outlined,
                      iconColor: AppColors.parentBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Search Bar
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText:
                                'Search by book title, author, or ISBN...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      if (isLibrarian) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Book to Catalog'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.librarianViolet,
                          ),
                          onPressed: () => AddBookDialog.show(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Catalog List
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
                            '${filteredBooks.length} Titles Listed',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.download, size: 16),
                            label: const Text('Export Catalogue (CSV)'),
                            onPressed: () =>
                                DataExportService.exportLibraryBooksCsv(
                                    filteredBooks),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (filteredBooks.isEmpty)
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
                          itemCount: filteredBooks.length,
                          separatorBuilder: (_, __) => const Divider(
                              height: 1, color: AppColors.borderLight),
                          itemBuilder: (ctx, idx) {
                            final b = filteredBooks[idx];
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
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
        },
      ),
    );
  }
}
