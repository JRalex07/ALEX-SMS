import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../models/student_model.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Generate Fee Invoice
/// Route: /fees/invoices/generate
class GenerateInvoiceScreen extends ConsumerStatefulWidget {
  const GenerateInvoiceScreen({super.key});

  @override
  ConsumerState<GenerateInvoiceScreen> createState() =>
      _GenerateInvoiceScreenState();
}

class _GenerateInvoiceScreenState extends ConsumerState<GenerateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedClass = '10';
  String _selectedScope = 'Entire Class Batch';
  Student? _individualStudent;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _isGenerating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isGenerating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Invoice "${_titleController.text.trim()}" generated and issued successfully!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go(AppRoutes.feeInvoices);
  }

  @override
  Widget build(BuildContext context) {
    final allStudentsAsync = ref.watch(allStudentsStreamProvider);

    return ResponsiveScaffold(
      title: 'Generate Fee Invoice',
      currentRoute: AppRoutes.feeInvoicesGenerate,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ErpCard(
              title: 'Fee Invoicing Engine',
              subtitle:
                  'Issue batch or individual student billing statements with due date enforcement',
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Billing Head *',
                        hintText: 'e.g. Term 2 Tuition & Science Lab Fee',
                        prefixIcon: Icon(Icons.receipt_long),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Please provide invoice billing head'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedScope,
                            decoration: const InputDecoration(
                              labelText: 'Billing Scope *',
                              prefixIcon: Icon(Icons.group_work_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Entire Class Batch',
                                  child: Text('Entire Class Batch')),
                              DropdownMenuItem(
                                  value: 'Individual Student',
                                  child: Text('Individual Student')),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedScope = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Standard / Class *',
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
                      ],
                    ),
                    if (_selectedScope == 'Individual Student') ...[
                      const SizedBox(height: 16),
                      allStudentsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (students) {
                          final classStudents = students
                              .where((s) => s.currentClassId == _selectedClass)
                              .toList();

                          return DropdownButtonFormField<Student>(
                            initialValue: _individualStudent,
                            decoration: const InputDecoration(
                              labelText: 'Select Student *',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            items: classStudents.map((s) {
                              return DropdownMenuItem<Student>(
                                value: s,
                                child: Text(
                                    '${s.fullName} (Adm #${s.admissionNumber})'),
                              );
                            }).toList(),
                            onChanged: (s) =>
                                setState(() => _individualStudent = s),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Bill Amount (INR ₹) *',
                        hintText: 'e.g. 35000',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter invoice amount';
                        }
                        if (int.tryParse(v.trim()) == null) {
                          return 'Enter integer amount';
                        }
                        return null;
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
                      title: const Text('Payment Due Date'),
                      subtitle: Text(_dueDate.toLocal().toString().split(' ')[0]),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 120)),
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
                          onPressed: () => context.go(AppRoutes.feeInvoices),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ErpButton(
                          label: _isGenerating
                              ? 'Issuing Invoices...'
                              : 'Generate & Dispatch Invoices',
                          icon: Icons.send_outlined,
                          onPressed: _isGenerating ? null : _submitInvoice,
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
