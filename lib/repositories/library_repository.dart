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

  Future<void> addBook(LibraryBook book) async {
    try {
      await _firestore
          .collection('library_books')
          .doc(book.bookId)
          .set(book.toMap(), SetOptions(merge: true));
    } catch (e, stack) {
      debugPrint('[LibraryRepository.addBook] Error adding book: $e\n$stack');
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
    final dueDate = DateTime.now().add(Duration(days: days));
    try {
      final callable = _functions.httpsCallable('issueLibraryBook');
      await callable.call<Map<String, dynamic>>({
        'bookId': bookId,
        'studentId': studentId,
        'dueDate': dueDate.toIso8601String(),
      });
    } catch (e, stack) {
      debugPrint('[LibraryRepository.issueBook] Authoritative circulation function failed for book $bookId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> returnBook(String loanId, String bookId) async {
    try {
      final callable = _functions.httpsCallable('returnLibraryBook');
      await callable.call<Map<String, dynamic>>({
        'loanId': loanId,
        'bookId': bookId,
      });
    } catch (e, stack) {
      debugPrint('[LibraryRepository.returnBook] Authoritative circulation function failed for loan $loanId: $e\n$stack');
      rethrow;
    }
  }

}
