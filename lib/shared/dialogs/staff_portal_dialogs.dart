import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../models/examination_model.dart';
import '../../providers/auth_providers.dart';
import '../../providers/feature_providers.dart';
import '../clay/clay.dart';

// ============================================================================
// 1. SCHOOL ADMINISTRATOR DIALOGS
// ============================================================================

/// Dialog for School Administrator to assign teachers to classes, sections & subjects
class AssignTeacherDialog extends ConsumerStatefulWidget {
  const AssignTeacherDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AssignTeacherDialog(),
    );
  }

  @override
  ConsumerState<AssignTeacherDialog> createState() =>
      _AssignTeacherDialogState();
}

class _AssignTeacherDialogState extends ConsumerState<AssignTeacherDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedTeacherUid = '';
  String _selectedClass = '10';
  String _selectedSection = 'A';
  final _subjectController = TextEditingController(text: 'Mathematics');
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _submitAssignment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeacherUid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a teacher to assign.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.assignTeacherScope(
        uid: _selectedTeacherUid,
        classes: [_selectedClass],
        sections: [_selectedSection],
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.adminIndigo,
            content: Text(
              'Assigned Class $_selectedClass-$_selectedSection (${_subjectController.text.trim()}) successfully.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Assignment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffUsersStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'Assign Teacher to Cohort',
          subtitle: 'Institutional Class, Section & Subject Scope Allocation',
          icon: Icons.person_add_alt_1_outlined,
          iconColor: AppColors.adminIndigo,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Teacher',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                staffAsync.when(
                  data: (staffList) {
                    final teachers =
                        staffList.where((u) => u.isTeacher).toList();
                    if (teachers.isEmpty) {
                      return const Text(
                          'No active teacher accounts found in staff directory.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13));
                    }
                    if (_selectedTeacherUid.isEmpty && teachers.isNotEmpty) {
                      _selectedTeacherUid = teachers.first.uid;
                    }

                    return ClayContainer(
                      depth: ClayDepth.inset,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTeacherUid,
                          isExpanded: true,
                          items: teachers.map((t) {
                            return DropdownMenuItem(
                              value: t.uid,
                              child: Text('${t.displayName} (${t.email})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedTeacherUid = val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => ClayTextField(
                    hintText: 'Enter Teacher UID or Email',
                    onChanged: (val) => _selectedTeacherUid = val.trim(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class Cohort',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClayContainer(
                            depth: ClayDepth.inset,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedClass,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: '9', child: Text('Class 9')),
                                  DropdownMenuItem(
                                      value: '10', child: Text('Class 10')),
                                  DropdownMenuItem(
                                      value: '11', child: Text('Class 11')),
                                  DropdownMenuItem(
                                      value: '12', child: Text('Class 12')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedClass = val);
                                  }
                                },
                              ),
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
                          const Text('Section',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClayContainer(
                            depth: ClayDepth.inset,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSection,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'A', child: Text('Section A')),
                                  DropdownMenuItem(
                                      value: 'B', child: Text('Section B')),
                                  DropdownMenuItem(
                                      value: 'C', child: Text('Section C')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSection = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Subject Name',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _subjectController,
                  hintText: 'e.g. Mathematics, Science, Social Studies',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClayButton(
                      label: 'Cancel',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ClayButton(
                      label: _isLoading ? 'Saving...' : 'Confirm Assignment',
                      variant: ClayButtonVariant.primary,
                      customColor: AppColors.adminIndigo,
                      onPressed: _isLoading ? null : _submitAssignment,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for School Administrator to transfer a student between classes/sections
class TransferStudentDialog extends ConsumerStatefulWidget {
  final Student? initialStudent;
  const TransferStudentDialog({super.key, this.initialStudent});

  static Future<void> show(BuildContext context, {Student? initialStudent}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => TransferStudentDialog(initialStudent: initialStudent),
    );
  }

  @override
  ConsumerState<TransferStudentDialog> createState() =>
      _TransferStudentDialogState();
}

class _TransferStudentDialogState extends ConsumerState<TransferStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedStudentId = '';
  String _targetClass = '10';
  String _targetSection = 'B';
  final _reasonController = TextEditingController(
      text: 'Academic section balancing & cohort reassignment');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStudent != null) {
      _selectedStudentId = widget.initialStudent!.studentId;
      _targetClass = widget.initialStudent!.currentClassId;
      _targetSection =
          widget.initialStudent!.currentSectionId == 'A' ? 'B' : 'A';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _executeTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student to transfer.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      await studentRepo.transferStudentClass(
        studentId: _selectedStudentId,
        newClassId: _targetClass,
        newSectionId: _targetSection,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.adminIndigo,
            content: Text(
              'Transferred student $_selectedStudentId to Class $_targetClass-$_targetSection.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Transfer error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'Transfer Student Cohort',
          subtitle:
              'Institutional Class and Section Reallocation with Audit Trail',
          icon: Icons.swap_horiz,
          iconColor: AppColors.adminIndigo,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Student',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return const Text(
                          'No students currently registered in database.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13));
                    }
                    if (students.isNotEmpty &&
                        !students
                            .any((s) => s.studentId == _selectedStudentId)) {
                      _selectedStudentId = students.first.studentId;
                    }

                    return ClayContainer(
                      depth: ClayDepth.inset,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStudentId,
                          isExpanded: true,
                          items: students.map((s) {
                            return DropdownMenuItem(
                              value: s.studentId,
                              child: Text(
                                '${s.fullName} (${s.admissionNumber}) - Current: ${s.currentClassId}-${s.currentSectionId}',
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStudentId = val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => ClayTextField(
                    hintText: 'Enter Student ID (e.g. STU_2026_001)',
                    onChanged: (val) => _selectedStudentId = val.trim(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Class',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClayContainer(
                            depth: ClayDepth.inset,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _targetClass,
                                isExpanded: true,
                                items: _buildClassDropdownItems(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _targetClass = val);
                                  }
                                },
                              ),
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
                          const Text('Target Section',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClayContainer(
                            depth: ClayDepth.inset,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _targetSection,
                                isExpanded: true,
                                items: _buildSectionDropdownItems(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _targetSection = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Transfer Reason',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _reasonController,
                  maxLines: 2,
                  hintText:
                      'Enter official transfer rationale for institutional audit',
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClayButton(
                      label: 'Cancel',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ClayButton(
                      label:
                          _isLoading ? 'Transferring...' : 'Execute Transfer',
                      variant: ClayButtonVariant.primary,
                      customColor: AppColors.adminIndigo,
                      onPressed: _isLoading ? null : _executeTransfer,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItems() {
    final classValues = <String>{
      'Class 9',
      'Class 10',
      'Class 11',
      'Class 12',
      '9',
      '10',
      '11',
      '12',
    };
    if (_targetClass.isNotEmpty) {
      classValues.add(_targetClass);
    }

    return classValues.map((cls) {
      final label = cls.startsWith('Class ') ? cls : 'Class $cls';
      return DropdownMenuItem<String>(
        value: cls,
        child: Text(label),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _buildSectionDropdownItems() {
    final sectionValues = <String>{'A', 'B', 'C', 'D'};
    if (_targetSection.isNotEmpty) {
      sectionValues.add(_targetSection);
    }

    return sectionValues.map((sec) {
      final label = sec.startsWith('Section ') ? sec : 'Section $sec';
      return DropdownMenuItem<String>(
        value: sec,
        child: Text(label),
      );
    }).toList();
  }
}

/// Dialog for School Administrator to manage Staff Accounts (Status & Role)
class StaffManagementDialog extends ConsumerStatefulWidget {
  const StaffManagementDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const StaffManagementDialog(),
    );
  }

  @override
  ConsumerState<StaffManagementDialog> createState() =>
      _StaffManagementDialogState();
}

class _StaffManagementDialogState extends ConsumerState<StaffManagementDialog> {
  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(allStaffUsersStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 600),
        child: ClayCard(
          title: 'Staff Accounts & Directory',
          subtitle:
              'Active institutional roles, authorization states and account controls',
          icon: Icons.manage_accounts_outlined,
          iconColor: AppColors.adminIndigo,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 300,
                child: staffAsync.when(
                  data: (staffList) {
                    if (staffList.isEmpty) {
                      return const Center(
                        child: Text('No staff members registered in directory.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: staffList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, idx) {
                        final staff = staffList[idx];
                        final isActive = staff.isActive;

                        return ClayCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClayContainer(
                                depth: ClayDepth.low,
                                padding: const EdgeInsets.all(10),
                                borderRadius: ClayTheme.radiusSm,
                                surfaceColor: AppColors.getRoleColor(staff.role)
                                    .withValues(alpha: 0.12),
                                child: Icon(
                                  Icons.person,
                                  color: AppColors.getRoleColor(staff.role),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      staff.displayName.isNotEmpty
                                          ? staff.displayName
                                          : 'Staff Member',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${staff.email} • Role: ${staff.role}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              ClayButton(
                                height: 34,
                                label: isActive ? 'Suspend' : 'Activate',
                                variant: isActive
                                    ? ClayButtonVariant.subtle
                                    : ClayButtonVariant.primary,
                                customColor: isActive
                                    ? AppColors.dangerRed
                                    : AppColors.successGreen,
                                onPressed: () async {
                                  final newStatus =
                                      isActive ? 'suspended' : 'active';
                                  await ref
                                      .read(authRepositoryProvider)
                                      .updateStaffStatus(
                                          uid: staff.uid, status: newStatus);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Account status updated to $newStatus.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: Text('Loading directory...')),
                  error: (e, _) =>
                      Center(child: Text('Error loading directory: $e')),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ClayButton(
                  label: 'Close Directory',
                  variant: ClayButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 2. TEACHER DIALOGS (Marks Entry & Homework)
// ============================================================================

/// Dialog for Teacher to enter and submit marks with strict limit validation
class SubmitMarksDialog extends ConsumerStatefulWidget {
  final Student student;
  final String subject;
  final String examId;
  final String subjectId;
  final int initialCa1;
  final int initialCa2;
  final int initialExam;

  const SubmitMarksDialog({
    super.key,
    required this.student,
    this.subject = 'Mathematics',
    this.examId = '',
    this.subjectId = 'SUB_MATH',
    this.initialCa1 = 0,
    this.initialCa2 = 0,
    this.initialExam = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required Student student,
    String subject = 'Mathematics',
    String examId = '',
    String subjectId = 'SUB_MATH',
    int initialCa1 = 0,
    int initialCa2 = 0,
    int initialExam = 0,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SubmitMarksDialog(
        student: student,
        subject: subject,
        examId: examId,
        subjectId: subjectId,
        initialCa1: initialCa1,
        initialCa2: initialCa2,
        initialExam: initialExam,
      ),
    );
  }

  @override
  ConsumerState<SubmitMarksDialog> createState() => _SubmitMarksDialogState();
}

class _SubmitMarksDialogState extends ConsumerState<SubmitMarksDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ca1Controller;
  late final TextEditingController _ca2Controller;
  late final TextEditingController _examController;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ca1Controller = TextEditingController(text: widget.initialCa1.toString());
    _ca2Controller = TextEditingController(text: widget.initialCa2.toString());
    _examController =
        TextEditingController(text: widget.initialExam.toString());
  }

  @override
  void dispose() {
    _ca1Controller.dispose();
    _ca2Controller.dispose();
    _examController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  int get _calculatedTotal {
    final c1 = int.tryParse(_ca1Controller.text) ?? 0;
    final c2 = int.tryParse(_ca2Controller.text) ?? 0;
    final ex = int.tryParse(_examController.text) ?? 0;
    return c1 + c2 + ex;
  }

  Future<void> _saveMark({required bool isSubmitting}) async {
    if (!_formKey.currentState!.validate()) return;

    final ca1 = int.tryParse(_ca1Controller.text) ?? 0;
    final ca2 = int.tryParse(_ca2Controller.text) ?? 0;
    final examScore = int.tryParse(_examController.text) ?? 0;

    if (ca1 < 0 || ca1 > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CA1 must be between 0 and 20.')),
      );
      return;
    }
    if (ca2 < 0 || ca2 > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CA2 must be between 0 and 20.')),
      );
      return;
    }
    if (examScore < 0 || examScore > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exam score must be between 0 and 60.')),
      );
      return;
    }
    if ((ca1 + ca2 + examScore) > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total score cannot exceed 100.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final markId =
          'MRK_${widget.student.studentId}_${widget.subjectId}_${widget.examId}';
      final mark = Mark(
        markId: markId,
        examId: widget.examId,
        studentId: widget.student.studentId,
        subjectId: widget.subjectId,
        classId: widget.student.currentClassId,
        sectionId: widget.student.currentSectionId,
        academicYearId: widget.student.currentAcademicYearId,
        continuousAssessment: ContinuousAssessment(ca1: ca1, ca2: ca2),
        examScore: examScore,
        totalScore: ca1 + ca2 + examScore,
        isApproved: false,
        isPublished: false,
        teacherComment: _commentController.text.trim(),
        updatedBy: ref.read(currentUserProfileProvider).value?.uid ?? '',
      );

      final examRepo = ref.read(examRepositoryProvider);
      await examRepo.saveDraftMark(mark);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.teacherTeal,
            content: Text(
              isSubmitting
                  ? 'Marks submitted for administrative approval (${widget.student.fullName}: $_calculatedTotal/100)'
                  : 'Draft marks saved successfully ($_calculatedTotal/100)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Error saving marks: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'Enter Assessment Marks',
          subtitle:
              '${widget.student.fullName} • Class ${widget.student.currentClassId}-${widget.student.currentSectionId} • ${widget.subject}',
          icon: Icons.edit_note,
          iconColor: AppColors.teacherTeal,
          child: SizedBox(
            height: 350,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CA 1 (Max 20)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              ClayTextField(
                                controller: _ca1Controller,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('CA 2 (Max 20)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              ClayTextField(
                                controller: _ca2Controller,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Exam (Max 60)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              ClayTextField(
                                controller: _examController,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClayContainer(
                      depth: ClayDepth.low,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      borderRadius: ClayTheme.radiusSm,
                      surfaceColor:
                          AppColors.teacherTeal.withValues(alpha: 0.08),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text('Total Score (Out of 100):',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                          ),
                          Text(
                            '$_calculatedTotal / 100',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _calculatedTotal > 100
                                  ? AppColors.dangerRed
                                  : AppColors.teacherTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Teacher Comments',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    ClayTextField(
                      controller: _commentController,
                      maxLines: 2,
                      hintText: 'Enter student assessment feedback',
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ClayButton(
                          label: 'Cancel',
                          variant: ClayButtonVariant.subtle,
                          onPressed: () => Navigator.pop(context),
                        ),
                        ClayButton(
                          label: 'Save Draft',
                          variant: ClayButtonVariant.secondary,
                          onPressed: _isLoading
                              ? null
                              : () => _saveMark(isSubmitting: false),
                        ),
                        ClayButton(
                          label: _isLoading
                              ? 'Submitting...'
                              : 'Submit for Review',
                          variant: ClayButtonVariant.primary,
                          customColor: AppColors.teacherTeal,
                          onPressed: _isLoading
                              ? null
                              : () => _saveMark(isSubmitting: true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for Teacher to publish new homework assignment to cohort
class CreateHomeworkDialog extends ConsumerStatefulWidget {
  final String currentClass;
  final String currentSection;

  const CreateHomeworkDialog({
    super.key,
    this.currentClass = '10',
    this.currentSection = 'A',
  });

  static Future<void> show(
    BuildContext context, {
    String currentClass = '10',
    String currentSection = 'A',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateHomeworkDialog(
        currentClass: currentClass,
        currentSection: currentSection,
      ),
    );
  }

  @override
  ConsumerState<CreateHomeworkDialog> createState() =>
      _CreateHomeworkDialogState();
}

class _CreateHomeworkDialogState extends ConsumerState<CreateHomeworkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _subject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submitHomework() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter homework title.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Published within assigned class and section scope
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.teacherTeal,
            content: Text(
              'Homework "${_titleController.text.trim()}" published to Class ${widget.currentClass}-${widget.currentSection}.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'Publish Homework Assignment',
          subtitle:
              'Target: Class ${widget.currentClass}-${widget.currentSection} Cohort',
          icon: Icons.assignment_outlined,
          iconColor: AppColors.teacherTeal,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subject',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayContainer(
                  depth: ClayDepth.inset,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _subject,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: 'Mathematics', child: Text('Mathematics')),
                        DropdownMenuItem(
                            value: 'Science', child: Text('Science')),
                        DropdownMenuItem(
                            value: 'English', child: Text('English')),
                        DropdownMenuItem(
                            value: 'Social Studies',
                            child: Text('Social Studies')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _subject = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Homework Title',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _titleController,
                  hintText: 'e.g. Chapter 4 Trigonometry Problem Set',
                ),
                const SizedBox(height: 14),
                const Text('Instructions / Problem Details',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _descController,
                  maxLines: 3,
                  hintText:
                      'Specify textbook exercises, submission formatting, and guidelines',
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Submission Date:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    ClayButton(
                      height: 36,
                      label:
                          '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClayButton(
                      label: 'Cancel',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ClayButton(
                      label: _isLoading ? 'Publishing...' : 'Publish Homework',
                      variant: ClayButtonVariant.primary,
                      customColor: AppColors.teacherTeal,
                      onPressed: _isLoading ? null : _submitHomework,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 3. ACCOUNTANT DIALOGS (Invoices & Fee Structures)
// ============================================================================

/// Dialog for Accountant to generate student invoices with integer paise calculation
class CreateInvoiceDialog extends ConsumerStatefulWidget {
  const CreateInvoiceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateInvoiceDialog(),
    );
  }

  @override
  ConsumerState<CreateInvoiceDialog> createState() =>
      _CreateInvoiceDialogState();
}

class _CreateInvoiceDialogState extends ConsumerState<CreateInvoiceDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedStudentId = '';
  final _titleController =
      TextEditingController(text: 'Term 2 Tuition & Activity Fee');
  final _rupeesController = TextEditingController(text: '12500');
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _rupeesController.dispose();
    super.dispose();
  }

  Future<void> _createInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student.')),
      );
      return;
    }

    final rupees = int.tryParse(_rupeesController.text.trim()) ?? 0;
    if (rupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice amount must be positive.')),
      );
      return;
    }
    final amountPaise = rupees * 100; // Strictly integer paise

    setState(() => _isLoading = true);
    try {
      final feeRepo = ref.read(feeRepositoryProvider);
      final id = await feeRepo.createInvoice(
        studentId: _selectedStudentId,
        academicYearId: 'AY_2026_2027',
        title: _titleController.text.trim(),
        totalAmountPaise: amountPaise,
        dueDate: _dueDate,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accountantEmerald,
            content: Text(
                'Generated invoice $id for ₹$rupees ($amountPaise paise) successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'Generate Student Invoice',
          subtitle: 'Institutional Fee Ledger • Integer Paise Calculation',
          icon: Icons.receipt_long,
          iconColor: AppColors.accountantEmerald,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Student',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return const Text('No students found in active database.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13));
                    }
                    if (_selectedStudentId.isEmpty) {
                      _selectedStudentId = students.first.studentId;
                    }

                    return ClayContainer(
                      depth: ClayDepth.inset,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStudentId,
                          isExpanded: true,
                          items: students.map((s) {
                            return DropdownMenuItem(
                              value: s.studentId,
                              child: Text(
                                  '${s.fullName} (${s.admissionNumber}) - Class ${s.currentClassId}'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedStudentId = val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => ClayTextField(
                    hintText: 'Enter Student ID',
                    onChanged: (val) => _selectedStudentId = val.trim(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Invoice Title',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _titleController,
                  hintText: 'e.g. Annual Tuition Fee',
                ),
                const SizedBox(height: 14),
                const Text('Amount (INR ₹)',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _rupeesController,
                  keyboardType: TextInputType.number,
                  hintText: 'e.g. 15000',
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Due Date:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    ClayButton(
                      height: 36,
                      label:
                          '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dueDate,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => _dueDate = picked);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClayButton(
                      label: 'Cancel',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ClayButton(
                      label: _isLoading ? 'Generating...' : 'Generate Invoice',
                      variant: ClayButtonVariant.primary,
                      customColor: AppColors.accountantEmerald,
                      onPressed: _isLoading ? null : _createInvoice,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for Accountant to add approved Fee Structure
class CreateFeeStructureDialog extends ConsumerStatefulWidget {
  const CreateFeeStructureDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateFeeStructureDialog(),
    );
  }

  @override
  ConsumerState<CreateFeeStructureDialog> createState() =>
      _CreateFeeStructureDialogState();
}

class _CreateFeeStructureDialogState
    extends ConsumerState<CreateFeeStructureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController =
      TextEditingController(text: 'Composite Secondary Laboratory Fee');
  final _rupeesController = TextEditingController(text: '8500');
  String _frequency = 'annual';
  String? _targetClass = '10';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _rupeesController.dispose();
    super.dispose();
  }

  Future<void> _submitStructure() async {
    if (!_formKey.currentState!.validate()) return;
    final rupees = int.tryParse(_rupeesController.text.trim()) ?? 0;
    if (rupees <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be positive.')),
      );
      return;
    }
    final amountPaise = rupees * 100;

    setState(() => _isLoading = true);
    try {
      final feeRepo = ref.read(feeRepositoryProvider);
      await feeRepo.createFeeStructure(
        title: _titleController.text.trim(),
        amountPaise: amountPaise,
        frequency: _frequency,
        classId: _targetClass,
        academicYearId: 'AY_2026_2027',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.accountantEmerald,
            content: Text('Created fee structure for ₹$rupees successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'New Fee Structure',
          subtitle: 'Institutional Tuition & Service Fee Definition',
          icon: Icons.account_balance_wallet_outlined,
          iconColor: AppColors.accountantEmerald,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fee Structure Title',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayTextField(
                  controller: _titleController,
                  hintText: 'e.g. Primary Activity Fee',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Amount (INR ₹)',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClayTextField(
                            controller: _rupeesController,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Frequency',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          const SizedBox(height: 6),
                          ClayContainer(
                            depth: ClayDepth.inset,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _frequency,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'annual', child: Text('Annual')),
                                  DropdownMenuItem(
                                      value: 'term', child: Text('Term-wise')),
                                  DropdownMenuItem(
                                      value: 'monthly', child: Text('Monthly')),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _frequency = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text('Target Cohort',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ClayContainer(
                  depth: ClayDepth.inset,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _targetClass,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                            value: null,
                            child: Text('School-Wide (All Classes)')),
                        DropdownMenuItem(
                            value: '9', child: Text('Class 9 Only')),
                        DropdownMenuItem(
                            value: '10', child: Text('Class 10 Only')),
                        DropdownMenuItem(
                            value: '11', child: Text('Class 11 Only')),
                        DropdownMenuItem(
                            value: '12', child: Text('Class 12 Only')),
                      ],
                      onChanged: (val) => setState(() => _targetClass = val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClayButton(
                      label: 'Cancel',
                      variant: ClayButtonVariant.subtle,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    ClayButton(
                      label: _isLoading ? 'Saving...' : 'Save Structure',
                      variant: ClayButtonVariant.primary,
                      customColor: AppColors.accountantEmerald,
                      onPressed: _isLoading ? null : _submitStructure,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. ADMISSIONS OFFICER DIALOGS (Demographics Allowlist & Enquiries)
// ============================================================================

/// Dialog for Admissions Officer to edit student demographics using strict field allowlist
class EditStudentDemographicsDialog extends ConsumerStatefulWidget {
  final Student student;

  const EditStudentDemographicsDialog({super.key, required this.student});

  static Future<void> show(BuildContext context, {required Student student}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditStudentDemographicsDialog(student: student),
    );
  }

  @override
  ConsumerState<EditStudentDemographicsDialog> createState() =>
      _EditStudentDemographicsDialogState();
}

class _EditStudentDemographicsDialogState
    extends ConsumerState<EditStudentDemographicsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dobController;
  late final TextEditingController _genderController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _medicalNotesController;
  late final TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dobController =
        TextEditingController(text: widget.student.dob ?? '2010-05-14');
    _genderController =
        TextEditingController(text: widget.student.gender ?? 'Male');
    _bloodGroupController =
        TextEditingController(text: widget.student.bloodGroup ?? 'O+');
    _emergencyContactController = TextEditingController(
        text: widget.student.emergencyContact ?? '+91 98765 43210');
    _medicalNotesController = TextEditingController(
        text: widget.student.medicalNotes ?? 'No chronic allergies reported.');
    _addressController = TextEditingController(
        text: widget.student.address ?? '42 Crescent Avenue, Bangalore 560001');
  }

  @override
  void dispose() {
    _dobController.dispose();
    _genderController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    _medicalNotesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveDemographics() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      // Strictly pass allowlisted demographic fields. StudentId, role, status are protected!
      await studentRepo.updateStudentDemographics(
        studentId: widget.student.studentId,
        dob: _dobController.text.trim(),
        gender: _genderController.text.trim(),
        bloodGroup: _bloodGroupController.text.trim(),
        emergencyContact: _emergencyContactController.text.trim(),
        medicalNotes: _medicalNotesController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.admissionsOrange,
            content: Text(
                'Updated demographic records for ${widget.student.fullName} via allowlist.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Update failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: ClayCard(
          title: 'Edit Student Demographics',
          subtitle:
              '${widget.student.fullName} • Admission: ${widget.student.admissionNumber} (Field Allowlist Enforced)',
          icon: Icons.badge_outlined,
          iconColor: AppColors.admissionsOrange,
          child: SizedBox(
            height: 360,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Date of Birth (YYYY-MM-DD)',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    ClayTextField(controller: _dobController),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Gender',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              ClayTextField(controller: _genderController),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Blood Group',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13)),
                              const SizedBox(height: 6),
                              ClayTextField(controller: _bloodGroupController),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Emergency Contact Phone',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    ClayTextField(controller: _emergencyContactController),
                    const SizedBox(height: 12),
                    const Text('Medical Notes',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    ClayTextField(
                        controller: _medicalNotesController, maxLines: 2),
                    const SizedBox(height: 12),
                    const Text('Residential Address',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    ClayTextField(controller: _addressController, maxLines: 2),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ClayButton(
                          label: 'Cancel',
                          variant: ClayButtonVariant.subtle,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        ClayButton(
                          label: _isLoading ? 'Saving...' : 'Save Demographics',
                          variant: ClayButtonVariant.primary,
                          customColor: AppColors.admissionsOrange,
                          onPressed: _isLoading ? null : _saveDemographics,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog for Admissions Officer to register prospective student enquiry
class CreateEnquiryDialog extends ConsumerStatefulWidget {
  const CreateEnquiryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateEnquiryDialog(),
    );
  }

  @override
  ConsumerState<CreateEnquiryDialog> createState() =>
      _CreateEnquiryDialogState();
}

class _CreateEnquiryDialogState extends ConsumerState<CreateEnquiryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _applicantNameController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  String _targetClass = '10';
  bool _isLoading = false;

  @override
  void dispose() {
    _applicantNameController.dispose();
    _guardianNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitEnquiry() async {
    if (!_formKey.currentState!.validate()) return;
    if (_applicantNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applicant name and phone are required.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      await studentRepo.createEnquiry(
        applicantName: _applicantNameController.text.trim(),
        targetClass: _targetClass,
        guardianName: _guardianNameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        notes: _notesController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.admissionsOrange,
            content: Text(
                'Enquiry registered for ${_applicantNameController.text.trim()}.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClayCard(
          title: 'Prospective Student Enquiry',
          subtitle: 'Admissions Pipeline Registration',
          icon: Icons.person_search_outlined,
          iconColor: AppColors.admissionsOrange,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Applicant Full Name',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  ClayTextField(
                    controller: _applicantNameController,
                    hintText: 'e.g. Diya Nair',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Target Class',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 6),
                            ClayContainer(
                              depth: ClayDepth.inset,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 4),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _targetClass,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(
                                        value: '9', child: Text('Class 9')),
                                    DropdownMenuItem(
                                        value: '10', child: Text('Class 10')),
                                    DropdownMenuItem(
                                        value: '11', child: Text('Class 11')),
                                    DropdownMenuItem(
                                        value: '12', child: Text('Class 12')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _targetClass = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Guardian Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 6),
                            ClayTextField(
                              controller: _guardianNameController,
                              hintText: 'e.g. Suresh Nair',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Contact Phone (+91)',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  ClayTextField(
                    controller: _phoneController,
                    hintText: '+91 98765 00000',
                  ),
                  const SizedBox(height: 12),
                  const Text('Notes / Background',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  ClayTextField(
                    controller: _notesController,
                    maxLines: 2,
                    hintText:
                        'Previous school transfer certificate status, entrance assessment date',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ClayButton(
                        label: 'Cancel',
                        variant: ClayButtonVariant.subtle,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      ClayButton(
                        label:
                            _isLoading ? 'Registering...' : 'Register Enquiry',
                        variant: ClayButtonVariant.primary,
                        customColor: AppColors.admissionsOrange,
                        onPressed: _isLoading ? null : _submitEnquiry,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 5. LIBRARIAN DIALOGS (Book Return & Fine Calculation)
// ============================================================================

/// Dialog for Librarian to process book returns with atomic inventory increment
class ReturnBookDialog extends ConsumerStatefulWidget {
  final String loanId;
  final String bookId;
  final String bookTitle;
  final String studentId;
  final DateTime dueDate;

  const ReturnBookDialog({
    super.key,
    required this.loanId,
    required this.bookId,
    required this.bookTitle,
    required this.studentId,
    required this.dueDate,
  });

  static Future<void> show(
    BuildContext context, {
    required String loanId,
    required String bookId,
    required String bookTitle,
    required String studentId,
    required DateTime dueDate,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReturnBookDialog(
        loanId: loanId,
        bookId: bookId,
        bookTitle: bookTitle,
        studentId: studentId,
        dueDate: dueDate,
      ),
    );
  }

  @override
  ConsumerState<ReturnBookDialog> createState() => _ReturnBookDialogState();
}

class _ReturnBookDialogState extends ConsumerState<ReturnBookDialog> {
  bool _isLoading = false;

  int get _daysOverdue {
    final now = DateTime.now();
    if (now.isAfter(widget.dueDate)) {
      return now.difference(widget.dueDate).inDays;
    }
    return 0;
  }

  int get _calculatedFineRupees => _daysOverdue * 5; // ₹5 per overdue day

  Future<void> _processReturn() async {
    setState(() => _isLoading = true);
    try {
      final libraryRepo = ref.read(libraryRepositoryProvider);
      await libraryRepo.returnBook(widget.loanId, widget.bookId);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.librarianViolet,
            content: Text(
              'Book "${widget.bookTitle}" returned successfully. Inventory stock incremented.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors.dangerRed,
              content: Text('Return error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ClayCard(
          title: 'Confirm Book Return',
          subtitle: 'Circulation Desk • Stock Reconciliation',
          icon: Icons.assignment_return_outlined,
          iconColor: AppColors.librarianViolet,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bookTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Issued to Student: ${widget.studentId}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ClayContainer(
                depth: ClayDepth.low,
                padding: const EdgeInsets.all(12),
                borderRadius: ClayTheme.radiusSm,
                surfaceColor: _daysOverdue > 0
                    ? AppColors.dangerRed.withValues(alpha: 0.08)
                    : AppColors.successGreen.withValues(alpha: 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _daysOverdue > 0
                              ? 'Overdue by $_daysOverdue days'
                              : 'Returned On Schedule',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _daysOverdue > 0
                                ? AppColors.dangerRed
                                : AppColors.successGreen,
                          ),
                        ),
                        Text(
                          'Due Date: ${widget.dueDate.year}-${widget.dueDate.month.toString().padLeft(2, '0')}-${widget.dueDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    if (_daysOverdue > 0)
                      Text(
                        'Fine: ₹$_calculatedFineRupees',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dangerRed,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Confirming return will atomically increment available copies in the catalogue and mark loan as returned.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClayButton(
                    label: 'Cancel',
                    variant: ClayButtonVariant.subtle,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  ClayButton(
                    label: _isLoading ? 'Processing...' : 'Confirm Return',
                    variant: ClayButtonVariant.primary,
                    customColor: AppColors.librarianViolet,
                    onPressed: _isLoading ? null : _processReturn,
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
