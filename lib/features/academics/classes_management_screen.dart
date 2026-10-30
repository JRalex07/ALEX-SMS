import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Classes Management
/// Route: /academics/classes
class ClassesManagementScreen extends ConsumerStatefulWidget {
  const ClassesManagementScreen({super.key});

  @override
  ConsumerState<ClassesManagementScreen> createState() =>
      _ClassesManagementScreenState();
}

class _ClassesManagementScreenState
    extends ConsumerState<ClassesManagementScreen> {
  final List<Map<String, dynamic>> _classes = [
    {
      'classId': '10',
      'title': 'Class 10 (Secondary Graduation)',
      'sections': ['A', 'B', 'C'],
      'headTeacher': 'Tarun Sharma',
      'enrolledStudents': 84,
      'capacity': 90,
    },
    {
      'classId': '9',
      'title': 'Class 9 (High School)',
      'sections': ['A', 'B'],
      'headTeacher': 'Anita Joshi',
      'enrolledStudents': 58,
      'capacity': 60,
    },
    {
      'classId': '8',
      'title': 'Class 8 (Middle School Senior)',
      'sections': ['A', 'B'],
      'headTeacher': 'Rajesh Gupta',
      'enrolledStudents': 52,
      'capacity': 60,
    },
    {
      'classId': '7',
      'title': 'Class 7 (Middle School Intermediate)',
      'sections': ['A', 'B'],
      'headTeacher': 'Priya Nair',
      'enrolledStudents': 49,
      'capacity': 60,
    },
    {
      'classId': '6',
      'title': 'Class 6 (Middle School Junior)',
      'sections': ['A', 'B'],
      'headTeacher': 'Sunita Rao',
      'enrolledStudents': 46,
      'capacity': 60,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Classes Management',
      currentRoute: AppRoutes.academicsClasses,
      actions: [
        ErpButton(
          label: 'Add New Class',
          icon: Icons.add,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Class creation dialog active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'School Academic Tier Structure',
            subtitle: 'Configured standard levels and class-teacher appointments',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Active Standards',
                  value: '${_classes.length} Classes',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Total Sections',
                  value: '11 Sections',
                  accentColor: AppColors.tealSuccess,
                ),
                const MetricItem(
                  label: 'Total Capacity',
                  value: '330 Seats',
                  accentColor: AppColors.infoBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Grade Standard Directory (${_classes.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _classes.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final c = _classes[idx];
                final sectionsList = (c['sections'] as List<String>).join(', ');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandNavy.withValues(alpha: 0.1),
                    child: Text(
                      c['classId'],
                      style: const TextStyle(
                          color: AppColors.brandNavy,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(c['title'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Sections: $sectionsList • Class Head: ${c['headTeacher']}\n'
                      'Enrolled: ${c['enrolledStudents']} / ${c['capacity']} students'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.view_column_outlined, size: 14),
                        label: const Text('Sections'),
                        onPressed: () =>
                            context.go(AppRoutes.academicsSections),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.people_outline, size: 14),
                        label: const Text('Roster'),
                        onPressed: () => context.go(AppRoutes.students),
                      ),
                    ],
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
