import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/library_model.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Issue Book (Circulation Desk)
/// Route: /library/issue
class IssueBookScreen extends ConsumerStatefulWidget {
  const IssueBookScreen({super.key});

  @override
  ConsumerState<IssueBookScreen> createState() => _IssueBookScreenState();
}

class _IssueBookScreenState extends ConsumerState<IssueBookScreen> {
  final _formKey = GlobalKey<FormState>();
  LibraryBook? _selectedBook;
  Student? _selectedStudent;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 14));
  bool _isIssuing = false;

  Future<void> _submitIssue() async {
    if (_selectedBook == null || _selectedStudent == null) return;

    setState(() => _isIssuing = true);

    try {
      await ref.read(libraryRepositoryProvider).issueBook(
            bookId: _selectedBook!.bookId,
            studentId: _selectedStudent!.studentId,
            days: _dueDate.difference(DateTime.now()).inDays.clamp(1, 365),
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Successfully issued "${_selectedBook!.title}" to ${_selectedStudent!.fullName}!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.go(AppRoutes.libraryLoans);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to issue book: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isIssuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(allBooksStreamProvider);
    final studentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Issue Book (Circulation Desk)',
      currentRoute: AppRoutes.libraryIssue,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.assignment_return_outlined, size: 16),
          label: const Text('Return Desk'),
          onPressed: () => context.go(AppRoutes.libraryReturn),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ErpCard(
              title: 'Book Circulation Issue Voucher',
              subtitle:
                  'Check out catalog volumes to enrolled student library accounts',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    booksAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading books: $e'),
                      data: (books) {
                        final available =
                            books.where((b) => b.availableCopies > 0).toList();

                        return DropdownButtonFormField<LibraryBook>(
                          initialValue: _selectedBook,
                          decoration: const InputDecoration(
                            labelText: 'Select Book Title *',
                            prefixIcon: Icon(Icons.menu_book),
                            border: OutlineInputBorder(),
                          ),
                          items: available.map((b) {
                            return DropdownMenuItem<LibraryBook>(
                              value: b,
                              child: Text(
                                  '${b.title} (${b.availableCopies} available)'),
                            );
                          }).toList(),
                          onChanged: (b) => setState(() => _selectedBook = b),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    studentsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Error loading students: $e'),
                      data: (students) {
                        return DropdownButtonFormField<Student>(
                          initialValue: _selectedStudent,
                          decoration: const InputDecoration(
                            labelText: 'Select Student Borrower *',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          items: students.map((s) {
                            return DropdownMenuItem<Student>(
                              value: s,
                              child: Text(
                                  '${s.fullName} (Adm #${s.admissionNumber}) — Cls ${s.currentClassId}-${s.currentSectionId}'),
                            );
                          }).toList(),
                          onChanged: (s) =>
                              setState(() => _selectedStudent = s),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      leading: const Icon(Icons.calendar_today,
                          color: AppColors.brandNavy),
                      title: const Text('Return Due Date (14 Days Loan)'),
                      subtitle:
                          Text(_dueDate.toLocal().toString().split(' ')[0]),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 60)),
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        child: const Text('Change Date'),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoutes.library),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ErpButton(
                          label: _isIssuing
                              ? 'Recording Loan...'
                              : 'Issue & Print Slip',
                          icon: Icons.check_circle_outline,
                          onPressed: _isIssuing ||
                                  _selectedBook == null ||
                                  _selectedStudent == null
                              ? null
                              : _submitIssue,
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
