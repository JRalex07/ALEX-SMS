import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/student_model.dart';

class StudentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  StudentRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<Student?> getStudentById(String studentId) async {
    try {
      final doc = await _firestore.collection('students').doc(studentId).get();
      if (!doc.exists) return null;
      return Student.fromFirestore(doc);
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.getStudentById] Error fetching student $studentId: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<Student>> getStudentsStream({
    String? classId,
    String? sectionId,
  }) {
    try {
      Query query = _firestore.collection('students');
      if (classId != null && classId.isNotEmpty) {
        query = query.where('currentClassId', isEqualTo: classId);
      }
      if (sectionId != null && sectionId.isNotEmpty) {
        query = query.where('currentSectionId', isEqualTo: sectionId);
      }
      return query.snapshots().handleError((err) {
        debugPrint(
            '[StudentRepository.getStudentsStream] FIRESTORE QUERY / INDEX ERROR ($classId-$sectionId): $err');
      }).map(
        (snapshot) =>
            snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
      );
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.getStudentsStream] Error initializing query: $e\n$stack');
      rethrow;
    }
  }

  Future<List<Student>> getLinkedStudentsForParent(String parentUid) async {
    try {
      final snapshot = await _firestore
          .collection('students')
          .where('guardianUserIds', arrayContains: parentUid)
          .where('status', isEqualTo: 'enrolled')
          .get();

      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.getLinkedStudentsForParent] Error fetching wards for $parentUid: $e\n$stack');
      rethrow;
    }
  }

  Future<void> enrollStudent(Student student) async {
    try {
      await _firestore.collection('students').doc(student.studentId).set({
        'studentId': student.studentId,
        'schoolId': 'SCH_001',
        'admissionNumber': student.admissionNumber,
        'fullName': student.fullName,
        'currentClassId': student.currentClassId,
        'currentSectionId': student.currentSectionId,
        'currentAcademicYearId': student.currentAcademicYearId,
        'status': 'enrolled',
        'guardianUserIds': <String>[],
        'dob': student.dob,
        'gender': student.gender,
        'bloodGroup': student.bloodGroup,
        'emergencyContact': student.emergencyContact,
        'medicalNotes': student.medicalNotes,
        'address': student.address,
        'enrollmentDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.enrollStudent] Error enrolling student ${student.studentId}: $e\n$stack');
      rethrow;
    }
  }

  Future<void> updateStudentDemographics({
    required String studentId,
    String? dob,
    String? gender,
    String? bloodGroup,
    String? emergencyContact,
    String? medicalNotes,
    String? address,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (dob != null) updates['dob'] = dob;
      if (gender != null) updates['gender'] = gender;
      if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
      if (emergencyContact != null) {
        updates['emergencyContact'] = emergencyContact;
      }
      if (medicalNotes != null) updates['medicalNotes'] = medicalNotes;
      if (address != null) updates['address'] = address;

      await _firestore.collection('students').doc(studentId).update(updates);
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.updateStudentDemographics] Error updating $studentId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> linkGuardian({
    required String studentId,
    required String guardianUid,
    required String relationship,
  }) async {
    try {
      final callable = _functions.httpsCallable('linkGuardian');
      await callable.call({
        'studentId': studentId,
        'guardianUid': guardianUid,
        'relationship': relationship,
      });
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.linkGuardian] Error linking $guardianUid to $studentId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> transferStudentClass({
    required String studentId,
    required String newClassId,
    required String newSectionId,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('transferStudentCohort');
      await callable.call<Map<String, dynamic>>({
        'studentId': studentId,
        'targetClassId': newClassId,
        'targetSectionId': newSectionId,
        'transferReason': reason,
      });
    } catch (e, stack) {
      debugPrint('[StudentRepository.transferStudentClass] Authoritative cohort-transfer function failed: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getEnquiriesStream() {
    try {
      return _firestore
          .collection('admissions_enquiries')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) {
                final data = doc.data();
                data['id'] = doc.id;
                return data;
              }).toList());
    } catch (e, stack) {
      debugPrint('[StudentRepository.getEnquiriesStream] Error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> createEnquiry({
    required String applicantName,
    required String targetClass,
    required String guardianName,
    required String phone,
    String? email,
    String? notes,
  }) async {
    try {
      await _firestore.collection('admissions_enquiries').add({
        'applicantName': applicantName,
        'targetClass': targetClass,
        'guardianName': guardianName,
        'phone': phone,
        'email': email ?? '',
        'notes': notes ?? '',
        'status':
            'enquiry', // enquiry -> applied -> documents_verified -> approved -> enrolled
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[StudentRepository.createEnquiry] Error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> updateApplicationStatus({
    required String enquiryId,
    required String newStatus,
    String? reviewerNotes,
  }) async {
    try {
      await _firestore
          .collection('admissions_enquiries')
          .doc(enquiryId)
          .update({
        'status': newStatus,
        if (reviewerNotes != null) 'reviewerNotes': reviewerNotes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
          '[StudentRepository.updateApplicationStatus] Error: $e\n$stack');
      rethrow;
    }
  }
}
