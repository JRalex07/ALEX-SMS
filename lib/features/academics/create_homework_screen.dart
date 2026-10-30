import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Create Homework Assignment
/// Route: /academics/homework/create
class CreateHomeworkScreen extends ConsumerStatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  ConsumerState<CreateHomeworkScreen> createState() =>
      _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends ConsumerState<CreateHomeworkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedClass = '10';
  String _selectedSection = 'A';
  String _selectedSubject = 'Mathematics';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submitHomework() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Assignment "${_titleController.text.trim()}" published for Class $_selectedClass-$_selectedSection!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go(AppRoutes.academicsHomework);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Create Homework Assignment',
      currentRoute: AppRoutes.academicsHomeworkCreate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ErpCard(
              title: 'New Homework Specification',
              subtitle:
                  'Publish coursework requirements, attachments, and due date to student & parent portals',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Assignment Title *',
                        hintText: 'e.g. Quadratic Equations Exercise 4.2',
                        prefixIcon: Icon(Icons.assignment_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Please provide an assignment title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Target Class *',
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
                            onChanged: (v) =>
                                setState(() => _selectedClass = v!),
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
                            onChanged: (v) =>
                                setState(() => _selectedSection = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubject,
                      decoration: const InputDecoration(
                        labelText: 'Subject *',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Mathematics', child: Text('Mathematics')),
                        DropdownMenuItem(
                            value: 'Science', child: Text('Science')),
                        DropdownMenuItem(
                            value: 'English', child: Text('English')),
                        DropdownMenuItem(
                            value: 'Social Science',
                            child: Text('Social Science')),
                        DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      ],
                      onChanged: (v) => setState(() => _selectedSubject = v!),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      leading: const Icon(Icons.calendar_today,
                          color: AppColors.brandNavy),
                      title: const Text('Submission Deadline'),
                      subtitle: Text(_dueDate.toLocal().toString().split(' ')[0]),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Instructions & Reference Problems',
                        hintText:
                            'Provide detailed problem statements or submission guidance...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              context.go(AppRoutes.academicsHomework),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ErpButton(
                          label: _isSaving
                              ? 'Publishing Task...'
                              : 'Publish Assignment',
                          icon: Icons.check_circle_outline,
                          onPressed: _isSaving ? null : _submitHomework,
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
