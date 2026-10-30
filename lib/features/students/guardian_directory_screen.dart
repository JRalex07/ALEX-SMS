import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent/Guardian Directory
/// Route: /students/guardians
class GuardianDirectoryScreen extends ConsumerStatefulWidget {
  const GuardianDirectoryScreen({super.key});

  @override
  ConsumerState<GuardianDirectoryScreen> createState() =>
      _GuardianDirectoryScreenState();
}

class _GuardianDirectoryScreenState
    extends ConsumerState<GuardianDirectoryScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Parent/Guardian Directory',
      currentRoute: AppRoutes.studentGuardians,
      actions: [
        ErpButton(
          label: 'Link Guardian',
          icon: Icons.link,
          isDense: true,
          onPressed: () => context.go(AppRoutes.studentLinkGuardians),
        ),
      ],
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            final matchesQuery = query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query) ||
                (s.emergencyContact?.toLowerCase().contains(query) ?? false);
            return matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Guardian Information & Verified Contacts',
                subtitle:
                    'Master phone directory and ward linkage verification index',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search by student name, admission number, or emergency phone...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Family Units & Linked Guardians (${filtered.length})',
                subtitle: 'Active student family connections',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No guardian records found.',
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
                          final hasGuardians = s.guardianUserIds.isNotEmpty;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: hasGuardians
                                  ? AppColors.brandNavy.withValues(alpha: 0.1)
                                  : AppColors.warningAmber.withValues(alpha: 0.15),
                              child: Icon(
                                hasGuardians
                                    ? Icons.family_restroom
                                    : Icons.person_off_outlined,
                                color: hasGuardians
                                    ? AppColors.brandNavy
                                    : AppColors.warningAmber,
                              ),
                            ),
                            title: Text(
                              s.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Ward: Class ${s.currentClassId}-${s.currentSectionId} (Adm #${s.admissionNumber})\n'
                              'Verified Emergency Phone: ${s.emergencyContact ?? "Unregistered"}\n'
                              'Linked Account IDs: ${hasGuardians ? s.guardianUserIds.join(", ") : "Pending verification"}',
                            ),
                            isThreeLine: true,
                            trailing: OutlinedButton.icon(
                              icon: const Icon(Icons.link, size: 14),
                              label: const Text('Manage Link'),
                              onPressed: () =>
                                  context.go(AppRoutes.studentLinkGuardians),
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
