import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/fee_model.dart';

class FeeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FeeRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<List<FeeStructure>> getFeeStructuresForParent({
    required List<String> parentWardClasses,
    required String academicYearId,
  }) async {
    try {
      final generalQuery = _firestore
          .collection('fee_structures')
          .where('classId', isNull: true)
          .where('academicYearId', isEqualTo: academicYearId)
          .get();

      Future<QuerySnapshot>? classQuery;
      if (parentWardClasses.isNotEmpty) {
        classQuery = _firestore
            .collection('fee_structures')
            .where('classId', whereIn: parentWardClasses)
            .where('academicYearId', isEqualTo: academicYearId)
            .get();
      }

      final generalSnapshot = await generalQuery;
      final List<DocumentSnapshot> allDocs = [...generalSnapshot.docs];

      if (classQuery != null) {
        final classSnapshot = await classQuery;
        allDocs.addAll(classSnapshot.docs);
      }

      return allDocs.map((doc) => FeeStructure.fromFirestore(doc)).toList();
    } catch (e, stack) {
      debugPrint('[FeeRepository.getFeeStructuresForParent] Error: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<StudentInvoice>> getInvoicesStream({String? studentId}) {
    try {
      Query query = _firestore
          .collection('student_invoices')
          .where('isArchived', isEqualTo: false);
      if (studentId != null && studentId.isNotEmpty) {
        query = query.where('studentId', isEqualTo: studentId);
      }
      return query.snapshots().handleError((err) {
        debugPrint(
            '[FeeRepository.getInvoicesStream] FIRESTORE QUERY / INDEX ERROR for student $studentId: $err');
      }).map((s) {
        final list =
            s.docs.map((d) => StudentInvoice.fromFirestore(d)).toList();
        list.sort((a, b) {
          final aDate = a.dueDate ?? DateTime(2026, 1, 1);
          final bDate = b.dueDate ?? DateTime(2026, 1, 1);
          return bDate.compareTo(aDate);
        });
        return list;
      });
    } catch (e, stack) {
      debugPrint(
          '[FeeRepository.getInvoicesStream] Error for student $studentId: $e\n$stack');
      rethrow;
    }
  }

  Future<List<StudentInvoice>> getWardInvoices(String studentId) async {
    try {
      final callable = _functions.httpsCallable('getWardInvoices');
      final result = await callable.call({'studentId': studentId});
      final rawList = result.data['invoices'] as List<dynamic>? ?? [];
      return rawList.map((item) {
        final map = Map<String, dynamic>.from(item);
        return StudentInvoice(
          invoiceId: map['id'] ?? map['invoiceId'] ?? '',
          studentId: map['studentId'] ?? '',
          academicYearId: map['academicYearId'] ?? '',
          title: map['title'] ?? '',
          totalAmountPaise: map['totalAmountPaise'] ?? 0,
          paidAmountPaise: map['paidAmountPaise'] ?? 0,
          outstandingBalancePaise: map['outstandingBalancePaise'] ?? 0,
          dueDate: map['dueDate'] != null
              ? (map['dueDate'] is Map
                  ? DateTime.now()
                  : DateTime.tryParse(map['dueDate'].toString()))
              : null,
          status: map['status'] ?? 'unpaid',
        );
      }).toList();
    } catch (e) {
      debugPrint(
          '[FeeRepository.getWardInvoices] Cloud Function unavailable, querying Firestore directly: $e');
      try {
        final snapshot = await _firestore
            .collection('student_invoices')
            .where('studentId', isEqualTo: studentId)
            .get();
        return snapshot.docs
            .map((d) => StudentInvoice.fromFirestore(d))
            .toList();
      } catch (directErr, stack) {
        debugPrint(
            '[FeeRepository.getWardInvoices] Direct query error for student $studentId: $directErr\n$stack');
        return [];
      }
    }
  }

  /// Retrieves authentic signed receipt download URL via Cloud Function.
  /// Never fabricates placeholder or fake URLs.
  Future<String?> getReceiptDownloadUrl(String paymentId) async {
    try {
      final callable = _functions.httpsCallable('getReceiptDownloadUrl');
      final result = await callable.call({'paymentId': paymentId});
      return result.data['signedUrl'] as String?;
    } catch (e, stack) {
      debugPrint(
          '[FeeRepository.getReceiptDownloadUrl] Error fetching receipt URL for $paymentId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> recordOfflinePayment({
    required String invoiceId,
    required String studentId,
    required String payerUserId,
    required int amountPaise,
    required String paymentMethod,
    required String notes,
  }) async {
    try {
      final callable = _functions.httpsCallable('recordOfflinePayment');
      await callable.call<Map<String, dynamic>>({
        'invoiceId': invoiceId,
        'studentId': studentId,
        'payerUserId': payerUserId,
        'amountPaise': amountPaise,
        'paymentMethod': paymentMethod,
        'notes': notes,
      });
    } catch (e, stack) {
      debugPrint('[FeeRepository.recordOfflinePayment] Authoritative payment function failed for invoice $invoiceId: $e\n$stack');
      rethrow;
    }
  }

  Future<String> createInvoice({
    required String studentId,
    required String academicYearId,
    required String title,
    required int totalAmountPaise,
    required DateTime dueDate,
  }) async {
    try {
      final callable = _functions.httpsCallable('createFeeInvoice');
      final result = await callable.call<Map<String, dynamic>>({
        'studentId': studentId,
        'academicYearId': academicYearId,
        'title': title,
        'totalAmountPaise': totalAmountPaise,
        'dueDate': dueDate.toIso8601String(),
      });
      final invoiceId = result.data['invoiceId'] as String?;
      if (invoiceId == null || invoiceId.isEmpty) {
        throw StateError('The invoice service did not return a persisted invoice ID.');
      }
      return invoiceId;
    } catch (e, stack) {
      debugPrint('[FeeRepository.createInvoice] Authoritative invoice function failed: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<FeeStructure>> getAllFeeStructuresStream(
      {String? academicYearId}) {
    try {
      Query query = _firestore.collection('fee_structures');
      if (academicYearId != null) {
        query = query.where('academicYearId', isEqualTo: academicYearId);
      }
      return query.snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => FeeStructure.fromFirestore(doc))
                .toList(),
          );
    } catch (e, stack) {
      debugPrint('[FeeRepository.getAllFeeStructuresStream] Error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> createFeeStructure({
    required String title,
    required int amountPaise,
    required String frequency,
    String? classId,
    required String academicYearId,
  }) async {
    try {
      final callable = _functions.httpsCallable('createFeeStructure');
      await callable.call<Map<String, dynamic>>({
        'title': title,
        'amountPaise': amountPaise,
        'frequency': frequency,
        'classId': classId,
        'academicYearId': academicYearId,
      });
    } catch (e, stack) {
      debugPrint('[FeeRepository.createFeeStructure] Authoritative fee-structure function failed: $e\n$stack');
      rethrow;
    }
  }

  Future<void> requestRefund({
    required String invoiceId,
    required String paymentId,
    required int amountPaise,
    required String reason,
  }) async {
    try {
      final callable = _functions.httpsCallable('processRefund');
      await callable.call<Map<String, dynamic>>({
        'invoiceId': invoiceId,
        'paymentId': paymentId,
        'amountPaise': amountPaise,
        'reason': reason,
      });
    } catch (e, stack) {
      debugPrint('[FeeRepository.requestRefund] Authoritative refund function failed: $e\n$stack');
      rethrow;
    }
  }

}
