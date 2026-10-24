import 'package:cloud_firestore/cloud_firestore.dart';

class LibraryBook {
  final String bookId;
  final String title;
  final String author;
  final String? isbn;
  final String? category;
  final int totalCopies;
  final int availableCopies;

  const LibraryBook({
    required this.bookId,
    required this.title,
    required this.author,
    this.isbn,
    this.category,
    required this.totalCopies,
    required this.availableCopies,
  });

  bool get isAvailable => availableCopies > 0;

  factory LibraryBook.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LibraryBook(
      bookId: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      isbn: data['isbn'],
      category: data['category'],
      totalCopies: data['totalCopies'] ?? 1,
      availableCopies: data['availableCopies'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'isbn': isbn,
      'category': category,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
    };
  }
}

class LibraryLoan {
  final String loanId;
  final String bookId;
  final String studentId;
  final DateTime issuedAt;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String status; // 'active', 'returned', 'overdue'

  const LibraryLoan({
    required this.loanId,
    required this.bookId,
    required this.studentId,
    required this.issuedAt,
    required this.dueDate,
    this.returnedAt,
    this.status = 'active',
  });

  bool get isReturned => returnedAt != null || status == 'returned';

  factory LibraryLoan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LibraryLoan(
      loanId: doc.id,
      bookId: data['bookId'] ?? '',
      studentId: data['studentId'] ?? '',
      issuedAt: (data['issuedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 14)),
      returnedAt: (data['returnedAt'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'loanId': loanId,
      'bookId': bookId,
      'studentId': studentId,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'dueDate': Timestamp.fromDate(dueDate),
      'returnedAt': returnedAt != null ? Timestamp.fromDate(returnedAt!) : null,
      'status': status,
    };
  }
}
