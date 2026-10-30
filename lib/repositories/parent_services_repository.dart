import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/parent_service_models.dart';

class ParentServicesRepository {
  final FirebaseFirestore? _explicitFirestore;
  final FirebaseAuth? _explicitAuth;

  ParentServicesRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _explicitFirestore = firestore,
        _explicitAuth = auth;

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_explicitAuth != null) return _explicitAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // 1. Homework
  Future<List<HomeworkItem>> getHomework({
    required String classId,
    required String sectionId,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('homework')
        .where('classId', isEqualTo: classId)
        .where('sectionId', isEqualTo: sectionId)
        .orderBy('dueDate', descending: true)
        .get();
    return snap.docs
        .map((doc) => HomeworkItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  // 2. Syllabus
  Future<List<SyllabusItem>> getSyllabus({required String classId}) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('syllabus')
        .where('classId', isEqualTo: classId)
        .get();
    return snap.docs
        .map((doc) => SyllabusItem.fromMap(doc.id, doc.data()))
        .toList();
  }

  // 3. Chat with School
  Stream<List<ParentChatMessage>> getChatStream({
    required String parentUid,
    required String recipientRole,
  }) {
    final conversationId = '${parentUid}_$recipientRole';
    final fs = _firestore;
    if (fs == null) return Stream.value(const <ParentChatMessage>[]);
    return fs
        .collection('parent_chats')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ParentChatMessage.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> sendChatMessage({
    required String parentUid,
    required String parentName,
    required String recipientRole,
    required String message,
  }) async {
    final fs = _firestore;
    if (fs == null) {
      throw StateError(
          'School messaging is unavailable without a Firestore connection.');
    }
    final conversationId = '${parentUid}_$recipientRole';
    final doc = fs.collection('parent_chats').doc();
    final chatMsg = ParentChatMessage(
      id: doc.id,
      conversationId: conversationId,
      senderUid: parentUid,
      senderName: parentName,
      senderRole: 'parent_guardian',
      recipientRole: recipientRole,
      message: message.trim(),
      timestamp: DateTime.now(),
      isRead: false,
    );
    await doc.set(chatMsg.toMap());
  }

  // 4. Complaints & Grievances
  Future<List<ParentComplaint>> getComplaints(
      {required String parentUid}) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('complaints')
        .where('parentUid', isEqualTo: parentUid)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => ParentComplaint.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<ParentComplaint> submitComplaint({
    required String parentUid,
    required String studentId,
    required String studentName,
    required String category,
    required String subject,
    required String description,
  }) async {
    final fs = _firestore;
    if (fs == null) {
      throw StateError(
          'Complaint submission is unavailable without a Firestore connection.');
    }
    final doc = fs.collection('complaints').doc();
    final complaint = ParentComplaint(
      id: doc.id,
      referenceNumber:
          'LAV-CMP-${DateTime.now().year}-${doc.id.substring(0, 6).toUpperCase()}',
      parentUid: parentUid,
      studentId: studentId,
      studentName: studentName,
      category: category,
      subject: subject,
      description: description,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    await doc.set(complaint.toMap());
    return complaint;
  }

  // 5. Timetable / Class Routine
  Future<List<TimetableSlot>> getTimetable({
    required String classId,
    required String sectionId,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('timetables')
        .where('classId', isEqualTo: classId)
        .where('sectionId', isEqualTo: sectionId)
        .get();
    return snap.docs.map((doc) => TimetableSlot.fromMap(doc.data())).toList()
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));
  }

  // 6. Online Classes
  Future<List<OnlineClassSession>> getOnlineClasses({
    required String classId,
    required String sectionId,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('online_classes')
        .where('classId', isEqualTo: classId)
        .where('sectionId', isEqualTo: sectionId)
        .get();
    return snap.docs
        .map((doc) => OnlineClassSession.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  // 7. Academic Calendar
  Future<List<SchoolCalendarEvent>> getCalendarEvents() async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs.collection('school_calendar').get();
    return snap.docs
        .map((doc) => SchoolCalendarEvent.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  // 8. Online Tests (Delegated Student Session Runner)
  Future<List<OnlineQuizItem>> getOnlineQuizzes({
    required String classId,
    required String sectionId,
  }) async {
    final fs = _firestore;
    if (fs == null) return [];
    final snap = await fs
        .collection('online_quizzes')
        .where('classId', isEqualTo: classId)
        .where('sectionId', isEqualTo: sectionId)
        .get();
    return snap.docs
        .map((doc) => OnlineQuizItem.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
  }

  // 9. Transport Information
  Future<TransportInfo> getTransportInfo({required String studentId}) async {
    final fs = _firestore;
    if (fs == null) {
      throw StateError(
          'Transport information is unavailable without a Firestore connection.');
    }
    final snap =
        await fs.collection('transport_assignments').doc(studentId).get();
    final data = snap.data();
    if (!snap.exists || data == null) {
      throw StateError('No transport assignment is recorded for this student.');
    }
    return TransportInfo.fromMap(data);
  }

  // 10. Update Parent Profile (Permitted fields only)
  Future<void> updateParentContactProfile({
    required String parentUid,
    required String phone,
    required String address,
    required String emergencyContact,
  }) async {
    // Only permitted contact fields; never touch protected role, ward links, or email identity
    final updates = {
      'phone': phone,
      'address': address,
      'emergencyContact': emergencyContact,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final fs = _firestore;
    if (fs == null) {
      throw StateError(
          'Profile updates are unavailable without a Firestore connection.');
    }
    await fs.collection('users').doc(parentUid).update(updates);
  }

  // 11. Change Password via Firebase Authentication
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user session found.',
      );
    }

    if (user.email == null || user.email!.isEmpty) {
      // If signed in via Phone OTP, password change is not applicable; phone sessions rely on SMS verification
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message:
            'This account uses verified phone number login. Password is not required for phone authentication.',
      );
    }

    // Reauthenticate first to satisfy security requirement
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }
}
