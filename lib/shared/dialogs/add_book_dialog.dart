import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../models/library_model.dart';

class AddBookDialog extends StatefulWidget {
  final Future<void> Function(LibraryBook book)? onBookAdded;

  const AddBookDialog({super.key, this.onBookAdded});

  static Future<void> show(BuildContext context, {Future<void> Function(LibraryBook book)? onBookAdded}) {
    return showDialog(
      context: context,
      builder: (ctx) => AddBookDialog(onBookAdded: onBookAdded),
    );
  }

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _isbnCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'General Science');
  final _copiesCtrl = TextEditingController(text: '10');
  final _shelfCtrl = TextEditingController(text: 'Stack A-3');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _isbnCtrl.dispose();
    _categoryCtrl.dispose();
    _copiesCtrl.dispose();
    _shelfCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final copies = int.tryParse(_copiesCtrl.text.trim()) ?? 1;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookId = 'BK_${DateTime.now().millisecondsSinceEpoch}';
      final book = LibraryBook(
        bookId: bookId,
        title: _titleCtrl.text.trim(),
        author: _authorCtrl.text.trim(),
        isbn: _isbnCtrl.text.trim(),
        totalCopies: copies,
        availableCopies: copies,
        category: _categoryCtrl.text.trim(),
      );

      if (widget.onBookAdded != null) {
        await widget.onBookAdded!(book);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${book.title}" added to catalogue successfully!')),
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
          Icon(Icons.bookmark_add, color: AppColors.librarianViolet),
          SizedBox(width: 8),
          Text('Add New Title to Catalogue', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Book Title', hintText: 'e.g. NCERT Physics Class 10'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Author is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(labelText: 'Category / Subject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _copiesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total Copies'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Must be >= 1';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _isbnCtrl,
                        decoration: const InputDecoration(labelText: 'ISBN Code'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _shelfCtrl,
                        decoration: const InputDecoration(labelText: 'Shelf Location'),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(_errorMessage!, style: const TextStyle(color: AppColors.dangerRed, fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.librarianViolet),
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Add Title'),
        ),
      ],
    );
  }
}
