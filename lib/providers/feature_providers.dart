import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../models/examination_model.dart';
import '../models/fee_model.dart';
import '../models/notice_model.dart';
import '../models/library_model.dart';
import '../repositories/attendance_repository.dart';
import '../repositories/exam_repository.dart';
import '../repositories/fee_repository.dart';
import '../repositories/notice_repository.dart';
import '../repositories/library_repository.dart';
import 'auth_providers.dart';
import 'child_context_provider.dart';

import '../models/student_model.dart';
import '../models/user_model.dart';

// Repository Providers
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository();
});

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository();
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  return NoticeRepository();
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return LibraryRepository();
});

// Published Notices Stream
final publishedNoticesProvider = StreamProvider<List<Notice>>((ref) {
  final repo = ref.watch(noticeRepositoryProvider);
  return repo.getPublishedNoticesStream();
});

// Library Books Stream
final libraryBooksProvider = StreamProvider<List<LibraryBook>>((ref) {
  final repo = ref.watch(libraryRepositoryProvider);
  return repo.getBooksStream();
});

// Students Streams
final allStudentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getStudentsStream();
});

final classStudentsStreamProvider = StreamProvider.family<List<Student>,
    ({String? classId, String? sectionId})>((ref, arg) {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getStudentsStream(classId: arg.classId, sectionId: arg.sectionId);
});

// Invoices Streams
final allInvoicesStreamProvider = StreamProvider<List<StudentInvoice>>((ref) {
  final repo = ref.watch(feeRepositoryProvider);
  return repo.getInvoicesStream();
});

final childInvoicesStreamProvider =
    StreamProvider.family<List<StudentInvoice>, String>((ref, studentId) {
  final repo = ref.watch(feeRepositoryProvider);
  return repo.getInvoicesStream(studentId: studentId);
});

// Attendance Sessions Stream
final attendanceSessionsStreamProvider = StreamProvider.family<
    List<AttendanceSession>, ({String classId, String sectionId})>((ref, arg) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getSessionsStream(classId: arg.classId, sectionId: arg.sectionId);
});

// Active Child Invoices Provider (uses Trusted-Backend Read Design getWardInvoices)
final activeChildInvoicesProvider =
    FutureProvider<List<StudentInvoice>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final feeRepo = ref.watch(feeRepositoryProvider);
  return await feeRepo.getWardInvoices(child.studentId);
});

// Active Child Marks Provider (uses getWardMarks Cloud Function)
final activeChildMarksProvider = FutureProvider<List<Mark>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final examRepo = ref.watch(examRepositoryProvider);
  return await examRepo.getWardMarks(studentId: child.studentId);
});

// Active Child Attendance Provider (uses getWardAttendanceHistory)
final activeChildAttendanceProvider =
    FutureProvider<List<AttendanceRecord>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final attendanceRepo = ref.watch(attendanceRepositoryProvider);
  return await attendanceRepo.getWardAttendanceHistory(child.studentId);
});

// Parent Fee Structures Provider (Separately Authorized Dual-Query Pattern)
final parentFeeStructuresProvider =
    FutureProvider<List<FeeStructure>>((ref) async {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null || !user.isParent) return [];

  final feeRepo = ref.watch(feeRepositoryProvider);
  return await feeRepo.getFeeStructuresForParent(
    parentWardClasses: user.wardClasses,
    academicYearId: 'AY_2026_2027',
  );
});

// All Staff Users Stream Provider for Admin Portal
final allStaffUsersStreamProvider = StreamProvider<List<AppUser>>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.getAllStaffUsersStream();
});

// All Fee Structures Stream Provider for Accountant Portal
final allFeeStructuresStreamProvider =
    StreamProvider.family<List<FeeStructure>, String?>((ref, academicYearId) {
  final feeRepo = ref.watch(feeRepositoryProvider);
  return feeRepo.getAllFeeStructuresStream(academicYearId: academicYearId);
});

// Admissions Enquiries Stream Provider for Admissions Portal
final admissionsEnquiriesStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final studentRepo = ref.watch(studentRepositoryProvider);
  return studentRepo.getEnquiriesStream();
});

// Library Loans Stream Provider for Librarian Portal
final allLibraryLoansStreamProvider = StreamProvider<List<LibraryLoan>>((ref) {
  final libraryRepo = ref.watch(libraryRepositoryProvider);
  return libraryRepo.getLoansStream();
});
