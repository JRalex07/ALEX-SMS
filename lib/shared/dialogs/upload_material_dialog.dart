import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';

class UploadMaterialDialog extends StatefulWidget {
  final String defaultClass;
  final String defaultSection;
  final Future<void> Function({
    required String title,
    required String classId,
    required String sectionId,
    required String subject,
    required String fileName,
  }) onUpload;

  const UploadMaterialDialog({
    super.key,
    this.defaultClass = '10',
    this.defaultSection = 'A',
    required this.onUpload,
  });

  static Future<void> show(
    BuildContext context, {
    String defaultClass = '10',
    String defaultSection = 'A',
    required Future<void> Function({
      required String title,
      required String classId,
      required String sectionId,
      required String subject,
      required String fileName,
    }) onUpload,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => UploadMaterialDialog(
        defaultClass: defaultClass,
        defaultSection: defaultSection,
        onUpload: onUpload,
      ),
    );
  }

  @override
  State<UploadMaterialDialog> createState() => _UploadMaterialDialogState();
}

class _UploadMaterialDialogState extends State<UploadMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _fileNameCtrl = TextEditingController(text: 'Chapter_5_Calculus_Notes.pdf');
  late String _classId;
  late String _sectionId;
  String _subject = 'Mathematics';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _classId = widget.defaultClass;
    _sectionId = widget.defaultSection;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _fileNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onUpload(
        title: _titleCtrl.text.trim(),
        classId: _classId,
        sectionId: _sectionId,
        subject: _subject,
        fileName: _fileNameCtrl.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study material uploaded and published successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.upload_file, color: AppColors.teacherTeal),
          SizedBox(width: 8),
          Text('Upload Class Study Material', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Material Title', hintText: 'e.g. Chapter 5 Summary & Exercises'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _classId,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: const [
                        DropdownMenuItem(value: '10', child: Text('Class 10')),
                        DropdownMenuItem(value: '9', child: Text('Class 9')),
                        DropdownMenuItem(value: '8', child: Text('Class 8')),
                      ],
                      onChanged: (v) => setState(() => _classId = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _sectionId,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Section A')),
                        DropdownMenuItem(value: 'B', child: Text('Section B')),
                      ],
                      onChanged: (v) => setState(() => _sectionId = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _subject,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: const [
                  DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                  DropdownMenuItem(value: 'Science & Lab', child: Text('Science & Lab')),
                  DropdownMenuItem(value: 'English Literature', child: Text('English Literature')),
                  DropdownMenuItem(value: 'Social Studies', child: Text('Social Studies')),
                ],
                onChanged: (v) => setState(() => _subject = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fileNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Document File Name',
                  prefixIcon: Icon(Icons.picture_as_pdf, size: 18),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'File name is required' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.teacherTeal),
          onPressed: _isLoading ? null : _handleUpload,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Publish Material'),
        ),
      ],
    );
  }
}
