import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/models/admission_application_model.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/models/fee_model.dart';
import 'package:lav_sms/shared/dialogs/print_preview_dialog.dart';

void main() {
  group('Admission Application Domain Model Tests', () {
    final testApp = AdmissionApplication(
      id: 'LAV-ADM-2026-0042',
      fullName: 'Devansh Rathore',
      firstName: 'Devansh',
      lastName: 'Rathore',
      dateOfBirth: DateTime(2015, 6, 20),
      gender: 'Male',
      bloodGroup: 'B+',
      nationality: 'Indian',
      motherTongue: 'Hindi',
      fatherName: 'Vikram Rathore',
      fatherOccupation: 'Civil Engineer',
      fatherPhone: '9829012345',
      fatherEmail: 'vikram.rathore@example.com',
      motherName: 'Sunita Rathore',
      motherPhone: '9829054321',
      primaryGuardian: 'Father',
      emergencyContactName: 'Vikram Rathore',
      emergencyContactPhone: '9829012345',
      houseNumber: '12-A',
      streetLocality: 'Malviya Nagar',
      city: 'Jaipur',
      district: 'Jaipur',
      state: 'Rajasthan',
      postalCode: '302017',
      country: 'India',
      academicYearId: 'AY-2026-2027',
      targetClass: '10',
      targetSection: 'B',
      previousSchoolName: 'Delhi Public School',
      previousClass: '9',
      previousResultPercentage: '91.4',
      transferCertificateNumber: 'TC-2026-889',
      admissionCategory: 'General',
      requestedAdmissionDate: DateTime(2026, 4, 1),
      documents: [
        UploadedDocument(
          documentType: 'birth_certificate',
          fileName: 'birth_cert_devansh.pdf',
          fileUrl: 'https://storage.googleapis.com/test/birth_cert.pdf',
          storagePath: 'admissions/LAV-ADM-2026-0042/birth_cert.pdf',
          fileSizeBytes: 245000,
          uploadedAt: DateTime.now(),
          verificationStatus: 'verified',
        ),
      ],
      status: 'submitted',
      isDraft: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Serializes to map and deserializes accurately without data loss', () {
      final map = testApp.toMap();
      expect(map['id'], 'LAV-ADM-2026-0042');
      expect(map['fullName'], 'Devansh Rathore');
      expect(map['fatherPhone'], '9829012345');
      expect(map['targetClass'], '10');
      expect(map['admissionCategory'], 'General');
      expect(map['status'], 'submitted');
      expect((map['documents'] as List).length, 1);

      final reconstructed =
          AdmissionApplication.fromMap('LAV-ADM-2026-0042', map);
      expect(reconstructed.fullName, testApp.fullName);
      expect(reconstructed.fatherName, testApp.fatherName);
      expect(reconstructed.documents.first.fileName, 'birth_cert_devansh.pdf');
      expect(reconstructed.documents.first.isVerified, isTrue);
      expect(reconstructed.formattedCurrentAddress,
          '12-A, Malviya Nagar, Jaipur, Jaipur, Rajasthan - 302017, India');
    });

    test('Helper getters compute correct primary guardian and status flags',
        () {
      expect(testApp.effectiveGuardianName, 'Vikram Rathore');
      expect(testApp.effectiveGuardianPhone, '9829012345');
      expect(testApp.isApproved, isFalse);
      expect(testApp.isEnrolled, isFalse);
    });
  });

  group('Print Preview Dialog Widgets & Layout Tests', () {
    final testApp = AdmissionApplication(
      id: 'LAV-ADM-2026-0099',
      fullName: 'Ananya Sen',
      dateOfBirth: DateTime(2016, 8, 10),
      academicYearId: 'AY-2026-2027',
      targetClass: '9',
      requestedAdmissionDate: DateTime(2026, 4, 1),
      status: 'approved',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets(
        'Renders official LAV Academy letterhead and print trigger button',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PrintPreviewDialog.showAdmissionApplication(ctx,
                      application: testApp);
                },
                child: const Text('Open Preview'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Preview'));
      await tester.pumpAndSettle();

      // Official Letterhead Verification
      expect(find.text('LAV ACADEMY'), findsOneWidget);
      expect(
          find.textContaining('Affiliated to CBSE New Delhi'), findsOneWidget);
      expect(find.textContaining('REF: LAV-ADM-2026-0099'), findsOneWidget);

      // Document Title & Action Controls
      expect(find.text('ADMISSION APPLICATION FORM'), findsOneWidget);
      expect(find.text('Print Document'), findsOneWidget);
      expect(find.textContaining('Ananya Sen'), findsOneWidget);
    });

    testWidgets('Renders Student Profile Document preview correctly',
        (tester) async {
      const student = Student(
        studentId: 'STU_TEST_01',
        admissionNumber: 'ADM-2026-888',
        fullName: 'Rohan Mehra',
        currentClassId: '10',
        currentSectionId: 'A',
        currentAcademicYearId: 'AY-2026-2027',
        status: 'enrolled',
        dob: '2010-05-15',
        gender: 'Male',
        bloodGroup: 'O+',
        address: 'B-14 Malviya Nagar, Jaipur',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PrintPreviewDialog.showStudentProfile(ctx, student: student);
                },
                child: const Text('Preview Profile'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Preview Profile'));
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL STUDENT RECORD'), findsOneWidget);
      expect(find.text('Rohan Mehra'), findsOneWidget);
      expect(find.textContaining('Admission No: ADM-2026-888'), findsOneWidget);
      expect(find.text('Print Document'), findsOneWidget);
    });

    testWidgets('Renders Fee Receipt preview with verified amount',
        (tester) async {
      const invoice = StudentInvoice(
        invoiceId: 'INV_2026_01',
        studentId: 'STU_TEST_01',
        academicYearId: 'AY-2026-2027',
        title: 'Term 1 Tuition Fee',
        totalAmountPaise: 4500000,
        paidAmountPaise: 4500000,
        outstandingBalancePaise: 0,
        status: 'paid',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  PrintPreviewDialog.showReceipt(
                    ctx,
                    invoice: invoice,
                    paymentAmountPaise: 4500000,
                    paymentMethod: 'UPI',
                    transactionId: 'TXN-998877',
                  );
                },
                child: const Text('Preview Receipt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Preview Receipt'));
      await tester.pumpAndSettle();

      expect(find.text('OFFICIAL FEE PAYMENT RECEIPT'), findsOneWidget);
      expect(find.text('PAYMENT RECEIVED & VERIFIED'), findsOneWidget);
      expect(find.text('₹ 45000.00'), findsOneWidget);
      expect(find.text('Print Document'), findsOneWidget);
    });
  });
}
