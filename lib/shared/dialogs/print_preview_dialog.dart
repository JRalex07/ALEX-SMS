import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/services/print_service.dart';
import '../../core/services/print_document_generator.dart';
import '../../models/admission_application_model.dart';
import '../../models/attendance_model.dart';
import '../../models/examination_model.dart';
import '../../models/fee_model.dart';
import '../../models/library_model.dart';
import '../../models/student_model.dart';

enum DocumentType {
  admissionApplication,
  studentProfile,
  invoice,
  receipt,
  reportCard,
  attendanceRegister,
  libraryReport,
}

class PrintPreviewDialog extends StatefulWidget {
  final String documentTitle;
  final String documentReference;
  final DocumentType documentType;
  final Widget documentBody;
  final String? htmlContent;
  final VoidCallback? onDownload;

  const PrintPreviewDialog({
    super.key,
    required this.documentTitle,
    required this.documentReference,
    required this.documentType,
    required this.documentBody,
    this.htmlContent,
    this.onDownload,
  });

  /// 1. Admission Application Preview
  static Future<void> showAdmissionApplication(
    BuildContext context, {
    required AdmissionApplication application,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Admission Application Form',
        documentReference: application.id,
        documentType: DocumentType.admissionApplication,
        documentBody: _AdmissionApplicationDocument(app: application),
        htmlContent: PrintDocumentGenerator.generateAdmissionApplicationHtml(
          application: application,
          referenceNumber: application.id,
        ),
      ),
    );
  }

  /// 2. Student Profile Document Preview
  static Future<void> showStudentProfile(
    BuildContext context, {
    required Student student,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Official Student Record',
        documentReference: student.admissionNumber,
        documentType: DocumentType.studentProfile,
        documentBody: _StudentProfileDocument(student: student),
        htmlContent: PrintDocumentGenerator.generateStudentProfileHtml(
          student: student,
          referenceNumber: student.admissionNumber,
        ),
      ),
    );
  }

  /// 3. Fee Invoice Document Preview
  static Future<void> showInvoice(
    BuildContext context, {
    required StudentInvoice invoice,
    Student? student,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Student Fee Invoice',
        documentReference: invoice.invoiceId,
        documentType: DocumentType.invoice,
        documentBody: _InvoiceDocument(invoice: invoice, student: student),
        htmlContent: PrintDocumentGenerator.generateInvoiceHtml(
          invoice: invoice,
          student: student,
          referenceNumber: invoice.invoiceId,
        ),
      ),
    );
  }

  /// 4. Fee Payment Receipt Preview
  static Future<void> showReceipt(
    BuildContext context, {
    required StudentInvoice invoice,
    required int paymentAmountPaise,
    required String paymentMethod,
    String? transactionId,
    Student? student,
  }) {
    final ref = 'REC-${invoice.invoiceId}';
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Official Fee Payment Receipt',
        documentReference: ref,
        documentType: DocumentType.receipt,
        documentBody: _ReceiptDocument(
          invoice: invoice,
          paymentAmountPaise: paymentAmountPaise,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
          student: student,
        ),
        htmlContent: PrintDocumentGenerator.generateReceiptHtml(
          invoice: invoice,
          paymentAmountPaise: paymentAmountPaise,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
          student: student,
          referenceNumber: ref,
        ),
      ),
    );
  }

  /// 5. Academic Report Card Preview
  static Future<void> showReportCard(
    BuildContext context, {
    required Student student,
    required Examination examination,
    required List<Mark> marks,
  }) {
    final ref = 'REP-${examination.examId}-${student.studentId}';
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Academic Progress Report Card',
        documentReference: ref,
        documentType: DocumentType.reportCard,
        documentBody: _ReportCardDocument(
          student: student,
          examination: examination,
          marks: marks,
        ),
        htmlContent: PrintDocumentGenerator.generateReportCardHtml(
          student: student,
          examination: examination,
          marks: marks,
          referenceNumber: ref,
        ),
      ),
    );
  }

  /// 6. Attendance Register Preview
  static Future<void> showAttendanceRegister(
    BuildContext context, {
    required String classId,
    required String sectionId,
    required String date,
    required List<AttendanceSession> sessions,
    List<Student>? students,
  }) {
    final ref = 'ATT-$classId-$sectionId-$date';
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Class Attendance Register',
        documentReference: ref,
        documentType: DocumentType.attendanceRegister,
        documentBody: _AttendanceRegisterDocument(
          classId: classId,
          sectionId: sectionId,
          date: date,
          sessions: sessions,
          students: students ?? [],
        ),
        htmlContent: PrintDocumentGenerator.generateAttendanceRegisterHtml(
          classId: classId,
          sectionId: sectionId,
          date: date,
          sessions: sessions,
          students: students ?? [],
          referenceNumber: ref,
        ),
      ),
    );
  }

  /// 7. Library Report Preview
  static Future<void> showLibraryReport(
    BuildContext context, {
    required List<LibraryBook> books,
    required List<LibraryLoan> loans,
  }) {
    final ref = 'LIB-REP-${DateTime.now().millisecondsSinceEpoch % 10000}';
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PrintPreviewDialog(
        documentTitle: 'Library Circulation & Inventory Report',
        documentReference: ref,
        documentType: DocumentType.libraryReport,
        documentBody: _LibraryReportDocument(books: books, loans: loans),
        htmlContent: PrintDocumentGenerator.generateLibraryReportHtml(
          books: books,
          loans: loans,
          referenceNumber: ref,
        ),
      ),
    );
  }

  @override
  State<PrintPreviewDialog> createState() => _PrintPreviewDialogState();
}

class _PrintPreviewDialogState extends State<PrintPreviewDialog> {
  static const double _kPaperWidth = 794.0;
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isMobile = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : (isMobile ? 6 : 14),
        vertical: isMobile ? 12 : 24,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 960 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.96,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Preview Header Bar (Adaptive for Mobile & Desktop)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 18,
                vertical: 12,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isCompact = headerConstraints.maxWidth < 620;

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.print_outlined,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.documentTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Ref: ${widget.documentReference}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white70),
                              tooltip: 'Close Preview',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.zoom_out,
                                      color: Color(0xFF94A3B8), size: 18),
                                  tooltip: 'Zoom Out',
                                  onPressed: () {
                                    setState(() =>
                                        _zoom = (_zoom - 0.1).clamp(0.4, 1.4));
                                  },
                                ),
                                Text(
                                  '${(_zoom * 100).toInt()}%',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.zoom_in,
                                      color: Color(0xFF94A3B8), size: 18),
                                  tooltip: 'Zoom In',
                                  onPressed: () {
                                    setState(() =>
                                        _zoom = (_zoom + 0.1).clamp(0.4, 1.4));
                                  },
                                ),
                              ],
                            ),
                            FilledButton.icon(
                              icon: const Icon(Icons.print, size: 15),
                              label: const Text('Print Document'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brandNavy,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                              onPressed: () {
                                PrintService.printDocument(
                                  htmlContent: widget.htmlContent,
                                  documentTitle: widget.documentTitle,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      const Icon(Icons.print_outlined,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.documentTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Reference: ${widget.documentReference} • Formal Print Preview',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_out,
                            color: Color(0xFF94A3B8)),
                        tooltip: 'Zoom Out',
                        onPressed: () {
                          setState(() => _zoom = (_zoom - 0.1).clamp(0.4, 1.4));
                        },
                      ),
                      Text(
                        '${(_zoom * 100).toInt()}%',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.zoom_in, color: Color(0xFF94A3B8)),
                        tooltip: 'Zoom In',
                        onPressed: () {
                          setState(() => _zoom = (_zoom + 0.1).clamp(0.4, 1.4));
                        },
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.print, size: 16),
                        label: const Text('Print Document'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onPressed: () {
                          PrintService.printDocument(
                            htmlContent: widget.htmlContent,
                            documentTitle: widget.documentTitle,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        tooltip: 'Close Preview',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Responsive Document Viewport with Uniform Proportional Scaling
            Expanded(
              child: LayoutBuilder(
                builder: (context, viewportConstraints) {
                  final viewportWidth = viewportConstraints.maxWidth;
                  final horizontalPad = isDesktop ? 32.0 : 12.0;
                  final availableWidth =
                      (viewportWidth - (horizontalPad * 2)).clamp(160.0, 860.0);

                  final autoFitScale =
                      (availableWidth / _kPaperWidth).clamp(0.18, 1.0);
                  final effectiveScale = autoFitScale * _zoom;
                  final scaledWidth = _kPaperWidth * effectiveScale;
                  final canPanHorizontally =
                      scaledWidth > (viewportWidth - (horizontalPad * 2) + 2);

                  return Container(
                    color: const Color(0xFF0F172A),
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPad,
                        vertical: isMobile ? 12 : 24,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: canPanHorizontally
                            ? const ClampingScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        child: Center(
                          child: SizedBox(
                            width: scaledWidth,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: _kPaperWidth,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 36),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 20,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _InstitutionalLetterhead(
                                      documentTitle: widget.documentTitle,
                                      referenceNumber: widget.documentReference,
                                    ),
                                    const SizedBox(height: 24),
                                    widget.documentBody,
                                    const SizedBox(height: 36),
                                    _InstitutionalFooter(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// SHARED LETTERHEAD & FOOTER
// ============================================================================

class _InstitutionalLetterhead extends StatelessWidget {
  final String documentTitle;
  final String referenceNumber;

  const _InstitutionalLetterhead({
    required this.documentTitle,
    required this.referenceNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandNavy,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.school, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LAV ACADEMY',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandNavy,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Higher Secondary Co-Educational Institution • Affiliated to CBSE New Delhi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    'Campus: Sector 4, Vidhyadhar Nagar, Jaipur, Rajasthan 302039',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                  Text(
                    'Tel: +91 141 289 4000 • Email: registrar@lavacademy.edu.in',
                    style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'DATE: ${DateTime.now().toLocal().toString().split(" ").first}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'REF: $referenceNumber',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 2.5,
          color: AppColors.brandNavy,
        ),
        const SizedBox(height: 2),
        Container(
          height: 1,
          color: AppColors.warningAmber,
        ),
        const SizedBox(height: 14),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              documentTitle.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brandNavy,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstitutionalFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, color: AppColors.borderLight),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 1,
                  color: AppColors.borderStrong,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Prepared By / Clerk',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 1,
                  color: AppColors.borderStrong,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Authorized Official Seal',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 1,
                  color: AppColors.borderStrong,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Principal / Headmaster',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'This is a system-generated official institution record produced by LAV Academy SMS. Any alteration invalidates this record.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 9, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ============================================================================
// DOCUMENT CONTENT IMPLEMENTATIONS
// ============================================================================

class _AdmissionApplicationDocument extends StatelessWidget {
  final AdmissionApplication app;
  const _AdmissionApplicationDocument({required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status & Target Header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Text('Academic Year: ${app.academicYearId}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              Text(
                  'Applied Class: ${app.targetClass} (Sec ${app.targetSection})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brandNavy,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  app.status.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSectionHeader('1. APPLICANT DETAILS'),
        _buildDataGrid([
          {'Label': 'Full Name', 'Value': app.fullName},
          {
            'Label': 'Date of Birth',
            'Value': app.dateOfBirth.toLocal().toString().split(" ").first
          },
          {'Label': 'Gender', 'Value': app.gender},
          {'Label': 'Blood Group', 'Value': app.bloodGroup},
          {'Label': 'Nationality', 'Value': app.nationality},
          {'Label': 'Mother Tongue', 'Value': app.motherTongue},
        ]),

        const SizedBox(height: 16),
        _buildSectionHeader('2. PARENT & GUARDIAN DETAILS'),
        _buildDataGrid([
          {'Label': 'Father\'s Name', 'Value': app.fatherName},
          {
            'Label': 'Father Occupation',
            'Value': app.fatherOccupation.isEmpty ? 'N/A' : app.fatherOccupation
          },
          {'Label': 'Father Contact', 'Value': app.fatherPhone},
          {'Label': 'Mother\'s Name', 'Value': app.motherName},
          {
            'Label': 'Mother Occupation',
            'Value': app.motherOccupation.isEmpty ? 'N/A' : app.motherOccupation
          },
          {
            'Label': 'Mother Contact',
            'Value': app.motherPhone.isEmpty ? 'N/A' : app.motherPhone
          },
          {'Label': 'Designated Primary', 'Value': app.primaryGuardian},
          {
            'Label': 'Emergency Contact',
            'Value':
                '${app.emergencyContactName} (${app.emergencyContactPhone})'
          },
        ]),

        const SizedBox(height: 16),
        _buildSectionHeader('3. RESIDENTIAL ADDRESS'),
        _buildDataGrid([
          {'Label': 'Present Address', 'Value': app.formattedCurrentAddress},
          {
            'Label': 'Permanent Address',
            'Value': app.isPermanentSameAsCurrent
                ? 'Same as Present Address'
                : app.permanentAddress
          },
        ]),

        const SizedBox(height: 16),
        _buildSectionHeader('4. ACADEMIC BACKGROUND & TRANSFER INFO'),
        _buildDataGrid([
          {
            'Label': 'Previous School',
            'Value': app.previousSchoolName.isEmpty
                ? 'Fresher / First Admission'
                : app.previousSchoolName
          },
          {
            'Label': 'Last Class Attended',
            'Value': app.previousClass.isEmpty ? 'N/A' : app.previousClass
          },
          {
            'Label': 'Previous Result %',
            'Value': app.previousResultPercentage.isEmpty
                ? 'N/A'
                : '${app.previousResultPercentage}%'
          },
          {
            'Label': 'Transfer Certificate No.',
            'Value': app.transferCertificateNumber.isEmpty
                ? 'N/A'
                : app.transferCertificateNumber
          },
        ]),

        const SizedBox(height: 16),
        _buildSectionHeader('5. VERIFIED DOCUMENTS CHECKLIST'),
        Table(
          border: TableBorder.all(color: AppColors.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.4),
            2: FlexColumnWidth(1.0),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Document Item',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('File Reference',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Verification Status',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
            for (final doc in app.documents)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                        doc.documentType.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(doc.fileName,
                        style: const TextStyle(fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(doc.verificationStatus.toUpperCase(),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: doc.isVerified
                                ? AppColors.successGreen
                                : AppColors.warningAmber)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(left: BorderSide(color: AppColors.brandNavy, width: 3)),
      ),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.brandNavy),
      ),
    );
  }

  Widget _buildDataGrid(List<Map<String, String>> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: items.map((item) {
          return SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['Label']!,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textMuted)),
                Text(item['Value']!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StudentProfileDocument extends StatelessWidget {
  final Student student;
  const _StudentProfileDocument({required this.student});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.brandNavy.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person,
                  color: AppColors.brandNavy, size: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    'Admission No: ${student.admissionNumber} • ID: ${student.studentId}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    'Current Placement: Class ${student.currentClassId}-${student.currentSectionId} • Year: ${student.currentAcademicYearId}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Table(
          border: TableBorder.all(color: AppColors.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.0),
          },
          children: [
            _tableRow('Student Status', student.status.toUpperCase()),
            _tableRow('Date of Birth', student.dob ?? 'N/A'),
            _tableRow('Gender', student.gender ?? 'N/A'),
            _tableRow('Blood Group', student.bloodGroup ?? 'N/A'),
            _tableRow('Emergency Contact', student.emergencyContact ?? 'N/A'),
            _tableRow('Residential Address', student.address ?? 'N/A'),
          ],
        ),
      ],
    );
  }

  TableRow _tableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _InvoiceDocument extends StatelessWidget {
  final StudentInvoice invoice;
  final Student? student;

  const _InvoiceDocument({required this.invoice, this.student});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('INVOICE NO: ${invoice.invoiceId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 13)),
                Text(
                  'Student: ${student?.fullName ?? invoice.studentId} (${invoice.studentId})',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Due Date: ${invoice.dueDate?.toLocal().toString().split(" ").first ?? "Immediate"}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text('Status: ${invoice.status.toUpperCase()}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: invoice.isPaid
                            ? AppColors.successGreen
                            : AppColors.dangerRed)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Table(
          border: TableBorder.all(color: AppColors.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(3.0),
            1: FlexColumnWidth(1.2),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Description / Fee Item',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Amount (INR)',
                      textAlign: TextAlign.right,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(invoice.title,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    CurrencyFormatter.formatPaiseToInr(
                        invoice.totalAmountPaise),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Paid Amount',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.successGreen)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    CurrencyFormatter.formatPaiseToInr(invoice.paidAmountPaise),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successGreen),
                  ),
                ),
              ],
            ),
            TableRow(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Net Outstanding Balance',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    CurrencyFormatter.formatPaiseToInr(
                        invoice.outstandingBalancePaise),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandNavy),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _ReceiptDocument extends StatelessWidget {
  final StudentInvoice invoice;
  final int paymentAmountPaise;
  final String paymentMethod;
  final String? transactionId;
  final Student? student;

  const _ReceiptDocument({
    required this.invoice,
    required this.paymentAmountPaise,
    required this.paymentMethod,
    this.transactionId,
    this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.successGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: AppColors.successGreen.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: AppColors.successGreen, size: 20),
                  SizedBox(width: 8),
                  Text('PAYMENT RECEIVED & VERIFIED',
                      style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ],
              ),
              Text(
                '₹ ${(paymentAmountPaise / 100).toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.successGreen),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: AppColors.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.0),
          },
          children: [
            _row('Student Name', student?.fullName ?? invoice.studentId),
            _row('Admission Number', student?.admissionNumber ?? 'N/A'),
            _row('Invoice Reference', invoice.invoiceId),
            _row('Payment Mode', paymentMethod.toUpperCase()),
            _row(
                'Transaction Ref',
                transactionId ??
                    'TXN-${DateTime.now().millisecondsSinceEpoch}'),
            _row('Paid Amount',
                CurrencyFormatter.formatPaiseToInr(paymentAmountPaise)),
            _row(
                'Remaining Balance',
                CurrencyFormatter.formatPaiseToInr(
                    invoice.outstandingBalancePaise)),
          ],
        ),
      ],
    );
  }

  TableRow _row(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(value, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}

class _ReportCardDocument extends StatelessWidget {
  final Student student;
  final Examination examination;
  final List<Mark> marks;

  const _ReportCardDocument({
    required this.student,
    required this.examination,
    required this.marks,
  });

  @override
  Widget build(BuildContext context) {
    final hasMarks = marks.isNotEmpty;
    final totalMarksObtained =
        marks.fold<int>(0, (sum, m) => sum + m.totalScore);
    final maxPossible = marks.length * 100;
    final percentage =
        maxPossible > 0 ? (totalMarksObtained / maxPossible) * 100 : 0.0;
    final overallGrade = percentage >= 90
        ? 'A1'
        : (percentage >= 80
            ? 'A2'
            : (percentage >= 70
                ? 'B1'
                : (percentage >= 60
                    ? 'B2'
                    : (percentage >= 50 ? 'C1' : 'C2'))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student: ${student.fullName}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adm No: ${student.admissionNumber} • Class ${student.currentClassId}-${student.currentSectionId}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Exam: ${examination.title}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Term: ${examination.term} • AY: ${examination.academicYearId}',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!hasMarks)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.pending_actions_rounded,
                      size: 36, color: AppColors.warningAmber),
                  const SizedBox(height: 10),
                  const Text(
                    'Examination Results Awaiting Publication',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Official marks for ${examination.title} are currently being evaluated and moderated by the Academic Council. Marks have not been finalized yet.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          Table(
            border: TableBorder.all(color: AppColors.borderLight),
            columnWidths: const {
              0: FlexColumnWidth(2.8),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.1),
              3: FlexColumnWidth(1.2),
              4: FlexColumnWidth(1.2),
              5: FlexColumnWidth(1.0),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Subject',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('CA1 (20)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('CA2 (20)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Exam (60)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Total (100)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Grade',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              for (final m in marks)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(m.subjectId.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${m.continuousAssessment.ca1}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${m.continuousAssessment.ca2}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${m.examScore}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${m.totalScore}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(m.grade,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandNavy)),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brandNavy.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: [
                Text(
                  'Grand Total: $totalMarksObtained / $maxPossible',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
                Text(
                  'Percentage: ${percentage.toStringAsFixed(1)}% (Grade: $overallGrade)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.brandNavy),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _AttendanceRegisterDocument extends StatelessWidget {
  final String classId;
  final String sectionId;
  final String date;
  final List<AttendanceSession> sessions;
  final List<Student> students;

  const _AttendanceRegisterDocument({
    required this.classId,
    required this.sectionId,
    required this.date,
    required this.sessions,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Class: $classId-$sectionId • Register Date: $date',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: AppColors.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(1.2),
            1: FlexColumnWidth(2.4),
            2: FlexColumnWidth(1.0),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Roll / Adm No',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Student Full Name',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Status',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            for (final s in students)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(s.admissionNumber,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(s.fullName,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('PRESENT',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.successGreen)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _LibraryReportDocument extends StatelessWidget {
  final List<LibraryBook> books;
  final List<LibraryLoan> loans;

  const _LibraryReportDocument({required this.books, required this.loans});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Total Titles Catalogued: ${books.length}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 12),
        Table(
          border: TableBorder.all(color: AppColors.borderLight),
          columnWidths: const {
            0: FlexColumnWidth(2.5),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.2),
            3: FlexColumnWidth(1.0),
          },
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Title',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Author',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('ISBN',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
                Padding(
                  padding: EdgeInsets.all(6),
                  child: Text('Available',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                ),
              ],
            ),
            for (final b in books.take(20))
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(b.title,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(b.author, style: const TextStyle(fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(b.isbn ?? 'N/A',
                        style: const TextStyle(fontSize: 11)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text('${b.availableCopies} / ${b.totalCopies}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
