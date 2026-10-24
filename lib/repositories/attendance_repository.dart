import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AttendanceRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<void> createDraftSession(AttendanceSession session) async {
    try {
      await _firestore
          .collection('attendance_sessions')
          .doc(session.sessionId)
          .set({
        'sessionId': session.sessionId,
        'schoolId': 'SCH_001',
        'classId': session.classId,
        'sectionId': session.sectionId,
        'date': session.date,
        'academicYearId': session.academicYearId,
        'markedBy': session.markedBy,
        'isApproved': false,
        'isFinalized': false,
        'remarks': session.remarks,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
          '[AttendanceRepository.createDraftSession] Error saving draft session ${session.sessionId}: $e\n$stack');
      rethrow;
    }
  }

  Future<void> saveAttendanceRecord({
    required String sessionId,
    required String studentId,
    required String status,
    String? remarks,
  }) async {
    try {
      await _firestore
          .collection('attendance_sessions')
          .doc(sessionId)
          .collection('records')
          .doc(studentId)
          .set({
        'studentId': studentId,
        'sessionId': sessionId,
        'status': status,
        'remarks': remarks,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
          '[AttendanceRepository.saveAttendanceRecord] Error saving record for student $studentId: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<AttendanceSession>> getSessionsStream({
    required String classId,
    required String sectionId,
  }) {
    try {
      return _firestore
          .collection('attendance_sessions')
          .where('classId', isEqualTo: classId)
          .where('sectionId', isEqualTo: sectionId)
          .snapshots()
          .handleError((err) {
            debugPrint('[AttendanceRepository.getSessionsStream] FIRESTORE QUERY / INDEX ERROR ($classId-$sectionId): $err');
          })
          .map((s) {
            final list = s.docs.map((d) => AttendanceSession.fromFirestore(d)).toList();
            list.sort((a, b) => b.date.compareTo(a.date));
            return list;
          });
    } catch (e, stack) {
      debugPrint(
          '[AttendanceRepository.getSessionsStream] Query error: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<AttendanceRecord>> getSessionRecordsStream(String sessionId) {
    try {
      return _firestore
          .collection('attendance_sessions')
          .doc(sessionId)
          .collection('records')
          .snapshots()
          .map((s) =>
              s.docs.map((d) => AttendanceRecord.fromFirestore(d)).toList());
    } catch (e, stack) {
      debugPrint(
          '[AttendanceRepository.getSessionRecordsStream] Query error for session $sessionId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> approveAttendanceSession(String sessionId) async {
    try {
      final callable = _functions.httpsCallable('approveAttendanceSession');
      await callable.call({'sessionId': sessionId});
    } catch (e, stack) {
      debugPrint(
          '[AttendanceRepository.approveAttendanceSession] Error approving session $sessionId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> finalizeAttendanceSession(String sessionId) async {
    try {
      final callable = _functions.httpsCallable('finalizeAttendanceSession');
      await callable.call({'sessionId': sessionId});
    } catch (e, stack) {
      debugPrint(
          '[AttendanceRepository.finalizeAttendanceSession] Error finalizing session $sessionId: $e\n$stack');
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getWardAttendanceHistory(
      String studentId) async {
    try {
      final callable = _functions.httpsCallable('getWardAttendanceHistory');
      final result = await callable.call({'studentId': studentId});
      final rawList = result.data['records'] as List<dynamic>? ?? [];
      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item);
        return AttendanceRecord(
          studentId: map['studentId'] ?? '',
          sessionId: map['sessionId'] ?? '',
          status: map['status'] ?? 'P',
          remarks: map['remarks'],
        );
      }).toList();
    } catch (e) {
      debugPrint(
          '[AttendanceRepository.getWardAttendanceHistory] Cloud Function unavailable, querying Firestore collectionGroup directly: $e');
      try {
        final snapshot = await _firestore
            .collectionGroup('records')
            .where('studentId', isEqualTo: studentId)
            .get();
        return snapshot.docs
            .map((d) => AttendanceRecord.fromFirestore(d))
            .toList();
      } catch (directErr, stack) {
        debugPrint(
            '[AttendanceRepository.getWardAttendanceHistory] Direct query error for student $studentId: $directErr\n$stack');
        return [];
      }
    }
  }
}
