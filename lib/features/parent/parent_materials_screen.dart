import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/child_context_provider.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/study_material_item.dart';

/// Dedicated Screen: Parent Study Materials Portal
/// Route: /parent/materials
class ParentMaterialsScreen extends ConsumerWidget {
  const ParentMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    return ResponsiveScaffold(
      title: "Child's Study Materials & Syllabi",
      currentRoute: AppRoutes.parentMaterials,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ParentChildSwitcher(),
          const SizedBox(height: 20),
          ErpCard(
            title: 'Curriculum Study Materials',
            subtitle: selectedChild != null
                ? 'Subject notes & blueprints for ${selectedChild.fullName} (Class ${selectedChild.currentClassId})'
                : 'Select child above',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                          content: Text('Downloading Social Studies workbook...')),
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
