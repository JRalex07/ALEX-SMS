import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/study_material_item.dart';

/// Dedicated Screen: Study Materials & Digital Repository
/// Route: /academics/materials
class StudyMaterialsScreen extends ConsumerStatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  ConsumerState<StudyMaterialsScreen> createState() =>
      _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends ConsumerState<StudyMaterialsScreen> {
  String _selectedSubject = 'All';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final isTeacher = user?.role == UserRoles.teacher ||
        user?.role == UserRoles.schoolAdmin;

    return ResponsiveScaffold(
      title: 'Study Materials & Repository',
      currentRoute: AppRoutes.academicsMaterials,
      actions: [
        if (isTeacher)
          ErpButton(
            label: 'Upload Material',
            icon: Icons.cloud_upload_outlined,
            isDense: true,
            onPressed: () => context.go(AppRoutes.academicsMaterialsUpload),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Digital Academic Curriculum Repository',
            subtitle:
                'Official teacher lecture notes, syllabus blueprints, practice worksheets, and reference guides',
            child: Row(
              children: [
                const Text('Filter by Subject: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedSubject,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Subjects')),
                    DropdownMenuItem(value: 'Mathematics', child: Text('Mathematics')),
                    DropdownMenuItem(value: 'Science', child: Text('Science')),
                    DropdownMenuItem(value: 'Social Science', child: Text('Social Science')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (v) => setState(() => _selectedSubject = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Curriculum Study Materials',
            subtitle: 'Verified syllabi, practice worksheets, and reference guides',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selectedSubject == 'All' || _selectedSubject == 'Mathematics')
                  StudyMaterialItem(
                    subject: 'Mathematics',
                    title:
                        'Quadratic Equations & Arithmetic Progressions Practice Notes',
                    uploader: 'Tarun Sharma (Faculty)',
                    fileSize: '2.4 MB',
                    fileType: 'PDF',
                    date: '24 Oct 2026',
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Downloading Mathematics study material...')),
                      );
                    },
                  ),
                if (_selectedSubject == 'All' || _selectedSubject == 'Science') ...[
                  StudyMaterialItem(
                    subject: 'Science',
                    title:
                        'Chemical Reactions, Acids, Bases & Salts Master Worksheet',
                    uploader: 'Dr. Anita Joshi (Senior Faculty)',
                    fileSize: '1.8 MB',
                    fileType: 'PDF',
                    date: '22 Oct 2026',
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Downloading Science study material...')),
                      );
                    },
                  ),
                  StudyMaterialItem(
                    subject: 'Science',
                    title:
                        'Life Processes & Control Coordination Laboratory Guide',
                    uploader: 'Science Department',
                    fileSize: '3.2 MB',
                    fileType: 'PDF',
                    date: '18 Oct 2026',
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Downloading Biology study material...')),
                      );
                    },
                  ),
                ],
                if (_selectedSubject == 'All' || _selectedSubject == 'Social Science')
                  StudyMaterialItem(
                    subject: 'Social Science',
                    title:
                        'Nationalism in India & Resource Development Map Workbook',
                    uploader: 'Humanities Department',
                    fileSize: '4.1 MB',
                    fileType: 'PDF',
                    date: '15 Oct 2026',
                    onDownload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Downloading Social Studies workbook...')),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
