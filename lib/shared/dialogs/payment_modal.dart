import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';
import 'fee_receipt_dialog.dart';

class PaymentModal extends StatefulWidget {
  final StudentInvoice invoice;
  final Student? student;
  final Future<void> Function({
    required String invoiceId,
    required String studentId,
    required int amountPaise,
    required String notes,
  })? onPaymentCompleted;

  const PaymentModal({
    super.key,
    required this.invoice,
    this.student,
    this.onPaymentCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentInvoice invoice,
    Student? student,
    Future<void> Function({
      required String invoiceId,
      required String studentId,
      required int amountPaise,
      required String notes,
    })? onPaymentCompleted,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => PaymentModal(
        invoice: invoice,
        student: student,
        onPaymentCompleted: onPaymentCompleted,
      ),
    );
  }

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  String _selectedGateway = 'Razorpay (UPI / Cards / NetBanking)';
  late final TextEditingController _amountCtrl;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: (widget.invoice.outstandingBalancePaise / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final parse = CurrencyFormatter.parseInrToPaise(_amountCtrl.text.trim());
    if (!parse.isSuccess ||
        parse.amountPaise == null ||
        parse.amountPaise! <= 0) {
      setState(() =>
          _errorMessage = parse.errorMessage ?? 'Please enter a valid amount.');
      return;
    }

    if (parse.amountPaise! > widget.invoice.outstandingBalancePaise) {
      setState(
          () => _errorMessage = 'Payment cannot exceed outstanding balance.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.onPaymentCompleted != null) {
        await widget.onPaymentCompleted!(
          invoiceId: widget.invoice.invoiceId,
          studentId: widget.invoice.studentId,
          amountPaise: parse.amountPaise!,
          notes:
              'Online Gateway: $_selectedGateway | Intent: SECURE_TXN_${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        final updatedInvoice = StudentInvoice(
          invoiceId: widget.invoice.invoiceId,
          studentId: widget.invoice.studentId,
          academicYearId: widget.invoice.academicYearId,
          title: widget.invoice.title,
          totalAmountPaise: widget.invoice.totalAmountPaise,
          paidAmountPaise: widget.invoice.paidAmountPaise + parse.amountPaise!,
          outstandingBalancePaise:
              widget.invoice.outstandingBalancePaise - parse.amountPaise!,
          dueDate: widget.invoice.dueDate,
          status:
              (widget.invoice.outstandingBalancePaise - parse.amountPaise!) <= 0
                  ? 'paid'
                  : 'partial',
        );

        FeeReceiptDialog.show(context,
            invoice: updatedInvoice, student: widget.student);
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
    final totalInr =
        CurrencyFormatter.formatPaiseToInr(widget.invoice.totalAmountPaise);
    final balanceInr = CurrencyFormatter.formatPaiseToInr(
        widget.invoice.outstandingBalancePaise);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.payment, color: AppColors.parentBlue),
          SizedBox(width: 8),
          Text('Initiate Secure Fee Payment',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.invoice.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Fee: $totalInr',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('Outstanding: $balanceInr',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dangerRed)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount to Pay (₹ INR)',
                prefixIcon: Icon(Icons.currency_rupee, size: 16),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedGateway,
              decoration:
                  const InputDecoration(labelText: 'Payment Gateway / Channel'),
              items: const [
                DropdownMenuItem(
                  value: 'Razorpay (UPI / Cards / NetBanking)',
                  child: Text('Razorpay (UPI / Cards / NetBanking)',
                      style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'Cashfree Payments Gateway',
                  child: Text('Cashfree Payments Gateway',
                      style: TextStyle(fontSize: 13)),
                ),
                DropdownMenuItem(
                  value: 'Direct Bharat BillPay (BBPS)',
                  child: Text('Direct Bharat BillPay (BBPS)',
                      style: TextStyle(fontSize: 13)),
                ),
              ],
              onChanged: (v) => setState(() => _selectedGateway = v!),
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
      actions: [
        TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton.icon(
          icon: const Icon(Icons.lock, size: 16),
          label: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('Pay Securely'),
          style:
              ElevatedButton.styleFrom(backgroundColor: AppColors.parentBlue),
          onPressed: _isLoading ? null : _processPayment,
        ),
      ],
    );
  }
}
