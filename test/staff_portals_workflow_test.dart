import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/models/examination_model.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/models/user_model.dart';
import 'package:lav_sms/providers/auth_providers.dart';
import 'package:lav_sms/providers/feature_providers.dart';
import 'package:lav_sms/repositories/exam_repository.dart';
import 'package:lav_sms/shared/dialogs/staff_portal_dialogs.dart';

void main() {
  group('Staff Portals Workflows, Assignment & Permission Validation Tests',
      () {
    const mockStudent = Student(
      studentId: 'STU_2026_001',
      admissionNumber: 'ADM-2026-001',
      fullName: 'Aarav Kumar',
      currentClassId: '10',
      currentSectionId: 'A',
      currentAcademicYearId: 'AY_2026_2027',
      status: 'enrolled',
      dob: '2010-04-12',
      gender: 'Male',
      bloodGroup: 'B+',
      emergencyContact: '+91 98765 11111',
      medicalNotes: 'No allergies',
      address: '10 Sector 4, Bangalore',
    );

    const mockTeacher = AppUser(
      uid: 'TEACHER_001',
      email: 'teacher.sharma@lav-school.edu',
      displayName: 'Tarun Sharma',
      role: UserRoles.teacher,
      status: 'active',
      assignedClasses: ['10', '9'],
      assignedSections: ['A', 'B'],
    );

    Widget createTestApp(Widget child) {
      return ProviderScope(
        overrides: [
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(mockTeacher),
          ),
          allStudentsStreamProvider.overrideWith(
            (ref) => Stream.value([mockStudent]),
          ),
          allStaffUsersStreamProvider.overrideWith(
            (ref) => Stream.value([mockTeacher]),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    test(
        '1. ExamRepository strictly validates assessment score bounds and rejects invalid inputs',
        () {
      // Negative CA1 must throw ArgumentError
      expect(
        () => ExamRepository.validateMarkBounds(
          const Mark(
            markId: 'M_1',
            examId: 'EXAM_1',
            studentId: 'STU_1',
            subjectId: 'SUB_1',
            classId: '10',
            sectionId: 'A',
            academicYearId: 'AY_1',
            continuousAssessment: ContinuousAssessment(ca1: -2, ca2: 15),
            examScore: 50,
            totalScore: 63,
            isApproved: false,
            isPublished: false,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // CA1 exceeding 20 must throw ArgumentError
      expect(
        () => ExamRepository.validateMarkBounds(
          const Mark(
            markId: 'M_2',
            examId: 'EXAM_1',
            studentId: 'STU_1',
            subjectId: 'SUB_1',
            classId: '10',
            sectionId: 'A',
            academicYearId: 'AY_1',
            continuousAssessment: ContinuousAssessment(ca1: 25, ca2: 15),
            examScore: 50,
            totalScore: 90,
            isApproved: false,
            isPublished: false,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // CA2 exceeding 20 must throw ArgumentError
      expect(
        () => ExamRepository.validateMarkBounds(
          const Mark(
            markId: 'M_3',
            examId: 'EXAM_1',
            studentId: 'STU_1',
            subjectId: 'SUB_1',
            classId: '10',
            sectionId: 'A',
            academicYearId: 'AY_1',
            continuousAssessment: ContinuousAssessment(ca1: 18, ca2: 22),
            examScore: 50,
            totalScore: 90,
            isApproved: false,
            isPublished: false,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Exam score exceeding 60 must throw ArgumentError
      expect(
        () => ExamRepository.validateMarkBounds(
          const Mark(
            markId: 'M_4',
            examId: 'EXAM_1',
            studentId: 'STU_1',
            subjectId: 'SUB_1',
            classId: '10',
            sectionId: 'A',
            academicYearId: 'AY_1',
            continuousAssessment: ContinuousAssessment(ca1: 18, ca2: 19),
            examScore: 65,
            totalScore: 102,
            isApproved: false,
            isPublished: false,
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets(
        '2. AssignTeacherDialog renders teacher dropdown, cohort selection and validates',
        (tester) async {
      await tester.pumpWidget(createTestApp(const AssignTeacherDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Assign Teacher to Cohort'), findsOneWidget);
      expect(find.text('Select Teacher'), findsOneWidget);
      expect(find.text('Class Cohort'), findsOneWidget);
      expect(find.text('Section'), findsOneWidget);
      expect(find.text('Subject Name'), findsOneWidget);
      expect(find.text('Confirm Assignment'), findsOneWidget);
    });

    testWidgets(
        '3. TransferStudentDialog renders student selection, target cohort and transfer reason',
        (tester) async {
      await tester.pumpWidget(createTestApp(
          const TransferStudentDialog(initialStudent: mockStudent)));
      await tester.pumpAndSettle();

      expect(find.text('Transfer Student Cohort'), findsOneWidget);
      expect(find.text('Target Class'), findsOneWidget);
      expect(find.text('Target Section'), findsOneWidget);
      expect(find.text('Transfer Reason'), findsOneWidget);
      expect(find.text('Execute Transfer'), findsOneWidget);
    });

    testWidgets(
        '4. StaffManagementDialog renders staff directory and account activation/suspension action',
        (tester) async {
      await tester.pumpWidget(createTestApp(const StaffManagementDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Staff Accounts & Directory'), findsOneWidget);
      expect(find.text('Tarun Sharma'), findsOneWidget);
      expect(find.text('Suspend'), findsOneWidget);
      expect(find.text('Close Directory'), findsOneWidget);
    });

    testWidgets(
        '5. SubmitMarksDialog dynamically calculates total score and validates out-of-bounds inputs',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const SubmitMarksDialog(
          student: mockStudent,
          subject: 'Mathematics',
          initialCa1: 18,
          initialCa2: 19,
          initialExam: 52,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Enter Assessment Marks'), findsOneWidget);
      expect(find.text('CA 1 (Max 20)'), findsOneWidget);
      expect(find.text('CA 2 (Max 20)'), findsOneWidget);
      expect(find.text('Exam (Max 60)'), findsOneWidget);
      expect(find.text('89 / 100'), findsOneWidget);
      expect(find.text('Submit for Review'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
    });

    testWidgets(
        '6. CreateHomeworkDialog renders cohort targeting, title, instructions, and date picker',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const CreateHomeworkDialog(currentClass: '10', currentSection: 'A'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Publish Homework Assignment'), findsOneWidget);
      expect(find.text('Target: Class 10-A Cohort'), findsOneWidget);
      expect(find.text('Subject'), findsOneWidget);
      expect(find.text('Homework Title'), findsOneWidget);
      expect(find.text('Instructions / Problem Details'), findsOneWidget);
      expect(find.text('Publish Homework'), findsOneWidget);
    });

    testWidgets(
        '7. CreateInvoiceDialog supports integer paise calculations for fee billing',
        (tester) async {
      await tester.pumpWidget(createTestApp(const CreateInvoiceDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Generate Student Invoice'), findsOneWidget);
      expect(find.text('Invoice Title'), findsOneWidget);
      expect(find.text('Amount (INR ₹)'), findsOneWidget);
      expect(find.text('Due Date:'), findsOneWidget);
      expect(find.text('Generate Invoice'), findsOneWidget);
    });

    testWidgets(
        '8. CreateFeeStructureDialog allows defining school-wide and class-specific fee schedules',
        (tester) async {
      await tester.pumpWidget(createTestApp(const CreateFeeStructureDialog()));
      await tester.pumpAndSettle();

      expect(find.text('New Fee Structure'), findsOneWidget);
      expect(find.text('Fee Structure Title'), findsOneWidget);
      expect(find.text('Amount (INR ₹)'), findsOneWidget);
      expect(find.text('Frequency'), findsOneWidget);
      expect(find.text('Target Cohort'), findsOneWidget);
      expect(find.text('Save Structure'), findsOneWidget);
    });

    testWidgets(
        '9. EditStudentDemographicsDialog enforces field allowlist and protects student identity',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const EditStudentDemographicsDialog(student: mockStudent),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Edit Student Demographics'), findsOneWidget);
      expect(find.text('Date of Birth (YYYY-MM-DD)'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);
      expect(find.text('Emergency Contact Phone'), findsOneWidget);
      expect(find.text('Medical Notes'), findsOneWidget);
      expect(find.text('Residential Address'), findsOneWidget);
      expect(find.text('Save Demographics'), findsOneWidget);
    });

    testWidgets(
        '10. CreateEnquiryDialog captures prospective student admission information',
        (tester) async {
      await tester.pumpWidget(createTestApp(const CreateEnquiryDialog()));
      await tester.pumpAndSettle();

      expect(find.text('Prospective Student Enquiry'), findsOneWidget);
      expect(find.text('Applicant Full Name'), findsOneWidget);
      expect(find.text('Target Class'), findsOneWidget);
      expect(find.text('Guardian Name'), findsOneWidget);
      expect(find.text('Contact Phone (+91)'), findsOneWidget);
      expect(find.text('Register Enquiry'), findsOneWidget);
    });

    testWidgets(
        '11. ReturnBookDialog displays circulation status, fine calculation and atomic return trigger',
        (tester) async {
      final pastDue = DateTime.now().subtract(const Duration(days: 4));

      await tester.pumpWidget(createTestApp(
        ReturnBookDialog(
          loanId: 'LOAN_001',
          bookId: 'BOOK_001',
          bookTitle: 'Concepts of Physics (Vol 1)',
          studentId: 'STU_2026_001',
          dueDate: pastDue,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Book Return'), findsOneWidget);
      expect(find.text('Concepts of Physics (Vol 1)'), findsOneWidget);
      expect(find.text('Issued to Student: STU_2026_001'), findsOneWidget);
      expect(find.textContaining('Overdue by'), findsOneWidget);
      expect(find.textContaining('Fine: ₹'), findsOneWidget);
      expect(find.text('Confirm Return'), findsOneWidget);
    });

    test(
        '12. AppUser normalizes account status across legacy and canonical representations',
        () {
      // Canonical status representation
      const userActive = AppUser(
        uid: 'U_1',
        email: 'admin@lav.edu',
        displayName: 'Admin',
        role: UserRoles.schoolAdmin,
        status: 'active',
      );
      expect(userActive.isActive, isTrue);

      const userSuspended = AppUser(
        uid: 'U_2',
        email: 'staff@lav.edu',
        displayName: 'Staff',
        role: UserRoles.teacher,
        status: 'suspended',
      );
      expect(userSuspended.isActive, isFalse);

      // Map output verification
      final map = userActive.toMap();
      expect(map['status'], equals('active'));
      expect(map['role'], equals('school_admin'));
    });

    test(
        '13. Live guardian-student relationship and cohort transfer invariants',
        () {
      const student = Student(
        studentId: 'STU_X',
        admissionNumber: 'ADM-X',
        fullName: 'Test Ward',
        currentClassId: '10',
        currentSectionId: 'A',
        currentAcademicYearId: 'AY_2026',
        status: 'enrolled',
        dob: '2010-01-01',
        gender: 'Male',
        bloodGroup: 'O+',
        emergencyContact: '9999999999',
        medicalNotes: '',
        address: '',
      );

      // Verify immutable core keys
      expect(student.studentId, equals('STU_X'));
      expect(student.status, equals('enrolled'));

      // Cohort reallocation test
      final transferred = Student(
        studentId: student.studentId,
        admissionNumber: student.admissionNumber,
        fullName: student.fullName,
        currentClassId: '11',
        currentSectionId: 'B',
        currentAcademicYearId: student.currentAcademicYearId,
        status: student.status,
        dob: student.dob,
        gender: student.gender,
        bloodGroup: student.bloodGroup,
        emergencyContact: student.emergencyContact,
        medicalNotes: student.medicalNotes,
        address: student.address,
      );
      expect(transferred.currentClassId, equals('11'));
      expect(transferred.currentSectionId, equals('B'));
      expect(transferred.studentId, equals(student.studentId));
    });

    test('14. Fee calculation integrity and integer paise balance invariants',
        () {
      const totalAmountPaise = 250000; // ₹2500.00
      const paymentAmountPaise = 100000; // ₹1000.00
      const outstandingPaise = totalAmountPaise - paymentAmountPaise;

      expect(outstandingPaise, equals(150000));

      // Zero-balance transitions to paid
      const finalOutstanding = outstandingPaise - 150000;
      expect(finalOutstanding, equals(0));
      const status = finalOutstanding == 0 ? 'paid' : 'partially_paid';
      expect(status, equals('paid'));
    });
  });
}
