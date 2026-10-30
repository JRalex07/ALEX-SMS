import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Student Directory (All Students)
/// Route: /students
class StudentDirectoryScreen extends ConsumerStatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  ConsumerState<StudentDirectoryScreen> createState() =>
      _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState
    extends ConsumerState<StudentDirectoryScreen> {
  final _searchController = TextEditingController();
  String _filterClass = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isParent = role == UserRoles.parentGuardian;

    final studentsAsync = isParent
        ? ref.watch(parentLinkedChildrenProvider)
        : ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Student Directory',
      currentRoute: AppRoutes.students,
      actions: [
        if (!isParent)
          ErpButton(
            label: 'Add Student',
            icon: Icons.person_add_outlined,
            isDense: true,
            onPressed: () => context.go(AppRoutes.studentAdd),
          ),
      ],
      body: studentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.dangerRed),
                const SizedBox(height: 12),
                Text('Error loading students: $err',
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (students) {
          final filtered = students.where((s) {
            final q = _searchController.text.toLowerCase();
            final matchesQuery = s.fullName.toLowerCase().contains(q) ||
                s.admissionNumber.toLowerCase().contains(q);
            final matchesClass =
                _filterClass == 'All' || s.currentClassId == _filterClass;
            return matchesQuery && matchesClass;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Search & Filter Bar
              Row(
                children: [
                  Expanded(
                    child: ErpSearchBar(
                      controller: _searchController,
                      hintText: 'Search by student name or admission number...',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterClass,
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                        items: ['All', 'CLASS_1', 'CLASS_2', 'CLASS_5', 'CLASS_9', 'CLASS_10', '1', '2', '5', '9', '10']
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c == 'All' ? 'All Classes' : 'Class $c'),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _filterClass = val);
                        },
                      ),
                    ),
                  ),
                  if (!isParent) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Export CSV'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => DataExportService.exportStudents(context, filtered),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Student Data View / Cards
              if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No students found matching your criteria.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final s = filtered[idx];
                    return ErpCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.brandNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandNavy,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        s.fullName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(
                                      label: s.status.toUpperCase(),
                                      type: s.status == 'enrolled'
                                          ? StatusType.success
                                          : StatusType.neutral,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Adm No: ${s.admissionNumber} • Class: ${s.currentClassId} (${s.currentSectionId})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.badge_outlined, size: 14),
                                label: const Text('Profile'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => context.go('/students/${s.studentId}'),
                              ),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                                label: const Text('Record PDF'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => PrintPreviewDialog.showStudentProfile(context, student: s),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
