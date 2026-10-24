import 'package:cloud_firestore/cloud_firestore.dart';

class AssessmentStructure {
  final int ca1Max;
  final int ca2Max;
  final int examMax;

  const AssessmentStructure({
    this.ca1Max = 20,
    this.ca2Max = 20,
    this.examMax = 60,
  });

  int get maxTotal => ca1Max + ca2Max + examMax;

  factory AssessmentStructure.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AssessmentStructure();
    return AssessmentStructure(
      ca1Max: data['ca1Max'] ?? 20,
      ca2Max: data['ca2Max'] ?? 20,
      examMax: data['examMax'] ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ca1Max': ca1Max,
      'ca2Max': ca2Max,
      'examMax': examMax,
    };
  }
}

class Examination {
  final String examId;
  final String title;
  final String academicYearId;
  final String term; // e.g. "Term 1", "Finals"
  final bool isLocked;
  final bool isPublished;
  final AssessmentStructure assessmentStructure;

  const Examination({
    required this.examId,
    required this.title,
    required this.academicYearId,
    required this.term,
    this.isLocked = false,
    this.isPublished = false,
    this.assessmentStructure = const AssessmentStructure(),
  });

  factory Examination.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Examination(
      examId: doc.id,
      title: data['title'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      term: data['term'] ?? '',
      isLocked: data['isLocked'] ?? false,
      isPublished: data['isPublished'] ?? false,
      assessmentStructure:
          AssessmentStructure.fromMap(data['assessmentStructure']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'examId': examId,
      'title': title,
      'academicYearId': academicYearId,
      'term': term,
      'isLocked': isLocked,
      'isPublished': isPublished,
      'assessmentStructure': assessmentStructure.toMap(),
    };
  }
}

class ContinuousAssessment {
  final int ca1;
  final int ca2;

  const ContinuousAssessment({
    this.ca1 = 0,
    this.ca2 = 0,
  });

  int get totalCa => ca1 + ca2;

  factory ContinuousAssessment.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const ContinuousAssessment();
    return ContinuousAssessment(
      ca1: data['ca1'] ?? 0,
      ca2: data['ca2'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ca1': ca1,
      'ca2': ca2,
    };
  }
}

class Mark {
  final String markId;
  final String examId;
  final String studentId;
  final String subjectId;
  final String classId;
  final String sectionId;
  final String academicYearId;
  final ContinuousAssessment continuousAssessment;
  final int examScore;
  final int totalScore;
  final bool isApproved;
  final bool isPublished;
  final String? teacherComment;
  final String? updatedBy;

  const Mark({
    required this.markId,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    required this.classId,
    required this.sectionId,
    required this.academicYearId,
    this.continuousAssessment = const ContinuousAssessment(),
    this.examScore = 0,
    this.totalScore = 0,
    this.isApproved = false,
    this.isPublished = false,
    this.teacherComment,
    this.updatedBy,
  });

  String get grade {
    if (totalScore >= 90) return 'A1';
    if (totalScore >= 80) return 'A2';
    if (totalScore >= 70) return 'B1';
    if (totalScore >= 60) return 'B2';
    if (totalScore >= 50) return 'C1';
    if (totalScore >= 40) return 'C2';
    if (totalScore >= 33) return 'D';
    return 'E';
  }

  static String generateMarkId(
      String examId, String studentId, String subjectId) {
    return '${examId}_${studentId}_$subjectId';
  }

  factory Mark.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Mark(
      markId: doc.id,
      examId: data['examId'] ?? '',
      studentId: data['studentId'] ?? '',
      subjectId: data['subjectId'] ?? '',
      classId: data['classId'] ?? '',
      sectionId: data['sectionId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      continuousAssessment:
          ContinuousAssessment.fromMap(data['continuousAssessment']),
      examScore: data['examScore'] ?? 0,
      totalScore: data['totalScore'] ?? 0,
      isApproved: data['isApproved'] ?? false,
      isPublished: data['isPublished'] ?? false,
      teacherComment: data['teacherComment'],
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'markId': markId,
      'examId': examId,
      'studentId': studentId,
      'subjectId': subjectId,
      'classId': classId,
      'sectionId': sectionId,
      'academicYearId': academicYearId,
      'continuousAssessment': continuousAssessment.toMap(),
      'examScore': examScore,
      'totalScore': totalScore,
      'isApproved': isApproved,
      'isPublished': isPublished,
      'teacherComment': teacherComment,
      'updatedBy': updatedBy,
    };
  }
}
