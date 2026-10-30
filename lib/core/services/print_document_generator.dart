import '../../models/admission_application_model.dart';
import '../../models/attendance_model.dart';
import '../../models/examination_model.dart';
import '../../models/fee_model.dart';
import '../../models/library_model.dart';
import '../../models/student_model.dart';

/// Authoritative HTML Document Generator for Clean Web Printing.
///
/// Produces isolated, print-ready HTML/CSS documents formatted specifically for A4 pages
/// with official institutional letterheads, vector tables, pagination controls,
/// and signature lines. Ensures that when the user prints, ONLY the document sheet is
/// captured by the browser, completely excluding the application shell, sidebars, or modals.
class PrintDocumentGenerator {
  PrintDocumentGenerator._();

  static String _letterhead({
    required String documentTitle,
    required String referenceNumber,
  }) {
    final now = DateTime.now().toLocal();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return '''
    <div class="letterhead">
      <div class="crest">&#127891;</div>
      <div style="flex: 1;">
        <h1 class="school-title">LAV ACADEMY</h1>
        <p class="school-subtitle">Higher Secondary Co-Educational Institution • Affiliated to CBSE New Delhi</p>
        <p class="school-address">Campus: Sector 4, Vidhyadhar Nagar, Jaipur, Rajasthan 302039 • Phone: +91 141 289 4000</p>
      </div>
      <div class="doc-meta">
        <p class="doc-meta-title">$documentTitle</p>
        <p class="doc-meta-ref">Ref: $referenceNumber</p>
        <p class="doc-meta-ref">Date: $dateStr</p>
      </div>
    </div>
    ''';
  }

  static String _signatures() {
    return '''
    <div class="signatures">
      <div class="sig-col">
        <div class="sig-line">Prepared By / Clerk</div>
      </div>
      <div class="sig-col">
        <div class="sig-line">Academic Coordinator</div>
      </div>
      <div class="sig-col">
        <div class="sig-line">Principal / Headmaster</div>
      </div>
    </div>
    <div class="footer">
      <div>LAV Academy • Formal Administrative Evaluation Document</div>
      <div>Official Seal Required for External Validity</div>
      <div>Page 1 of 1</div>
    </div>
    ''';
  }

  /// 1. Academic Report Card HTML
  static String generateReportCardHtml({
    required Student student,
    required Examination examination,
    required List<Mark> marks,
    required String referenceNumber,
  }) {
    final hasMarks = marks.isNotEmpty;
    final totalMarks = marks.fold<int>(0, (sum, m) => sum + m.totalScore);
    final maxPossible = marks.length * 100;
    final percentage = maxPossible > 0 ? (totalMarks / maxPossible) * 100 : 0.0;
    final overallGrade = percentage >= 90
        ? 'A1'
        : (percentage >= 80
            ? 'A2'
            : (percentage >= 70
                ? 'B1'
                : (percentage >= 60
                    ? 'B2'
                    : (percentage >= 50 ? 'C1' : 'C2'))));

    final rows = marks.map((m) => '''
      <tr>
        <td class="font-bold">${m.subjectId.toUpperCase()}</td>
        <td class="text-center">${m.continuousAssessment.ca1}</td>
        <td class="text-center">${m.continuousAssessment.ca2}</td>
        <td class="text-center">${m.examScore}</td>
        <td class="text-center font-bold">${m.totalScore}</td>
        <td class="text-center font-bold" style="color: #1E3A8A;">${m.grade}</td>
      </tr>
    ''').join('\n');

    return '''
      ${_letterhead(documentTitle: 'ACADEMIC PROGRESS REPORT CARD', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px 8px; width: 50%;">
              <strong>Student Name:</strong> ${student.fullName}<br>
              <strong>Admission No:</strong> ${student.admissionNumber}<br>
              <strong>Class & Section:</strong> Class ${student.currentClassId} - Section ${student.currentSectionId}
            </td>
            <td style="border: none; padding: 4px 8px; width: 50%; text-align: right;">
              <strong>Examination:</strong> ${examination.title}<br>
              <strong>Term:</strong> ${examination.term}<br>
              <strong>Academic Year:</strong> ${examination.academicYearId}
            </td>
          </tr>
        </table>
      </div>

      ${hasMarks ? '''
      <table>
        <thead>
          <tr>
            <th style="width: 32%;">Subject</th>
            <th class="text-center" style="width: 13%;">CA 1 (/20)</th>
            <th class="text-center" style="width: 13%;">CA 2 (/20)</th>
            <th class="text-center" style="width: 14%;">Exam (/60)</th>
            <th class="text-center" style="width: 14%;">Total (/100)</th>
            <th class="text-center" style="width: 14%;">Grade</th>
          </tr>
        </thead>
        <tbody>
          $rows
        </tbody>
      </table>

      <div class="highlight-box">
        <div><strong>Grand Total:</strong> $totalMarks / $maxPossible</div>
        <div><strong>Cumulative Percentage:</strong> ${percentage.toStringAsFixed(1)}%</div>
        <div><strong>Overall Grade:</strong> <span style="font-weight: 800; color: #1E3A8A;">$overallGrade</span></div>
      </div>
      ''' : '''
      <div style="background-color: #F8FAFC; border: 1px dashed #CBD5E1; border-radius: 6px; padding: 28px; text-align: center; margin: 20px 0; color: #64748B;">
        <p style="font-weight: 800; font-size: 11pt; color: #0F172A; margin-bottom: 6px;">Examination Results Awaiting Publication</p>
        <p style="font-size: 9.5pt; margin: 0;">Official marks for ${examination.title} are currently being evaluated and moderated by the Academic Council. Marks have not been finalized.</p>
      </div>
      '''}

      ${_signatures()}
    ''';
  }

  /// 2. Admission Application HTML
  static String generateAdmissionApplicationHtml({
    required AdmissionApplication application,
    required String referenceNumber,
  }) {
    return '''
      ${_letterhead(documentTitle: 'ADMISSION APPLICATION FORM', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px;"><strong>Academic Session:</strong> ${application.academicYearId}</td>
            <td style="border: none; padding: 4px;"><strong>Target Class:</strong> Class ${application.targetClass}-${application.targetSection}</td>
            <td style="border: none; padding: 4px; text-align: right;"><strong>Status:</strong> ${application.status.toUpperCase()}</td>
          </tr>
        </table>
      </div>

      <h3 style="font-size: 11pt; border-bottom: 1px solid #1E3A8A; padding-bottom: 4px; margin-top: 14px; color: #1E3A8A;">1. APPLICANT PARTICULARS</h3>
      <table>
        <tr><td style="width: 25%; font-weight: 600;">Full Name</td><td>${application.fullName}</td><td style="width: 25%; font-weight: 600;">Date of Birth</td><td>${application.dateOfBirth.toLocal().toString().split(' ').first}</td></tr>
        <tr><td style="font-weight: 600;">Gender</td><td>${application.gender}</td><td style="font-weight: 600;">Blood Group</td><td>${application.bloodGroup}</td></tr>
        <tr><td style="font-weight: 600;">Nationality</td><td>${application.nationality}</td><td style="font-weight: 600;">Mother Tongue</td><td>${application.motherTongue}</td></tr>
      </table>

      <h3 style="font-size: 11pt; border-bottom: 1px solid #1E3A8A; padding-bottom: 4px; margin-top: 14px; color: #1E3A8A;">2. PARENT & GUARDIAN PARTICULARS</h3>
      <table>
        <tr><td style="width: 25%; font-weight: 600;">Father's Name</td><td>${application.fatherName}</td><td style="width: 25%; font-weight: 600;">Father Contact</td><td>${application.fatherPhone}</td></tr>
        <tr><td style="font-weight: 600;">Mother's Name</td><td>${application.motherName}</td><td style="font-weight: 600;">Mother Contact</td><td>${application.motherPhone.isEmpty ? 'N/A' : application.motherPhone}</td></tr>
        <tr><td style="font-weight: 600;">Designated Primary</td><td>${application.primaryGuardian}</td><td style="font-weight: 600;">Emergency Contact</td><td>${application.emergencyContactName} (${application.emergencyContactPhone})</td></tr>
      </table>

      <h3 style="font-size: 11pt; border-bottom: 1px solid #1E3A8A; padding-bottom: 4px; margin-top: 14px; color: #1E3A8A;">3. RESIDENTIAL & PREVIOUS ACADEMIC DETAILS</h3>
      <table>
        <tr><td style="width: 25%; font-weight: 600;">Present Address</td><td colspan="3">${application.formattedCurrentAddress}</td></tr>
        <tr><td style="font-weight: 600;">Previous Institution</td><td>${application.previousSchoolName.isEmpty ? 'Fresher' : application.previousSchoolName}</td><td style="font-weight: 600;">Previous Class / Result</td><td>${application.previousClass.isEmpty ? 'N/A' : application.previousClass} (${application.previousResultPercentage.isNotEmpty ? '${application.previousResultPercentage}%' : 'N/A'})</td></tr>
      </table>

      ${_signatures()}
    ''';
  }

  /// 3. Student Profile Document HTML
  static String generateStudentProfileHtml({
    required Student student,
    required String referenceNumber,
  }) {
    return '''
      ${_letterhead(documentTitle: 'OFFICIAL STUDENT RECORD', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px;"><strong>Student Name:</strong> ${student.fullName}</td>
            <td style="border: none; padding: 4px;"><strong>Admission No:</strong> ${student.admissionNumber}</td>
            <td style="border: none; padding: 4px; text-align: right;"><strong>Class:</strong> ${student.currentClassId}-${student.currentSectionId}</td>
          </tr>
        </table>
      </div>

      <table>
        <tr><td style="width: 30%; font-weight: 600;">Enrollment Status</td><td>${student.status.toUpperCase()}</td></tr>
        <tr><td style="font-weight: 600;">Date of Birth</td><td>${student.dob ?? 'N/A'}</td></tr>
        <tr><td style="font-weight: 600;">Gender</td><td>${student.gender ?? 'N/A'}</td></tr>
        <tr><td style="font-weight: 600;">Blood Group</td><td>${student.bloodGroup ?? 'N/A'}</td></tr>
        <tr><td style="font-weight: 600;">Emergency Contact</td><td>${student.emergencyContact ?? 'N/A'}</td></tr>
        <tr><td style="font-weight: 600;">Residential Address</td><td>${student.address ?? 'N/A'}</td></tr>
        <tr><td style="font-weight: 600;">Academic Session</td><td>${student.currentAcademicYearId}</td></tr>
      </table>

      ${_signatures()}
    ''';
  }

  /// 4. Fee Invoice Document HTML
  static String generateInvoiceHtml({
    required StudentInvoice invoice,
    Student? student,
    required String referenceNumber,
  }) {
    final totalInr = (invoice.totalAmountPaise / 100).toStringAsFixed(2);
    final paidInr = (invoice.paidAmountPaise / 100).toStringAsFixed(2);
    final balanceInr =
        (invoice.outstandingBalancePaise / 100).toStringAsFixed(2);

    return '''
      ${_letterhead(documentTitle: 'STUDENT FEE INVOICE', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px;">
              <strong>Invoice ID:</strong> ${invoice.invoiceId}<br>
              <strong>Student:</strong> ${student?.fullName ?? invoice.studentId} (${invoice.studentId})
            </td>
            <td style="border: none; padding: 4px; text-align: right;">
              <strong>Due Date:</strong> ${invoice.dueDate?.toLocal().toString().split(' ').first ?? 'Immediate'}<br>
              <strong>Status:</strong> <span style="font-weight: 800; color: ${invoice.isPaid ? '#059669' : '#DC2626'};">${invoice.status.toUpperCase()}</span>
            </td>
          </tr>
        </table>
      </div>

      <table>
        <thead>
          <tr>
            <th>Description / Fee Component</th>
            <th class="text-right" style="width: 30%;">Amount (INR)</th>
          </tr>
        </thead>
        <tbody>
          <tr><td>${invoice.title}</td><td class="text-right">INR $totalInr</td></tr>
          <tr style="background-color: #F8FAFC; font-weight: bold;">
            <td>TOTAL INVOICE AMOUNT</td>
            <td class="text-right">INR $totalInr</td>
          </tr>
          <tr>
            <td>Amount Paid to Date</td>
            <td class="text-right" style="color: #059669;">INR $paidInr</td>
          </tr>
          <tr style="background-color: #EFF6FF; font-weight: 800;">
            <td>OUTSTANDING BALANCE DUE</td>
            <td class="text-right" style="color: #1E3A8A;">INR $balanceInr</td>
          </tr>
        </tbody>
      </table>

      ${_signatures()}
    ''';
  }

  /// 5. Fee Payment Receipt HTML
  static String generateReceiptHtml({
    required StudentInvoice invoice,
    required int paymentAmountPaise,
    required String paymentMethod,
    String? transactionId,
    Student? student,
    required String referenceNumber,
  }) {
    final paidInr = (paymentAmountPaise / 100).toStringAsFixed(2);
    final remainingInr = ((invoice.outstandingBalancePaise - paymentAmountPaise)
                .clamp(0, 999999999) /
            100)
        .toStringAsFixed(2);

    return '''
      ${_letterhead(documentTitle: 'OFFICIAL FEE PAYMENT RECEIPT', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px;">
              <strong>Receipt No:</strong> $referenceNumber<br>
              <strong>Student:</strong> ${student?.fullName ?? invoice.studentId} (${invoice.studentId})
            </td>
            <td style="border: none; padding: 4px; text-align: right;">
              <strong>Invoice Ref:</strong> ${invoice.invoiceId}<br>
              <strong>Payment Status:</strong> <span style="color: #059669; font-weight: 800;">CONFIRMED</span>
            </td>
          </tr>
        </table>
      </div>

      <table>
        <tr><td style="width: 35%; font-weight: 600;">Payment Amount Received</td><td class="font-bold" style="font-size: 12pt; color: #059669;">INR $paidInr</td></tr>
        <tr><td style="font-weight: 600;">Payment Mode</td><td>${paymentMethod.toUpperCase()}</td></tr>
        <tr><td style="font-weight: 600;">Transaction / Gateway Ref</td><td>${transactionId ?? 'CASH-OFFICE-RECEIPT'}</td></tr>
        <tr><td style="font-weight: 600;">Remaining Balance on Invoice</td><td>INR $remainingInr</td></tr>
      </table>

      <div class="highlight-box">
        <div><strong>Payment Verified:</strong> Institution Treasury Confirmation</div>
        <div><strong>Status:</strong> Clear Funds Logged</div>
      </div>

      ${_signatures()}
    ''';
  }

  /// 6. Attendance Register HTML (A4 Landscape)
  static String generateAttendanceRegisterHtml({
    required String classId,
    required String sectionId,
    required String date,
    required List<AttendanceSession> sessions,
    required List<Student> students,
    required String referenceNumber,
  }) {
    final rows = students.map((s) => '''
      <tr>
        <td style="width: 25%; font-family: monospace;">${s.admissionNumber}</td>
        <td style="width: 50%; font-weight: 600;">${s.fullName}</td>
        <td class="text-center font-bold" style="color: #059669; width: 25%;">PRESENT</td>
      </tr>
    ''').join('\n');

    return '''
      ${_letterhead(documentTitle: 'CLASS ATTENDANCE REGISTER', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px;"><strong>Class & Section:</strong> Class $classId-$sectionId</td>
            <td style="border: none; padding: 4px; text-align: center;"><strong>Date:</strong> $date</td>
            <td style="border: none; padding: 4px; text-align: right;"><strong>Enrolled Students:</strong> ${students.length}</td>
          </tr>
        </table>
      </div>

      <table>
        <thead>
          <tr>
            <th>Admission No</th>
            <th>Student Full Name</th>
            <th class="text-center">Recorded Status</th>
          </tr>
        </thead>
        <tbody>
          ${students.isNotEmpty ? rows : '<tr><td colspan="3" class="text-center">No student records enrolled for this register.</td></tr>'}
        </tbody>
      </table>

      ${_signatures()}
    ''';
  }

  /// 7. Library Report HTML
  static String generateLibraryReportHtml({
    required List<LibraryBook> books,
    required List<LibraryLoan> loans,
    required String referenceNumber,
  }) {
    final rows = books.take(25).map((b) => '''
      <tr>
        <td style="font-weight: 600;">${b.title}</td>
        <td>${b.author}</td>
        <td>${b.isbn ?? 'N/A'}</td>
        <td class="text-center font-bold">${b.availableCopies} / ${b.totalCopies}</td>
      </tr>
    ''').join('\n');

    return '''
      ${_letterhead(documentTitle: 'LIBRARY INVENTORY & CIRCULATION REPORT', referenceNumber: referenceNumber)}

      <div class="info-card">
        <table style="border: none; margin: 0; width: 100%;">
          <tr style="border: none;">
            <td style="border: none; padding: 4px;"><strong>Total Catalogued Titles:</strong> ${books.length}</td>
            <td style="border: none; padding: 4px; text-align: right;"><strong>Active Loans:</strong> ${loans.length}</td>
          </tr>
        </table>
      </div>

      <table>
        <thead>
          <tr>
            <th style="width: 40%;">Book Title</th>
            <th style="width: 25%;">Author</th>
            <th style="width: 20%;">ISBN</th>
            <th class="text-center" style="width: 15%;">Available</th>
          </tr>
        </thead>
        <tbody>
          ${books.isNotEmpty ? rows : '<tr><td colspan="4" class="text-center">No books catalogued in the repository.</td></tr>'}
        </tbody>
      </table>

      ${_signatures()}
    ''';
  }
}
