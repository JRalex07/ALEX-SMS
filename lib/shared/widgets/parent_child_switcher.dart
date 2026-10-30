import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/apple_design_system.dart';
import '../../models/student_model.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';

class ParentChildSwitcher extends ConsumerWidget {
  const ParentChildSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedChildrenAsync = ref.watch(parentLinkedChildrenProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final isCompact = AppBreakpoints.isCompact(context);

    return linkedChildrenAsync.when(
      loading: () => const LinearProgressIndicator(
        minHeight: 2,
        color: AppColors.parentBlue,
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (children) {
        if (children.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warningAmber.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: AppColors.warningAmber),
                SizedBox(width: 10),
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

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
            border: Border.all(color: AppColors.borderLight, width: 1.0),
            boxShadow: AppleMaterials.elevationCard,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.parentBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.parentBlue.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  currentChild.fullName.isNotEmpty
                      ? currentChild.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: AppColors.parentBlue,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
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
                      spacing: 8,
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
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: AppColors.parentBlue
                                    .withValues(alpha: 0.25)),
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
                    const SizedBox(height: 3),
                    Text(
                      'Class ${currentChild.currentClassId} • Section ${currentChild.currentSectionId} • Roll/Adm: ${currentChild.admissionNumber}',
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  color: Colors.white,
                  elevation: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.parentBlue.withValues(alpha: 0.3)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline,
                            size: 16, color: AppColors.parentBlue),
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
                    // Invalidate caches instantly for immediate re-render
                    ref.invalidate(activeChildAttendanceProvider);
                    ref.invalidate(activeChildMarksProvider);
                    ref.invalidate(
                        childInvoicesStreamProvider(student.studentId));
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
