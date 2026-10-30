import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/print_service.dart';
import '../../core/services/print_document_generator.dart';
import '../../models/fee_model.dart';
import '../../models/student_model.dart';

class FeeReceiptDialog extends StatelessWidget {
  final StudentInvoice invoice;
  final Student? student;

  const FeeReceiptDialog({
    super.key,
    required this.invoice,
    this.student,
  });

  static Future<void> show(
    BuildContext context, {
    required StudentInvoice invoice,
    Student? student,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => FeeReceiptDialog(invoice: invoice, student: student),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paidInr = CurrencyFormatter.formatPaiseToInr(invoice.paidAmountPaise);
    final totalInr =
        CurrencyFormatter.formatPaiseToInr(invoice.totalAmountPaise);
    final balanceInr =
        CurrencyFormatter.formatPaiseToInr(invoice.outstandingBalancePaise);
    final receiptNo = 'REC-2026-${invoice.invoiceId.replaceAll('INV_', '')}';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border:
                    Border(bottom: BorderSide(color: AppColors.borderLight)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.receipt,
                            size: 20, color: AppColors.accountantEmerald),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text('Official Fee Payment Receipt',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Receipt'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accountantEmerald,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: () {
                          final htmlContent =
                              PrintDocumentGenerator.generateReceiptHtml(
                            invoice: invoice,
                            paymentAmountPaise: invoice.paidAmountPaise,
                            paymentMethod: 'ONLINE / BANK TRANSFER',
                            transactionId: receiptNo,
                            student: student,
                            referenceNumber: receiptNo,
                          );
                          PrintService.printDocument(
                            htmlContent: htmlContent,
                            documentTitle:
                                'Official Fee Payment Receipt - $receiptNo',
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ],
              ),
            ),

            // Receipt Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'LAV INTERNATIONAL ACADEMY',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                  color: Color(0xFF0F172A)),
                            ),
                            const Text(
                              'BURSAR & ACCOUNTS DEPARTMENT • RECEIPT VOUCHER',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                'RECEIPT NO: $receiptNo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Color(0xFF15803D)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, thickness: 1),

                      // Particulars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _row('Student ID', invoice.studentId),
                                const SizedBox(height: 4),
                                _row('Student Name',
                                    student?.fullName ?? 'Student ${invoice.studentId}'),
                                const SizedBox(height: 4),
                                _row('Invoice Reference', invoice.invoiceId),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _row(
                                    'Receipt Date',
                                    DateTime.now()
                                        .toIso8601String()
                                        .split('T')
                                        .first),
                                const SizedBox(height: 4),
                                _row(
                                    'Academic Session', invoice.academicYearId),
                                const SizedBox(height: 4),
                                _row('Payment Mode',
                                    'Verified Cashier / Electronic Transfer'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Item Table
                      Table(
                        border: TableBorder.all(color: const Color(0xFFE2E8F0)),
                        columnWidths: const {
                          0: FlexColumnWidth(3),
                          1: FlexColumnWidth(1.5),
                        },
                        children: [
                          const TableRow(
                            decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Particulars / Fee Description',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12))),
                              Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Amount (INR)',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12))),
                            ],
                          ),
                          TableRow(
                            children: [
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(invoice.title,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))),
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(totalInr,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 12))),
                            ],
                          ),
                          TableRow(
                            decoration:
                                const BoxDecoration(color: Color(0xFFF0FDF4)),
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('AMOUNT REALIZED / PAID',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                          color: Color(0xFF15803D)))),
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(paidInr,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF15803D)))),
                            ],
                          ),
                          TableRow(
                            children: [
                              const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text('Remaining Outstanding Balance',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.dangerRed))),
                              Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(balanceInr,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.dangerRed))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Signoff
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: TRANSACTION CONFIRMED',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF15803D))),
                              Text(
                                  'System Generated Official Receipt • Non-Transferable',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          Column(
                            children: [
                              Container(
                                  width: 120, height: 1, color: Colors.black87),
                              const SizedBox(height: 4),
                              const Text('Bursar / Cashier Signature',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String val) {
    return Row(
      children: [
        SizedBox(
            width: 90,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary))),
        Expanded(
            child: Text(val,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A)))),
      ],
    );
  }
}
