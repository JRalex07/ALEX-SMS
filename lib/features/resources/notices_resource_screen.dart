import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/create_notice_dialog.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

class NoticesResourceScreen extends ConsumerWidget {
  const NoticesResourceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final canPublish =
        role == UserRoles.schoolAdmin || role == UserRoles.teacher;

    final noticesAsync = ref.watch(publishedNoticesProvider);

    return ResponsiveScaffold(
      title: 'School Circulars & Notices',
      currentRoute: '/notices',
      actions: [
        if (canPublish)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.campaign, size: 16),
              label: const Text('Publish Circular'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandNavy,
              ),
              onPressed: () => CreateNoticeDialog.show(context),
            ),
          ),
      ],
      body: noticesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error loading notices: $err',
              style: const TextStyle(color: AppColors.dangerRed),
            ),
          ),
        ),
        data: (notices) {
          if (notices.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 56, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text(
                      'No Published Circulars',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Official announcements will appear here once published.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, idx) {
              final n = notices[idx];
              final dateStr = n.publishedAt != null
                  ? '${n.publishedAt!.day}/${n.publishedAt!.month}/${n.publishedAt!.year}'
                  : 'Recent';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.borderLight),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge.info(
                            n.targetAudience.toUpperCase(),
                          ),
                          Text(
                            dateStr,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        n.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        n.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: AppColors.brandNavy),
                          const SizedBox(width: 6),
                          Text(
                            'Notice ID: ${n.noticeId}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
