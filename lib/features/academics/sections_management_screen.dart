import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Sections Management
/// Route: /academics/sections
class SectionsManagementScreen extends ConsumerStatefulWidget {
  const SectionsManagementScreen({super.key});

  @override
  ConsumerState<SectionsManagementScreen> createState() =>
      _SectionsManagementScreenState();
}

class _SectionsManagementScreenState
    extends ConsumerState<SectionsManagementScreen> {
  String _selectedClass = '10';

  final List<Map<String, dynamic>> _sections = [
    {
      'classId': '10',
      'sectionId': 'A',
      'roomNumber': 'Room 301',
      'classTeacher': 'Tarun Sharma (Mathematics)',
      'studentsCount': 30,
      'capacity': 30,
    },
    {
      'classId': '10',
      'sectionId': 'B',
      'roomNumber': 'Room 302',
      'classTeacher': 'Dr. Anita Joshi (Science)',
      'studentsCount': 28,
      'capacity': 30,
    },
    {
      'classId': '10',
      'sectionId': 'C',
      'roomNumber': 'Room 303',
      'classTeacher': 'Priya Nair (English)',
      'studentsCount': 26,
      'capacity': 30,
    },
    {
      'classId': '9',
      'sectionId': 'A',
      'roomNumber': 'Room 201',
      'classTeacher': 'Sunita Rao (Hindi)',
      'studentsCount': 29,
      'capacity': 30,
    },
    {
      'classId': '9',
      'sectionId': 'B',
      'roomNumber': 'Room 202',
      'classTeacher': 'Rajesh Gupta (Social Science)',
      'studentsCount': 29,
      'capacity': 30,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered =
        _sections.where((s) => s['classId'] == _selectedClass).toList();

    return ResponsiveScaffold(
      title: 'Sections Management',
      currentRoute: AppRoutes.academicsSections,
      actions: [
        ErpButton(
          label: 'Create Section',
          icon: Icons.add,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Section creation modal active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Class Cohort Divisions',
            subtitle:
                'Allocate classrooms, section supervisors, and manage maximum cohort size',
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
            title: 'Sections in Class $_selectedClass (${filtered.length})',
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text('No sections configured for this standard.',
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (ctx, idx) {
                      final s = filtered[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.brandNavy.withValues(alpha: 0.1),
                          child: Text(
                            s['sectionId'],
                            style: const TextStyle(
                                color: AppColors.brandNavy,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        title: Text(
                            'Class ${s['classId']}-${s['sectionId']} (${s['roomNumber']})',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(
                            'Section Supervisor: ${s['classTeacher']}\n'
                            'Strength: ${s['studentsCount']} / ${s['capacity']} students'),
                        isThreeLine: true,
                        trailing: OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Managing Class ${s['classId']}-${s['sectionId']}')),
                            );
                          },
                          child: const Text('Edit Details'),
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
