import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/examination_model.dart';

class ExamRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ExamRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  static void validateMarkBounds(Mark mark) {
    if (mark.continuousAssessment.ca1 < 0 ||
        mark.continuousAssessment.ca1 > 20) {
      throw ArgumentError(
          'Continuous Assessment 1 (CA1) must be between 0 and 20.');
    }
    if (mark.continuousAssessment.ca2 < 0 ||
        mark.continuousAssessment.ca2 > 20) {
      throw ArgumentError(
          'Continuous Assessment 2 (CA2) must be between 0 and 20.');
    }
    if (mark.examScore < 0 || mark.examScore > 60) {
      throw ArgumentError('Examination score must be between 0 and 60.');
    }

    final total = mark.continuousAssessment.ca1 +
        mark.continuousAssessment.ca2 +
        mark.examScore;

    if (total > 100) {
      throw ArgumentError('Total assessment score cannot exceed 100.');
    }
  }

  Stream<List<Examination>> getExaminationsStream() {
    try {
      return _firestore
          .collection('examinations')
          .snapshots()
          .map((s) => s.docs.map((d) => Examination.fromFirestore(d)).toList());
    } catch (e, stack) {
      debugPrint('[ExamRepository.getExaminationsStream] Error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> saveDraftMark(Mark mark) async {
    validateMarkBounds(mark);
    try {
      final total = mark.continuousAssessment.ca1 +
          mark.continuousAssessment.ca2 +
          mark.examScore;

      await _firestore.collection('marks').doc(mark.markId).set({
        'markId': mark.markId,
        'schoolId': 'SCH_001',
        'examId': mark.examId,
        'studentId': mark.studentId,
        'subjectId': mark.subjectId,
        'classId': mark.classId,
        'sectionId': mark.sectionId,
        'academicYearId': mark.academicYearId,
        'continuousAssessment': {
          'ca1': mark.continuousAssessment.ca1,
          'ca2': mark.continuousAssessment.ca2,
        },
        'examScore': mark.examScore,
        'totalScore': total,
        'isApproved': false,
        'isPublished': false,
        'teacherComment': mark.teacherComment,
        'updatedBy': mark.updatedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
          '[ExamRepository.saveDraftMark] Error saving mark ${mark.markId}: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<Mark>> getMarksForClassSection({
    required String subjectId,
    required String classId,
    required String sectionId,
  }) {
    try {
      return _firestore
          .collection('marks')
          .where('subjectId', isEqualTo: subjectId)
          .where('classId', isEqualTo: classId)
          .where('sectionId', isEqualTo: sectionId)
          .snapshots()
          .map((s) => s.docs.map((d) => Mark.fromFirestore(d)).toList());
    } catch (e, stack) {
      debugPrint(
          '[ExamRepository.getMarksForClassSection] Query error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> adminCorrectMark({
    required String markId,
    int? newCa1,
    int? newCa2,
    int? newExamScore,
    required String correctionReason,
  }) async {
    try {
      final callable = _functions.httpsCallable('adminCorrectMark');
      await callable.call({
        'markId': markId,
        'newCa1': newCa1,
        'newCa2': newCa2,
        'newExamScore': newExamScore,
        'correctionReason': correctionReason,
      });
    } catch (e, stack) {
      debugPrint(
          '[ExamRepository.adminCorrectMark] Error correcting mark $markId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> publishExamResults({
    required String examId,
    String? classId,
  }) async {
    try {
      final callable = _functions.httpsCallable('publishExamResults');
      await callable.call({
        'examId': examId,
        'classId': classId,
      });
    } catch (e, stack) {
      debugPrint(
          '[ExamRepository.publishExamResults] Error publishing exam results $examId: $e\n$stack');
      rethrow;
    }
  }

  Future<List<Mark>> getWardMarks({
    required String studentId,
    String? examId,
  }) async {
    try {
      final callable = _functions.httpsCallable('getWardMarks');
      final result = await callable.call({
        'studentId': studentId,
        'examId': examId,
      });
      final rawList = result.data['marks'] as List<dynamic>? ?? [];
      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item);
        return Mark(
          markId: map['id'] ?? map['markId'] ?? '',
          examId: map['examId'] ?? '',
          studentId: map['studentId'] ?? '',
          subjectId: map['subjectId'] ?? '',
          classId: map['classId'] ?? '',
          sectionId: map['sectionId'] ?? '',
          academicYearId: map['academicYearId'] ?? '',
          continuousAssessment:
              ContinuousAssessment.fromMap(map['continuousAssessment']),
          examScore: map['examScore'] ?? 0,
          totalScore: map['totalScore'] ?? 0,
          isApproved: map['isApproved'] ?? false,
          isPublished: map['isPublished'] ?? false,
          teacherComment: map['teacherComment'],
        );
      }).toList();
    } catch (e) {
      debugPrint(
          '[ExamRepository.getWardMarks] Cloud Function unavailable, querying Firestore directly: $e');
      try {
        Query query = _firestore
            .collection('marks')
            .where('studentId', isEqualTo: studentId)
            .where('isPublished', isEqualTo: true);
        if (examId != null && examId.isNotEmpty) {
          query = query.where('examId', isEqualTo: examId);
        }
        final snapshot = await query.get();
        return snapshot.docs.map((d) => Mark.fromFirestore(d)).toList();
      } catch (directErr, stack) {
        debugPrint(
            '[ExamRepository.getWardMarks] Direct query error for ward $studentId: $directErr\n$stack');
        return [];
      }
    }
  }

  /// Obtains authentic signed URL for student report card via Cloud Function.
  /// Never fabricates simulated download URLs.
  Future<String?> getReportCardDownloadUrl({
    required String studentId,
    required String examId,
  }) async {
    try {
      final callable = _functions.httpsCallable('getReportCardDownloadUrl');
      final result = await callable.call({
        'studentId': studentId,
        'examId': examId,
      });
      return result.data['signedUrl'] as String?;
    } catch (e, stack) {
      debugPrint(
          '[ExamRepository.getReportCardDownloadUrl] Error fetching signed URL: $e\n$stack');
      rethrow;
    }
  }
}
