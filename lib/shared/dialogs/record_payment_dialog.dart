import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/fee_model.dart';

class RecordPaymentDialog extends StatefulWidget {
  final StudentInvoice? defaultInvoice;
  final Future<void> Function({
    required String invoiceId,
    required String studentId,
    required String payerUserId,
    required int amountPaise,
    required String notes,
  })? onPaymentRecorded;

  const RecordPaymentDialog({
    super.key,
    this.defaultInvoice,
    this.onPaymentRecorded,
  });

  static Future<void> show(
    BuildContext context, {
    StudentInvoice? defaultInvoice,
    Future<void> Function({
      required String invoiceId,
      required String studentId,
      required String payerUserId,
      required int amountPaise,
      required String notes,
    })? onPaymentRecorded,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => RecordPaymentDialog(
        defaultInvoice: defaultInvoice,
        onPaymentRecorded: onPaymentRecorded,
      ),
    );
  }

  @override
  State<RecordPaymentDialog> createState() => _RecordPaymentDialogState();
}

class _RecordPaymentDialogState extends State<RecordPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _invoiceIdCtrl;
  late final TextEditingController _studentIdCtrl;
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController(text: 'Cash receipt at bursar counter');
  String _paymentMode = 'Cash';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invoiceIdCtrl = TextEditingController(text: widget.defaultInvoice?.invoiceId ?? 'INV_2026_001');
    _studentIdCtrl = TextEditingController(text: widget.defaultInvoice?.studentId ?? 'STU_2026_001');
    if (widget.defaultInvoice != null) {
      _amountCtrl.text = (widget.defaultInvoice!.outstandingBalancePaise / 100).toStringAsFixed(2);
    } else {
      _amountCtrl.text = '5000.00';
    }
  }

  @override
  void dispose() {
    _invoiceIdCtrl.dispose();
    _studentIdCtrl.dispose();
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final parse = CurrencyFormatter.parseInrToPaise(_amountCtrl.text.trim());
    if (!parse.isSuccess || parse.amountPaise == null || parse.amountPaise! <= 0) {
      setState(() => _errorMessage = parse.errorMessage ?? 'Please enter a valid amount.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.onPaymentRecorded != null) {
        await widget.onPaymentRecorded!(
          invoiceId: _invoiceIdCtrl.text.trim(),
          studentId: _studentIdCtrl.text.trim(),
          payerUserId: 'parent_counter_user',
          amountPaise: parse.amountPaise!,
          notes: 'Mode: $_paymentMode | Ref: ${_refCtrl.text.trim()}',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment of ${CurrencyFormatter.formatPaiseToInr(parse.amountPaise)} successfully posted to ledger!',
            ),
          ),
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
          Icon(Icons.point_of_sale, color: AppColors.accountantEmerald),
          SizedBox(width: 8),
          Text('Record Counter / Offline Fee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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
                controller: _invoiceIdCtrl,
                decoration: const InputDecoration(labelText: 'Invoice ID (e.g. INV_2026_001)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Invoice ID is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _studentIdCtrl,
                decoration: const InputDecoration(labelText: 'Student ID (e.g. STU_2026_001)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Student ID is required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹ INR)',
                        prefixIcon: Icon(Icons.currency_rupee, size: 16),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Amount is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _paymentMode,
                      decoration: const InputDecoration(labelText: 'Payment Mode'),
                      items: const [
                        DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                        DropdownMenuItem(value: 'Cheque', child: Text('Cheque')),
                        DropdownMenuItem(value: 'Bank POS', child: Text('Bank POS')),
                        DropdownMenuItem(value: 'Demand Draft', child: Text('Demand Draft')),
                      ],
                      onChanged: (v) => setState(() => _paymentMode = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _refCtrl,
                decoration: const InputDecoration(labelText: 'Reference Notes / Cheque Number'),
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
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accountantEmerald),
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Post Payment'),
        ),
      ],
    );
  }
}
