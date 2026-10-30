import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/core/services/print_document_generator.dart';
import 'package:lav_sms/core/services/print_service.dart';
import 'package:lav_sms/models/admission_application_model.dart';
import 'package:lav_sms/models/examination_model.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/shared/dialogs/print_preview_dialog.dart';
import 'package:lav_sms/shared/widgets/study_material_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StudyMaterialItem Responsive Layout Tests', () {
    testWidgets(
        'Renders StudyMaterialItem on compact mobile (320x568) without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      bool downloadTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: StudyMaterialItem(
                  title: 'Quadratic Equations & Polynomial Algebra Guide',
                  subject: 'Mathematics',
                  uploader: 'Dr. Ramesh Sharma',
                  date: '24 Oct 2026',
                  fileSize: '2.4 MB',
                  onDownload: () => downloadTapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Quadratic Equations & Polynomial Algebra Guide'),
          findsOneWidget);
      expect(find.text('MATHEMATICS'), findsOneWidget);
      expect(find.text('Download Material'), findsOneWidget);

      await tester.tap(find.text('Download Material'));
      await tester.pumpAndSettle();
      expect(downloadTapped, isTrue);
    });

    testWidgets(
        'Renders StudyMaterialItem on desktop (1280x800) with spacious layout',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 800,
                child: StudyMaterialItem(
                  title: 'Organic Chemistry Reactions',
                  subject: 'Chemistry',
                  uploader: 'Priya Verma',
                  date: '25 Oct 2026',
                  fileSize: '5.2 MB',
                  onDownload: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Organic Chemistry Reactions'), findsOneWidget);
      expect(find.text('CHEMISTRY'), findsOneWidget);
      expect(find.text('Download'), findsOneWidget);
    });
  });

  group('PrintDocumentGenerator Authoritative HTML Tests', () {
    test('Generates complete admission application HTML with official tags',
        () {
      final app = AdmissionApplication(
        id: 'LAV-ADM-2026-999',
        fullName: 'Aarav Gupta',
        dateOfBirth: DateTime(2015, 6, 12),
        academicYearId: 'AY-2026-2027',
        targetClass: '8',
        targetSection: 'B',
        gender: 'Male',
        admissionCategory: 'General',
        fatherName: 'Sanjay Gupta',
        fatherPhone: '9876543210',
        requestedAdmissionDate: DateTime(2026, 4, 1),
        status: 'approved',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final html = PrintDocumentGenerator.generateAdmissionApplicationHtml(
        application: app,
        referenceNumber: app.id,
      );

      expect(html, contains('LAV ACADEMY'));
      expect(html, contains('ADMISSION APPLICATION FORM'));
      expect(html, contains('Aarav Gupta'));
      expect(html, contains('Sanjay Gupta'));
      expect(html, contains('AY-2026-2027'));
      expect(html, contains('<table'));
    });

    test('Generates report card HTML handling empty marks gracefully', () {
      const student = Student(
        studentId: 'STU_REP_01',
        admissionNumber: 'ADM-2026-101',
        fullName: 'Meera Kapoor',
        currentClassId: '10',
        currentSectionId: 'A',
        currentAcademicYearId: 'AY-2026-2027',
        status: 'enrolled',
      );

      const exam = Examination(
        examId: 'EXAM_TERM1_2026',
        title: 'Term 1 Mid-Year Examination',
        academicYearId: 'AY-2026-2027',
        term: 'Term 1',
      );

      final htmlEmpty = PrintDocumentGenerator.generateReportCardHtml(
        student: student,
        examination: exam,
        marks: [],
        referenceNumber: 'REP-01',
      );

      expect(htmlEmpty, contains('Examination Results Awaiting Publication'));
      expect(htmlEmpty, isNot(contains('Grand Total: 0 / 0')));

      const sampleMark = Mark(
        markId: 'MARK_01',
        examId: 'EXAM_TERM1_2026',
        studentId: 'STU_REP_01',
        subjectId: 'Mathematics',
        classId: '10',
        sectionId: 'A',
        academicYearId: 'AY-2026-2027',
        continuousAssessment: ContinuousAssessment(ca1: 18, ca2: 19),
        examScore: 54,
        totalScore: 91,
      );

      final htmlFilled = PrintDocumentGenerator.generateReportCardHtml(
        student: student,
        examination: exam,
        marks: [sampleMark],
        referenceNumber: 'REP-02',
      );

      expect(htmlFilled, contains('MATHEMATICS'));
      expect(htmlFilled, contains('91'));
      expect(htmlFilled, contains('Grand Total:'));
    });
  });

  group('PrintPreviewDialog Multi-Viewport Layout Integrity', () {
    testWidgets('Renders PrintPreviewDialog at 360x800 with zero overflow',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const student = Student(
        studentId: 'STU_PREVIEW_360',
        admissionNumber: 'ADM-2026-360',
        fullName: 'Ishaan Verma',
        currentClassId: '9',
        currentSectionId: 'B',
        currentAcademicYearId: 'AY-2026-2027',
        status: 'enrolled',
        dob: '2011-09-20',
        gender: 'Male',
        bloodGroup: 'B+',
        address: '15 Civil Lines, Jaipur',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PrintPreviewDialog.showStudentProfile(ctx, student: student);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('OFFICIAL STUDENT RECORD'), findsOneWidget);
      expect(find.text('Ishaan Verma'), findsOneWidget);
      expect(find.text('Print Document'), findsOneWidget);
    });

    testWidgets('PrintService.printDocument runs safely without exception',
        (tester) async {
      expect(
        () => PrintService.printDocument(
          htmlContent: '<div>Test Document</div>',
          documentTitle: 'Test Document',
        ),
        returnsNormally,
      );
    });
  });
}
