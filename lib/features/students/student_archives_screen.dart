import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Student Status & Historical Archives
/// Route: /students/archives
class StudentArchivesScreen extends ConsumerStatefulWidget {
  const StudentArchivesScreen({super.key});

  @override
  ConsumerState<StudentArchivesScreen> createState() =>
      _StudentArchivesScreenState();
}

class _StudentArchivesScreenState extends ConsumerState<StudentArchivesScreen> {
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
      title: 'Student Status & Historical Archives',
      currentRoute: AppRoutes.studentArchives,
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final archived = students.where((s) {
            final isArchived =
                s.status == 'withdrawn' || s.status == 'archived' || s.status == 'alumni';
            final matchesQuery = query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
            return isArchived && matchesQuery;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Permanent Archive Registry',
                subtitle:
                    'Historical alumni, transferred-out, or withdrawn student files retained under institutional compliance',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search archived student by name or admission number...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Archived Student Records (${archived.length})',
                subtitle: 'Read-only preservation records',
                child: archived.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No archived or withdrawn student records found for the current institutional database.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: archived.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final s = archived[idx];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceMuted,
                              child: Icon(Icons.archive_outlined,
                                  color: AppColors.textSecondary),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Adm #${s.admissionNumber} • Last Standard: Class ${s.currentClassId}-${s.currentSectionId} • Year: ${s.currentAcademicYearId}'),
                            trailing: StatusBadge(
                              label: s.status.toUpperCase(),
                              type: StatusType.neutral,
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
