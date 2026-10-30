import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/breakpoints.dart';
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
    required Uint8List fileBytes,
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
      required Uint8List fileBytes,
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
  PlatformFile? _selectedFile;
  Uint8List? _selectedFileBytes;
  int _selectedFileSize = 0;
  late String _classId;
  late String _sectionId;
  String _subject = 'SUB_MATH';
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
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'zip',
          'png',
          'jpg',
          'jpeg',
          'webp',
          'doc',
          'docx'
        ],
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        setState(() => _errorMessage =
            'The selected file could not be read. Try selecting it again.');
        return;
      }
      final size = file.lengthSync() ?? bytes.length;
      if (size > 25 * 1024 * 1024) {
        setState(() => _errorMessage = 'Files must be 25 MB or smaller.');
        return;
      }
      setState(() {
        _selectedFile = file;
        _selectedFileBytes = bytes;
        _selectedFileSize = size;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() => _errorMessage = 'File selection failed: $e');
    }
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileBytes == null || _selectedFile == null) {
      setState(() => _errorMessage = 'Select a real file before uploading.');
      return;
    }

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
        fileName: _selectedFile!.name,
        fileBytes: _selectedFileBytes!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Study material uploaded to secure storage and registered.')),
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
          Expanded(
            child: Text(
              'Upload Class Study Material',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: AppResponsive.dialogConstraints(context, maxWidth: 460),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Material Title',
                      hintText: 'e.g. Chapter 5 Summary & Exercises'),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                AdaptiveFormRow(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _classId,
                      decoration: const InputDecoration(labelText: 'Class'),
                      items: const [
                        DropdownMenuItem(value: '10', child: Text('Class 10')),
                        DropdownMenuItem(value: '9', child: Text('Class 9')),
                        DropdownMenuItem(value: '8', child: Text('Class 8')),
                      ],
                      onChanged: (v) => setState(() => _classId = v!),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _sectionId,
                      decoration: const InputDecoration(labelText: 'Section'),
                      items: const [
                        DropdownMenuItem(value: 'A', child: Text('Section A')),
                        DropdownMenuItem(value: 'B', child: Text('Section B')),
                      ],
                      onChanged: (v) => setState(() => _sectionId = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  items: const [
                    DropdownMenuItem(
                        value: 'SUB_MATH', child: Text('Mathematics')),
                    DropdownMenuItem(
                        value: 'SUB_SCI', child: Text('Science & Lab')),
                    DropdownMenuItem(
                        value: 'SUB_ENG', child: Text('English Literature')),
                    DropdownMenuItem(
                        value: 'SUB_SOC', child: Text('Social Studies')),
                  ],
                  onChanged: (v) => setState(() => _subject = v!),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(_selectedFile == null
                      ? 'Choose a document'
                      : 'Change document'),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _selectedFile == null
                        ? 'PDF, ZIP, image or Word document • max 25 MB'
                        : '${_selectedFile!.name} • ${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!,
                      style: const TextStyle(
                          color: AppColors.dangerRed, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.teacherTeal),
          onPressed: _isLoading ? null : _handleUpload,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Publish Material'),
        ),
      ],
    );
  }
}
