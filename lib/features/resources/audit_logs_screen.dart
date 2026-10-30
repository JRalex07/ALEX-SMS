import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final _searchController = TextEditingController();
  String _selectedActionFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    if (role != UserRoles.schoolAdmin) {
      return const ResponsiveScaffold(
        title: 'Access Restricted',
        currentRoute: AppRoutes.auditLogs,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.gpp_bad, size: 56, color: AppColors.dangerRed),
                SizedBox(height: 16),
                Text(
                  '403 Forbidden: Audit Logs Restricted',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Only School Administrators possess authorization to inspect immutable institutional audit logs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final auditLogsAsync = ref.watch(auditLogsStreamProvider);

    return ResponsiveScaffold(
      title: 'Institutional Audit Logs & Security Trail',
      currentRoute: AppRoutes.auditLogs,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.file_download, size: 16),
          label: const Text('Export Audit CSV'),
          onPressed: () {
            final logs = auditLogsAsync.value ?? [];
            if (logs.isNotEmpty) {
              DataExportService.exportAuditLogsCsv(logs);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Audit log CSV exported successfully.')),
              );
            }
          },
        ),
        const SizedBox(width: 8),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSearchFilterHeader(),
          const SizedBox(height: 16),
          auditLogsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ErpCard(
              title: 'Audit Log Feed',
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load audit events: $err',
                    style: const TextStyle(color: AppColors.dangerRed)),
              ),
            ),
            data: (allLogs) {
              final filtered = allLogs.where((l) {
                final action = (l['action'] ?? '').toString().toLowerCase();
                final actor = (l['actorEmail'] ?? '').toString().toLowerCase();
                final details = (l['details'] ?? '').toString().toLowerCase();
                final q = _searchController.text.toLowerCase();
                final matchesQuery =
                    action.contains(q) || actor.contains(q) || details.contains(q);
                final matchesAction = _selectedActionFilter == 'All' ||
                    (l['action'] ?? '').toString() == _selectedActionFilter;
                return matchesQuery && matchesAction;
              }).toList();

              return ErpCard(
                title: 'Recorded Security & Data Events (${filtered.length})',
                subtitle:
                    'Immutable append-only ledger capturing mutations across all modules',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                              'No audit events found matching the specified filters.',
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
                          final log = filtered[idx];
                          final action = log['action'] ?? 'SYSTEM_EVENT';
                          final actorEmail =
                              log['actorEmail'] ?? 'Automated System';
                          final timestamp = log['timestamp']?.toString() ??
                              'Recent Action';
                          final details = log['details']?.toString() ?? '';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.brandNavy
                                  .withValues(alpha: 0.1),
                              child: const Icon(Icons.shield_outlined,
                                  color: AppColors.brandNavy, size: 20),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  action.toString().toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.successGreen
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('VERIFIED',
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.successGreen)),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Actor: $actorEmail • $timestamp',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                                if (details.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    details,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilterHeader() {
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
                  hintText: 'Search audit logs by actor, action, or payload details...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedActionFilter,
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Actions')),
                DropdownMenuItem(
                    value: 'ASSIGN_TEACHER', child: Text('Assign Teacher')),
                DropdownMenuItem(
                    value: 'TRANSFER_STUDENT',
                    child: Text('Transfer Student')),
                DropdownMenuItem(
                    value: 'RECORD_PAYMENT', child: Text('Record Payment')),
                DropdownMenuItem(
                    value: 'PUBLISH_RESULTS', child: Text('Publish Results')),
                DropdownMenuItem(
                    value: 'UPDATE_STAFF', child: Text('Update Staff')),
              ],
              onChanged: (v) => setState(() => _selectedActionFilter = v!),
            ),
          ],
        ),
      ),
    );
  }
}

