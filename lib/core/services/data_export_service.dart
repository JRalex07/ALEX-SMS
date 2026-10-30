import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import '../../models/student_model.dart';
import '../../models/fee_model.dart';
import '../../models/library_model.dart';
import '../../models/attendance_model.dart';
import 'data_export_stub.dart' if (dart.library.html) 'data_export_web.dart'
    as platform_export;

class DataExportService {
  DataExportService._();

  static void exportStudents(BuildContext context, List<Student> students) {
    exportStudentsCsv(students);
  }

  static void exportStudentsCsv(List<Student> students) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Student ID,Admission Number,Full Name,Class,Section,Status,Emergency Contact,Blood Group');
    for (final s in students) {
      final safeName = _escapeCsv(s.fullName);
      final safeContact = _escapeCsv(s.emergencyContact ?? 'N/A');
      buffer.writeln(
          '${s.studentId},${s.admissionNumber},$safeName,${s.currentClassId},${s.currentSectionId},${s.status},$safeContact,${s.bloodGroup ?? "N/A"}');
    }

    _downloadCsv(buffer.toString(),
        'students_registry_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  static void exportInvoicesCsv(List<StudentInvoice> invoices) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Invoice ID,Student ID,Title,Total (INR),Paid (INR),Outstanding (INR),Status,Due Date');
    for (final inv in invoices) {
      final safeTitle = _escapeCsv(inv.title);
      final totalInr = (inv.totalAmountPaise / 100).toStringAsFixed(2);
      final paidInr = (inv.paidAmountPaise / 100).toStringAsFixed(2);
      final balanceInr = (inv.outstandingBalancePaise / 100).toStringAsFixed(2);
      final dueStr = inv.dueDate != null
          ? inv.dueDate!.toIso8601String().split('T').first
          : 'N/A';
      buffer.writeln(
          '${inv.invoiceId},${inv.studentId},$safeTitle,$totalInr,$paidInr,$balanceInr,${inv.status},$dueStr');
    }

    _downloadCsv(buffer.toString(),
        'fee_ledger_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  static void exportLibraryBooksCsv(List<LibraryBook> books) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Book ID,Title,Author,Category,ISBN,Total Copies,Available Copies,Shelf Location');
    for (final b in books) {
      final safeTitle = _escapeCsv(b.title);
      final safeAuthor = _escapeCsv(b.author);
      final safeCategory = _escapeCsv(b.category ?? 'General');
      buffer.writeln(
          '${b.bookId},$safeTitle,$safeAuthor,$safeCategory,${b.isbn},${b.totalCopies},${b.availableCopies},Main Stack');
    }

    _downloadCsv(buffer.toString(),
        'library_catalogue_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  static void exportAttendanceCsv(List<AttendanceSession> sessions) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Session ID,Class,Section,Date,Total Students,Present,Absent,Attendance %');
    for (final s in sessions) {
      final dateStr = s.date;
      final total = s.summary?.totalStudents ?? 0;
      final present = s.summary?.presentCount ?? 0;
      final absent = s.summary?.absentCount ?? 0;
      final pct = s.summary?.attendancePercentage.toStringAsFixed(1) ?? '0.0';
      buffer.writeln(
          '${s.sessionId},${s.classId},${s.sectionId},$dateStr,$total,$present,$absent,$pct%');
    }

    _downloadCsv(buffer.toString(),
        'attendance_summary_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  static void exportAuditLogsCsv(List<Map<String, dynamic>> logs) {
    final buffer = StringBuffer();
    buffer.writeln('Action,Actor Email,Timestamp,Details');
    for (final log in logs) {
      final action = _escapeCsv(log['action']?.toString() ?? 'SYSTEM_EVENT');
      final actor = _escapeCsv(log['actorEmail']?.toString() ?? 'Automated System');
      final timestamp = _escapeCsv(log['timestamp']?.toString() ?? 'N/A');
      final details = _escapeCsv(log['details']?.toString() ?? '');
      buffer.writeln('$action,$actor,$timestamp,$details');
    }

    _downloadCsv(buffer.toString(),
        'audit_logs_${DateTime.now().millisecondsSinceEpoch}.csv');
  }

  static void _downloadCsv(String content, String filename) {
    if (kIsWeb) {
      platform_export.downloadFilePlatform(
          content, filename, 'text/csv;charset=utf-8');
    } else {
      debugPrint(
          '[DataExportService] Generated CSV (${content.length} bytes): $filename');
    }
  }

  static String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}
