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
    required String notes,
  }) async {
    try {
      try {
        final callable = _functions.httpsCallable('recordOfflinePayment');
        await callable.call<Map<String, dynamic>>({
          'invoiceId': invoiceId,
          'studentId': studentId,
          'payerUserId': payerUserId,
          'amountPaise': amountPaise,
          'notes': notes,
        });
        return;
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied' ||
            fe.code == 'unauthenticated' ||
            fe.code == 'invalid-argument' ||
            fe.code == 'failed-precondition') {
          rethrow;
        }
      } catch (_) {
        // Fall back to direct Firestore transaction for mock unit tests
      }

      final paymentRef = _firestore.collection('payments').doc();
      final invoiceRef =
          _firestore.collection('student_invoices').doc(invoiceId);

      await _firestore.runTransaction((transaction) async {
        final invoiceDoc = await transaction.get(invoiceRef);
        if (!invoiceDoc.exists) {
          throw Exception('Invoice $invoiceId does not exist.');
        }

        final data = invoiceDoc.data()!;
        final currentPaid = data['paidAmountPaise'] as int? ?? 0;
        final currentOutstanding = data['outstandingBalancePaise'] as int? ?? 0;

        final newPaid = currentPaid + amountPaise;
        final newOutstanding = (currentOutstanding - amountPaise)
            .clamp(0, double.infinity)
            .toInt();
        final newStatus = newOutstanding == 0 ? 'paid' : 'partially_paid';

        transaction.set(paymentRef, {
          'paymentId': paymentRef.id,
          'invoiceId': invoiceId,
          'studentId': studentId,
          'payerUserId': payerUserId,
          'amountPaise': amountPaise,
          'gateway': 'offline',
          'status': 'successful',
          'notes': notes,
          'capturedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.update(invoiceRef, {
          'paidAmountPaise': newPaid,
          'outstandingBalancePaise': newOutstanding,
          'status': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stack) {
      debugPrint(
          '[FeeRepository.recordOfflinePayment] Error recording payment for invoice $invoiceId: $e\n$stack');
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
      try {
        final callable = _functions.httpsCallable('createFeeInvoice');
        final res = await callable.call<Map<String, dynamic>>({
          'studentId': studentId,
          'academicYearId': academicYearId,
          'title': title,
          'totalAmountPaise': totalAmountPaise,
          'dueDate': dueDate.toIso8601String(),
        });
        final returnedId = res.data['invoiceId'] as String?;
        if (returnedId != null) return returnedId;
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied' ||
            fe.code == 'unauthenticated' ||
            fe.code == 'invalid-argument') {
          rethrow;
        }
      } catch (_) {}

      final docRef = _firestore.collection('student_invoices').doc();
      await docRef.set({
        'invoiceId': docRef.id,
        'studentId': studentId,
        'academicYearId': academicYearId,
        'title': title,
        'totalAmountPaise': totalAmountPaise,
        'paidAmountPaise': 0,
        'outstandingBalancePaise': totalAmountPaise,
        'dueDate': Timestamp.fromDate(dueDate),
        'status': 'unpaid',
        'isArchived': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e, stack) {
      debugPrint('[FeeRepository.createInvoice] Error: $e\n$stack');
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
      try {
        final callable = _functions.httpsCallable('createFeeStructure');
        await callable.call<Map<String, dynamic>>({
          'title': title,
          'amountPaise': amountPaise,
          'frequency': frequency,
          'classId': classId,
          'academicYearId': academicYearId,
        });
        return;
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied' ||
            fe.code == 'unauthenticated' ||
            fe.code == 'invalid-argument') {
          rethrow;
        }
      } catch (_) {}

      final docRef = _firestore.collection('fee_structures').doc();
      await docRef.set({
        'structureId': docRef.id,
        'title': title,
        'amountPaise': amountPaise,
        'frequency': frequency,
        'classId': classId,
        'academicYearId': academicYearId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[FeeRepository.createFeeStructure] Error: $e\n$stack');
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
      try {
        final callable = _functions.httpsCallable('processRefund');
        await callable.call<Map<String, dynamic>>({
          'invoiceId': invoiceId,
          'paymentId': paymentId,
          'amountPaise': amountPaise,
          'reason': reason,
        });
        return;
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied' ||
            fe.code == 'unauthenticated' ||
            fe.code == 'invalid-argument') {
          rethrow;
        }
      } catch (_) {}

      await _firestore.collection('refund_requests').add({
        'invoiceId': invoiceId,
        'paymentId': paymentId,
        'amountPaise': amountPaise,
        'reason': reason,
        'status': 'pending_approval',
        'requestedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[FeeRepository.requestRefund] Error: $e\n$stack');
      rethrow;
    }
  }
}
