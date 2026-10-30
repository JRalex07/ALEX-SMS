import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSummary {
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int excusedCount;
  final int totalStudents;
  final double attendancePercentage;

  const AttendanceSummary({
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.excusedCount = 0,
    this.totalStudents = 0,
    this.attendancePercentage = 0.0,
  });

  factory AttendanceSummary.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AttendanceSummary();
    return AttendanceSummary(
      presentCount: data['presentCount'] ?? 0,
      absentCount: data['absentCount'] ?? 0,
      lateCount: data['lateCount'] ?? 0,
      excusedCount: data['excusedCount'] ?? 0,
      totalStudents: data['totalStudents'] ?? 0,
      attendancePercentage:
          (data['attendancePercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'presentCount': presentCount,
      'absentCount': absentCount,
      'lateCount': lateCount,
      'excusedCount': excusedCount,
      'totalStudents': totalStudents,
      'attendancePercentage': attendancePercentage,
    };
  }
}

class AttendanceSession {
  final String sessionId;
  final String schoolId;
  final String classId;
  final String sectionId;
  final String date; // YYYY-MM-DD
  final String academicYearId;
  final String markedBy;
  final bool isApproved;
  final bool isFinalized;
  final String? approvedBy;
  final AttendanceSummary? summary;
  final String? remarks;

  const AttendanceSession({
    required this.sessionId,
    this.schoolId = 'SCH_001',
    required this.classId,
    required this.sectionId,
    required this.date,
    required this.academicYearId,
    required this.markedBy,
    this.isApproved = false,
    this.isFinalized = false,
    this.approvedBy,
    this.summary,
    this.remarks,
  });

  factory AttendanceSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    AttendanceSummary? summaryObj;
    if (data['summary'] != null && data['summary'] is Map) {
      summaryObj =
          AttendanceSummary.fromMap(Map<String, dynamic>.from(data['summary']));
    } else if (data['presentCount'] != null ||
        data['absentCount'] != null ||
        data['totalStudents'] != null) {
      final p = (data['presentCount'] as num?)?.toInt() ?? 0;
      final a = (data['absentCount'] as num?)?.toInt() ?? 0;
      final t = (data['totalStudents'] as num?)?.toInt() ?? (p + a);
      final pct = t > 0 ? (p / t) * 100.0 : 0.0;
      summaryObj = AttendanceSummary(
        presentCount: p,
        absentCount: a,
        totalStudents: t,
        attendancePercentage: pct,
      );
    }

    return AttendanceSession(
      sessionId: doc.id,
      schoolId: data['schoolId'] ?? 'SCH_001',
      classId: data['classId'] ?? '',
      sectionId: data['sectionId'] ?? '',
      date: data['date'] ?? '',
      academicYearId: data['academicYearId'] ?? '2026-2027',
      markedBy: data['markedBy'] ?? '',
      isApproved: data['isApproved'] ?? false,
      isFinalized: data['isFinalized'] ?? false,
      approvedBy: data['approvedBy'],
      summary: summaryObj,
      remarks: data['remarks'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'schoolId': schoolId,
      'classId': classId,
      'sectionId': sectionId,
      'date': date,
      'academicYearId': academicYearId,
      'markedBy': markedBy,
      'isApproved': isApproved,
      'isFinalized': isFinalized,
      'approvedBy': approvedBy,
      'summary': summary?.toMap(),
      'remarks': remarks,
    };
  }
}

class AttendanceRecord {
  final String studentId;
  final String sessionId;
  final String status; // 'P', 'A', 'L', 'E'
  final String? remarks;
  final DateTime? recordDate;

  const AttendanceRecord({
    required this.studentId,
    required this.sessionId,
    required this.status,
    this.remarks,
    this.recordDate,
  });

  DateTime get date => recordDate ?? _parseDateFromSession(sessionId);

  static DateTime _parseDateFromSession(String session) {
    final match = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(session);
    if (match != null) {
      final parsed = DateTime.tryParse(match.group(0)!);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawDate = data['date'] ?? data['recordedAt'] ?? data['timestamp'];
    DateTime? parsedDate;
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return AttendanceRecord(
      studentId: doc.id,
      sessionId: data['sessionId'] ?? doc.reference.parent.parent?.id ?? '',
      status: data['status'] ?? 'P',
      remarks: data['remarks'],
      recordDate: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'sessionId': sessionId,
      'status': status,
      'remarks': remarks,
    };
  }
}
