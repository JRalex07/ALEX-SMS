import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/create_notice_dialog.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Official Announcements Board
/// Route: /notices/announcements
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  String _targetFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final canPublish =
        role == UserRoles.schoolAdmin || role == UserRoles.teacher;
    final noticesAsync = ref.watch(publishedNoticesProvider);

    return ResponsiveScaffold(
      title: 'Announcements Board',
      currentRoute: AppRoutes.announcements,
      actions: [
        if (canPublish)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.campaign, size: 16),
              label: const Text('Post Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
                foregroundColor: Colors.white,
              ),
              onPressed: () => CreateNoticeDialog.show(context),
            ),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Institutional Broadcast Announcements',
            subtitle:
                'Real-time administrative notices, emergency bulletins, and school circulars',
            headerTrailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ALL', label: Text('All')),
                ButtonSegment(value: 'URGENT', label: Text('Urgent')),
                ButtonSegment(value: 'GENERAL', label: Text('General')),
              ],
              selected: {_targetFilter},
              onSelectionChanged: (set) =>
                  setState(() => _targetFilter = set.first),
            ),
            child: noticesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.brandNavy),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading announcements: $err',
                      style: const TextStyle(color: AppColors.dangerRed)),
                ),
              ),
              data: (notices) {
                final filtered = notices.where((n) {
                  if (_targetFilter == 'URGENT') {
                    return n.priority == 'HIGH' || n.priority == 'URGENT';
                  }
                  if (_targetFilter == 'GENERAL') {
                    return n.priority != 'HIGH' && n.priority != 'URGENT';
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(36),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text(
                            'No Announcements Broadcasted',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'New broadcast announcements will appear here automatically.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.borderLight),
                  itemBuilder: (ctx, idx) {
                    final item = filtered[idx];
                    final isUrgent = item.priority == 'HIGH' ||
                        item.priority == 'URGENT';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: isUrgent
                            ? AppColors.dangerRed.withValues(alpha: 0.12)
                            : AppColors.brandNavy.withValues(alpha: 0.1),
                        child: Icon(
                          isUrgent ? Icons.warning_amber : Icons.campaign,
                          color: isUrgent
                              ? AppColors.dangerRed
                              : AppColors.brandNavy,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                          if (isUrgent)
                            const StatusBadge(
                              label: 'URGENT',
                              type: StatusType.danger,
                            ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          item.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.textSecondary, height: 1.4),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
