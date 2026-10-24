import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/notice_model.dart';

class NoticeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  NoticeRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Stream<List<Notice>> getPublishedNoticesStream() {
    try {
      return _firestore
          .collection('notices')
          .where('isPublished', isEqualTo: true)
          .snapshots()
          .handleError((err) {
        debugPrint(
            '[NoticeRepository.getPublishedNoticesStream] FIRESTORE QUERY / INDEX ERROR: $err');
      }).map((s) {
        final list = s.docs.map((d) => Notice.fromFirestore(d)).toList();
        list.sort((a, b) {
          final aDate = a.publishedAt ?? a.createdAt ?? DateTime(2026, 1, 1);
          final bDate = b.publishedAt ?? b.createdAt ?? DateTime(2026, 1, 1);
          return bDate.compareTo(aDate);
        });
        return list;
      });
    } catch (e, stack) {
      debugPrint(
          '[NoticeRepository.getPublishedNoticesStream] Error: $e\n$stack');
      rethrow;
    }
  }

  Stream<List<Notice>> getTeacherDraftsStream(String teacherUid) {
    try {
      return _firestore
          .collection('notices')
          .where('authorUid', isEqualTo: teacherUid)
          .where('isPublished', isEqualTo: false)
          .snapshots()
          .map((s) => s.docs.map((d) => Notice.fromFirestore(d)).toList());
    } catch (e, stack) {
      debugPrint(
          '[NoticeRepository.getTeacherDraftsStream] Error for teacher $teacherUid: $e\n$stack');
      rethrow;
    }
  }

  Future<void> createDraftNotice({
    required String noticeId,
    required String title,
    required String content,
    required String targetAudience,
    String? targetClassId,
    required String authorUid,
  }) async {
    try {
      await _firestore.collection('notices').doc(noticeId).set({
        'noticeId': noticeId,
        'schoolId': 'SCH_001',
        'title': title,
        'content': content,
        'targetAudience': targetAudience,
        'targetClassId': targetClassId,
        'isPublished': false,
        'authorUid': authorUid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint(
          '[NoticeRepository.createDraftNotice] Error creating notice $noticeId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> publishNotice(String noticeId) async {
    try {
      final callable = _functions.httpsCallable('publishNotice');
      await callable.call({'noticeId': noticeId});
    } catch (e, stack) {
      debugPrint(
          '[NoticeRepository.publishNotice] Error publishing notice $noticeId: $e\n$stack');
      rethrow;
    }
  }

  Future<void> unpublishNotice(String noticeId) async {
    try {
      final callable = _functions.httpsCallable('unpublishNotice');
      await callable.call({'noticeId': noticeId});
    } catch (e, stack) {
      debugPrint(
          '[NoticeRepository.unpublishNotice] Error unpublishing notice $noticeId: $e\n$stack');
      rethrow;
    }
  }
}
