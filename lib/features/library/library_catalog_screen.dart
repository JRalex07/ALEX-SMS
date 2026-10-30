import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Library Book Catalog
/// Route: /library
class LibraryCatalogScreen extends ConsumerStatefulWidget {
  const LibraryCatalogScreen({super.key});

  @override
  ConsumerState<LibraryCatalogScreen> createState() =>
      _LibraryCatalogScreenState();
}

class _LibraryCatalogScreenState extends ConsumerState<LibraryCatalogScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(allBooksStreamProvider);
    final user = ref.watch(currentUserProfileProvider).value;
    final isLibrarian = user?.role == UserRoles.librarian ||
        user?.role == UserRoles.schoolAdmin;

    return ResponsiveScaffold(
      title: 'Library Book Catalog',
      currentRoute: AppRoutes.library,
      actions: [
        if (isLibrarian) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.assignment_return_outlined, size: 16),
            label: const Text('Issue / Return'),
            onPressed: () => context.go(AppRoutes.libraryIssue),
          ),
          const SizedBox(width: 8),
          ErpButton(
            label: 'Add Book',
            icon: Icons.add,
            isDense: true,
            onPressed: () => context.go(AppRoutes.libraryAdd),
          ),
        ],
      ],
      body: booksAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (books) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = books.where((b) {
            final matchesQuery = query.isEmpty ||
                b.title.toLowerCase().contains(query) ||
                b.author.toLowerCase().contains(query) ||
                (b.isbn?.toLowerCase().contains(query) ?? false);
            return matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Library Catalog & Inventory Register',
                subtitle:
                    'Searchable database of curriculum textbooks, journals, fiction, and reference volumes',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search by title, author, or ISBN...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Books in Repository (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No books found.',
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
                          final book = filtered[idx];
                          final isAvailable = book.availableCopies > 0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: const Icon(Icons.menu_book,
                                  color: AppColors.brandNavy),
                            ),
                            title: Text(book.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Author: ${book.author} • ISBN: ${book.isbn}\n'
                                'Copies Available: ${book.availableCopies} of ${book.totalCopies}'),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(
                                  label: isAvailable
                                      ? 'AVAILABLE (${book.availableCopies})'
                                      : 'BORROWED OUT',
                                  type: isAvailable
                                      ? StatusType.success
                                      : StatusType.danger,
                                ),
                                if (isLibrarian && isAvailable) ...[
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.libraryIssue),
                                    child: const Text('Issue'),
                                  ),
                                ],
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
