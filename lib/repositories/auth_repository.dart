import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/role_colors.dart';
import '../models/user_model.dart';

/// Custom domain exceptions for production authentication & authorization.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class ProfileNotFoundException extends AuthException {
  const ProfileNotFoundException(
      [super.message = 'User profile not found in institutional directory.']);
}

class AccountSuspendedException extends AuthException {
  const AccountSuspendedException(
      [super.message = 'Your account is deactivated. Contact administration.']);
}

class UnauthorizedRoleException extends AuthException {
  const UnauthorizedRoleException(
      [super.message = 'Account does not possess authorized role privileges.']);
}

class GuardianshipNotEstablishedException extends AuthException {
  const GuardianshipNotEstablishedException(
      [super.message =
          'No authorized parent/guardian record is linked to this phone number. Contact school administration.']);
}

class InvalidOtpException extends AuthException {
  const InvalidOtpException(
      [super.message = 'Invalid or expired verification code.']);
}

/// Production Authentication Repository.
/// Strictly enforces Firebase Authentication, Firestore profile verification,
/// and fail-closed security for all 6 authenticated roles.
class AuthRepository {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseFunctions? _functions;

  ConfirmationResult? _webConfirmationResult;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    try {
      _auth = auth ?? FirebaseAuth.instance;
    } catch (e) {
      debugPrint(
          '[AuthRepository] FirebaseAuth instance note (offline/mock): $e');
    }
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint(
          '[AuthRepository] FirebaseFirestore instance note (offline/mock): $e');
    }
    try {
      _functions = functions ?? FirebaseFunctions.instance;
    } catch (e) {
      debugPrint(
          '[AuthRepository] FirebaseFunctions instance note (offline/mock): $e');
    }
  }

  Stream<User?> get authStateChanges {
    if (_auth != null) {
      return _auth!.authStateChanges();
    }
    return Stream.value(null);
  }

  User? get currentFirebaseUser => _auth?.currentUser;

  /// Loads and validates the authoritative user profile from Firestore.
  /// Fails closed if the profile is missing, role is unrecognized, or status is suspended.
  Future<AppUser?> getCurrentUserProfile() async {
    final user = _auth?.currentUser;
    if (user == null) return null;

    if (_firestore == null) {
      throw const AuthException('Firestore database service is not available.');
    }

    final doc = await _firestore!.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      throw const ProfileNotFoundException();
    }

    final appUser = AppUser.fromFirestore(doc);
    if (!appUser.isActive) {
      throw const AccountSuspendedException();
    }

    if (!UserRoles.isValidRole(appUser.role)) {
      throw const UnauthorizedRoleException();
    }

    return appUser;
  }

  /// Real-time stream of the current user's profile document from Firestore.
  Stream<AppUser?> userProfileStream(String uid) {
    if (uid.isEmpty || _firestore == null) return Stream.value(null);

    return _firestore!.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final appUser = AppUser.fromFirestore(doc);
      return appUser;
    });
  }

  // =========================================================================
  // 1. Parent / Guardian Phone Authentication
  // =========================================================================

  /// Initiates Firebase Phone Authentication with OTP delivery.
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String errorMessage) onError,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(' ', '').trim();
    if (!cleanPhone.startsWith('+')) {
      onError('Phone number must include country code (e.g. +91).');
      return;
    }

    if (_auth == null) {
      onError('Firebase Authentication service is not initialized.');
      return;
    }

    try {
      if (kIsWeb) {
        _webConfirmationResult = await _auth!.signInWithPhoneNumber(cleanPhone);
        onCodeSent(_webConfirmationResult?.verificationId ??
            'web_verification_session');
      } else {
        await _auth!.verifyPhoneNumber(
          phoneNumber: cleanPhone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            await _auth!.signInWithCredential(credential);
          },
          verificationFailed: (FirebaseAuthException e) {
            onError(e.message ?? 'Phone verification failed.');
          },
          codeSent: (String verificationId, int? resendToken) {
            onCodeSent(verificationId);
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }
    } catch (e) {
      debugPrint('Error sending phone OTP: $e');
      onError(e.toString().replaceAll('Exception:', '').trim());
    }
  }

  /// Verifies OTP and confirms parent_guardian record linkage.
  Future<AppUser> verifyOtpAndSignIn({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    final cleanCode = smsCode.trim();
    if (cleanCode.length != 6) {
      throw const InvalidOtpException(
          'Verification code must be exactly 6 digits.');
    }

    if (_auth == null || _firestore == null) {
      throw const AuthException('Firebase service is not initialized.');
    }

    UserCredential credential;

    try {
      if (kIsWeb && _webConfirmationResult != null) {
        credential = await _webConfirmationResult!.confirm(cleanCode);
      } else {
        final phoneCredential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: cleanCode,
        );
        credential = await _auth!.signInWithCredential(phoneCredential);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[AuthRepository.verifyOtpAndSignIn] FirebaseAuthException: ${e.code} - ${e.message}');
      throw InvalidOtpException(
          e.message ?? 'Invalid or expired verification code.');
    } catch (e, stack) {
      debugPrint(
          '[AuthRepository.verifyOtpAndSignIn] Unexpected exception: $e\n$stack');
      throw InvalidOtpException('Authentication error: ${e.toString()}');
    }

    final user = credential.user;
    if (user == null) {
      throw const AuthException(
          'Authentication session could not be established.');
    }

    var doc = await _firestore!.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final cleanPhone = phoneNumber ?? user.phoneNumber;
      if (cleanPhone != null && cleanPhone.isNotEmpty) {
        final phoneQuery = await _firestore!
            .collection('users')
            .where('phoneNumber', isEqualTo: cleanPhone)
            .limit(1)
            .get();
        if (phoneQuery.docs.isNotEmpty) {
          final data = Map<String, dynamic>.from(phoneQuery.docs.first.data());
          data['uid'] = user.uid;
          await _firestore!.collection('users').doc(user.uid).set(data);
          doc = await _firestore!.collection('users').doc(user.uid).get();
        }
      }
    }

    if (!doc.exists) {
      await _auth!.signOut();
      throw const GuardianshipNotEstablishedException(
        'No institutional parent/guardian record is linked to this phone number. Please contact school administration.',
      );
    }

    final appUser = AppUser.fromFirestore(doc);
    if (!appUser.isActive) {
      await _auth!.signOut();
      throw const AccountSuspendedException(
          'Your parent account is suspended. Contact school administration.');
    }

    if (appUser.role != UserRoles.parentGuardian) {
      await _auth!.signOut();
      throw const UnauthorizedRoleException(
          'This login flow is restricted to parents and guardians.');
    }

    if (appUser.wardStudentIds.isEmpty) {
      await _auth!.signOut();
      throw const GuardianshipNotEstablishedException(
        'No active student records are associated with this guardian account.',
      );
    }

    return appUser;
  }

  // =========================================================================
  // 2. Staff / Administrative Email & Password Authentication
  // =========================================================================

  Future<AppUser> signInStaff({
    required String email,
    required String password,
  }) =>
      signInStaffWithEmailAndPassword(email: email, password: password);

  Future<AppUser> signInStaffWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw const AuthException(
          'Institutional email and password are required.');
    }

    if (_auth == null || _firestore == null) {
      throw const AuthException('Firebase service is not initialized.');
    }

    UserCredential credential;
    try {
      credential = await _auth!.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
          '[AuthRepository.signInStaff] FirebaseAuthException: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
        case 'invalid-email':
          throw const AuthException(
              'Invalid institutional credentials. Please check your email and password.');
        case 'user-disabled':
          throw const AccountSuspendedException(
              'This staff account has been disabled. Contact school administration.');
        case 'too-many-requests':
          throw const AuthException(
              'Too many failed attempts. Please try again in a few minutes.');
        default:
          throw AuthException(
              e.message ?? 'Authentication failed. Please verify credentials.');
      }
    } catch (e, stack) {
      debugPrint('[AuthRepository.signInStaff] Unexpected error: $e\n$stack');
      throw AuthException('Authentication error: ${e.toString()}');
    }

    final user = credential.user;
    if (user == null) {
      throw const AuthException('Failed to establish staff session.');
    }

    var doc = await _firestore!.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      final emailQuery = await _firestore!
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) {
        final data = Map<String, dynamic>.from(emailQuery.docs.first.data());
        data['uid'] = user.uid;
        await _firestore!.collection('users').doc(user.uid).set(data);
        doc = await _firestore!.collection('users').doc(user.uid).get();
      }
    }

    if (!doc.exists) {
      await _auth!.signOut();
      throw const ProfileNotFoundException(
        'Staff profile does not exist in institutional database. Contact IT administrator.',
      );
    }

    final appUser = AppUser.fromFirestore(doc);
    if (!appUser.isActive) {
      await _auth!.signOut();
      throw const AccountSuspendedException(
          'Your staff account is suspended. Contact IT administrator.');
    }

    if (!UserRoles.isStaffRole(appUser.role)) {
      await _auth!.signOut();
      throw const UnauthorizedRoleException(
        'This portal is strictly for authorized school staff members.',
      );
    }

    return appUser;
  }

  /// General alias for signInStaffWithEmailAndPassword
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return signInStaffWithEmailAndPassword(email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw const AuthException('Email address is required.');
    }
    if (_auth != null) {
      await _auth!.sendPasswordResetEmail(email: cleanEmail);
    }
  }

  Future<void> signOut() async {
    _webConfirmationResult = null;
    if (_auth != null) {
      await _auth!.signOut();
    }
  }

  // =========================================================================
  // 3. Staff Administration & Role / Cohort Assignment
  // =========================================================================

  /// Stream of all staff users for administrative directory
  Stream<List<AppUser>> getAllStaffUsersStream() {
    if (_firestore == null) return Stream.value([]);
    try {
      return _firestore!.collection('users').snapshots().map((snapshot) =>
          snapshot.docs
              .map((doc) => AppUser.fromFirestore(doc))
              .where((user) => user.role != 'parent_guardian')
              .toList());
    } catch (e, stack) {
      debugPrint('[AuthRepository.getAllStaffUsersStream] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Updates staff account active / suspended status
  Future<void> updateStaffStatus({
    required String uid,
    required String status,
  }) async {
    if (status != 'active' && status != 'suspended') {
      throw ArgumentError('Status must be either active or suspended.');
    }
    try {
      if (_functions != null) {
        try {
          final callable = _functions!.httpsCallable('updateStaffStatus');
          await callable.call<Map<String, dynamic>>({
            'uid': uid,
            'status': status,
          });
          return;
        } on FirebaseException catch (fe) {
          if (fe.code == 'permission-denied' ||
              fe.code == 'unauthenticated' ||
              fe.code == 'invalid-argument' ||
              fe.code == 'failed-precondition') {
            rethrow;
          }
        } catch (_) {}
      }

      if (_firestore == null) {
        throw const AuthException('Firestore service unavailable.');
      }
      await _firestore!.collection('users').doc(uid).update({
        'status': status,
        'isActive': status == 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[AuthRepository.updateStaffStatus] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Updates staff member institutional role
  Future<void> updateStaffRole({
    required String uid,
    required String newRole,
  }) async {
    if (!UserRoles.isValidRole(newRole)) {
      throw ArgumentError(
          'Role $newRole is not one of the 6 permitted institutional roles.');
    }
    try {
      if (_functions != null) {
        try {
          final callable = _functions!.httpsCallable('updateStaffRole');
          await callable.call<Map<String, dynamic>>({
            'uid': uid,
            'newRole': newRole,
          });
          return;
        } on FirebaseException catch (fe) {
          if (fe.code == 'permission-denied' ||
              fe.code == 'unauthenticated' ||
              fe.code == 'invalid-argument' ||
              fe.code == 'failed-precondition') {
            rethrow;
          }
        } catch (_) {}
      }

      if (_firestore == null) {
        throw const AuthException('Firestore service unavailable.');
      }
      await _firestore!.collection('users').doc(uid).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[AuthRepository.updateStaffRole] Error: $e\n$stack');
      rethrow;
    }
  }

  /// Assigns classes and sections scope to a teacher
  Future<void> assignTeacherScope({
    required String uid,
    required List<String> classes,
    required List<String> sections,
  }) async {
    try {
      if (_functions != null) {
        try {
          final callable = _functions!.httpsCallable('assignTeacherScope');
          await callable.call<Map<String, dynamic>>({
            'uid': uid,
            'classes': classes,
            'sections': sections,
          });
          return;
        } on FirebaseException catch (fe) {
          if (fe.code == 'permission-denied' ||
              fe.code == 'unauthenticated' ||
              fe.code == 'invalid-argument' ||
              fe.code == 'failed-precondition') {
            rethrow;
          }
        } catch (_) {}
      }

      if (_firestore == null) {
        throw const AuthException('Firestore service unavailable.');
      }
      await _firestore!.collection('users').doc(uid).update({
        'assignedClasses': classes,
        'assignedSections': sections,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[AuthRepository.assignTeacherScope] Error: $e\n$stack');
      rethrow;
    }
  }
}
