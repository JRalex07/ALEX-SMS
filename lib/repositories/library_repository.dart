import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/library_model.dart';

class LibraryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  LibraryRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Stream<List<LibraryBook>> getBooksStream() {
    try {
      return _firestore
          .collection('library_books')
          .snapshots()
          .map((s) => s.docs.map((d) => LibraryBook.fromFirestore(d)).toList());
    } catch (e, stack) {
      debugPrint('[LibraryRepository.getBooksStream] Error: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<LibraryLoan>> getLoansStream({String? studentId}) {
    try {
      Query query = _firestore.collection('library_loans');
      if (studentId != null && studentId.isNotEmpty) {
        query = query.where('studentId', isEqualTo: studentId);
      }
      return query
          .snapshots()
          .map((s) => s.docs.map((d) => LibraryLoan.fromFirestore(d)).toList());
    } catch (e, stack) {
      debugPrint('[LibraryRepository.getLoansStream] Error: $e\n$stack');
      rethrow;
    }
  }

  Future<void> issueBook({
    required String bookId,
    required String studentId,
    int days = 14,
  }) async {
    final now = DateTime.now();
    final dueDate = now.add(Duration(days: days));

    try {
      try {
        final callable = _functions.httpsCallable('issueLibraryBook');
        await callable.call<Map<String, dynamic>>({
          'bookId': bookId,
          'studentId': studentId,
          'dueDate': dueDate.toIso8601String(),
        });
        return;
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied' ||
            fe.code == 'unauthenticated' ||
            fe.code == 'invalid-argument' ||
            fe.code == 'failed-precondition') {
          rethrow;
        }
      } catch (_) {}

      final loanRef = _firestore.collection('library_loans').doc();
      final bookRef = _firestore.collection('library_books').doc(bookId);

      await _firestore.runTransaction((transaction) async {
        final bookDoc = await transaction.get(bookRef);
        if (!bookDoc.exists) {
          throw Exception('Book $bookId not found in catalogue.');
        }
        final available = bookDoc.data()?['availableCopies'] as int? ?? 0;
        if (available <= 0) {
          throw Exception('No available copies remaining for this book.');
        }

        transaction.set(loanRef, {
          'loanId': loanRef.id,
          'bookId': bookId,
          'studentId': studentId,
          'issuedAt': Timestamp.fromDate(now),
          'dueDate': Timestamp.fromDate(dueDate),
          'status': 'active',
        });

        transaction.update(bookRef, {
          'availableCopies': available - 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stack) {
      debugPrint(
          '[LibraryRepository.issueBook] Error issuing book $bookId to student $studentId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> returnBook(String loanId, String bookId) async {
    try {
      try {
        final callable = _functions.httpsCallable('returnLibraryBook');
        await callable.call<Map<String, dynamic>>({
          'loanId': loanId,
          'bookId': bookId,
        });
        return;
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied' ||
            fe.code == 'unauthenticated' ||
            fe.code == 'invalid-argument' ||
            fe.code == 'failed-precondition') {
          rethrow;
        }
      } catch (_) {}

      final loanRef = _firestore.collection('library_loans').doc(loanId);
      final bookRef = _firestore.collection('library_books').doc(bookId);

      await _firestore.runTransaction((transaction) async {
        final loanDoc = await transaction.get(loanRef);
        if (!loanDoc.exists) {
          throw Exception('Loan record $loanId not found.');
        }
        final loanData = loanDoc.data();
        if (loanData?['status'] == 'returned') {
          throw Exception(
              'This book loan has already been marked as returned.');
        }

        final bookDoc = await transaction.get(bookRef);
        if (!bookDoc.exists) {
          throw Exception('Book $bookId not found.');
        }
        final available = bookDoc.data()?['availableCopies'] as int? ?? 0;

        transaction.update(loanRef, {
          'returnedAt': FieldValue.serverTimestamp(),
          'status': 'returned',
        });

        transaction.update(bookRef, {
          'availableCopies': available + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e, stack) {
      debugPrint(
          '[LibraryRepository.returnBook] Error returning loan $loanId for book $bookId: $e\n$stack');
      rethrow;
    }
  }
}
