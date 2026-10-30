import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../models/admission_application_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/print_preview_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class AdmissionsResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;
  final String? applicationId;

  const AdmissionsResourceScreen({
    super.key,
    this.initialTab,
    this.applicationId,
  });

  @override
  ConsumerState<AdmissionsResourceScreen> createState() =>
      _AdmissionsResourceScreenState();
}

class _AdmissionsResourceScreenState
    extends ConsumerState<AdmissionsResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filterClass = 'All';

  final List<String> _tabs = [
    'Applications',
    'Review Queue',
    'Verification',
    'Decisions',
    'Enrollment',
    'Reports',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab != null) {
      switch (widget.initialTab) {
        case 'review':
          initialIndex = 1;
          break;
        case 'verification':
          initialIndex = 2;
          break;
        case 'decisions':
          initialIndex = 3;
          break;
        case 'enrollment':
          initialIndex = 4;
          break;
        case 'reports':
          initialIndex = 5;
          break;
        default:
          initialIndex = 0;
      }
    }
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(covariant AdmissionsResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      int targetIndex = 0;
      switch (widget.initialTab) {
        case 'review':
          targetIndex = 1;
          break;
        case 'verification':
          targetIndex = 2;
          break;
        case 'decisions':
          targetIndex = 3;
          break;
        case 'enrollment':
          targetIndex = 4;
          break;
        case 'reports':
          targetIndex = 5;
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
    final isAuthorized =
        role == UserRoles.schoolAdmin || role == UserRoles.admissionsOfficer;

    if (!isAuthorized) {
      return const ResponsiveScaffold(
        title: 'Access Restricted',
        currentRoute: AppRoutes.admissions,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, size: 56, color: AppColors.dangerRed),
                SizedBox(height: 16),
                Text(
                  '403 Forbidden: Admissions Module Restricted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Access to the applicant registry and admissions processing desk is restricted to Admissions Officers and Administrators.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    return ResponsiveScaffold(
      title: 'Admissions & Enrollment Desk',
      currentRoute: AppRoutes.admissions,
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Application'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.admissionsTeal,
            foregroundColor: Colors.white,
          ),
          onPressed: () => context.go(AppRoutes.admissionsApply),
        ),
        const SizedBox(width: 8),
      ],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.admissionsTeal,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.admissionsTeal,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: enquiriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading admission records: $err',
                      style: const TextStyle(color: AppColors.dangerRed)),
                ),
              ),
              data: (enquiries) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllApplicationsTab(enquiries),
                    _buildReviewQueueTab(enquiries),
                    _buildVerificationTab(enquiries),
                    _buildDecisionsTab(enquiries),
                    _buildEnrollmentTab(enquiries),
                    _buildReportsTab(enquiries),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllApplicationsTab(List<Map<String, dynamic>> enquiries) {
    final filtered = enquiries.where((e) {
      final name = (e['applicantName'] ?? '').toString().toLowerCase();
      final phone = (e['phone'] ?? '').toString();
      final q = _searchController.text.toLowerCase();
      final matchesSearch = name.contains(q) || phone.contains(q);
      final matchesClass = _filterClass == 'All' ||
          (e['targetClass'] ?? '').toString() == _filterClass;
      return matchesSearch && matchesClass;
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildFilterHeader(),
        const SizedBox(height: 16),
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
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final app = filtered[idx];
                    final status = (app['status'] ?? 'enquiry').toString();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 4),
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
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                          'Class: ${app['targetClass'] ?? "N/A"} • Guardian: ${app['guardianName'] ?? "N/A"} • Tel: ${app['phone'] ?? "N/A"}'),
                      onTap: () =>
                          context.go('${AppRoutes.admissions}/${app['id']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(status),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            onSelected: (val) {
                              if (val == 'review') {
                                context
                                    .go('${AppRoutes.admissions}/${app['id']}');
                              } else if (val == 'print') {
                                final model = AdmissionApplication.fromMap(
                                    app['id'], app);
                                PrintPreviewDialog.showAdmissionApplication(
                                    context,
                                    application: model);
                              } else {
                                _handleApplicationStatusChange(app['id'], val);
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
  }

  Widget _buildReviewQueueTab(List<Map<String, dynamic>> enquiries) {
    final queue = enquiries
        .where((e) =>
            e['status'] == 'enquiry' ||
            e['status'] == 'applied' ||
            e['status'] == 'under_review')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Review Queue (${queue.length} Pending)',
          subtitle: 'Applications awaiting review and admission screening',
          child: queue.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('Review queue is clear.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: queue.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final app = queue[idx];
                    return ListTile(
                      title: Text(app['applicantName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          'Target: Class ${app['targetClass']} • Phone: ${app['phone']} • Notes: ${app['notes'] ?? "None"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.check, size: 14),
                            label: const Text('Accept for Review'),
                            onPressed: () => _handleApplicationStatusChange(
                                app['id'], 'under_review'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.fact_check, size: 14),
                            label: const Text('Verify Docs'),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.admissionsTeal),
                            onPressed: () => _handleApplicationStatusChange(
                                app['id'], 'documents_verified'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildVerificationTab(List<Map<String, dynamic>> enquiries) {
    final docsQueue = enquiries
        .where((e) =>
            e['status'] == 'under_review' ||
            e['status'] == 'documents_verified')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Mandatory Document Verification',
          subtitle:
              'Check verification status for statutory KYC and academic records',
          child: docsQueue.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No candidates currently in verification.',
                          style: TextStyle(color: AppColors.textMuted))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docsQueue.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final app = docsQueue[idx];
                    final isVerified = app['status'] == 'documents_verified';
                    return ListTile(
                      title: Text(app['applicantName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text(
                          'Required: Birth Certificate, TC, Previous Marksheet, Aadhar Card'),
                      trailing: isVerified
                          ? const Chip(
                              label: Text('Verified',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              backgroundColor: AppColors.successGreen,
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.admissionsTeal),
                              onPressed: () => _handleApplicationStatusChange(
                                  app['id'], 'documents_verified'),
                              child: const Text('Verify All Documents'),
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDecisionsTab(List<Map<String, dynamic>> enquiries) {
    final decisionsList = enquiries
        .where((e) =>
            e['status'] == 'documents_verified' || e['status'] == 'approved')
        .toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Admission Decision Desk',
          subtitle: 'Grant formal admission approvals or record decisions',
          child: decisionsList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                      child: Text('No candidates awaiting admission decision.',
                          style: TextStyle(color: AppColors.textMuted))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: decisionsList.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final app = decisionsList[idx];
                    final isApproved = app['status'] == 'approved';
                    return ListTile(
                      title: Text(app['applicantName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          'Candidate for Class ${app['targetClass']} • Guardian: ${app['guardianName']}'),
                      trailing: isApproved
                          ? const Chip(
                              label: Text('Approved',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                              backgroundColor: AppColors.successGreen,
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.dangerRed),
                                  onPressed: () =>
                                      _handleApplicationStatusChange(
                                          app['id'], 'rejected'),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.successGreen),
                                  onPressed: () =>
                                      _handleApplicationStatusChange(
                                          app['id'], 'approved'),
                                  child: const Text('Approve Admission'),
                                ),
                              ],
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEnrollmentTab(List<Map<String, dynamic>> enquiries) {
    final approvedList =
        enquiries.where((e) => e['status'] == 'approved').toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Enrollment Register (${approvedList.length} Approved)',
          subtitle:
              'Assign admission numbers and class/section placements to finalized candidates',
          child: approvedList.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text('No approved candidates pending enrollment.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: approvedList.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final app = approvedList[idx];
                    return ListTile(
                      title: Text(app['applicantName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          'Target: Class ${app['targetClass']} • Phone: ${app['phone']}'),
                      trailing: FilledButton.icon(
                        icon: const Icon(Icons.how_to_reg, size: 16),
                        label: const Text('Complete Enrollment'),
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandNavy),
                        onPressed: () => _showEnrollStudentDialog(app),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(List<Map<String, dynamic>> enquiries) {
    final total = enquiries.length;
    final underReview =
        enquiries.where((e) => e['status'] == 'under_review').length;
    final verified =
        enquiries.where((e) => e['status'] == 'documents_verified').length;
    final approved = enquiries.where((e) => e['status'] == 'approved').length;
    final enrolled = enquiries.where((e) => e['status'] == 'enrolled').length;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ErpCard(
          title: 'Admissions Pipeline Funnel (AY 2026-2027)',
          subtitle: 'Progressive conversion across admission lifecycle stages',
          child: Column(
            children: [
              _buildFunnelRow('1. Received Applications', total,
                  Colors.blueGrey, total == 0 ? 0 : 1.0),
              _buildFunnelRow('2. Under Review', underReview, Colors.indigo,
                  total == 0 ? 0 : underReview / total),
              _buildFunnelRow('3. Documents Verified', verified, Colors.teal,
                  total == 0 ? 0 : verified / total),
              _buildFunnelRow('4. Approved Admissions', approved, Colors.green,
                  total == 0 ? 0 : approved / total),
              _buildFunnelRow('5. Final Enrolled', enrolled,
                  AppColors.brandNavy, total == 0 ? 0 : enrolled / total),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunnelRow(
      String label, int count, Color color, double fraction) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('$count candidates',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Card(
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
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by applicant name or phone...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    String label;
    switch (status) {
      case 'approved':
        bg = AppColors.successGreen;
        label = 'Approved';
        break;
      case 'documents_verified':
        bg = AppColors.admissionsTeal;
        label = 'Docs Verified';
        break;
      case 'under_review':
        bg = Colors.amber.shade700;
        label = 'Under Review';
        break;
      case 'enrolled':
        bg = AppColors.brandNavy;
        label = 'Enrolled';
        break;
      case 'rejected':
        bg = AppColors.dangerRed;
        label = 'Rejected';
        break;
      default:
        bg = Colors.blueGrey;
        label = 'Enquiry';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bg.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: bg, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }

  Future<void> _handleApplicationStatusChange(
      String? id, String newStatus) async {
    if (id == null) return;
    try {
      final repo = ref.read(studentRepositoryProvider);
      await repo.updateApplicationStatus(
        enquiryId: id,
        newStatus: newStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application updated to: $newStatus')),
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

  Future<void> _showEnrollStudentDialog(Map<String, dynamic> app) async {
    final admNoController = TextEditingController(
        text: 'ADM-2026-${DateTime.now().millisecondsSinceEpoch % 10000}');
    String targetClass = app['targetClass'] ?? '10';
    String targetSection = 'A';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Student Enrollment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Applicant: ${app['applicantName']}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: admNoController,
              decoration: const InputDecoration(
                labelText: 'Admission Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: targetClass,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                    ),
                    items: ['6', '7', '8', '9', '10']
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text('Class $c')))
                        .toList(),
                    onChanged: (v) => targetClass = v ?? targetClass,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: targetSection,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                    ),
                    items: ['A', 'B', 'C']
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text('Section $s')))
                        .toList(),
                    onChanged: (v) => targetSection = v ?? targetSection,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandNavy),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Enrollment'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = ref.read(studentRepositoryProvider);
        final newStudent = Student(
          studentId: 'STU_${DateTime.now().millisecondsSinceEpoch}',
          admissionNumber: admNoController.text.trim(),
          fullName: app['applicantName'] ?? 'Enrolled Student',
          currentClassId: targetClass,
          currentSectionId: targetSection,
          currentAcademicYearId: 'AY_2026_2027',
          status: 'enrolled',
          emergencyContact: app['phone'] ?? '',
        );

        await repo.enrollStudent(newStudent);
        await repo.updateApplicationStatus(
          enquiryId: app['id'],
          newStatus: 'enrolled',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Enrolled ${newStudent.fullName} as ${newStudent.admissionNumber}!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Enrollment failed: $e'),
              backgroundColor: AppColors.dangerRed,
            ),
          );
        }
      }
    }
  }
}
