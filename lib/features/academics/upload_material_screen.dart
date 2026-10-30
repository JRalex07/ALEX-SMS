import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Upload Study Material
/// Route: /academics/materials/upload
class UploadMaterialScreen extends ConsumerStatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  ConsumerState<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  String _selectedClass = '10';
  String _selectedSection = 'A';
  String _selectedSubject = 'Mathematics';
  final String _selectedFileName = 'Course_Syllabus_Module_4.pdf';
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submitUpload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Material "${_titleController.text.trim()}" successfully published to Class $_selectedClass-$_selectedSection!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go(AppRoutes.academicsMaterials);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Upload Study Material',
      currentRoute: AppRoutes.academicsMaterialsUpload,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ErpCard(
              title: 'Curriculum Repository Upload Desk',
              subtitle:
                  'Publish lecture notes, question banks, or lab manuals to classroom portals',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Document Title *',
                        hintText: 'e.g. Chapter 4 Practice Workbook',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please provide document title'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Target Standard *',
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
                        labelText: 'Academic Subject *',
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
                      ],
                      onChanged: (v) => setState(() => _selectedSubject = v!),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.borderLight, style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf,
                              color: AppColors.dangerRed, size: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedFileName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                const Text(
                                  'Ready to upload (PDF, 2.1 MB) • SHA-256 Verified',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('File picker ready.')),
                              );
                            },
                            child: const Text('Change File'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              context.go(AppRoutes.academicsMaterials),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ErpButton(
                          label: _isUploading
                              ? 'Uploading & Indexing...'
                              : 'Publish Material',
                          icon: Icons.cloud_upload_outlined,
                          onPressed: _isUploading ? null : _submitUpload,
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
