import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent Grievances & Support Desk
/// Route: /parent/support
class ParentSupportScreen extends ConsumerStatefulWidget {
  const ParentSupportScreen({super.key});

  @override
  ConsumerState<ParentSupportScreen> createState() =>
      _ParentSupportScreenState();
}

class _ParentSupportScreenState extends ConsumerState<ParentSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  String _department = 'Academics & Teachers';
  bool _isSending = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isSending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Support inquiry logged with ticket #TKT-8841. Administration will respond within 24 hours.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    context.go(AppRoutes.parentRequests);
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'School Helpdesk & Grievance Desk',
      currentRoute: AppRoutes.parentSupport,
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
                  title: 'Submit Inquiry or Grievance',
                  subtitle:
                      'Direct communication channel to school coordinators and executive staff',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _department,
                          decoration: const InputDecoration(
                            labelText: 'Direct To Department *',
                            prefixIcon: Icon(Icons.domain_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Academics & Teachers',
                                child: Text('Academics & Teaching Faculty')),
                            DropdownMenuItem(
                                value: 'Accounts & Fees',
                                child: Text('Accounts & Bursar Counter')),
                            DropdownMenuItem(
                                value: 'Transport',
                                child: Text('Transport & Bus Coordinator')),
                            DropdownMenuItem(
                                value: 'Administration',
                                child: Text('Principal & Administration')),
                          ],
                          onChanged: (v) => setState(() => _department = v!),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject Line *',
                            hintText: 'e.g. Bus Route 4 timing discrepancy',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Subject required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Message Body *',
                            hintText:
                                'Describe your question, observation, or concern in detail...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Message required'
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
                              label: _isSending
                                  ? 'Transmitting Ticket...'
                                  : 'Submit Support Ticket',
                              icon: Icons.send,
                              onPressed: _isSending ? null : _submitTicket,
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
