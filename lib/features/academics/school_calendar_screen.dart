import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: School Calendar & Events
/// Route: /academics/calendar
class SchoolCalendarScreen extends ConsumerStatefulWidget {
  const SchoolCalendarScreen({super.key});

  @override
  ConsumerState<SchoolCalendarScreen> createState() =>
      _SchoolCalendarScreenState();
}

class _SchoolCalendarScreenState extends ConsumerState<SchoolCalendarScreen> {
  final List<Map<String, dynamic>> _events = [
    {
      'title': 'Mid-Term Examinations Commences',
      'date': '15 Nov 2026',
      'type': 'Examination',
      'audience': 'Classes 6 to 10',
      'color': AppColors.dangerRed,
    },
    {
      'title': 'Annual Science & Tech Fair 2026',
      'date': '28 Nov 2026',
      'type': 'Co-Curricular',
      'audience': 'All Students & Parents',
      'color': AppColors.infoBlue,
    },
    {
      'title': 'Parent-Teacher Conference (Term 1)',
      'date': '05 Dec 2026',
      'type': 'Institutional',
      'audience': 'Parents of All Classes',
      'color': AppColors.tealSuccess,
    },
    {
      'title': 'Winter Sports Meet 2026',
      'date': '18 Dec 2026',
      'type': 'Sports & Athletics',
      'audience': 'All Houses & Students',
      'color': AppColors.warningAmber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'School Calendar',
      currentRoute: AppRoutes.academicsCalendar,
      actions: [
        ErpButton(
          label: 'Add School Event',
          icon: Icons.event,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Calendar event scheduler active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Institutional Academic Calendar — AY 2026-2027',
            subtitle:
                'Key academic milestones, term assessments, inspections, and events',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Scheduled Events',
                  value: '${_events.length} Upcoming',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Next Milestone',
                  value: 'Mid-Term Exams',
                  accentColor: AppColors.dangerRed,
                ),
                const MetricItem(
                  label: 'Current Academic Term',
                  value: 'Term 1 / 3',
                  accentColor: AppColors.tealSuccess,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Upcoming Academic & School Milestones (${_events.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _events.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final ev = _events[idx];
                final color = ev['color'] as Color;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(Icons.event_note, color: color, size: 20),
                  ),
                  title: Text(ev['title'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Date: ${ev['date']} • Category: ${ev['type']} • Target: ${ev['audience']}'),
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Viewing event details for ${ev['title']}')),
                      );
                    },
                    child: const Text('View Notice'),
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
