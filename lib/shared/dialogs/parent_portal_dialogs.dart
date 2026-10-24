import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../models/parent_service_models.dart';
import '../../models/student_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/parent_services_providers.dart';
import '../clay/clay.dart';

/// 1. Homework Dialog
class HomeworkListDialog extends ConsumerWidget {
  final Student child;
  const HomeworkListDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hwAsync = ref.watch(childHomeworkProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.homeworkModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.menu_book,
                        color: AppColors.homeworkModule),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Assigned Homework',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${child.fullName} • Class ${child.currentClassId} (${child.currentSectionId})',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: hwAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                          child: Text('No homework assigned at this time.'));
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        final isEvaluated =
                            item.submissionStatus == 'evaluated';
                        final isSubmitted =
                            item.submissionStatus == 'submitted';

                        return ClayContainer(
                          depth: ClayDepth.low,
                          borderRadius: ClayTheme.radiusMd,
                          surfaceColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.homeworkModule
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.subjectName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.homeworkModule,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isEvaluated
                                          ? AppColors.successBg
                                          : (isSubmitted
                                              ? AppColors.infoBg
                                              : AppColors.warningBg),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.submissionStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isEvaluated
                                            ? AppColors.successGreen
                                            : (isSubmitted
                                                ? AppColors.infoSky
                                                : AppColors.warningAmber),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.instructions,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.teacherName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.event_outlined,
                                      size: 14, color: AppColors.dangerRed),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${item.dueDate.day}/${item.dueDate.month}/${item.dueDate.year}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dangerRed,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 2. Syllabus Dialog
class SyllabusDialog extends ConsumerWidget {
  final Student child;
  const SyllabusDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sylAsync = ref.watch(childSyllabusProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.syllabusModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.library_books,
                        color: AppColors.syllabusModule),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Class Syllabus & Topics',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Curriculum Term 1 • Class ${child.currentClassId}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),
              Expanded(
                child: sylAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (items) {
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (ctx, i) {
                        final item = items[i];
                        return ClayContainer(
                          depth: ClayDepth.low,
                          borderRadius: ClayTheme.radiusMd,
                          surfaceColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.subjectName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${item.completionPercentage}% Completed',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.syllabusModule,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: item.completionPercentage / 100,
                                backgroundColor: const Color(0xFFF1F5F9),
                                color: AppColors.syllabusModule,
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Prescribed Syllabus Topics:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...item.topics.map(
                                (t) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline,
                                          size: 14,
                                          color: AppColors.syllabusModule),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(t,
                                            style:
                                                const TextStyle(fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 3. Chat with School Dialog
class ParentChatDialog extends ConsumerStatefulWidget {
  final Student child;
  const ParentChatDialog({super.key, required this.child});

  @override
  ConsumerState<ParentChatDialog> createState() => _ParentChatDialogState();
}

class _ParentChatDialogState extends ConsumerState<ParentChatDialog> {
  String _selectedRole = 'teacher';
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatStream = ref.watch(parentChatStreamProvider(_selectedRole));
    final user = ref.watch(currentUserProfileProvider).value;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.chatModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.chatModule),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chat with School',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('Direct messaging with authorized school staff',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Channel Switcher (Class Teacher, Administration, Accounts)
              Row(
                children: [
                  _buildChannelTab('teacher', 'Class Teacher', Icons.school),
                  const SizedBox(width: 8),
                  _buildChannelTab(
                      'school_admin', 'Admin Desk', Icons.admin_panel_settings),
                  const SizedBox(width: 8),
                  _buildChannelTab(
                      'accountant', 'Fee Bursar', Icons.receipt_long),
                ],
              ),
              const Divider(height: 20),

              // Message Stream
              Expanded(
                child: chatStream.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('Error loading messages: $e')),
                  data: (messages) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final msg = messages[i];
                        final isMe = msg.senderRole == 'parent_guardian';

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 380),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.parentBlue
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.senderName,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isMe
                                        ? Colors.white.withValues(alpha: 0.8)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isMe
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Message Input
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClayTextField(
                      controller: _messageController,
                      hintText: 'Type your message...',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.parentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: () async {
                      final text = _messageController.text.trim();
                      if (text.isEmpty) return;
                      _messageController.clear();

                      final repo = ref.read(parentServicesRepositoryProvider);
                      await repo.sendChatMessage(
                        parentUid: user?.uid ?? 'guest_parent',
                        parentName: user?.displayName.isNotEmpty == true
                            ? user!.displayName
                            : 'Parent',
                        recipientRole: _selectedRole,
                        message: text,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTab(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: ClayContainer(
          depth: isSelected ? ClayDepth.inset : ClayDepth.low,
          borderRadius: ClayTheme.radiusSm,
          surfaceColor: isSelected
              ? AppColors.chatModule.withValues(alpha: 0.12)
              : Colors.white,
          borderColor:
              isSelected ? AppColors.chatModule : AppColors.borderLight,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14,
                  color: isSelected
                      ? AppColors.chatModule
                      : AppColors.textSecondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.chatModule
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 4. Complaints & Grievance Dialog
class ComplaintsDialog extends ConsumerStatefulWidget {
  final Student child;
  const ComplaintsDialog({super.key, required this.child});

  @override
  ConsumerState<ComplaintsDialog> createState() => _ComplaintsDialogState();
}

class _ComplaintsDialogState extends ConsumerState<ComplaintsDialog> {
  bool _isCreatingNew = false;
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedCategory = 'transport';

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(parentComplaintsProvider);
    final user = ref.watch(currentUserProfileProvider).value;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.complaintModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.report_problem_outlined,
                        color: AppColors.complaintModule),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Complaints & Grievances',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            'Submit official concerns and track administrative resolution',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_isCreatingNew) ...[
                // New Complaint Form
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: [
                            'transport',
                            'academics',
                            'fees',
                            'discipline',
                            'general'
                          ].map((cat) {
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat.toUpperCase()),
                              selected: isSel,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = cat),
                              selectedColor: AppColors.complaintModule
                                  .withValues(alpha: 0.15),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text('Subject',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 6),
                        ClayTextField(
                          controller: _subjectCtrl,
                          hintText: 'Brief summary of the issue...',
                        ),
                        const SizedBox(height: 14),
                        const Text('Detailed Description',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Provide specific details, dates, and background...',
                            filled: true,
                            fillColor: ClayTheme.claySurfaceInset,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () =>
                                  setState(() => _isCreatingNew = false),
                              child: const Text('Cancel'),
                            ),
                            const Spacer(),
                            ClayButton(
                              label: 'Submit Official Complaint',
                              icon: Icons.send,
                              onPressed: () async {
                                final sub = _subjectCtrl.text.trim();
                                final desc = _descCtrl.text.trim();
                                if (sub.isEmpty || desc.isEmpty) return;

                                final repo =
                                    ref.read(parentServicesRepositoryProvider);
                                await repo.submitComplaint(
                                  parentUid: user?.uid ?? 'guest_parent',
                                  studentId: widget.child.studentId,
                                  studentName: widget.child.fullName,
                                  category: _selectedCategory,
                                  subject: sub,
                                  description: desc,
                                );

                                setState(() {
                                  _isCreatingNew = false;
                                  _subjectCtrl.clear();
                                  _descCtrl.clear();
                                });
                                ref.invalidate(parentComplaintsProvider);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // List of Complaints
                Row(
                  children: [
                    const Text('Filed Grievances',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const Spacer(),
                    ClayButton(
                      label: '+ New Complaint',
                      icon: Icons.add,
                      onPressed: () => setState(() => _isCreatingNew = true),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: complaintsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (items) {
                      if (items.isEmpty) {
                        return const Center(
                            child: Text('No complaints submitted.'));
                      }
                      return ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final item = items[i];
                          final isResolved = item.status == 'resolved';
                          final isInReview = item.status == 'in_review';

                          return ClayContainer(
                            depth: ClayDepth.low,
                            borderRadius: ClayTheme.radiusMd,
                            surfaceColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      item.referenceNumber,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.complaintModule,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isResolved
                                            ? AppColors.successBg
                                            : (isInReview
                                                ? AppColors.infoBg
                                                : AppColors.warningBg),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.status
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: isResolved
                                              ? AppColors.successGreen
                                              : (isInReview
                                                  ? AppColors.infoSky
                                                  : AppColors.warningAmber),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(item.subject,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(item.description,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                                if (item.responses.isNotEmpty) ...[
                                  const Divider(height: 16),
                                  ...item.responses.map(
                                    (r) => Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Official Response from ${r.responderName} (${r.responderRole}):',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.brandNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(r.message,
                                              style: const TextStyle(
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Class Routine / Timetable Dialog
class TimetableDialog extends ConsumerWidget {
  final Student child;
  const TimetableDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttAsync = ref.watch(childTimetableProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.routineModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.schedule,
                        color: AppColors.routineModule),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Class Routine & Timetable',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            '${child.fullName} • Class ${child.currentClassId} (${child.currentSectionId})',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ttAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (slots) {
                    return ListView.separated(
                      itemCount: slots.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) {
                        final slot = slots[i];
                        return ClayContainer(
                          depth: ClayDepth.low,
                          borderRadius: ClayTheme.radiusMd,
                          surfaceColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.routineModule
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  'P${slot.periodNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.routineModule,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      slot.subjectName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${slot.teacherName} • ${slot.roomNumber}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${slot.startTime} - ${slot.endTime}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6. Online Classes Dialog
class OnlineClassesDialog extends ConsumerWidget {
  final Student child;
  const OnlineClassesDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocAsync = ref.watch(childOnlineClassesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          AppColors.onlineClassModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.video_call,
                        color: AppColors.onlineClassModule),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Virtual Online Classes',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            '${child.fullName} • Class ${child.currentClassId}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ocAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (sessions) {
                    if (sessions.isEmpty) {
                      return const Center(
                          child: Text(
                              'No virtual classes scheduled at this time.'));
                    }
                    return ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final s = sessions[i];
                        return ClayContainer(
                          depth: ClayDepth.low,
                          borderRadius: ClayTheme.radiusMd,
                          surfaceColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.onlineClassModule
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s.subjectName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onlineClassModule,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      s.provider
                                          .toUpperCase()
                                          .replaceAll('_', ' '),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(s.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                  'Faculty: ${s.teacherName} • ${s.durationMinutes} Minutes',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              if (s.meetingId != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                    'Meeting ID: ${s.meetingId}  |  Passcode: ${s.passcode ?? "None"}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                              const SizedBox(height: 12),
                              ClayButton(
                                label: 'Join Virtual Lecture',
                                icon: Icons.open_in_new,
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Launching ${s.provider} session: ${s.joinUrl}')),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 7. Academic Calendar Dialog
class CalendarDialog extends ConsumerWidget {
  const CalendarDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calAsync = ref.watch(schoolCalendarEventsProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.calendarModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.event_note,
                        color: AppColors.calendarModule),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Academic Calendar & Events',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text('Session 2026-2027 • Holidays, Examinations & PTM',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: calAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (events) {
                    return ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final ev = events[i];
                        final isHoliday = ev.type == 'holiday';
                        final isExam = ev.type == 'exam';

                        return ClayContainer(
                          depth: ClayDepth.low,
                          borderRadius: ClayTheme.radiusMd,
                          surfaceColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 50,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isHoliday
                                      ? AppColors.dangerBg
                                      : (isExam
                                          ? AppColors.infoBg
                                          : AppColors.warningBg),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '${ev.startDate.day}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: isHoliday
                                            ? AppColors.dangerRed
                                            : (isExam
                                                ? AppColors.infoSky
                                                : AppColors.warningAmber),
                                      ),
                                    ),
                                    Text(
                                      _getMonthAbbr(ev.startDate.month),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isHoliday
                                            ? AppColors.dangerRed
                                            : (isExam
                                                ? AppColors.infoSky
                                                : AppColors.warningAmber),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ev.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14)),
                                    const SizedBox(height: 3),
                                    Text(ev.description,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary)),
                                    if (ev.location != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined,
                                              size: 13,
                                              color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(ev.location!,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getMonthAbbr(int month) {
    const m = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return m[(month - 1) % 12];
  }
}

/// 8. Online Test / Assessment Runner Dialog (Delegated Student Session)
class OnlineTestDialog extends ConsumerStatefulWidget {
  final Student child;
  const OnlineTestDialog({super.key, required this.child});

  @override
  ConsumerState<OnlineTestDialog> createState() => _OnlineTestDialogState();
}

class _OnlineTestDialogState extends ConsumerState<OnlineTestDialog> {
  OnlineQuizItem? _activeQuiz;
  int _activeQuestionIdx = 0;
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(childOnlineQuizzesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 700),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.onlineTestModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.computer,
                        color: AppColors.onlineTestModule),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Online Tests & Quizzes',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            'Student Session: ${widget.child.fullName} • Class ${widget.child.currentClassId}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_activeQuiz != null && !_isSubmitted) ...[
                // Active Test Session
                Row(
                  children: [
                    Text(
                      'Question ${_activeQuestionIdx + 1} of ${_activeQuiz!.questions.length}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            AppColors.onlineTestModule.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined,
                              size: 14, color: AppColors.onlineTestModule),
                          const SizedBox(width: 4),
                          Text('${_activeQuiz!.durationMinutes} mins',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onlineTestModule)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _activeQuiz!.questions[_activeQuestionIdx].questionText,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: _activeQuiz!
                        .questions[_activeQuestionIdx].options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, optIdx) {
                      final opt = _activeQuiz!
                          .questions[_activeQuestionIdx].options[optIdx];
                      final isSelected = _activeQuiz!
                              .questions[_activeQuestionIdx]
                              .selectedOptionIndex ==
                          optIdx;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _activeQuiz!.questions[_activeQuestionIdx]
                                .selectedOptionIndex = optIdx;
                          });
                        },
                        child: ClayContainer(
                          depth: isSelected ? ClayDepth.inset : ClayDepth.low,
                          borderRadius: ClayTheme.radiusSm,
                          surfaceColor: isSelected
                              ? AppColors.onlineTestModule
                                  .withValues(alpha: 0.12)
                              : Colors.white,
                          borderColor: isSelected
                              ? AppColors.onlineTestModule
                              : AppColors.borderLight,
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppColors.onlineTestModule
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.onlineTestModule
                                        : AppColors.textMuted,
                                  ),
                                ),
                                child: Text(
                                  String.fromCharCode(65 + optIdx),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(opt,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    if (_activeQuestionIdx > 0)
                      TextButton(
                        onPressed: () => setState(() => _activeQuestionIdx--),
                        child: const Text('Previous'),
                      ),
                    const Spacer(),
                    if (_activeQuestionIdx < _activeQuiz!.questions.length - 1)
                      ClayButton(
                        label: 'Next Question',
                        icon: Icons.arrow_forward,
                        onPressed: () => setState(() => _activeQuestionIdx++),
                      )
                    else
                      ClayButton(
                        label: 'Submit Test',
                        icon: Icons.check,
                        onPressed: () {
                          setState(() => _isSubmitted = true);
                        },
                      ),
                  ],
                ),
              ] else if (_isSubmitted) ...[
                // Submission Confirmation & Result
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.successGreen, size: 54),
                        const SizedBox(height: 14),
                        const Text('Assessment Successfully Submitted!',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          'Test record saved for ${widget.child.fullName} (ID: ${widget.child.studentId})',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                        ClayButton(
                          label: 'Return to Tests List',
                          onPressed: () {
                            setState(() {
                              _activeQuiz = null;
                              _isSubmitted = false;
                              _activeQuestionIdx = 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                // Available Quizzes List
                Expanded(
                  child: quizAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (quizzes) {
                      return ListView.separated(
                        itemCount: quizzes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final q = quizzes[i];
                          return ClayContainer(
                            depth: ClayDepth.low,
                            borderRadius: ClayTheme.radiusMd,
                            surfaceColor: Colors.white,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      q.subjectName,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onlineTestModule,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: q.isCompleted
                                            ? AppColors.successBg
                                            : AppColors.infoBg,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        q.isCompleted
                                            ? 'COMPLETED (${q.scoreObtained}/${q.totalMarks})'
                                            : 'ACTIVE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: q.isCompleted
                                              ? AppColors.successGreen
                                              : AppColors.infoSky,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(q.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  'Duration: ${q.durationMinutes} mins • Questions: ${q.totalQuestions} • Total Marks: ${q.totalMarks}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 12),
                                if (!q.isCompleted)
                                  ClayButton(
                                    label: 'Start Quiz Session',
                                    icon: Icons.play_arrow,
                                    onPressed: () {
                                      setState(() {
                                        _activeQuiz = q;
                                        _activeQuestionIdx = 0;
                                        _isSubmitted = false;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 9. Location & Transport Information Dialog
class LocationTransportDialog extends ConsumerStatefulWidget {
  final Student child;
  const LocationTransportDialog({super.key, required this.child});

  @override
  ConsumerState<LocationTransportDialog> createState() =>
      _LocationTransportDialogState();
}

class _LocationTransportDialogState
    extends ConsumerState<LocationTransportDialog> {
  int _selectedTabIndex = 0; // 0 = Campus Location, 1 = Bus Route

  @override
  Widget build(BuildContext context) {
    final transAsync = ref.watch(childTransportProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.locationModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.location_on,
                        color: AppColors.locationModule),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location & Transit Details',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            'Campus address, contact directions, and student bus route',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Segmented Tab Switcher
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 0),
                      child: ClayContainer(
                        depth: _selectedTabIndex == 0
                            ? ClayDepth.inset
                            : ClayDepth.low,
                        borderRadius: ClayTheme.radiusSm,
                        surfaceColor: _selectedTabIndex == 0
                            ? AppColors.locationModule.withValues(alpha: 0.12)
                            : Colors.white,
                        borderColor: _selectedTabIndex == 0
                            ? AppColors.locationModule
                            : AppColors.borderLight,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const Center(
                          child: Text(
                            '🏫 Campus Location',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTabIndex = 1),
                      child: ClayContainer(
                        depth: _selectedTabIndex == 1
                            ? ClayDepth.inset
                            : ClayDepth.low,
                        borderRadius: ClayTheme.radiusSm,
                        surfaceColor: _selectedTabIndex == 1
                            ? AppColors.locationModule.withValues(alpha: 0.12)
                            : Colors.white,
                        borderColor: _selectedTabIndex == 1
                            ? AppColors.locationModule
                            : AppColors.borderLight,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: const Center(
                          child: Text(
                            '🚌 Assigned Bus Route',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: _selectedTabIndex == 0
                    ? _buildCampusLocationView()
                    : _buildBusRouteView(transAsync),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampusLocationView() {
    return ListView(
      children: const [
        ClayContainer(
          depth: ClayDepth.low,
          borderRadius: ClayTheme.radiusMd,
          surfaceColor: Colors.white,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('LAV Academy Senior & Junior Campus',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              SizedBox(height: 6),
              Text(
                'Plot 42, Institutional Area, Sector 62, New Delhi NCR, 201309',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Divider(height: 20),
              Row(
                children: [
                  Icon(Icons.phone_outlined,
                      size: 16, color: AppColors.brandNavy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('+91 11 2345 6789 / +91 11 2345 6790',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.email_outlined,
                      size: 16, color: AppColors.brandNavy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('admissions@lav-school.edu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: AppColors.brandNavy),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Visitor Hours: 08:30 AM - 02:30 PM (Mon-Fri)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBusRouteView(AsyncValue<TransportInfo> transAsync) {
    return transAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (info) {
        return ListView(
          children: [
            ClayContainer(
              depth: ClayDepth.low,
              borderRadius: ClayTheme.radiusMd,
              surfaceColor: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.transportModule
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            info.busNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.transportModule,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Enrolled in Transit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(info.routeName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const Divider(height: 20),
                  _buildTransitRow('Designated Pickup Stop', info.pickupStop,
                      Icons.trip_origin, Colors.green),
                  const SizedBox(height: 8),
                  _buildTransitRow('Morning Pickup Timing', info.pickupTime,
                      Icons.alarm, Colors.blue),
                  const SizedBox(height: 8),
                  _buildTransitRow('Afternoon Drop Timing', info.dropTime,
                      Icons.alarm_on, Colors.orange),
                  const Divider(height: 20),
                  const Text('Verified Transport Staff Contact:',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_pin,
                          size: 16, color: AppColors.brandNavy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Driver: ${info.driverName} (${info.driverPhone})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 16, color: AppColors.brandNavy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Conductor: ${info.conductorName} (${info.conductorPhone})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransitRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }
}

/// 10. Change Password Dialog
class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  String? _successMsg;

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.passwordModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset,
                        color: AppColors.passwordModule),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change Account Password',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        Text('Secure Firebase Authentication update',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              if (_successMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: AppColors.successGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_successMsg!,
                            style: const TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.dangerRed, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: AppColors.dangerRed,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const Text('Current Password',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              ClayTextField(
                controller: _currentPwdCtrl,
                obscureText: true,
                hintText: 'Enter your existing password',
              ),
              const SizedBox(height: 12),
              const Text('New Password',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              ClayTextField(
                controller: _newPwdCtrl,
                obscureText: true,
                hintText: 'At least 8 characters, letters & numbers',
              ),
              const SizedBox(height: 12),
              const Text('Confirm New Password',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              ClayTextField(
                controller: _confirmPwdCtrl,
                obscureText: true,
                hintText: 'Re-enter new password to verify',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ClayButton(
                    label: _isLoading ? 'Updating...' : 'Update Password',
                    icon: Icons.check,
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final curr = _currentPwdCtrl.text.trim();
                            final newP = _newPwdCtrl.text.trim();
                            final conf = _confirmPwdCtrl.text.trim();

                            if (curr.isEmpty || newP.isEmpty || conf.isEmpty) {
                              setState(
                                  () => _errorMsg = 'All fields are required.');
                              return;
                            }
                            if (newP.length < 8) {
                              setState(() => _errorMsg =
                                  'New password must be at least 8 characters long.');
                              return;
                            }
                            if (newP != conf) {
                              setState(() =>
                                  _errorMsg = 'New passwords do not match.');
                              return;
                            }

                            setState(() {
                              _isLoading = true;
                              _errorMsg = null;
                              _successMsg = null;
                            });

                            try {
                              final repo =
                                  ref.read(parentServicesRepositoryProvider);
                              await repo.changePassword(
                                currentPassword: curr,
                                newPassword: newP,
                              );
                              setState(() {
                                _isLoading = false;
                                _successMsg = 'Password updated successfully!';
                              });
                            } catch (e) {
                              setState(() {
                                _isLoading = false;
                                _errorMsg =
                                    e.toString().replaceAll('Exception: ', '');
                              });
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 11. Parent & Student Profile Dialog
class ParentStudentProfileDialog extends ConsumerWidget {
  final Student child;
  const ParentStudentProfileDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
        child: ClayContainer(
          depth: ClayDepth.high,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.studentModule.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school,
                        color: AppColors.studentModule),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student & Guardian Profile',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Text(
                            'Institutional record and authorized emergency contact details',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    // Student Card
                    const Text('Student Demographic Record (School-Managed)',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ClayContainer(
                      depth: ClayDepth.low,
                      borderRadius: ClayTheme.radiusMd,
                      surfaceColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileRow('Full Legal Name', child.fullName),
                          const Divider(height: 14),
                          _buildProfileRow(
                              'Admission Number', child.admissionNumber),
                          const Divider(height: 14),
                          _buildProfileRow('Current Class & Section',
                              'Class ${child.currentClassId} (${child.currentSectionId})'),
                          const Divider(height: 14),
                          _buildProfileRow('Enrollment Status',
                              child.isEnrolled ? 'Active Student' : 'Inactive'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Guardian Card
                    const Text('Guardian Contact Profile',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    ClayContainer(
                      depth: ClayDepth.low,
                      borderRadius: ClayTheme.radiusMd,
                      surfaceColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileRow('Guardian Name',
                              user?.displayName ?? 'Parent/Guardian'),
                          const Divider(height: 14),
                          _buildProfileRow('Registered Email',
                              user?.email ?? 'guardian@parent.edu'),
                          const Divider(height: 14),
                          _buildProfileRow(
                              'Account Role', 'Authorized Guardian'),
                          const Divider(height: 14),
                          _buildProfileRow(
                              'Emergency Hotline', '+91 11 2345 6789'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
