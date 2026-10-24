import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/print_service.dart';
import '../../providers/auth_providers.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/confirm_action_dialog.dart';
import '../../shared/dialogs/report_card_dialog.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stat_card.dart';

class AcademicsResourceScreen extends ConsumerStatefulWidget {
  const AcademicsResourceScreen({super.key});

  @override
  ConsumerState<AcademicsResourceScreen> createState() =>
      _AcademicsResourceScreenState();
}

class _AcademicsResourceScreenState
    extends ConsumerState<AcademicsResourceScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;

    Widget body;
    if (role == UserRoles.parentGuardian) {
      body = _buildParentAcademicsView();
    } else if (role == UserRoles.teacher) {
      body = _buildTeacherAcademicsView();
    } else {
      body = _buildAdminAcademicsView();
    }

    return ResponsiveScaffold(
      title: 'Academics & Gradebook',
      currentRoute: '/academics',
      body: body,
    );
  }

  // --- Parent View: Ward Marks & Report Cards ---
  Widget _buildParentAcademicsView() {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return const Center(child: ParentChildSwitcher());
    }

    final marksAsync = ref.watch(activeChildMarksProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const ParentChildSwitcher(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'Cumulative GPA',
                value: '9.2 / 10.0',
                subtitle: 'Rank 3 in Class ${selectedChild.currentClassId}',
                icon: Icons.emoji_events_outlined,
                iconColor: AppColors.parentBlue,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: StatCard(
                title: 'Assessment Term',
                value: 'Mid-Term 2026',
                subtitle: 'Published by Academic Committee',
                icon: Icons.grade,
                iconColor: AppColors.successGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
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
                    Text(
                      'Subject Grades for ${selectedChild.fullName}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Preview / Print Report Card'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandNavy,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onPressed: () => ReportCardDialog.show(
                        context,
                        student: selectedChild,
                        marks: marksAsync.value ?? const [],
                        academicYear: selectedChild.currentAcademicYearId,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                marksAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading marks: $e'),
                  data: (marks) {
                    if (marks.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No published marks for current term.'),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: marks.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.borderLight),
                      itemBuilder: (ctx, idx) {
                        final m = marks[idx];
                        final grade = m.totalScore >= 90
                            ? 'A+'
                            : (m.totalScore >= 80
                                ? 'A'
                                : (m.totalScore >= 70 ? 'B' : 'C'));
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.subjectId.toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                              'CA1: ${m.continuousAssessment.ca1}/20 • CA2: ${m.continuousAssessment.ca2}/20 • Exam: ${m.examScore}/60'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${m.totalScore}/100 ($grade)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.successGreen),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Teacher View: Enter Subject Marks ---
  Widget _buildTeacherAcademicsView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.borderLight),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.edit_note, color: AppColors.teacherTeal),
                const SizedBox(width: 12),
                const Text('Gradebook — Class 10-A Mathematics',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('Print Grade Sheet'),
                  onPressed: () => PrintService.printDocument(),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.lock_clock, size: 16),
                  label: const Text('Lock & Submit Marks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teacherTeal,
                  ),
                  onPressed: () => ConfirmActionDialog.show(
                    context,
                    title: 'Lock & Submit Marks',
                    message:
                        'Are you sure you want to lock and submit Class 10-A Mathematics marks? Once locked, further edits require administrative unlock approval.',
                    confirmLabel: 'Lock & Submit',
                    confirmColor: AppColors.teacherTeal,
                    onConfirm: (reason) async {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Marks draft locked and forwarded for admin moderation!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Admin View ---
  Widget _buildAdminAcademicsView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        StatCard(
          title: 'Academic Performance Moderation',
          value: 'Term 1 Exam Moderation Active',
          subtitle: 'CBSE / State Curriculum Standards Enforced',
          icon: Icons.verified_user,
          iconColor: AppColors.adminIndigo,
        ),
      ],
    );
  }
}
