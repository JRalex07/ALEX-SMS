import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Examination Timetable & Schedule
/// Route: /examinations/schedule
class ExaminationScheduleScreen extends ConsumerStatefulWidget {
  const ExaminationScheduleScreen({super.key});

  @override
  ConsumerState<ExaminationScheduleScreen> createState() =>
      _ExaminationScheduleScreenState();
}

class _ExaminationScheduleScreenState
    extends ConsumerState<ExaminationScheduleScreen> {
  String _selectedClass = '10';

  final List<Map<String, dynamic>> _schedule = [
    {
      'date': '16 Nov 2026',
      'day': 'Monday',
      'subject': 'Mathematics (Theory)',
      'code': 'MTH-101',
      'time': '09:00 AM – 12:00 PM',
      'maxMarks': 60,
      'room': 'Exam Hall A & B',
    },
    {
      'date': '18 Nov 2026',
      'day': 'Wednesday',
      'subject': 'Science (Physics & Chemistry)',
      'code': 'SCI-101',
      'time': '09:00 AM – 12:00 PM',
      'maxMarks': 60,
      'room': 'Exam Hall A & B',
    },
    {
      'date': '20 Nov 2026',
      'day': 'Friday',
      'subject': 'Social Science',
      'code': 'SOC-101',
      'time': '09:00 AM – 12:00 PM',
      'maxMarks': 60,
      'room': 'Exam Hall A & B',
    },
    {
      'date': '23 Nov 2026',
      'day': 'Monday',
      'subject': 'English Language & Literature',
      'code': 'ENG-101',
      'time': '09:00 AM – 12:00 PM',
      'maxMarks': 60,
      'room': 'Exam Hall A & B',
    },
    {
      'date': '25 Nov 2026',
      'day': 'Wednesday',
      'subject': 'Hindi Second Language',
      'code': 'HIN-101',
      'time': '09:00 AM – 12:00 PM',
      'maxMarks': 60,
      'room': 'Exam Hall A & B',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Examination Schedule',
      currentRoute: AppRoutes.examinationsSchedule,
      actions: [
        ErpButton(
          label: 'Marks Entry',
          icon: Icons.grading,
          isDense: true,
          onPressed: () => context.go(AppRoutes.examinationsMarks),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Mid-Term Examination Datesheet (AY 2026-2027)',
            subtitle:
                'Session timetable, hall allocations, and examination invigilation slots',
            child: Row(
              children: [
                const Text('Select Standard: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedClass,
                  items: const [
                    DropdownMenuItem(value: '10', child: Text('Class 10')),
                    DropdownMenuItem(value: '9', child: Text('Class 9')),
                    DropdownMenuItem(value: '8', child: Text('Class 8')),
                    DropdownMenuItem(value: '7', child: Text('Class 7')),
                    DropdownMenuItem(value: '6', child: Text('Class 6')),
                  ],
                  onChanged: (v) => setState(() => _selectedClass = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title:
                'Class $_selectedClass Paper Schedule (${_schedule.length} Papers)',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _schedule.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final p = _schedule[idx];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandNavy.withValues(alpha: 0.1),
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandNavy)),
                  ),
                  title: Text('${p['subject']} (${p['code']})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Date: ${p['date']} (${p['day']}) • Timing: ${p['time']}\n'
                      'Center: ${p['room']} • Maximum Marks: ${p['maxMarks']}'),
                  isThreeLine: true,
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Viewing seating arrangement for ${p['subject']}')),
                      );
                    },
                    child: const Text('Seating Plan'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
