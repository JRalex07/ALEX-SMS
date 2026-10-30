import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String phoneNumber;
  final String displayName;
  final String role; // Exactly one of the 6 active roles
  final String status; // 'active', 'suspended', 'pending'
  final int tokenVersion;
  final List<String> assignedClasses;
  final List<String> assignedSections;
  final List<String> wardStudentIds;
  final List<String> wardClasses;
  final List<String> wardSections;

  const AppUser({
    required this.uid,
    required this.email,
    this.phoneNumber = '',
    required this.displayName,
    required this.role,
    this.status = 'active',
    this.tokenVersion = 1,
    this.assignedClasses = const [],
    this.assignedSections = const [],
    this.wardStudentIds = const [],
    this.wardClasses = const [],
    this.wardSections = const [],
  });

  bool get isActive => status == 'active';
  bool get isAdmin => role == 'school_admin';
  bool get isTeacher => role == 'teacher';
  bool get isAccountant => role == 'accountant';
  bool get isAdmissions => role == 'admissions_officer';
  bool get isLibrarian => role == 'librarian';
  bool get isParent => role == 'parent_guardian';

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'parent_guardian',
      status: data['status'] ?? 'active',
      tokenVersion: data['tokenVersion'] ?? 1,
      assignedClasses: List<String>.from(data['assignedClasses'] ?? []),
      assignedSections: List<String>.from(data['assignedSections'] ?? []),
      wardStudentIds: List<String>.from(data['wardStudentIds'] ?? []),
      wardClasses: List<String>.from(data['wardClasses'] ?? []),
      wardSections: List<String>.from(data['wardSections'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role,
      'status': status,
      'tokenVersion': tokenVersion,
      'assignedClasses': assignedClasses,
      'assignedSections': assignedSections,
      'wardStudentIds': wardStudentIds,
      'wardClasses': wardClasses,
      'wardSections': wardSections,
    };
  }
}
