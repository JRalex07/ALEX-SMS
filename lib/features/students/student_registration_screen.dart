import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../providers/child_context_provider.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Register New Student
/// Route: /students/add
class StudentRegistrationScreen extends ConsumerStatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  ConsumerState<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState
    extends ConsumerState<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _admissionNumController = TextEditingController();
  final _rollNumController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _guardianPhoneController = TextEditingController();

  String _selectedClass = '10';
  String _selectedSection = 'A';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _admissionNumController.dispose();
    _rollNumController.dispose();
    _emergencyContactController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final newStudentId = 'STU_${DateTime.now().millisecondsSinceEpoch}';
      final student = Student(
        studentId: newStudentId,
        schoolId: 'SCH_001',
        admissionNumber: _admissionNumController.text.trim(),
        fullName: _nameController.text.trim(),
        currentClassId: _selectedClass,
        currentSectionId: _selectedSection,
        currentAcademicYearId: 'AY_2026_2027',
        status: 'enrolled',
        guardianUserIds: const [],
        emergencyContact: _emergencyContactController.text.trim().isNotEmpty
            ? _emergencyContactController.text.trim()
            : null,
      );

      await ref.read(studentRepositoryProvider).enrollStudent(student);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully registered student: ${student.fullName}'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.go(AppRoutes.students);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to register student: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Register New Student',
      currentRoute: AppRoutes.studentAdd,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ErpCard(
              title: 'Student Enrollment Form',
              subtitle: 'Enroll a new student into LAV Academy academic records',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please enter student full name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _admissionNumController,
                            decoration: const InputDecoration(
                              labelText: 'Admission Number *',
                              prefixIcon: Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _rollNumController,
                            decoration: const InputDecoration(
                              labelText: 'Roll Number',
                              prefixIcon: Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Class *',
                              prefixIcon: Icon(Icons.school_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: '10', child: Text('Class 10')),
                              DropdownMenuItem(value: '9', child: Text('Class 9')),
                              DropdownMenuItem(value: '8', child: Text('Class 8')),
                              DropdownMenuItem(value: '7', child: Text('Class 7')),
                              DropdownMenuItem(value: '6', child: Text('Class 6')),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedClass = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedSection,
                            decoration: const InputDecoration(
                              labelText: 'Section *',
                              prefixIcon: Icon(Icons.view_column_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'A', child: Text('Section A')),
                              DropdownMenuItem(value: 'B', child: Text('Section B')),
                              DropdownMenuItem(value: 'C', child: Text('Section C')),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedSection = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emergencyContactController,
                            decoration: const InputDecoration(
                              labelText: 'Emergency Contact Phone',
                              prefixIcon: Icon(Icons.phone_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _guardianPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Guardian Verified Phone',
                              prefixIcon: Icon(Icons.family_restroom_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.students),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ErpButton(
                          label: _isSubmitting
                              ? 'Enrolling Student...'
                              : 'Register & Enroll Student',
                          icon: Icons.check_circle_outline,
                          onPressed: _isSubmitting ? null : _submitRegistration,
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
