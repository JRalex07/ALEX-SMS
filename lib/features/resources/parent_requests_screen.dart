import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/dialogs/parent_portal_dialogs.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class ParentRequestsResourceScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const ParentRequestsResourceScreen({super.key, this.initialTab});

  @override
  ConsumerState<ParentRequestsResourceScreen> createState() =>
      _ParentRequestsResourceScreenState();
}

class _ParentRequestsResourceScreenState
    extends ConsumerState<ParentRequestsResourceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local state for submitted leave applications
  final List<Map<String, dynamic>> _leaveApplications = [
    {
      'id': 'LV_2026_01',
      'startDate': '2026-11-03',
      'endDate': '2026-11-05',
      'reason': 'Medical — Viral fever recovery',
      'status': 'Approved',
      'appliedOn': '2026-10-25',
    },
    {
      'id': 'LV_2026_02',
      'startDate': '2026-11-14',
      'endDate': '2026-11-15',
      'reason': 'Family event — Out of city',
      'status': 'Pending Approval',
      'appliedOn': '2026-10-27',
    },
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTab == 'support') {
      initialIndex = 1;
    }
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void didUpdateWidget(covariant ParentRequestsResourceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        widget.initialTab != null) {
      final target = widget.initialTab == 'support' ? 1 : 0;
      if (_tabController.index != target) {
        _tabController.animateTo(target);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isAuthorized =
        role == UserRoles.parentGuardian || role == UserRoles.schoolAdmin;

    if (!isAuthorized) {
      return const ResponsiveScaffold(
        title: 'Access Restricted',
        currentRoute: AppRoutes.requests,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Unauthorized: Requests desk is available to Parents and School Administrators.',
              style: TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ),
      );
    }

    final isParent = role == UserRoles.parentGuardian;

    return ResponsiveScaffold(
      title: 'Requests & Grievance Desk',
      currentRoute: AppRoutes.requests,
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.parentBlue,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.parentBlue,
              tabs: const [
                Tab(
                    icon: Icon(Icons.event_busy),
                    text: 'Student Leave Requests'),
                Tab(
                    icon: Icon(Icons.contact_support),
                    text: 'Grievance & Support Tickets'),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLeaveRequestsTab(isParent),
                _buildSupportTab(isParent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestsTab(bool isParent) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (isParent) ...[
          const ParentChildSwitcher(),
          const SizedBox(height: 16),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isParent
                  ? 'Leave Applications for ${selectedChild?.fullName ?? "Ward"}'
                  : 'Institutional Leave Applications',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (isParent && selectedChild != null)
              FilledButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Apply for Leave'),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.parentBlue),
                onPressed: _showApplyLeaveDialog,
              ),
          ],
        ),
        const SizedBox(height: 16),
        ErpCard(
          title: 'Submitted Applications (${_leaveApplications.length})',
          subtitle:
              'Track leave approval status and authorized absences for student academic records',
          child: _leaveApplications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                        'No leave applications recorded for current term.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _leaveApplications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final app = _leaveApplications[idx];
                    final isApproved = app['status'] == 'Approved';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      leading: CircleAvatar(
                        backgroundColor: (isApproved
                                ? AppColors.successGreen
                                : Colors.amber.shade700)
                            .withValues(alpha: 0.15),
                        child: Icon(
                          isApproved ? Icons.check_circle : Icons.hourglass_top,
                          color: isApproved
                              ? AppColors.successGreen
                              : Colors.amber.shade700,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${app['startDate']} to ${app['endDate']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                          'Reason: ${app['reason']} • Applied: ${app['appliedOn']}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isApproved
                                  ? AppColors.successGreen
                                  : Colors.amber.shade700)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          app['status'],
                          style: TextStyle(
                            color: isApproved
                                ? AppColors.successGreen
                                : Colors.amber.shade700,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSupportTab(bool isParent) {
    final complaintsAsync = ref.watch(parentComplaintsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Grievance & Support Desk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.add_comment, size: 16),
              label: const Text('File New Grievance'),
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.parentBlue),
              onPressed: () {
                final child = ref.read(selectedChildProvider);
                if (child != null) {
                  showDialog(
                    context: context,
                    builder: (_) => ComplaintsDialog(child: child),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select a student first.')),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        complaintsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading complaints: $err',
                  style: const TextStyle(color: AppColors.dangerRed)),
            ),
          ),
          data: (complaints) {
            return ErpCard(
              title: 'Registered Support Tickets (${complaints.length})',
              subtitle:
                  'Every grievance generates a tracked institutional reference ID with audit logging',
              child: complaints.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                            'No active complaints or tickets filed for this account.',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: complaints.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final c = complaints[idx];
                        final isResolved = c.status == 'Resolved';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.parentBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.confirmation_number,
                                color: AppColors.parentBlue, size: 20),
                          ),
                          title: Text(
                            '${c.referenceNumber} — ${c.subject}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                              'Category: ${c.category} • Filed: ${c.createdAt.toString().split(" ").first}\n${c.description}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isResolved
                                      ? AppColors.successGreen
                                      : Colors.amber.shade700)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.status,
                              style: TextStyle(
                                color: isResolved
                                    ? AppColors.successGreen
                                    : Colors.amber.shade700,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
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

  Future<void> _showApplyLeaveDialog() async {
    final startController = TextEditingController(text: '2026-11-10');
    final endController = TextEditingController(text: '2026-11-12');
    final reasonController = TextEditingController();
    String category = 'Medical';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apply for Student Leave'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Leave Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Medical', 'Family Event', 'Religious', 'Other']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => category = v ?? category,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startController,
                decoration: const InputDecoration(
                  labelText: 'Start Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endController,
                decoration: const InputDecoration(
                  labelText: 'End Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for absence',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.parentBlue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Application'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _leaveApplications.insert(0, {
          'id': 'LV_2026_${DateTime.now().millisecondsSinceEpoch % 1000}',
          'startDate': startController.text,
          'endDate': endController.text,
          'reason':
              '$category — ${reasonController.text.trim().isEmpty ? "Unspecified reason" : reasonController.text.trim()}',
          'status': 'Pending Approval',
          'appliedOn': DateTime.now().toString().split(' ').first,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave application submitted for school review.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}
