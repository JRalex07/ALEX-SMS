import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String noticeId;
  final String title;
  final String content;
  final String targetAudience; // 'all', 'staff', 'parents', 'class'
  final String? targetClassId;
  final bool isPublished;
  final String authorUid;
  final String? authorName;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final DateTime? createdAt;
  final DateTime? publishedAt;

  const Notice({
    required this.noticeId,
    required this.title,
    required this.content,
    this.targetAudience = 'all',
    this.targetClassId,
    this.isPublished = false,
    required this.authorUid,
    this.authorName,
    this.priority = 'medium',
    this.createdAt,
    this.publishedAt,
  });

  factory Notice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Notice(
      noticeId: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      targetAudience: data['targetAudience'] ?? 'all',
      targetClassId: data['targetClassId'],
      isPublished: data['isPublished'] ?? false,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'],
      priority: data['priority'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      publishedAt: (data['publishedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noticeId': noticeId,
      'title': title,
      'content': content,
      'targetAudience': targetAudience,
      'targetClassId': targetClassId,
      'isPublished': isPublished,
      'authorUid': authorUid,
      'authorName': authorName,
      'priority': priority,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'publishedAt':
          publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
    };
  }
}
