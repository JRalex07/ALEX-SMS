import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Library Reports & Circulation Statistics
/// Route: /library/reports
class LibraryReportsScreen extends ConsumerStatefulWidget {
  const LibraryReportsScreen({super.key});

  @override
  ConsumerState<LibraryReportsScreen> createState() =>
      _LibraryReportsScreenState();
}

class _LibraryReportsScreenState extends ConsumerState<LibraryReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(allBooksStreamProvider);
    final activeLoansAsync = ref.watch(activeLoansStreamProvider);

    return ResponsiveScaffold(
      title: 'Library Reports & Analytics',
      currentRoute: AppRoutes.libraryReports,
      actions: [
        ErpButton(
          label: 'Export Circulation CSV',
          icon: Icons.file_download_outlined,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Exporting library circulation data (CSV)...'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Institutional Library Analytics & Resource Utilization',
            subtitle:
                'Circulation frequency, stock preservation, and reader engagement across cohorts',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Cataloged Titles',
                  value: '${booksAsync.value?.length ?? 0} Titles',
                  accentColor: AppColors.brandNavy,
                ),
                MetricItem(
                  label: 'Active Loans',
                  value: '${activeLoansAsync.value?.length ?? 0} Volumes',
                  accentColor: AppColors.tealSuccess,
                ),
                const MetricItem(
                  label: 'Annual Turnover',
                  value: '4.2x / Volume',
                  accentColor: AppColors.infoBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Subject Domain Circulation Breakdown',
            subtitle: 'Demand distribution by category',
            child: Column(
              children: [
                _buildCategoryRow('Science & Technology (STEM)', 0.42, '142 Loans'),
                _buildCategoryRow('Mathematics & Statistics', 0.28, '96 Loans'),
                _buildCategoryRow('English & World Literature', 0.18, '62 Loans'),
                _buildCategoryRow('Social Sciences & History', 0.12, '41 Loans'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, double ratio, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: Text(category,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppColors.surfaceBackground,
              color: AppColors.brandNavy,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
