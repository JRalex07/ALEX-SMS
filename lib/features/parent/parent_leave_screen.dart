import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Apply for Leave
/// Route: /parent/leave
class ParentLeaveScreen extends ConsumerStatefulWidget {
  const ParentLeaveScreen({super.key});

  @override
  ConsumerState<ParentLeaveScreen> createState() => _ParentLeaveScreenState();
}

class _ParentLeaveScreenState extends ConsumerState<ParentLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 2));
  String _leaveCategory = 'Medical';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Leave request successfully submitted! Class supervisor notified for approval.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go(AppRoutes.parentRequests);
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ResponsiveScaffold(
      title: 'Apply for Student Leave',
      currentRoute: AppRoutes.parentLeave,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const ParentChildSwitcher(),
                const SizedBox(height: 20),
                ErpCard(
                  title: 'Student Leave Application Form',
                  subtitle: selectedChild != null
                      ? 'Applying for ${selectedChild.fullName} (Class ${selectedChild.currentClassId}-${selectedChild.currentSectionId})'
                      : 'Select student above',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _leaveCategory,
                          decoration: const InputDecoration(
                            labelText: 'Leave Classification *',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Medical',
                                child: Text('Medical / Sickness')),
                            DropdownMenuItem(
                                value: 'Family Event',
                                child: Text('Family Event / Function')),
                            DropdownMenuItem(
                                value: 'Bereavement',
                                child: Text('Bereavement / Family Emergency')),
                            DropdownMenuItem(
                                value: 'External Tournament',
                                child: Text('External Tournament / Exam')),
                          ],
                          onChanged: (v) =>
                              setState(() => _leaveCategory = v!),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                leading: const Icon(Icons.date_range,
                                    color: AppColors.parentBlue),
                                title: const Text('Start Date'),
                                subtitle: Text(_startDate
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0]),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _startDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 60)),
                                    );
                                    if (picked != null) {
                                      setState(() => _startDate = picked);
                                    }
                                  },
                                  child: const Text('Select'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                      color: AppColors.borderLight),
                                ),
                                leading: const Icon(Icons.event_busy,
                                    color: AppColors.parentBlue),
                                title: const Text('End Date'),
                                subtitle: Text(_endDate
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0]),
                                trailing: TextButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _endDate,
                                      firstDate: _startDate,
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 60)),
                                    );
                                    if (picked != null) {
                                      setState(() => _endDate = picked);
                                    }
                                  },
                                  child: const Text('Select'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _reasonController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Absence *',
                            hintText:
                                'Explain the circumstance in detail for teacher and principal review...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Please explain the reason for absence'
                              : null,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () =>
                                  context.go(AppRoutes.parentRequests),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ErpButton(
                              label: _isSubmitting
                                  ? 'Transmitting Application...'
                                  : 'Submit Leave Application',
                              icon: Icons.send_outlined,
                              onPressed: _isSubmitting ? null : _submitLeave,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
