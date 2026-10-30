import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/admission_application_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Admission Applications (All Applications)
/// Route: /admissions
class AdmissionsOverviewScreen extends ConsumerStatefulWidget {
  const AdmissionsOverviewScreen({super.key});

  @override
  ConsumerState<AdmissionsOverviewScreen> createState() =>
      _AdmissionsOverviewScreenState();
}

class _AdmissionsOverviewScreenState
    extends ConsumerState<AdmissionsOverviewScreen> {
  final _searchController = TextEditingController();
  String _filterClass = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleStatusChange(String id, String status) async {
    try {
      await ref.read(admissionRepositoryProvider).updateApplicationStatus(
            applicationId: id,
            status: status,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to $status'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    return ResponsiveScaffold(
      title: 'Admission Applications',
      currentRoute: AppRoutes.admissions,
      actions: [
        ErpButton(
          label: 'New Application',
          icon: Icons.add,
          isDense: true,
          onPressed: () => context.go(AppRoutes.admissionsApply),
        ),
      ],
      body: enquiriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.admissionsTeal),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $err',
                style: const TextStyle(color: AppColors.dangerRed)),
          ),
        ),
        data: (enquiries) {
          final q = _searchController.text.trim().toLowerCase();
          final filtered = enquiries.where((e) {
            final name = (e['applicantName'] ?? '').toString().toLowerCase();
            final phone = (e['phone'] ?? '').toString();
            final matchesSearch = q.isEmpty || name.contains(q) || phone.contains(q);
            final matchesClass = _filterClass == 'All' ||
                (e['targetClass'] ?? '').toString() == _filterClass;
            return matchesSearch && matchesClass;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Application Filter & Search',
                subtitle: 'Filter active candidates by academic grade or contact',
                child: Row(
                  children: [
                    Expanded(
                      child: ErpSearchBar(
                        controller: _searchController,
                        hintText: 'Search by applicant name or telephone...',
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
                title: 'Registered Applications (${filtered.length})',
                subtitle: 'Active candidates for AY 2026-2027 admissions cycle',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No applications match criteria.',
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
                          final app = filtered[idx];
                          final status = (app['status'] ?? 'enquiry').toString();
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.admissionsTeal.withValues(alpha: 0.1),
                              child: Text(
                                (app['applicantName'] ?? 'A').toString().isNotEmpty
                                    ? (app['applicantName'] ?? 'A')
                                        .toString()
                                        .substring(0, 1)
                                    : 'A',
                                style: const TextStyle(
                                    color: AppColors.admissionsTeal,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(
                              app['applicantName'] ?? 'Unknown Applicant',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                                'Class: ${app['targetClass'] ?? "N/A"} • Guardian: ${app['guardianName'] ?? "N/A"} • Tel: ${app['phone'] ?? "N/A"}'),
                            onTap: () =>
                                context.go('${AppRoutes.admissions}/${app['id']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                StatusBadge(
                                  label: status.toUpperCase().replaceAll('_', ' '),
                                  type: status == 'approved'
                                      ? StatusType.success
                                      : (status == 'rejected'
                                          ? StatusType.danger
                                          : StatusType.warning),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (val) {
                                    if (val == 'review') {
                                      context.go(
                                          '${AppRoutes.admissions}/${app['id']}');
                                    } else if (val == 'print') {
                                      final model = AdmissionApplication.fromMap(
                                          app['id'], app);
                                      PrintPreviewDialog.showAdmissionApplication(
                                          context,
                                          application: model);
                                    } else {
                                      _handleStatusChange(app['id'], val);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'review',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_note, size: 16),
                                          SizedBox(width: 8),
                                          Text('Review & Decision'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'print',
                                      child: Row(
                                        children: [
                                          Icon(Icons.print_outlined, size: 16),
                                          SizedBox(width: 8),
                                          Text('Print Preview Form'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                        value: 'under_review',
                                        child: Text('Mark Under Review')),
                                    const PopupMenuItem(
                                        value: 'documents_verified',
                                        child: Text('Mark Documents Verified')),
                                    const PopupMenuItem(
                                        value: 'approved',
                                        child: Text('Approve Admission')),
                                    const PopupMenuItem(
                                        value: 'rejected',
                                        child: Text('Reject Application')),
                                  ],
                                ),
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
