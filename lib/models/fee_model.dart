import 'package:cloud_firestore/cloud_firestore.dart';

class FeeItem {
  final String name;
  final int amountPaise;

  const FeeItem({required this.name, required this.amountPaise});

  factory FeeItem.fromMap(Map<String, dynamic> data) {
    return FeeItem(
      name: data['name'] ?? '',
      amountPaise: data['amountPaise'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amountPaise': amountPaise,
    };
  }
}

class FeeStructure {
  final String structureId;
  final String title;
  final String? classId; // Null for school-wide general fees
  final String academicYearId;
  final int totalAmountPaise;
  final List<FeeItem> breakdown;

  const FeeStructure({
    required this.structureId,
    required this.title,
    this.classId,
    required this.academicYearId,
    required this.totalAmountPaise,
    this.breakdown = const [],
  });

  bool get isGeneralSchoolWide => classId == null;
  String get name => title;
  List<FeeItem> get components => breakdown;
  String get frequency => 'Annual / Termly';

  factory FeeStructure.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawList = data['breakdown'] as List<dynamic>? ?? [];
    final breakdown = rawList
        .map((item) => FeeItem.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return FeeStructure(
      structureId: doc.id,
      title: data['title'] ?? '',
      classId: data['classId'],
      academicYearId: data['academicYearId'] ?? '',
      totalAmountPaise: data['totalAmountPaise'] ?? 0,
      breakdown: breakdown,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'structureId': structureId,
      'title': title,
      'classId': classId,
      'academicYearId': academicYearId,
      'totalAmountPaise': totalAmountPaise,
      'breakdown': breakdown.map((i) => i.toMap()).toList(),
    };
  }
}

class StudentInvoice {
  final String invoiceId;
  final String studentId;
  final String academicYearId;
  final String title;
  final int totalAmountPaise;
  final int paidAmountPaise;
  final int outstandingBalancePaise;
  final DateTime? dueDate;
  final String status; // 'unpaid', 'partially_paid', 'paid', 'overdue'
  final bool isArchived;
  final String? payerUserId;

  const StudentInvoice({
    required this.invoiceId,
    required this.studentId,
    required this.academicYearId,
    required this.title,
    required this.totalAmountPaise,
    this.paidAmountPaise = 0,
    required this.outstandingBalancePaise,
    this.dueDate,
    this.status = 'unpaid',
    this.isArchived = false,
    this.payerUserId,
  });

  bool get isPaid => outstandingBalancePaise == 0 || status == 'paid';
  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isPaid;

  factory StudentInvoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StudentInvoice(
      invoiceId: doc.id,
      studentId: data['studentId'] ?? '',
      academicYearId: data['academicYearId'] ?? '',
      title: data['title'] ?? '',
      totalAmountPaise: data['totalAmountPaise'] ?? 0,
      paidAmountPaise: data['paidAmountPaise'] ?? 0,
      outstandingBalancePaise: data['outstandingBalancePaise'] ?? 0,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'unpaid',
      isArchived: data['isArchived'] ?? false,
      payerUserId: data['payerUserId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceId': invoiceId,
      'studentId': studentId,
      'academicYearId': academicYearId,
      'title': title,
      'totalAmountPaise': totalAmountPaise,
      'paidAmountPaise': paidAmountPaise,
      'outstandingBalancePaise': outstandingBalancePaise,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status,
      'isArchived': isArchived,
      'payerUserId': payerUserId,
    };
  }
}

class Payment {
  final String paymentId;
  final String invoiceId;
  final String studentId;
  final String payerUserId;
  final int amountPaise;
  final String gateway; // 'cashfree', 'razorpay', 'phonepe', 'offline'
  final String status; // 'successful', 'pending', 'failed'
  final DateTime? capturedAt;

  const Payment({
    required this.paymentId,
    required this.invoiceId,
    required this.studentId,
    required this.payerUserId,
    required this.amountPaise,
    required this.gateway,
    this.status = 'successful',
    this.capturedAt,
  });

  factory Payment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Payment(
      paymentId: doc.id,
      invoiceId: data['invoiceId'] ?? '',
      studentId: data['studentId'] ?? '',
      payerUserId: data['payerUserId'] ?? '',
      amountPaise: data['amountPaise'] ?? 0,
      gateway: data['gateway'] ?? 'offline',
      status: data['status'] ?? 'successful',
      capturedAt: (data['capturedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'invoiceId': invoiceId,
      'studentId': studentId,
      'payerUserId': payerUserId,
      'amountPaise': amountPaise,
      'gateway': gateway,
      'status': status,
      'capturedAt': capturedAt != null ? Timestamp.fromDate(capturedAt!) : null,
    };
  }
}
