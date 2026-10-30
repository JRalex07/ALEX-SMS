import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../models/notice_model.dart';

class CreateNoticeDialog extends StatefulWidget {
  final Future<void> Function(Notice notice)? onNoticeCreated;

  const CreateNoticeDialog({super.key, this.onNoticeCreated});

  static Future<void> show(BuildContext context,
      {Future<void> Function(Notice notice)? onNoticeCreated}) {
    return showDialog(
      context: context,
      builder: (ctx) => CreateNoticeDialog(onNoticeCreated: onNoticeCreated),
    );
  }

  @override
  State<CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends State<CreateNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _targetAudience = 'all';
  String _priority = 'high';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final noticeId = 'NOT_${DateTime.now().millisecondsSinceEpoch}';
      final notice = Notice(
        noticeId: noticeId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        targetAudience: _targetAudience,
        priority: _priority,
        authorUid: '',
        authorName: 'School Administration',
        isPublished: true,
        createdAt: DateTime.now(),
        publishedAt: DateTime.now(),
      );

      if (widget.onNoticeCreated != null) {
        await widget.onNoticeCreated!(notice);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Institutional Notice published successfully!')),
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
          Icon(Icons.campaign, color: AppColors.brandNavy),
          SizedBox(width: 8),
          Text('Publish Institutional Notice',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Notice Title',
                    hintText: 'e.g. Annual Sports Day 2026'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Notice title is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                    labelText: 'Notice Body / Details',
                    hintText: 'Full announcement text...'),
                maxLines: 4,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Notice content is required'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _targetAudience,
                      decoration:
                          const InputDecoration(labelText: 'Target Audience'),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Users')),
                        DropdownMenuItem(
                            value: 'parents', child: Text('Parents Only')),
                        DropdownMenuItem(
                            value: 'teachers', child: Text('Teachers Only')),
                      ],
                      onChanged: (val) =>
                          setState(() => _targetAudience = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priority,
                      decoration:
                          const InputDecoration(labelText: 'Priority Level'),
                      items: const [
                        DropdownMenuItem(
                            value: 'high', child: Text('High Priority')),
                        DropdownMenuItem(
                            value: 'medium', child: Text('Normal Priority')),
                        DropdownMenuItem(
                            value: 'low', child: Text('Low Priority')),
                      ],
                      onChanged: (val) => setState(() => _priority = val!),
                    ),
                  ),
                ],
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
      actions: [
        TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton.icon(
          icon: const Icon(Icons.send, size: 16),
          label: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Publish Notice'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandNavy),
          onPressed: _isLoading ? null : _handleSave,
        ),
      ],
    );
  }
}
