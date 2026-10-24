import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/student_model.dart';
import '../repositories/student_repository.dart';
import 'auth_providers.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

/// Stream of all enrolled students for authorized staff members
final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final studentRepo = ref.watch(studentRepositoryProvider);
  return studentRepo.getStudentsStream();
});

/// Fetches single student record by studentId
final studentByIdProvider =
    FutureProvider.family<Student?, String>((ref, studentId) async {
  final repo = ref.watch(studentRepositoryProvider);
  return await repo.getStudentById(studentId);
});

/// Fetches all active children linked to the currently logged in parent/guardian
final parentLinkedChildrenProvider = FutureProvider<List<Student>>((ref) async {
  final user = ref.watch(currentUserProfileProvider).value;
  if (user == null || !user.isParent) return [];

  final studentRepo = ref.watch(studentRepositoryProvider);
  return await studentRepo.getLinkedStudentsForParent(user.uid);
});

/// Active Child Context: ID of currently selected child in parent switcher
final selectedChildIdProvider = StateProvider<String?>((ref) {
  // Defaults to the first linked child when list resolves
  final linkedChildren = ref.watch(parentLinkedChildrenProvider).value;
  if (linkedChildren != null && linkedChildren.isNotEmpty) {
    return linkedChildren.first.studentId;
  }
  return null;
});

/// Currently selected child entity
final selectedChildProvider = Provider<Student?>((ref) {
  final selectedId = ref.watch(selectedChildIdProvider);
  final linkedChildren = ref.watch(parentLinkedChildrenProvider).value;
  if (selectedId == null || linkedChildren == null) return null;

  try {
    return linkedChildren.firstWhere((c) => c.studentId == selectedId);
  } catch (e) {
    debugPrint(
        '[selectedChildProvider] Selected child ID $selectedId not found in linked children list. Falling back to first available child: $e');
    return linkedChildren.isNotEmpty ? linkedChildren.first : null;
  }
});
