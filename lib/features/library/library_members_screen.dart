import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Library Members & Borrowing Privilege
/// Route: /library/members
class LibraryMembersScreen extends ConsumerStatefulWidget {
  const LibraryMembersScreen({super.key});

  @override
  ConsumerState<LibraryMembersScreen> createState() =>
      _LibraryMembersScreenState();
}

class _LibraryMembersScreenState extends ConsumerState<LibraryMembersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsStreamProvider);
    final activeLoansAsync = ref.watch(activeLoansStreamProvider);

    return ResponsiveScaffold(
      title: 'Library Members & Borrowing Privilege',
      currentRoute: AppRoutes.libraryMembers,
      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final loans = activeLoansAsync.value ?? [];
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            return query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Library Membership Cards & Barcode Directory',
                subtitle:
                    'Audit student borrower quotas, active cards, and borrowing clearances',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search member by pupil name or admission number...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Registered Member Pupils (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No members found matching search.',
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
                          final studentLoans = loans
                              .where((l) =>
                                  l.studentId == s.studentId &&
                                  l.status == 'active')
                              .toList();

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: const Icon(Icons.card_membership,
                                  color: AppColors.brandNavy),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              'Card ID: LIB-${s.admissionNumber} • Standard: Class ${s.currentClassId}-${s.currentSectionId}\n'
                              'Books Checked Out: ${studentLoans.length} / 2 Maximum Allowance',
                            ),
                            isThreeLine: true,
                            trailing: OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Inspecting borrowing history for ${s.fullName}')),
                                );
                              },
                              child: const Text('History Dossier'),
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
