import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';
import '../../models/student_model.dart';
import '../../providers/child_context_provider.dart';
import '../clay/clay_container.dart';

class ParentChildSwitcher extends ConsumerWidget {
  const ParentChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedChildrenAsync = ref.watch(parentLinkedChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final isCompact = AppBreakpoints.isCompact(context);

    return linkedChildrenAsync.when(
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (e, _) => const SizedBox.shrink(),
      data: (children) {
        if (children.isEmpty) {
          return ClayContainer(
            depth: ClayDepth.low,
            surfaceColor: AppColors.warningBg,
            borderColor: AppColors.warningAmber.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: AppColors.warningAmber),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No student profile linked to your account. Please contact admissions.',
                    style:
                        TextStyle(color: AppColors.warningAmber, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }

        final currentChild = selectedChild ?? children.first;

        return ClayContainer(
          depth: ClayDepth.medium,
          borderRadius: ClayTheme.radiusMd,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClayContainer(
                depth: ClayDepth.low,
                borderRadius: ClayTheme.radiusSm,
                surfaceColor: AppColors.parentBlue.withValues(alpha: 0.12),
                borderColor: AppColors.parentBlue.withValues(alpha: 0.25),
                padding: const EdgeInsets.all(10),
                child: Text(
                  currentChild.fullName.isNotEmpty
                      ? currentChild.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: AppColors.parentBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          currentChild.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.parentBlue
                                    .withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'Active Ward',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.parentBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Class ${currentChild.currentClassId} • Section ${currentChild.currentSectionId} • Roll: ${currentChild.admissionNumber}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (children.length > 1) ...[
                const SizedBox(width: 8),
                PopupMenuButton<Student>(
                  tooltip: 'Switch Active Ward',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ClayTheme.radiusMd),
                  ),
                  color: Colors.white,
                  elevation: 6,
                  child: ClayContainer(
                    depth: ClayDepth.low,
                    borderRadius: ClayTheme.radiusSm,
                    surfaceColor: const Color(0xFFEFF6FF),
                    borderColor: AppColors.parentBlue.withValues(alpha: 0.3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 15, color: AppColors.parentBlue),
                        if (!isCompact) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'Switch Child',
                            style: TextStyle(
                              color: AppColors.parentBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down,
                            size: 16, color: AppColors.parentBlue),
                      ],
                    ),
                  ),
                  onSelected: (student) {
                    ref.read(selectedChildIdProvider.notifier).state =
                        student.studentId;
                  },
                  itemBuilder: (context) {
                    return children.map((child) {
                      final isSelected =
                          child.studentId == currentChild.studentId;
                      return PopupMenuItem<Student>(
                        value: child,
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              size: 18,
                              color: isSelected
                                  ? AppColors.parentBlue
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    child.fullName,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.parentBlue
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Class ${child.currentClassId}-${child.currentSectionId} • ${child.admissionNumber}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
