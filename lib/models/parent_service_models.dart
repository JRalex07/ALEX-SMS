import 'package:cloud_firestore/cloud_firestore.dart';

/// 1. Homework Item
class HomeworkItem {
  final String id;
  final String title;
  final String subjectName;
  final String classId;
  final String sectionId;
  final DateTime assignedDate;
  final DateTime dueDate;
  final String instructions;
  final String? attachmentName;
  final String? attachmentUrl;
  final String submissionStatus; // 'pending', 'submitted', 'evaluated'
  final String teacherName;

  const HomeworkItem({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.classId,
    required this.sectionId,
    required this.assignedDate,
    required this.dueDate,
    required this.instructions,
    this.attachmentName,
    this.attachmentUrl,
    this.submissionStatus = 'pending',
    required this.teacherName,
  });

  factory HomeworkItem.fromMap(String id, Map<String, dynamic> data) {
    return HomeworkItem(
      id: id,
      title: data['title'] ?? '',
      subjectName: data['subjectName'] ?? 'General',
      classId: data['classId'] ?? '',
      sectionId: data['sectionId'] ?? '',
      assignedDate:
          (data['assignedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 2)),
      instructions: data['instructions'] ?? '',
      attachmentName: data['attachmentName'],
      attachmentUrl: data['attachmentUrl'],
      submissionStatus: data['submissionStatus'] ?? 'pending',
      teacherName: data['teacherName'] ?? 'Faculty Member',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subjectName': subjectName,
      'classId': classId,
      'sectionId': sectionId,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      'instructions': instructions,
      'attachmentName': attachmentName,
      'attachmentUrl': attachmentUrl,
      'submissionStatus': submissionStatus,
      'teacherName': teacherName,
    };
  }
}

/// 2. Syllabus Item
class SyllabusItem {
  final String id;
  final String subjectName;
  final String classId;
  final String term;
  final List<String> topics;
  final int completionPercentage;
  final String? documentUrl;

  const SyllabusItem({
    required this.id,
    required this.subjectName,
    required this.classId,
    required this.term,
    required this.topics,
    this.completionPercentage = 0,
    this.documentUrl,
  });

  factory SyllabusItem.fromMap(String id, Map<String, dynamic> data) {
    return SyllabusItem(
      id: id,
      subjectName: data['subjectName'] ?? '',
      classId: data['classId'] ?? '',
      term: data['term'] ?? 'Term 1',
      topics: List<String>.from(data['topics'] ?? []),
      completionPercentage:
          (data['completionPercentage'] as num?)?.toInt() ?? 0,
      documentUrl: data['documentUrl'],
    );
  }
}

/// 3. Chat Message
class ParentChatMessage {
  final String id;
  final String conversationId;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String recipientRole;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ParentChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.recipientRole,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory ParentChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ParentChatMessage(
      id: id,
      conversationId: data['conversationId'] ?? '',
      senderUid: data['senderUid'] ?? '',
      senderName: data['senderName'] ?? '',
      senderRole: data['senderRole'] ?? 'parent_guardian',
      recipientRole: data['recipientRole'] ?? 'teacher',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'conversationId': conversationId,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderRole': senderRole,
      'recipientRole': recipientRole,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
    };
  }
}

/// 4. Complaint & Grievance
class ComplaintResponse {
  final String responderName;
  final String responderRole;
  final String message;
  final DateTime timestamp;

  const ComplaintResponse({
    required this.responderName,
    required this.responderRole,
    required this.message,
    required this.timestamp,
  });

  factory ComplaintResponse.fromMap(Map<String, dynamic> data) {
    return ComplaintResponse(
      responderName: data['responderName'] ?? 'School Admin',
      responderRole: data['responderRole'] ?? 'school_admin',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'responderName': responderName,
      'responderRole': responderRole,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class ParentComplaint {
  final String id;
  final String referenceNumber;
  final String parentUid;
  final String studentId;
  final String studentName;
  final String
      category; // 'academics', 'transport', 'fees', 'discipline', 'general'
  final String subject;
  final String description;
  final String status; // 'pending', 'in_review', 'resolved'
  final List<ComplaintResponse> responses;
  final DateTime createdAt;

  const ParentComplaint({
    required this.id,
    required this.referenceNumber,
    required this.parentUid,
    required this.studentId,
    required this.studentName,
    required this.category,
    required this.subject,
    required this.description,
    this.status = 'pending',
    this.responses = const [],
    required this.createdAt,
  });

  factory ParentComplaint.fromMap(String id, Map<String, dynamic> data) {
    return ParentComplaint(
      id: id,
      referenceNumber: data['referenceNumber'] ?? 'LAV-CMP-000',
      parentUid: data['parentUid'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      category: data['category'] ?? 'general',
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'pending',
      responses: (data['responses'] as List<dynamic>?)
              ?.map((r) => ComplaintResponse.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceNumber': referenceNumber,
      'parentUid': parentUid,
      'studentId': studentId,
      'studentName': studentName,
      'category': category,
      'subject': subject,
      'description': description,
      'status': status,
      'responses': responses.map((r) => r.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

/// 5. Timetable Slot
class TimetableSlot {
  final String dayOfWeek;
  final int periodNumber;
  final String startTime;
  final String endTime;
  final String subjectName;
  final String teacherName;
  final String roomNumber;

  const TimetableSlot({
    required this.dayOfWeek,
    required this.periodNumber,
    required this.startTime,
    required this.endTime,
    required this.subjectName,
    required this.teacherName,
    required this.roomNumber,
  });

  factory TimetableSlot.fromMap(Map<String, dynamic> data) {
    return TimetableSlot(
      dayOfWeek: data['dayOfWeek'] ?? 'Monday',
      periodNumber: (data['periodNumber'] as num?)?.toInt() ?? 1,
      startTime: data['startTime'] ?? '09:00 AM',
      endTime: data['endTime'] ?? '09:45 AM',
      subjectName: data['subjectName'] ?? '',
      teacherName: data['teacherName'] ?? '',
      roomNumber: data['roomNumber'] ?? 'Room 101',
    );
  }
}

/// 6. Online Class Session
class OnlineClassSession {
  final String id;
  final String title;
  final String subjectName;
  final String teacherName;
  final String classId;
  final String sectionId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String provider; // 'google_meet', 'zoom', 'teams'
  final String joinUrl;
  final String? meetingId;
  final String? passcode;
  final String status; // 'live', 'upcoming', 'completed'

  const OnlineClassSession({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.teacherName,
    required this.classId,
    required this.sectionId,
    required this.scheduledAt,
    required this.durationMinutes,
    this.provider = 'google_meet',
    required this.joinUrl,
    this.meetingId,
    this.passcode,
    this.status = 'upcoming',
  });

  factory OnlineClassSession.fromMap(String id, Map<String, dynamic> data) {
    return OnlineClassSession(
      id: id,
      title: data['title'] ?? '',
      subjectName: data['subjectName'] ?? '',
      teacherName: data['teacherName'] ?? 'Faculty Member',
      classId: data['classId'] ?? '',
      sectionId: data['sectionId'] ?? '',
      scheduledAt:
          (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 45,
      provider: data['provider'] ?? 'google_meet',
      joinUrl: data['joinUrl'] ?? 'https://meet.google.com/new',
      meetingId: data['meetingId'],
      passcode: data['passcode'],
      status: data['status'] ?? 'upcoming',
    );
  }
}

/// 7. Academic Calendar Event
class SchoolCalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // 'holiday', 'exam', 'ptm', 'sports', 'event'
  final String? location;

  const SchoolCalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.location,
  });

  factory SchoolCalendarEvent.fromMap(String id, Map<String, dynamic> data) {
    return SchoolCalendarEvent(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'event',
      location: data['location'],
    );
  }
}

/// 8. Online Test / Assessment
class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  int? selectedOptionIndex;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.selectedOptionIndex,
  });

  factory QuizQuestion.fromMap(String id, Map<String, dynamic> data) {
    return QuizQuestion(
      id: id,
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctOptionIndex: (data['correctOptionIndex'] as num?)?.toInt() ?? 0,
      selectedOptionIndex: (data['selectedOptionIndex'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'selectedOptionIndex': selectedOptionIndex,
    };
  }
}

class OnlineQuizItem {
  final String id;
  final String title;
  final String subjectName;
  final String classId;
  final String sectionId;
  final int durationMinutes;
  final int totalQuestions;
  final int totalMarks;
  final DateTime dueAt;
  final bool isCompleted;
  final int? scoreObtained;
  final List<QuizQuestion> questions;

  const OnlineQuizItem({
    required this.id,
    required this.title,
    required this.subjectName,
    required this.classId,
    required this.sectionId,
    required this.durationMinutes,
    required this.totalQuestions,
    required this.totalMarks,
    required this.dueAt,
    this.isCompleted = false,
    this.scoreObtained,
    this.questions = const [],
  });

  factory OnlineQuizItem.fromMap(String id, Map<String, dynamic> data) {
    return OnlineQuizItem(
      id: id,
      title: data['title'] ?? '',
      subjectName: data['subjectName'] ?? '',
      classId: data['classId'] ?? '',
      sectionId: data['sectionId'] ?? '',
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 5,
      totalMarks: (data['totalMarks'] as num?)?.toInt() ?? 20,
      dueAt: (data['dueAt'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 3)),
      isCompleted: data['isCompleted'] ?? false,
      scoreObtained: (data['scoreObtained'] as num?)?.toInt(),
      questions: (data['questions'] as List<dynamic>?)
              ?.asMap()
              .entries
              .map((e) => QuizQuestion.fromMap(
                  'q_${e.key}', e.value as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 9. Transport Info
class TransportInfo {
  final String busNumber;
  final String routeName;
  final String driverName;
  final String driverPhone;
  final String conductorName;
  final String conductorPhone;
  final String pickupStop;
  final String dropStop;
  final String pickupTime;
  final String dropTime;
  final String vehicleType;

  const TransportInfo({
    required this.busNumber,
    required this.routeName,
    required this.driverName,
    required this.driverPhone,
    required this.conductorName,
    required this.conductorPhone,
    required this.pickupStop,
    required this.dropStop,
    required this.pickupTime,
    required this.dropTime,
    this.vehicleType = 'School Bus (40-Seater)',
  });

  factory TransportInfo.fromMap(Map<String, dynamic> data) {
    return TransportInfo(
      busNumber: data['busNumber'] ?? 'DL-01-AB-1234 (Bus #04)',
      routeName:
          data['routeName'] ?? 'Route 4: Green Park - Model Town - Campus',
      driverName: data['driverName'] ?? 'Rajesh Kumar',
      driverPhone: data['driverPhone'] ?? '+91 98765 43210',
      conductorName: data['conductorName'] ?? 'Sunil Sharma',
      conductorPhone: data['conductorPhone'] ?? '+91 98765 12345',
      pickupStop: data['pickupStop'] ?? 'Green Park Metro Station Gate 2',
      dropStop: data['dropStop'] ?? 'Green Park Metro Station Gate 2',
      pickupTime: data['pickupTime'] ?? '07:25 AM',
      dropTime: data['dropTime'] ?? '03:15 PM',
      vehicleType: data['vehicleType'] ?? 'School Bus (40-Seater)',
    );
  }
}
