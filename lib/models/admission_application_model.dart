import 'package:cloud_firestore/cloud_firestore.dart';

class UploadedDocument {
  final String
      documentType; // 'photo', 'birth_certificate', 'transfer_certificate', 'report_card', 'address_proof', 'guardian_id'
  final String fileName;
  final String fileUrl;
  final String storagePath;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final String
      verificationStatus; // 'pending', 'verified', 'rejected', 'missing'
  final String? reviewerNotes;

  const UploadedDocument({
    required this.documentType,
    required this.fileName,
    required this.fileUrl,
    required this.storagePath,
    this.fileSizeBytes = 0,
    required this.uploadedAt,
    this.verificationStatus = 'pending',
    this.reviewerNotes,
  });

  bool get isVerified => verificationStatus == 'verified';

  factory UploadedDocument.fromMap(Map<String, dynamic> data) {
    return UploadedDocument(
      documentType: data['documentType'] ?? 'general',
      fileName: data['fileName'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      storagePath: data['storagePath'] ?? '',
      fileSizeBytes: (data['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verificationStatus: data['verificationStatus'] ?? 'pending',
      reviewerNotes: data['reviewerNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'documentType': documentType,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'storagePath': storagePath,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'verificationStatus': verificationStatus,
      'reviewerNotes': reviewerNotes,
    };
  }

  UploadedDocument copyWith({
    String? documentType,
    String? fileName,
    String? fileUrl,
    String? storagePath,
    int? fileSizeBytes,
    DateTime? uploadedAt,
    String? verificationStatus,
    String? reviewerNotes,
  }) {
    return UploadedDocument(
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
    );
  }
}

class AdmissionApplication {
  final String id; // e.g. "LAV-ADM-2026-0042"

  // 1. Applicant Details
  final String fullName;
  final String firstName;
  final String middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String gender;
  final String bloodGroup;
  final String nationality;
  final String motherTongue;
  final String? photoUrl;
  final String? studentAadhaarNumber;

  // 2. Parent & Guardian Details
  final String fatherName;
  final String fatherOccupation;
  final String fatherPhone;
  final String fatherEmail;
  final String motherName;
  final String motherOccupation;
  final String motherPhone;
  final String motherEmail;
  final String primaryGuardian; // 'Father', 'Mother', 'Other'
  final String guardianRelationship;
  final String guardianName;
  final String guardianPhone;
  final String guardianEmail;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelation;
  final String? existingGuardianUserId;

  // 3. Address Details
  final String houseNumber;
  final String streetLocality;
  final String city;
  final String district;
  final String state;
  final String postalCode;
  final String country;
  final String permanentAddress;
  final bool isPermanentSameAsCurrent;

  // 4. Academic Details
  final String academicYearId;
  final String targetClass;
  final String targetSection;
  final String previousSchoolName;
  final String previousSchoolAddress;
  final String previousClass;
  final String previousResultPercentage;
  final String transferCertificateNumber;
  final DateTime? transferCertificateDate;
  final String reasonForLeaving;

  // 5. Preferences & Referral
  final String
      admissionCategory; // 'General', 'Management', 'Sibling', 'Staff Child', 'RTE'
  final DateTime requestedAdmissionDate;
  final String referralSource;

  // 6. Documents
  final List<UploadedDocument> documents;

  // 7. Status & Audit
  final String
      status; // 'draft', 'submitted', 'under_review', 'documents_verified', 'approved', 'rejected', 'waitlisted', 'enrolled'
  final bool isDraft;
  final String? reviewerNotes;
  final DateTime? decisionDate;
  final String? decidedByUid;
  final String? decidedByName;
  final String? rejectionReason;
  final String? enrolledStudentId;
  final String? enrolledAdmissionNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;

  const AdmissionApplication({
    required this.id,
    required this.fullName,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    required this.dateOfBirth,
    this.gender = 'Male',
    this.bloodGroup = 'O+',
    this.nationality = 'Indian',
    this.motherTongue = 'English',
    this.photoUrl,
    this.studentAadhaarNumber,
    this.fatherName = '',
    this.fatherOccupation = '',
    this.fatherPhone = '',
    this.fatherEmail = '',
    this.motherName = '',
    this.motherOccupation = '',
    this.motherPhone = '',
    this.motherEmail = '',
    this.primaryGuardian = 'Father',
    this.guardianRelationship = 'Parent',
    this.guardianName = '',
    this.guardianPhone = '',
    this.guardianEmail = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelation = 'Parent',
    this.existingGuardianUserId,
    this.houseNumber = '',
    this.streetLocality = '',
    this.city = 'Jaipur',
    this.district = 'Jaipur',
    this.state = 'Rajasthan',
    this.postalCode = '302001',
    this.country = 'India',
    this.permanentAddress = '',
    this.isPermanentSameAsCurrent = true,
    required this.academicYearId,
    required this.targetClass,
    this.targetSection = 'A',
    this.previousSchoolName = '',
    this.previousSchoolAddress = '',
    this.previousClass = '',
    this.previousResultPercentage = '',
    this.transferCertificateNumber = '',
    this.transferCertificateDate,
    this.reasonForLeaving = '',
    this.admissionCategory = 'General',
    required this.requestedAdmissionDate,
    this.referralSource = 'Website',
    this.documents = const [],
    this.status = 'draft',
    this.isDraft = true,
    this.reviewerNotes,
    this.decisionDate,
    this.decidedByUid,
    this.decidedByName,
    this.rejectionReason,
    this.enrolledStudentId,
    this.enrolledAdmissionNumber,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isEnrolled => status == 'enrolled';
  bool get isRejected => status == 'rejected';
  bool get isUnderReview =>
      status == 'under_review' || status == 'documents_verified';

  String get effectiveGuardianName => primaryGuardian == 'Father'
      ? fatherName
      : (primaryGuardian == 'Mother' ? motherName : guardianName);

  String get effectiveGuardianPhone => primaryGuardian == 'Father'
      ? fatherPhone
      : (primaryGuardian == 'Mother' ? motherPhone : guardianPhone);

  String get formattedCurrentAddress =>
      '$houseNumber, $streetLocality, $city, $district, $state - $postalCode, $country';

  factory AdmissionApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdmissionApplication.fromMap(doc.id, data);
  }

  factory AdmissionApplication.fromMap(String id, Map<String, dynamic> data) {
    final docsList = (data['documents'] as List<dynamic>?)
            ?.map((d) => UploadedDocument.fromMap(Map<String, dynamic>.from(d)))
            .toList() ??
        [];

    return AdmissionApplication(
      id: id,
      fullName: data['fullName'] ?? data['applicantName'] ?? '',
      firstName: data['firstName'] ?? '',
      middleName: data['middleName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth:
          (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(2015, 1, 1),
      gender: data['gender'] ?? 'Male',
      bloodGroup: data['bloodGroup'] ?? 'O+',
      nationality: data['nationality'] ?? 'Indian',
      motherTongue: data['motherTongue'] ?? 'English',
      photoUrl: data['photoUrl'],
      studentAadhaarNumber: data['studentAadhaarNumber'],
      fatherName: data['fatherName'] ?? '',
      fatherOccupation: data['fatherOccupation'] ?? '',
      fatherPhone: data['fatherPhone'] ?? '',
      fatherEmail: data['fatherEmail'] ?? '',
      motherName: data['motherName'] ?? '',
      motherOccupation: data['motherOccupation'] ?? '',
      motherPhone: data['motherPhone'] ?? '',
      motherEmail: data['motherEmail'] ?? '',
      primaryGuardian: data['primaryGuardian'] ?? 'Father',
      guardianRelationship: data['guardianRelationship'] ?? 'Parent',
      guardianName: data['guardianName'] ?? '',
      guardianPhone: data['guardianPhone'] ?? data['phone'] ?? '',
      guardianEmail: data['guardianEmail'] ?? data['email'] ?? '',
      emergencyContactName: data['emergencyContactName'] ?? '',
      emergencyContactPhone: data['emergencyContactPhone'] ?? '',
      emergencyContactRelation: data['emergencyContactRelation'] ?? 'Parent',
      existingGuardianUserId: data['existingGuardianUserId'],
      houseNumber: data['houseNumber'] ?? '',
      streetLocality: data['streetLocality'] ?? '',
      city: data['city'] ?? 'Jaipur',
      district: data['district'] ?? 'Jaipur',
      state: data['state'] ?? 'Rajasthan',
      postalCode: data['postalCode'] ?? '302001',
      country: data['country'] ?? 'India',
      permanentAddress: data['permanentAddress'] ?? '',
      isPermanentSameAsCurrent: data['isPermanentSameAsCurrent'] ?? true,
      academicYearId: data['academicYearId'] ?? 'AY-2026-2027',
      targetClass: data['targetClass'] ?? '10',
      targetSection: data['targetSection'] ?? 'A',
      previousSchoolName: data['previousSchoolName'] ?? '',
      previousSchoolAddress: data['previousSchoolAddress'] ?? '',
      previousClass: data['previousClass'] ?? '',
      previousResultPercentage: data['previousResultPercentage'] ?? '',
      transferCertificateNumber: data['transferCertificateNumber'] ?? '',
      transferCertificateDate:
          (data['transferCertificateDate'] as Timestamp?)?.toDate(),
      reasonForLeaving: data['reasonForLeaving'] ?? '',
      admissionCategory: data['admissionCategory'] ?? 'General',
      requestedAdmissionDate:
          (data['requestedAdmissionDate'] as Timestamp?)?.toDate() ??
              DateTime(2026, 4, 1),
      referralSource: data['referralSource'] ?? 'Website',
      documents: docsList,
      status: data['status'] ?? 'draft',
      isDraft: data['isDraft'] ?? (data['status'] == 'draft'),
      reviewerNotes: data['reviewerNotes'],
      decisionDate: (data['decisionDate'] as Timestamp?)?.toDate(),
      decidedByUid: data['decidedByUid'],
      decidedByName: data['decidedByName'],
      rejectionReason: data['rejectionReason'],
      enrolledStudentId: data['enrolledStudentId'],
      enrolledAdmissionNumber: data['enrolledAdmissionNumber'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'applicantName': fullName, // backward compatibility
      'firstName': firstName,
      'middleName': middleName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'nationality': nationality,
      'motherTongue': motherTongue,
      'photoUrl': photoUrl,
      'studentAadhaarNumber': studentAadhaarNumber,
      'fatherName': fatherName,
      'fatherOccupation': fatherOccupation,
      'fatherPhone': fatherPhone,
      'fatherEmail': fatherEmail,
      'motherName': motherName,
      'motherOccupation': motherOccupation,
      'motherPhone': motherPhone,
      'motherEmail': motherEmail,
      'primaryGuardian': primaryGuardian,
      'guardianRelationship': guardianRelationship,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'phone': guardianPhone, // backward compatibility
      'guardianEmail': guardianEmail,
      'email': guardianEmail, // backward compatibility
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'emergencyContactRelation': emergencyContactRelation,
      'existingGuardianUserId': existingGuardianUserId,
      'houseNumber': houseNumber,
      'streetLocality': streetLocality,
      'city': city,
      'district': district,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'permanentAddress': permanentAddress,
      'isPermanentSameAsCurrent': isPermanentSameAsCurrent,
      'academicYearId': academicYearId,
      'targetClass': targetClass,
      'targetSection': targetSection,
      'previousSchoolName': previousSchoolName,
      'previousSchoolAddress': previousSchoolAddress,
      'previousClass': previousClass,
      'previousResultPercentage': previousResultPercentage,
      'transferCertificateNumber': transferCertificateNumber,
      'transferCertificateDate': transferCertificateDate != null
          ? Timestamp.fromDate(transferCertificateDate!)
          : null,
      'reasonForLeaving': reasonForLeaving,
      'admissionCategory': admissionCategory,
      'requestedAdmissionDate': Timestamp.fromDate(requestedAdmissionDate),
      'referralSource': referralSource,
      'documents': documents.map((d) => d.toMap()).toList(),
      'status': status,
      'isDraft': isDraft,
      'reviewerNotes': reviewerNotes,
      'decisionDate':
          decisionDate != null ? Timestamp.fromDate(decisionDate!) : null,
      'decidedByUid': decidedByUid,
      'decidedByName': decidedByName,
      'rejectionReason': rejectionReason,
      'enrolledStudentId': enrolledStudentId,
      'enrolledAdmissionNumber': enrolledAdmissionNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'submittedAt':
          submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
    };
  }
}
