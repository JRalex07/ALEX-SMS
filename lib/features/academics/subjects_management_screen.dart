import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Subjects Management
/// Route: /academics/subjects
class SubjectsManagementScreen extends ConsumerStatefulWidget {
  const SubjectsManagementScreen({super.key});

  @override
  ConsumerState<SubjectsManagementScreen> createState() =>
      _SubjectsManagementScreenState();
}

class _SubjectsManagementScreenState
    extends ConsumerState<SubjectsManagementScreen> {
  final List<Map<String, dynamic>> _subjects = [
    {
      'code': 'MTH-101',
      'name': 'Mathematics',
      'category': 'Core STEM',
      'periodsPerWeek': 6,
      'isCompulsory': true,
      'teachers': ['Tarun Sharma', 'K. V. Raman'],
    },
    {
      'code': 'SCI-101',
      'name': 'Science (Physics, Chemistry, Biology)',
      'category': 'Core STEM',
      'periodsPerWeek': 6,
      'isCompulsory': true,
      'teachers': ['Dr. Anita Joshi', 'Vikram Sethi'],
    },
    {
      'code': 'ENG-101',
      'name': 'English Language & Literature',
      'category': 'Languages',
      'periodsPerWeek': 5,
      'isCompulsory': true,
      'teachers': ['Priya Nair'],
    },
    {
      'code': 'SOC-101',
      'name': 'Social Science (History, Civics, Geography)',
      'category': 'Humanities',
      'periodsPerWeek': 5,
      'isCompulsory': true,
      'teachers': ['Rajesh Gupta'],
    },
    {
      'code': 'HIN-101',
      'name': 'Hindi Second Language',
      'category': 'Languages',
      'periodsPerWeek': 4,
      'isCompulsory': true,
      'teachers': ['Sunita Rao'],
    },
    {
      'code': 'CSC-101',
      'name': 'Computer Applications & Coding',
      'category': 'Vocational / IT',
      'periodsPerWeek': 3,
      'isCompulsory': false,
      'teachers': ['Aman Verma'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Subjects Management',
      currentRoute: AppRoutes.academicsSubjects,
      actions: [
        ErpButton(
          label: 'Add Subject',
          icon: Icons.add,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Subject creation form active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Curriculum Subject Master Index',
            subtitle:
                'Core and elective course catalog with weekly period allocations and faculty mappings',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Registered Subjects',
                  value: '${_subjects.length}',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Core Subjects',
                  value: '5 Compulsory',
                  accentColor: AppColors.tealSuccess,
                ),
                const MetricItem(
                  label: 'Weekly Contact Periods',
                  value: '29 Periods',
                  accentColor: AppColors.infoBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Curriculum Subjects Directory (${_subjects.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final sub = _subjects[idx];
                final teachers = (sub['teachers'] as List<String>).join(', ');

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.brandNavy.withValues(alpha: 0.1),
                    child: const Icon(Icons.menu_book,
                        color: AppColors.brandNavy, size: 20),
                  ),
                  title: Text('${sub['name']} (${sub['code']})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Category: ${sub['category']} • ${sub['periodsPerWeek']} periods/week\n'
                      'Authorized Faculty: $teachers'),
                  isThreeLine: true,
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Subject syllabus & syllabus unit details for ${sub['name']}')),
                      );
                    },
                    child: const Text('Syllabus & Units'),
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
