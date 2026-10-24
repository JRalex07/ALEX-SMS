import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/core/utils/currency_formatter.dart';
import 'package:lav_sms/models/examination_model.dart';
import 'package:lav_sms/models/fee_model.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/models/user_model.dart';

void main() {
  group('Currency & Integer Paise Operations (Section 12.2)', () {
    test('Converts integer paise to formatted Indian Rupee strings', () {
      expect(CurrencyFormatter.formatPaiseToInr(150000), '₹1,500.00');
      expect(CurrencyFormatter.formatPaiseToInr(2500050), '₹25,000.50');
      expect(CurrencyFormatter.formatPaiseToInr(0), '₹0.00');
      expect(CurrencyFormatter.formatPaiseToInr(null), '₹0.00');
    });

    test(
        'Parses Rupee input strings into exact integer paise without floating point errors',
        () {
      final res1 = CurrencyFormatter.parseInrToPaise('1500');
      expect(res1.isSuccess, true);
      expect(res1.amountPaise, 150000);

      final res2 = CurrencyFormatter.parseInrToPaise('₹ 25,000.50');
      expect(res2.isSuccess, true);
      expect(res2.amountPaise, 2500050);

      final res3 = CurrencyFormatter.parseInrToPaise('0.75');
      expect(res3.isSuccess, true);
      expect(res3.amountPaise, 75);

      final res4 = CurrencyFormatter.parseInrToPaise('invalid');
      expect(res4.isSuccess, false);

      final res5 = CurrencyFormatter.parseInrToPaise(
          '10.999'); // more than 2 decimal places
      expect(res5.isSuccess, false);
    });

    test('Compact format produces clean summary figures', () {
      expect(CurrencyFormatter.formatPaiseCompact(50000000), '₹5L');
    });
  });

  group('Domain Entities & Invariants (Section 7 & 12)', () {
    test('AppUser distinguishes active roles correctly', () {
      const admin = AppUser(
        uid: 'u_admin',
        email: 'admin@school.edu',
        displayName: 'Admin User',
        role: 'school_admin',
      );
      expect(admin.isAdmin, true);
      expect(admin.isParent, false);

      const parent = AppUser(
        uid: 'u_parent',
        email: 'parent@school.edu',
        displayName: 'Parent User',
        role: 'parent_guardian',
        wardStudentIds: ['STU_001', 'STU_002'],
      );
      expect(parent.isParent, true);
      expect(parent.isAdmin, false);
      expect(parent.wardStudentIds.length, 2);
    });

    test('Student model enforces demographic fields and guardian relationship',
        () {
      const student = Student(
        studentId: 'STU_001',
        admissionNumber: 'ADM-2026-001',
        fullName: 'Aarav Sharma',
        currentClassId: '10',
        currentSectionId: 'A',
        currentAcademicYearId: 'AY_2026_2027',
        guardianUserIds: ['u_parent'],
      );
      expect(student.isEnrolled, true);
      expect(student.guardianUserIds.contains('u_parent'), true);
      expect(student.studentId, 'STU_001');
    });

    test('Mark model calculates total score consistently', () {
      const mark = Mark(
        markId: 'EXAM_TERM1_2026_STU_001_SUB_MATH',
        examId: 'EXAM_TERM1_2026',
        studentId: 'STU_001',
        subjectId: 'SUB_MATH',
        classId: '10',
        sectionId: 'A',
        academicYearId: 'AY_2026_2027',
        continuousAssessment: ContinuousAssessment(ca1: 18, ca2: 19),
        examScore: 54,
        totalScore: 91,
      );
      expect(
          mark.totalScore,
          mark.continuousAssessment.ca1 +
              mark.continuousAssessment.ca2 +
              mark.examScore);
      expect(mark.isPublished, false);
    });

    test('StudentInvoice computes outstanding balance and overdue state', () {
      final invoice = StudentInvoice(
        invoiceId: 'INV_001',
        studentId: 'STU_001',
        academicYearId: 'AY_2026_2027',
        title: 'Term 1 Tuition',
        totalAmountPaise: 2500000,
        paidAmountPaise: 1500000,
        outstandingBalancePaise: 1000000,
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
      );
      expect(invoice.isPaid, false);
      expect(invoice.isOverdue, true);
    });
  });
}
