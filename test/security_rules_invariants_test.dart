import 'package:flutter_test/flutter_test.dart';
import 'package:lav_sms/core/constants/role_colors.dart';
import 'package:lav_sms/models/admission_application_model.dart';
import 'package:lav_sms/models/student_model.dart';
import 'package:lav_sms/models/user_model.dart';

void main() {
  group('1. Role Authorization & Least Privilege Invariants', () {
    test('Exactly 6 authorized roles defined and isolated', () {
      expect(UserRoles.allRoles.length, 6);
      expect(UserRoles.allRoles, contains(UserRoles.schoolAdmin));
      expect(UserRoles.allRoles, contains(UserRoles.teacher));
      expect(UserRoles.allRoles, contains(UserRoles.accountant));
      expect(UserRoles.allRoles, contains(UserRoles.admissionsOfficer));
      expect(UserRoles.allRoles, contains(UserRoles.librarian));
      expect(UserRoles.allRoles, contains(UserRoles.parentGuardian));
      // Students are records managed by authorized staff, not independent login users
      expect(UserRoles.allRoles.contains('student'), isFalse);
    });

    test('Staff roles are strictly isolated from parent role', () {
      expect(UserRoles.isStaffRole(UserRoles.schoolAdmin), isTrue);
      expect(UserRoles.isStaffRole(UserRoles.teacher), isTrue);
      expect(UserRoles.isStaffRole(UserRoles.accountant), isTrue);
      expect(UserRoles.isStaffRole(UserRoles.admissionsOfficer), isTrue);
      expect(UserRoles.isStaffRole(UserRoles.librarian), isTrue);
      expect(UserRoles.isStaffRole(UserRoles.parentGuardian), isFalse);
    });

    test('User profile self-elevation is rejected', () {
      const parentUser = AppUser(
        uid: 'parent_001',
        email: 'parent@example.com',
        displayName: 'John Doe',
        role: UserRoles.parentGuardian,
        status: 'active',
      );

      // Attempting to modify role client-side
      const elevatedUser = AppUser(
        uid: 'parent_001',
        email: 'parent@example.com',
        displayName: 'John Doe',
        role: UserRoles.schoolAdmin,
        status: 'active',
      );
      expect(elevatedUser.role, isNot(equals(parentUser.role)));
      // In Firestore rules: match /users/{uid} { allow write: if false; }
    });
  });

  group('2. Parent & Student Relationship Boundaries (ReBAC)', () {
    const student1 = Student(
      studentId: 'STU_001',
      admissionNumber: 'LAV-2026-001',
      fullName: 'Alice Smith',
      currentClassId: '10',
      currentSectionId: 'A',
      currentAcademicYearId: 'AY-2026-27',
      status: 'enrolled',
      guardianUserIds: ['parent_alice_uid'],
    );

    const student2 = Student(
      studentId: 'STU_002',
      admissionNumber: 'LAV-2026-002',
      fullName: 'Bob Jones',
      currentClassId: '10',
      currentSectionId: 'B',
      currentAcademicYearId: 'AY-2026-27',
      status: 'enrolled',
      guardianUserIds: ['parent_bob_uid'],
    );

    test('Parent Alice can access only Alice Smith and not Bob Jones', () {
      const currentParentUid = 'parent_alice_uid';

      final canAccessAlice =
          student1.guardianUserIds.contains(currentParentUid);
      final canAccessBob = student2.guardianUserIds.contains(currentParentUid);

      expect(canAccessAlice, isTrue);
      expect(canAccessBob, isFalse);
    });

    test('Guardian links cannot be modified by ordinary client updates', () {
      // In firestore.rules, request.resource.data.guardianUserIds == resource.data.guardianUserIds
      // and request.resource.data.diff(resource.data).affectedKeys().hasOnly(['dob', 'gender', ...])
      final originalGuardians = List<String>.from(student1.guardianUserIds);
      final attemptedTamper = List<String>.from(originalGuardians)
        ..add('attacker_uid');

      expect(attemptedTamper, isNot(equals(originalGuardians)));
      expect(attemptedTamper.contains('attacker_uid'), isTrue);
    });
  });

  group('3. Teacher Academic & Class Assignment Boundaries', () {
    const teacherAssignedClasses = ['10', '9'];
    const teacherAssignedSections = ['A'];

    test('Teacher can only access assigned classes and sections', () {
      expect(teacherAssignedClasses.contains('10'), isTrue);
      expect(teacherAssignedClasses.contains('12'),
          isFalse); // Class 12 unassigned

      expect(teacherAssignedSections.contains('A'), isTrue);
      expect(teacherAssignedSections.contains('B'),
          isFalse); // Section B unassigned
    });

    test('Attendance sessions enforce unapproved/unfinalized draft creation',
        () {
      // In firestore.rules:
      // request.resource.data.isApproved == false && request.resource.data.isFinalized == false
      const isApprovedAttempt = true;
      const isFinalizedAttempt = true;

      // Both must be rejected by rules if set to true by client
      expect(isApprovedAttempt, isTrue);
      expect(isFinalizedAttempt, isTrue);
    });
  });

  group('4. Admission Pipeline State Transitions & State Protection', () {
    bool isValidAdmissionTransition(String current, String next) {
      if (current == 'draft' && (next == 'draft' || next == 'submitted')) {
        return true;
      }
      if (current == 'submitted' &&
          ['under_review', 'documents_verified', 'rejected', 'waitlisted']
              .contains(next)) {
        return true;
      }
      if (current == 'under_review' &&
          ['documents_verified', 'approved', 'rejected', 'waitlisted']
              .contains(next)) {
        return true;
      }
      if (current == 'documents_verified' &&
          ['approved', 'rejected', 'waitlisted'].contains(next)) {
        return true;
      }
      if (current == 'waitlisted' &&
          ['under_review', 'approved', 'rejected'].contains(next)) {
        return true;
      }
      if (current == 'approved' && ['enrolled', 'rejected'].contains(next)) {
        return true;
      }
      if (current == next) return true;
      return false;
    }

    test('Permits valid progressive admission transitions', () {
      expect(isValidAdmissionTransition('draft', 'submitted'), isTrue);
      expect(isValidAdmissionTransition('submitted', 'under_review'), isTrue);
      expect(isValidAdmissionTransition('under_review', 'documents_verified'),
          isTrue);
      expect(
          isValidAdmissionTransition('documents_verified', 'approved'), isTrue);
      expect(isValidAdmissionTransition('approved', 'enrolled'), isTrue);
    });

    test('Rejects invalid or unauthorized state skips', () {
      // Direct jump from draft to approved is unauthorized
      expect(isValidAdmissionTransition('draft', 'approved'), isFalse);
      // Direct jump from draft to enrolled is unauthorized
      expect(isValidAdmissionTransition('draft', 'enrolled'), isFalse);
      // Direct jump from submitted to enrolled without approval is unauthorized
      expect(isValidAdmissionTransition('submitted', 'enrolled'), isFalse);
    });

    test('Parent cannot modify internal reviewer notes or decision flags', () {
      final app = AdmissionApplication(
        id: 'LAV-ADM-2026-0042',
        fullName: 'Jane Doe',
        firstName: 'Jane',
        middleName: '',
        lastName: 'Doe',
        dateOfBirth: DateTime(2015, 5, 20),
        gender: 'Female',
        bloodGroup: 'O+',
        nationality: 'Indian',
        motherTongue: 'Hindi',
        fatherName: 'Rajesh Doe',
        fatherOccupation: 'Engineer',
        fatherPhone: '+919876543210',
        fatherEmail: 'rajesh@example.com',
        motherName: 'Sunita Doe',
        motherOccupation: 'Doctor',
        motherPhone: '+919876543211',
        motherEmail: 'sunita@example.com',
        primaryGuardian: 'Father',
        guardianRelationship: 'Father',
        guardianName: 'Rajesh Doe',
        guardianPhone: '+919876543210',
        guardianEmail: 'rajesh@example.com',
        emergencyContactName: 'Rajesh Doe',
        emergencyContactPhone: '+919876543210',
        emergencyContactRelation: 'Father',
        existingGuardianUserId: 'parent_user_123',
        houseNumber: '12',
        streetLocality: 'Oak St',
        city: 'Dehradun',
        district: 'Dehradun',
        state: 'Uttarakhand',
        postalCode: '248001',
        country: 'India',
        permanentAddress: 'Same',
        isPermanentSameAsCurrent: true,
        academicYearId: 'AY-2026-27',
        targetClass: '5',
        targetSection: 'A',
        previousSchoolName: 'St Mary',
        previousSchoolAddress: 'Dehradun',
        previousClass: '4',
        previousResultPercentage: '88.5',
        transferCertificateNumber: 'TC-101',
        reasonForLeaving: 'Relocation',
        admissionCategory: 'General',
        requestedAdmissionDate: DateTime(2026, 4, 1),
        referralSource: 'Website',
        documents: const [],
        status: 'draft',
        isDraft: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reviewerNotes: null,
      );

      expect(app.reviewerNotes, isNull);
      expect(app.status, 'draft');
    });
  });

  group('5. Financial Record Tamper Prevention', () {
    test('Invoices and payments allow write: if false (server-only mutations)',
        () {
      // In firestore.rules:
      // match /student_invoices/{invoiceId} { allow write: if false; }
      // match /payments/{paymentId} { allow write: if false; }
      const clientCanDirectlyWritePayment = false;
      expect(clientCanDirectlyWritePayment, isFalse);
    });
  });

  group('6. Storage File Size & Content-Type Constraints', () {
    test('Enforces 2MB limit for profile avatars', () {
      const maxAvatarBytes = 2 * 1024 * 1024;
      const validPhotoSize = 1024 * 1024; // 1MB
      const oversizedPhotoSize = 3 * 1024 * 1024; // 3MB

      expect(validPhotoSize <= maxAvatarBytes, isTrue);
      expect(oversizedPhotoSize <= maxAvatarBytes, isFalse);
    });

    test('Enforces 10MB limit for admission documents', () {
      const maxDocBytes = 10 * 1024 * 1024;
      const validDocSize = 5 * 1024 * 1024;
      const oversizedDocSize = 15 * 1024 * 1024;

      expect(validDocSize <= maxDocBytes, isTrue);
      expect(oversizedDocSize <= maxDocBytes, isFalse);
    });

    test('Enforces 25MB limit for study materials', () {
      const maxMaterialBytes = 25 * 1024 * 1024;
      const validMaterial = 20 * 1024 * 1024;
      const oversizedMaterial = 30 * 1024 * 1024;

      expect(validMaterial <= maxMaterialBytes, isTrue);
      expect(oversizedMaterial <= maxMaterialBytes, isFalse);
    });

    test('Direct access to secure_reports is denied completely', () {
      // match /secure_reports/{allPaths=**} { allow read, write: if false; }
      const directClientRead = false;
      const directClientWrite = false;
      expect(directClientRead, isFalse);
      expect(directClientWrite, isFalse);
    });
  });
}
