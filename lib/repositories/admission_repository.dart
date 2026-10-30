import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../core/services/crash_reporting_service.dart';
import '../models/admission_application_model.dart';
import '../models/student_model.dart';

class AdmissionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AdmissionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  static const String collectionName = 'admissions_enquiries';

  String generateApplicationId() {
    final year = DateTime.now().year;
    final randomSuffix = (DateTime.now().millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'LAV-ADM-$year-$randomSuffix';
  }

  Stream<List<AdmissionApplication>> getApplicationsStream({
    String? status,
    String? classId,
  }) {
    Query query = _firestore.collection(collectionName);
    if (status != null && status != 'All' && status.isNotEmpty) {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }
    if (classId != null && classId != 'All' && classId.isNotEmpty) {
      query = query.where('targetClass', isEqualTo: classId);
    }

    return query.orderBy('updatedAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => AdmissionApplication.fromFirestore(doc))
            .toList());
  }

  Future<AdmissionApplication?> getApplicationById(String id) async {
    final doc = await _firestore.collection(collectionName).doc(id).get();
    if (!doc.exists) return null;
    return AdmissionApplication.fromFirestore(doc);
  }

  Future<void> saveDraft(AdmissionApplication app) async {
    final docRef = _firestore.collection(collectionName).doc(app.id);
    final map = app.toMap();
    map['status'] = 'draft';
    map['isDraft'] = true;
    map['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(map, SetOptions(merge: true));

    // Audit log
    await _logAuditEvent(
      action: 'ADMISSION_DRAFT_SAVED',
      details: 'Draft saved for applicant: ${app.fullName} (${app.id})',
    );
  }

  Future<void> submitApplication(AdmissionApplication app) async {
    final docRef = _firestore.collection(collectionName).doc(app.id);
    final map = app.toMap();
    map['status'] = 'submitted';
    map['isDraft'] = false;
    map['submittedAt'] = FieldValue.serverTimestamp();
    map['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(map, SetOptions(merge: true));

    // Audit log
    await _logAuditEvent(
      action: 'ADMISSION_APPLICATION_SUBMITTED',
      details:
          'Application submitted for ${app.fullName} (Target: Class ${app.targetClass}, ID: ${app.id})',
    );
  }

  Future<UploadedDocument> uploadDocument({
    required String applicationId,
    required String documentType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final storagePath = 'admissions/$applicationId/${documentType}_$safeName';
      final storageRef = _storage.ref(storagePath);

      final metadata = SettableMetadata(
        customMetadata: {
          'applicationId': applicationId,
          'documentType': documentType,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = await storageRef.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      final uploadedDoc = UploadedDocument(
        documentType: documentType,
        fileName: fileName,
        fileUrl: downloadUrl,
        storagePath: storagePath,
        fileSizeBytes: bytes.length,
        uploadedAt: DateTime.now(),
        verificationStatus: 'pending',
      );

      // Update document list in Firestore
      final appDoc =
          await _firestore.collection(collectionName).doc(applicationId).get();
      if (appDoc.exists) {
        final app = AdmissionApplication.fromFirestore(appDoc);
        final updatedDocs = List<UploadedDocument>.from(app.documents)
          ..removeWhere((d) => d.documentType == documentType)
          ..add(uploadedDoc);

        await _firestore.collection(collectionName).doc(applicationId).update({
          'documents': updatedDocs.map((d) => d.toMap()).toList(),
          if (documentType == 'photo') 'photoUrl': downloadUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return uploadedDoc;
    } catch (e, stack) {
      await CrashReportingService.instance.recordError(
        e,
        stack,
        reason: 'admission_document_upload_failed',
        customContext: {
          'applicationId': applicationId,
          'documentType': documentType,
        },
      );
      rethrow;
    }
  }

  Future<void> updateDocumentVerification({
    required String applicationId,
    required String documentType,
    required String verificationStatus, // 'verified', 'rejected', 'missing'
    String? reviewerNotes,
  }) async {
    final appDoc =
        await _firestore.collection(collectionName).doc(applicationId).get();
    if (!appDoc.exists) return;

    final app = AdmissionApplication.fromFirestore(appDoc);
    final updatedDocs = app.documents.map((d) {
      if (d.documentType == documentType) {
        return d.copyWith(
          verificationStatus: verificationStatus,
          reviewerNotes: reviewerNotes ?? d.reviewerNotes,
        );
      }
      return d;
    }).toList();

    await _firestore.collection(collectionName).doc(applicationId).update({
      'documents': updatedDocs.map((d) => d.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logAuditEvent(
      action: 'DOCUMENT_VERIFICATION_UPDATED',
      details:
          'Document $documentType for app $applicationId marked as $verificationStatus',
    );
  }

  Future<void> recordDecision({
    required String applicationId,
    required String
        decision, // 'approved', 'rejected', 'waitlisted', 'under_review'
    required String reviewerUid,
    required String reviewerName,
    String? notes,
    String? reason,
  }) async {
    await _firestore.collection(collectionName).doc(applicationId).update({
      'status': decision.toLowerCase(),
      'decisionDate': FieldValue.serverTimestamp(),
      'decidedByUid': reviewerUid,
      'decidedByName': reviewerName,
      if (notes != null) 'reviewerNotes': notes,
      if (reason != null) 'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _logAuditEvent(
      action: 'ADMISSION_DECISION_RECORDED',
      details:
          'Application $applicationId decided as $decision by $reviewerName',
    );
  }

  /// Convenience wrapper to update application status / decision
  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String reviewerUid = 'admin',
    String reviewerName = 'Admissions Officer',
    String? notes,
  }) =>
      recordDecision(
        applicationId: applicationId,
        decision: status,
        reviewerUid: reviewerUid,
        reviewerName: reviewerName,
        notes: notes,
      );

  Future<Student> enrollApplicant({
    required AdmissionApplication application,
    required String assignedClass,
    required String assignedSection,
    required String admissionNumber,
    required String enrollerName,
  }) async {
    // Generate new student ID
    final studentId =
        'STU_${application.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}';

    final student = Student(
      studentId: studentId,
      admissionNumber: admissionNumber,
      fullName: application.fullName,
      currentClassId: assignedClass,
      currentSectionId: assignedSection,
      currentAcademicYearId: application.academicYearId,
      status: 'enrolled',
      guardianUserIds: application.existingGuardianUserId != null
          ? [application.existingGuardianUserId!]
          : [],
      dob: application.dateOfBirth.toIso8601String().split('T').first,
      gender: application.gender,
      bloodGroup: application.bloodGroup,
      emergencyContact:
          '${application.emergencyContactName} (${application.emergencyContactPhone})',
      address: application.formattedCurrentAddress,
      enrollmentDate: DateTime.now(),
    );

    final batch = _firestore.batch();

    // 1. Create Student record
    final studentDoc = _firestore.collection('students').doc(studentId);
    batch.set(studentDoc, {
      'studentId': student.studentId,
      'schoolId': 'SCH_001',
      'admissionNumber': student.admissionNumber,
      'fullName': student.fullName,
      'currentClassId': student.currentClassId,
      'currentSectionId': student.currentSectionId,
      'currentAcademicYearId': student.currentAcademicYearId,
      'status': 'enrolled',
      'guardianUserIds': student.guardianUserIds,
      'dob': student.dob,
      'gender': student.gender,
      'bloodGroup': student.bloodGroup,
      'emergencyContact': student.emergencyContact,
      'address': student.address,
      'enrollmentDate': FieldValue.serverTimestamp(),
      'admissionApplicationId': application.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Mark application as enrolled with reference to student
    final appDoc = _firestore.collection(collectionName).doc(application.id);
    batch.update(appDoc, {
      'status': 'enrolled',
      'enrolledStudentId': studentId,
      'enrolledAdmissionNumber': admissionNumber,
      'targetClass': assignedClass,
      'targetSection': assignedSection,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Commit batch atomically
    await batch.commit();

    // 4. Audit trail
    await _logAuditEvent(
      action: 'APPLICANT_ENROLLED_AS_STUDENT',
      details:
          'Applicant ${application.fullName} enrolled into Class $assignedClass-$assignedSection (Adm No: $admissionNumber) by $enrollerName',
    );

    return student;
  }

  Future<void> _logAuditEvent({
    required String action,
    required String details,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'action': action,
        'actorEmail': 'admissions_desk@lav.edu',
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AdmissionRepository] Failed to write audit event: $e');
    }
  }
}
