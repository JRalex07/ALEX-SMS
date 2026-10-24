import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/role_colors.dart';
import '../models/parent_service_models.dart';
import '../repositories/parent_services_repository.dart';
import 'auth_providers.dart';
import 'child_context_provider.dart';

final parentServicesRepositoryProvider = Provider<ParentServicesRepository>((ref) {
  return ParentServicesRepository();
});

/// Dynamically resolves the active RoleThemePalette for the authenticated user
final currentRoleThemeProvider = Provider<RoleThemePalette>((ref) {
  final user = ref.watch(currentUserProfileProvider).value;
  final role = user?.role ?? UserRoles.parentGuardian;
  return RoleThemePalette.forRole(role);
});

/// 1. Homework for selected child
final childHomeworkProvider = FutureProvider<List<HomeworkItem>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getHomework(
    classId: child.currentClassId,
    sectionId: child.currentSectionId,
  );
});

/// 2. Syllabus for selected child's class
final childSyllabusProvider = FutureProvider<List<SyllabusItem>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getSyllabus(classId: child.currentClassId);
});

/// 3. Parent Chat Stream with School (by recipient role: 'teacher', 'school_admin', 'accountant')
final parentChatStreamProvider =
    StreamProvider.family<List<ParentChatMessage>, String>((ref, recipientRole) {
  final user = ref.watch(currentUserProfileProvider).value;
  final parentUid = user?.uid ?? 'guest_parent';
  final repo = ref.watch(parentServicesRepositoryProvider);

  return repo.getChatStream(parentUid: parentUid, recipientRole: recipientRole);
});

/// 4. Parent Complaints & Grievance History
final parentComplaintsProvider = FutureProvider<List<ParentComplaint>>((ref) async {
  final user = ref.watch(currentUserProfileProvider).value;
  final parentUid = user?.uid ?? 'guest_parent';
  final repo = ref.watch(parentServicesRepositoryProvider);

  return repo.getComplaints(parentUid: parentUid);
});

/// 5. Timetable / Class Routine for selected child
final childTimetableProvider = FutureProvider<List<TimetableSlot>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getTimetable(
    classId: child.currentClassId,
    sectionId: child.currentSectionId,
  );
});

/// 6. Online Classes for selected child
final childOnlineClassesProvider =
    FutureProvider<List<OnlineClassSession>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getOnlineClasses(
    classId: child.currentClassId,
    sectionId: child.currentSectionId,
  );
});

/// 7. Academic Calendar Events
final schoolCalendarEventsProvider =
    FutureProvider<List<SchoolCalendarEvent>>((ref) async {
  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getCalendarEvents();
});

/// 8. Online Tests / Quizzes for selected child
final childOnlineQuizzesProvider =
    FutureProvider<List<OnlineQuizItem>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return [];

  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getOnlineQuizzes(
    classId: child.currentClassId,
    sectionId: child.currentSectionId,
  );
});

/// 9. Transport Information for selected child
final childTransportProvider = FutureProvider<TransportInfo>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null) {
    return const TransportInfo(
      busNumber: 'N/A',
      routeName: 'No child selected',
      driverName: 'N/A',
      driverPhone: 'N/A',
      conductorName: 'N/A',
      conductorPhone: 'N/A',
      pickupStop: 'N/A',
      dropStop: 'N/A',
      pickupTime: 'N/A',
      dropTime: 'N/A',
    );
  }

  final repo = ref.watch(parentServicesRepositoryProvider);
  return repo.getTransportInfo(studentId: child.studentId);
});
