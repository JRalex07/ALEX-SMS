import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String studentId;
  final String schoolId;
  final String admissionNumber;
  final String fullName;
  final String currentClassId;
  final String currentSectionId;
  final String currentAcademicYearId;
  final String status; // 'enrolled', 'transferred', 'graduated', 'suspended'
  final List<String> guardianUserIds;
  final String? dob;
  final String? gender;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? medicalNotes;
  final String? address;
  final DateTime? enrollmentDate;

  const Student({
    required this.studentId,
    this.schoolId = 'SCH_001',
    required this.admissionNumber,
    required this.fullName,
    required this.currentClassId,
    required this.currentSectionId,
    required this.currentAcademicYearId,
    this.status = 'enrolled',
    this.guardianUserIds = const [],
    this.dob,
    this.gender,
    this.bloodGroup,
    this.emergencyContact,
    this.medicalNotes,
    this.address,
    this.enrollmentDate,
  });

  bool get isEnrolled => status == 'enrolled';

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Student(
      studentId: doc.id,
      schoolId: data['schoolId'] ?? 'SCH_001',
      admissionNumber: data['admissionNumber'] ?? '',
      fullName: data['fullName'] ?? '',
      currentClassId: data['currentClassId'] ?? '',
      currentSectionId: data['currentSectionId'] ?? '',
      currentAcademicYearId: data['currentAcademicYearId'] ?? '',
      status: data['status'] ?? 'enrolled',
      guardianUserIds: List<String>.from(data['guardianUserIds'] ?? []),
      dob: data['dob'],
      gender: data['gender'],
      bloodGroup: data['bloodGroup'],
      emergencyContact: data['emergencyContact'],
      medicalNotes: data['medicalNotes'],
      address: data['address'],
      enrollmentDate: (data['enrollmentDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'schoolId': schoolId,
      'admissionNumber': admissionNumber,
      'fullName': fullName,
      'currentClassId': currentClassId,
      'currentSectionId': currentSectionId,
      'currentAcademicYearId': currentAcademicYearId,
      'status': status,
      'guardianUserIds': guardianUserIds,
      'dob': dob,
      'gender': gender,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'medicalNotes': medicalNotes,
      'address': address,
      'enrollmentDate':
          enrollmentDate != null ? Timestamp.fromDate(enrollmentDate!) : null,
    };
  }
}
