import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Parent Examination Timetable
/// Route: /parent/exams
class ParentExamsScreen extends ConsumerWidget {
  const ParentExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    final List<Map<String, dynamic>> schedule = [
      {
        'date': '16 Nov 2026',
        'day': 'Monday',
        'subject': 'Mathematics (Theory)',
        'time': '09:00 AM – 12:00 PM',
        'maxMarks': 60,
      },
      {
        'date': '18 Nov 2026',
        'day': 'Wednesday',
        'subject': 'Science (Physics & Chemistry)',
        'time': '09:00 AM – 12:00 PM',
        'maxMarks': 60,
      },
      {
        'date': '20 Nov 2026',
        'day': 'Friday',
        'subject': 'Social Science',
        'time': '09:00 AM – 12:00 PM',
        'maxMarks': 60,
      },
      {
        'date': '23 Nov 2026',
        'day': 'Monday',
        'subject': 'English Language & Literature',
        'time': '09:00 AM – 12:00 PM',
        'maxMarks': 60,
      },
    ];

    return ResponsiveScaffold(
      title: "Child's Examination Schedule",
      currentRoute: AppRoutes.parentExams,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          ErpCard(
            title: 'Mid-Term Examinations Datesheet (AY 2026-2027)',
            subtitle: selectedChild != null
                ? 'Examination schedule for ${selectedChild.fullName} (Class ${selectedChild.currentClassId})'
                : 'Select child above',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: schedule.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final p = schedule[idx];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.parentBlue.withValues(alpha: 0.1),
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.parentBlue)),
                  ),
                  title: Text(p['subject'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Date: ${p['date']} (${p['day']}) • Time: ${p['time']} • Max: ${p['maxMarks']} marks'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
