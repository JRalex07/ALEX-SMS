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
    if (fs != null) {
      try {
        final snap = await fs
            .collection('homework')
            .where('classId', isEqualTo: classId)
            .where('sectionId', isEqualTo: sectionId)
            .orderBy('dueDate', descending: true)
            .get();

        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => HomeworkItem.fromMap(doc.id, doc.data()))
              .toList();
        }
      } catch (_) {}
    }

    // Institutional syllabus assignments for class
    return [
      HomeworkItem(
        id: 'HW_001',
        title: 'Mathematics: Fractions & Decimals Exercise 4.2',
        subjectName: 'Mathematics',
        classId: classId,
        sectionId: sectionId,
        assignedDate: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 1)),
        instructions:
            'Complete Questions 1 through 15 on Page 84 of the NCERT Textbook in your homework notebook. Show all intermediate calculation steps clearly.',
        attachmentName: 'Fractions_Worksheet_Ch4.pdf',
        submissionStatus: 'pending',
        teacherName: 'Mrs. S. Sharma',
      ),
      HomeworkItem(
        id: 'HW_002',
        title: 'Science: Plant Cell Diagram & Organelle Functions',
        subjectName: 'General Science',
        classId: classId,
        sectionId: sectionId,
        assignedDate: DateTime.now().subtract(const Duration(days: 2)),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        instructions:
            'Draw and neatly label the structure of a plant cell on an A4 sheet. List the distinct functions of chloroplasts and mitochondria.',
        attachmentName: 'Plant_Cell_Reference.pdf',
        submissionStatus: 'submitted',
        teacherName: 'Mr. A. Verma',
      ),
      HomeworkItem(
        id: 'HW_003',
        title: 'English: Creative Writing - My Ideal School',
        subjectName: 'English Literature',
        classId: classId,
        sectionId: sectionId,
        assignedDate: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
        instructions:
            'Write a 200-word essay describing your vision for a futuristic school. Focus on vocabulary, paragraph transitions, and punctuation.',
        submissionStatus: 'evaluated',
        teacherName: 'Ms. P. Roy',
      ),
    ];
  }

  // 2. Syllabus
  Future<List<SyllabusItem>> getSyllabus({required String classId}) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('syllabus')
            .where('classId', isEqualTo: classId)
            .get();

        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => SyllabusItem.fromMap(doc.id, doc.data()))
              .toList();
        }
      } catch (_) {}
    }

    return [
      const SyllabusItem(
        id: 'SYL_001',
        subjectName: 'Mathematics',
        classId: 'CLASS_5',
        term: 'Term 1 (April - September 2026)',
        topics: [
          'Large Numbers & Place Value System',
          'Operations on Large Numbers',
          'Factors and Multiples (HCF & LCM)',
          'Fractions and Decimals',
          'Geometry: Basic Shapes, Angles, and Perimeter',
        ],
        completionPercentage: 85,
        documentUrl: 'https://lav-school.edu/syllabus/class5_math.pdf',
      ),
      const SyllabusItem(
        id: 'SYL_002',
        subjectName: 'General Science',
        classId: 'CLASS_5',
        term: 'Term 1 (April - September 2026)',
        topics: [
          'Plant Life: Reproduction and Germination',
          'Animal Habitat & Adaptations',
          'Human Body: Skeletal and Muscular Systems',
          'Food, Health & Deficiency Diseases',
          'Air, Water and Weather',
        ],
        completionPercentage: 70,
        documentUrl: 'https://lav-school.edu/syllabus/class5_science.pdf',
      ),
      const SyllabusItem(
        id: 'SYL_003',
        subjectName: 'Social Studies',
        classId: 'CLASS_5',
        term: 'Term 1 (April - September 2026)',
        topics: [
          'The Globe: Latitudes and Longitudes',
          'Movements of the Earth: Rotation & Revolution',
          'Major Landforms and Water Bodies',
          'Democratic Government & Constitution',
        ],
        completionPercentage: 80,
      ),
      const SyllabusItem(
        id: 'SYL_004',
        subjectName: 'English Literature & Grammar',
        classId: 'CLASS_5',
        term: 'Term 1 (April - September 2026)',
        topics: [
          'Prose: The Giving Tree, Alice in Wonderland',
          'Poetry: The Road Not Taken, Daffodils',
          'Grammar: Nouns, Pronouns, Subject-Verb Agreement',
          'Formal Letter Writing & Comprehension',
        ],
        completionPercentage: 90,
      ),
    ];
  }

  // 3. Chat with School
  Stream<List<ParentChatMessage>> getChatStream({
    required String parentUid,
    required String recipientRole,
  }) {
    final conversationId = '${parentUid}_$recipientRole';
    final fs = _firestore;
    if (fs == null) {
      return Stream.value(_getDefaultMessages(conversationId, recipientRole));
    }
    return fs
        .collection('parent_chats')
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        return _getDefaultMessages(conversationId, recipientRole);
      }
      return snap.docs
          .map((doc) => ParentChatMessage.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  List<ParentChatMessage> _getDefaultMessages(
      String conversationId, String recipientRole) {
    final now = DateTime.now();
    return [
      ParentChatMessage(
        id: 'msg_01',
        conversationId: conversationId,
        senderUid: 'staff_system',
        senderName: recipientRole == 'teacher'
            ? 'Class Teacher (Mrs. S. Sharma)'
            : 'Admissions & Admin Desk',
        senderRole: recipientRole,
        recipientRole: 'parent_guardian',
        message: recipientRole == 'teacher'
            ? 'Namaste! Welcome to the classroom communication channel. Feel free to reach out regarding academic progress, homework questions, or class activities.'
            : 'Welcome to the LAV Academy Administration Office. How can we assist you today?',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  Future<void> sendChatMessage({
    required String parentUid,
    required String parentName,
    required String recipientRole,
    required String message,
  }) async {
    final conversationId = '${parentUid}_$recipientRole';
    final fs = _firestore;
    final id = fs != null ? fs.collection('parent_chats').doc().id : 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final chatMsg = ParentChatMessage(
      id: id,
      conversationId: conversationId,
      senderUid: parentUid,
      senderName: parentName,
      senderRole: 'parent_guardian',
      recipientRole: recipientRole,
      message: message,
      timestamp: DateTime.now(),
      isRead: false,
    );

    if (fs != null) {
      try {
        await fs.collection('parent_chats').doc(id).set(chatMsg.toMap());
      } catch (_) {}
    }
  }

  // 4. Complaints & Grievances
  Future<List<ParentComplaint>> getComplaints({
    required String parentUid,
  }) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('complaints')
            .where('parentUid', isEqualTo: parentUid)
            .orderBy('createdAt', descending: true)
            .get();

        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => ParentComplaint.fromMap(doc.id, doc.data()))
              .toList();
        }
      } catch (_) {}
    }

    return [
      ParentComplaint(
        id: 'CMP_101',
        referenceNumber: 'LAV-CMP-2026-084',
        parentUid: parentUid,
        studentId: 'STU_001',
        studentName: 'Tanishk Anand',
        category: 'transport',
        subject: 'Morning Bus Route 4 delayed by 25 minutes at Green Park stop',
        description:
            'On Wednesday morning the school bus arrived at 7:50 AM instead of 7:25 AM without prior notification. Requesting driver coordination update.',
        status: 'in_review',
        responses: [
          ComplaintResponse(
            responderName: 'Mr. R. Singhania',
            responderRole: 'school_admin',
            message:
                'We have taken note of the delay. The driver reported unexpected road construction along the Ring Road. We have directed the transport supervisor to issue automated SMS alerts if delays exceed 10 minutes.',
            timestamp: DateTime.now().subtract(const Duration(hours: 18)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ParentComplaint(
        id: 'CMP_102',
        referenceNumber: 'LAV-CMP-2026-012',
        parentUid: parentUid,
        studentId: 'STU_001',
        studentName: 'Tanishk Anand',
        category: 'academics',
        subject:
            'Clarification regarding Computer Science Term 1 practical evaluation',
        description:
            'Requesting the rubric used for the Scratch programming practical evaluation for Term 1 marks.',
        status: 'resolved',
        responses: [
          ComplaintResponse(
            responderName: 'Mrs. S. Sharma',
            responderRole: 'teacher',
            message:
                'The evaluation rubric has been uploaded to the Study Materials section. Tanishk scored 19/20 on logic flow and animations.',
            timestamp: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
    ];
  }

  Future<ParentComplaint> submitComplaint({
    required String parentUid,
    required String studentId,
    required String studentName,
    required String category,
    required String subject,
    required String description,
  }) async {
    final refNum =
        'LAV-CMP-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}';
    final fs = _firestore;
    final docId = fs != null ? fs.collection('complaints').doc().id : 'CMP_${DateTime.now().millisecondsSinceEpoch}';

    final complaint = ParentComplaint(
      id: docId,
      referenceNumber: refNum,
      parentUid: parentUid,
      studentId: studentId,
      studentName: studentName,
      category: category,
      subject: subject,
      description: description,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    if (fs != null) {
      try {
        await fs.collection('complaints').doc(docId).set(complaint.toMap());
      } catch (_) {}
    }

    return complaint;
  }

  // 5. Timetable / Class Routine
  Future<List<TimetableSlot>> getTimetable({
    required String classId,
    required String sectionId,
  }) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('timetables')
            .where('classId', isEqualTo: classId)
            .where('sectionId', isEqualTo: sectionId)
            .get();

        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => TimetableSlot.fromMap(doc.data()))
              .toList();
        }
      } catch (_) {}
    }

    return [
      const TimetableSlot(
        dayOfWeek: 'Monday',
        periodNumber: 1,
        startTime: '08:30 AM',
        endTime: '09:15 AM',
        subjectName: 'Mathematics',
        teacherName: 'Mrs. S. Sharma',
        roomNumber: 'Room 204',
      ),
      const TimetableSlot(
        dayOfWeek: 'Monday',
        periodNumber: 2,
        startTime: '09:15 AM',
        endTime: '10:00 AM',
        subjectName: 'General Science',
        teacherName: 'Mr. A. Verma',
        roomNumber: 'Science Lab 1',
      ),
      const TimetableSlot(
        dayOfWeek: 'Monday',
        periodNumber: 3,
        startTime: '10:00 AM',
        endTime: '10:45 AM',
        subjectName: 'English Literature',
        teacherName: 'Ms. P. Roy',
        roomNumber: 'Room 204',
      ),
      const TimetableSlot(
        dayOfWeek: 'Monday',
        periodNumber: 4,
        startTime: '11:15 AM',
        endTime: '12:00 PM',
        subjectName: 'Social Studies',
        teacherName: 'Mr. K. Nair',
        roomNumber: 'Room 204',
      ),
      const TimetableSlot(
        dayOfWeek: 'Monday',
        periodNumber: 5,
        startTime: '12:00 PM',
        endTime: '12:45 PM',
        subjectName: 'Computer Science',
        teacherName: 'Ms. R. Gupta',
        roomNumber: 'IT Lab A',
      ),
      const TimetableSlot(
        dayOfWeek: 'Monday',
        periodNumber: 6,
        startTime: '01:15 PM',
        endTime: '02:00 PM',
        subjectName: 'Physical Education',
        teacherName: 'Coach M. Singh',
        roomNumber: 'Sports Complex',
      ),
    ];
  }

  // 6. Online Classes
  Future<List<OnlineClassSession>> getOnlineClasses({
    required String classId,
    required String sectionId,
  }) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('online_classes')
            .where('classId', isEqualTo: classId)
            .where('sectionId', isEqualTo: sectionId)
            .get();

        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => OnlineClassSession.fromMap(doc.id, doc.data()))
              .toList();
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    return [
      OnlineClassSession(
        id: 'OC_01',
        title: 'Fractions Doubt Clearing & Interactive Problem Solving',
        subjectName: 'Mathematics',
        teacherName: 'Mrs. S. Sharma',
        classId: classId,
        sectionId: sectionId,
        scheduledAt: now.add(const Duration(hours: 2)),
        durationMinutes: 45,
        provider: 'google_meet',
        joinUrl: 'https://meet.google.com/lav-math-cls5',
        meetingId: 'lav-math-cls5',
        passcode: 'LAV2026',
        status: 'upcoming',
      ),
      OnlineClassSession(
        id: 'OC_02',
        title: 'Interactive Virtual Science Lab: Observing Plant Cells',
        subjectName: 'General Science',
        teacherName: 'Mr. A. Verma',
        classId: classId,
        sectionId: sectionId,
        scheduledAt: now.add(const Duration(days: 1, hours: 4)),
        durationMinutes: 40,
        provider: 'zoom',
        joinUrl: 'https://zoom.us/j/9876543210',
        meetingId: '987 654 3210',
        passcode: 'SCIENCE5',
        status: 'upcoming',
      ),
    ];
  }

  // 7. Academic Calendar
  Future<List<SchoolCalendarEvent>> getCalendarEvents() async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs.collection('school_calendar').get();
        if (snap.docs.isNotEmpty) {
          return snap.docs
              .map((doc) => SchoolCalendarEvent.fromMap(doc.id, doc.data()))
              .toList();
        }
      } catch (_) {}
    }

    final now = DateTime.now();
    return [
      SchoolCalendarEvent(
        id: 'EV_01',
        title: 'Dussehra Holiday & Autumn Break',
        description: 'School campus closed for festivities and autumn holiday.',
        startDate: now.add(const Duration(days: 4)),
        endDate: now.add(const Duration(days: 7)),
        type: 'holiday',
      ),
      SchoolCalendarEvent(
        id: 'EV_02',
        title: 'Parent-Teacher Meeting (PTM Term 1)',
        description:
            'Interactive evaluation session with class teachers and subject faculty to review report cards.',
        startDate: now.add(const Duration(days: 12)),
        endDate: now.add(const Duration(days: 12)),
        type: 'ptm',
        location: 'Junior School Wing Auditorium',
      ),
      SchoolCalendarEvent(
        id: 'EV_03',
        title: 'Mid-Term Formative Assessment 2 (FA-2)',
        description:
            'Commencement of formal CBSE syllabus mid-term examinations.',
        startDate: now.add(const Duration(days: 18)),
        endDate: now.add(const Duration(days: 26)),
        type: 'exam',
      ),
      SchoolCalendarEvent(
        id: 'EV_04',
        title: 'Annual Inter-House Sports & Athletic Meet',
        description: 'Track and field events, relay races, and award ceremony.',
        startDate: now.add(const Duration(days: 34)),
        endDate: now.add(const Duration(days: 35)),
        type: 'sports',
        location: 'LAV Academy Sports Grounds',
      ),
    ];
  }

  // 8. Online Tests (Delegated Student Session Runner)
  Future<List<OnlineQuizItem>> getOnlineQuizzes({
    required String classId,
    required String sectionId,
  }) async {
    return [
      OnlineQuizItem(
        id: 'QUIZ_01',
        title: 'Mathematics Weekly Quiz: Fractions & HCF',
        subjectName: 'Mathematics',
        classId: classId,
        sectionId: sectionId,
        durationMinutes: 15,
        totalQuestions: 4,
        totalMarks: 20,
        dueAt: DateTime.now().add(const Duration(days: 2)),
        isCompleted: false,
        questions: [
          QuizQuestion(
            id: 'Q1',
            questionText:
                'What is the Highest Common Factor (HCF) of 24 and 36?',
            options: ['6', '8', '12', '18'],
            correctOptionIndex: 2,
          ),
          QuizQuestion(
            id: 'Q2',
            questionText:
                'What is the sum of 3/8 and 1/4 in simplest fractional form?',
            options: ['4/12', '5/8', '1/2', '7/8'],
            correctOptionIndex: 1,
          ),
          QuizQuestion(
            id: 'Q3',
            questionText: 'Which of the following numbers is a Prime Number?',
            options: ['27', '39', '43', '51'],
            correctOptionIndex: 2,
          ),
          QuizQuestion(
            id: 'Q4',
            questionText:
                'Convert 0.75 into a standard fraction in lowest terms.',
            options: ['3/4', '7/5', '1/4', '75/10'],
            correctOptionIndex: 0,
          ),
        ],
      ),
      OnlineQuizItem(
        id: 'QUIZ_02',
        title: 'Science Chapter Check: Human Skeletal System',
        subjectName: 'General Science',
        classId: classId,
        sectionId: sectionId,
        durationMinutes: 20,
        totalQuestions: 3,
        totalMarks: 15,
        dueAt: DateTime.now().subtract(const Duration(days: 3)),
        isCompleted: true,
        scoreObtained: 15,
        questions: [
          QuizQuestion(
            id: 'SQ1',
            questionText:
                'How many bones are present in an adult human skeleton?',
            options: ['180', '206', '250', '300'],
            correctOptionIndex: 1,
            selectedOptionIndex: 1,
          ),
          QuizQuestion(
            id: 'SQ2',
            questionText:
                'Which joint in the human body allows 360-degree rotation?',
            options: [
              'Hinge Joint',
              'Pivot Joint',
              'Ball and Socket Joint',
              'Fixed Joint'
            ],
            correctOptionIndex: 2,
            selectedOptionIndex: 2,
          ),
          QuizQuestion(
            id: 'SQ3',
            questionText:
                'Which mineral is primarily responsible for strong bones and teeth?',
            options: ['Iron', 'Calcium', 'Sodium', 'Potassium'],
            correctOptionIndex: 1,
            selectedOptionIndex: 1,
          ),
        ],
      ),
    ];
  }

  // 9. Transport Information
  Future<TransportInfo> getTransportInfo({required String studentId}) async {
    final fs = _firestore;
    if (fs != null) {
      try {
        final snap = await fs
            .collection('transport_assignments')
            .doc(studentId)
            .get();

        if (snap.exists && snap.data() != null) {
          return TransportInfo.fromMap(snap.data()!);
        }
      } catch (_) {}
    }

    return const TransportInfo(
      busNumber: 'DL-01-AB-1234 (Bus #04)',
      routeName: 'Route 4: Green Park - South Extension - Campus',
      driverName: 'Mr. Rajesh Kumar',
      driverPhone: '+91 98765 43210',
      conductorName: 'Mr. Sunil Sharma',
      conductorPhone: '+91 98765 12345',
      pickupStop: 'Green Park Metro Station Gate 2',
      dropStop: 'Green Park Metro Station Gate 2',
      pickupTime: '07:25 AM',
      dropTime: '03:15 PM',
      vehicleType: 'School Bus (40-Seater, GPS & CCTV Equipped)',
    );
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
    if (fs != null) {
      await fs.collection('users').doc(parentUid).update(updates);
    }
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
