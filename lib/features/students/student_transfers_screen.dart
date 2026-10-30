import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Class & Section Transfers
/// Route: /students/transfers
class StudentTransfersScreen extends ConsumerStatefulWidget {
  const StudentTransfersScreen({super.key});

  @override
  ConsumerState<StudentTransfersScreen> createState() =>
      _StudentTransfersScreenState();
}

class _StudentTransfersScreenState
    extends ConsumerState<StudentTransfersScreen> {
  final _searchController = TextEditingController();
  String _filterClass = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Class & Section Transfers',
      currentRoute: AppRoutes.studentTransfers,
      actions: [
        ErpButton(
          label: 'Initiate Transfer',
          icon: Icons.swap_horiz,
          isDense: true,
          onPressed: () => TransferStudentDialog.show(context),
        ),
      ],
      body: allStudentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error loading students: $err')),
        data: (students) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = students.where((s) {
            final matchesQuery = query.isEmpty ||
                s.fullName.toLowerCase().contains(query) ||
                s.admissionNumber.toLowerCase().contains(query);
            final matchesClass =
                _filterClass == 'All' || s.currentClassId == _filterClass;
            return matchesQuery && matchesClass;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Section & Class Transfer Protocol',
                subtitle:
                    'Reassign students between sections (e.g. 10-A to 10-B) or academic streams',
                child: Row(
                  children: [
                    Expanded(
                      child: ErpSearchBar(
                        controller: _searchController,
                        hintText: 'Search student to transfer...',
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _filterClass,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All Classes')),
                        DropdownMenuItem(value: '10', child: Text('Class 10')),
                        DropdownMenuItem(value: '9', child: Text('Class 9')),
                        DropdownMenuItem(value: '8', child: Text('Class 8')),
                        DropdownMenuItem(value: '7', child: Text('Class 7')),
                        DropdownMenuItem(value: '6', child: Text('Class 6')),
                      ],
                      onChanged: (v) => setState(() => _filterClass = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Eligible Enrolled Students (${filtered.length})',
                subtitle:
                    'Select a student to modify their academic section or branch',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No students match filter criteria.',
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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: Text(
                                s.fullName.isNotEmpty ? s.fullName[0] : 'S',
                                style: const TextStyle(
                                    color: AppColors.brandNavy,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(s.fullName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                'Adm: ${s.admissionNumber} • Current Standard: Class ${s.currentClassId}-${s.currentSectionId}'),
                            trailing: OutlinedButton.icon(
                              icon: const Icon(Icons.swap_horiz, size: 14),
                              label: const Text('Transfer Section'),
                              onPressed: () =>
                                  TransferStudentDialog.show(context),
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
