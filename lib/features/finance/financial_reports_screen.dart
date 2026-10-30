import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Financial Reports & Ledger Aggregations
/// Route: /fees/reports
class FinancialReportsScreen extends ConsumerStatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  ConsumerState<FinancialReportsScreen> createState() =>
      _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends ConsumerState<FinancialReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(allInvoicesStreamProvider);

    return ResponsiveScaffold(
      title: 'Financial Reports',
      currentRoute: AppRoutes.feeReports,
      actions: [
        ErpButton(
          label: 'Export Ledger (CSV)',
          icon: Icons.file_download_outlined,
          isDense: true,
          onPressed: () {
            final invoices = invoicesAsync.value ?? [];
            DataExportService.exportInvoicesCsv(invoices);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Financial ledger exported successfully!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
          },
        ),
      ],
      body: invoicesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (invoices) {
          final totalInvoiced =
              invoices.fold<int>(0, (sum, i) => sum + i.totalAmountPaise);
          final totalCollected =
              invoices.fold<int>(0, (sum, i) => sum + i.paidAmountPaise);
          final totalOutstanding = totalInvoiced - totalCollected;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Institutional Financial Health & Collections Report',
                subtitle:
                    'Fiscal summary for Academic Year 2026-2027 with integer accuracy',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Total Billings',
                      value: '₹${(totalInvoiced / 100).toInt()}',
                      accentColor: AppColors.brandNavy,
                    ),
                    MetricItem(
                      label: 'Net Collections',
                      value: '₹${(totalCollected / 100).toInt()}',
                      accentColor: AppColors.successGreen,
                    ),
                    MetricItem(
                      label: 'Total Outstanding',
                      value: '₹${(totalOutstanding / 100).toInt()}',
                      accentColor: AppColors.dangerRed,
                    ),
                    MetricItem(
                      label: 'Collection Efficiency',
                      value: totalInvoiced > 0
                          ? '${((totalCollected / totalInvoiced) * 100).toStringAsFixed(1)}%'
                          : '100%',
                      accentColor: AppColors.tealSuccess,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Collection Stream Breakdown',
                subtitle: 'Revenue heads by category',
                child: Column(
                  children: [
                    _buildStreamRow('Term Tuition Fees', '₹5,80,000', 0.65),
                    _buildStreamRow('Computer & Science Laboratories', '₹1,20,000', 0.15),
                    _buildStreamRow('Annual Development Fund', '₹95,000', 0.12),
                    _buildStreamRow('Examination & Evaluation Charges', '₹65,000', 0.08),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreamRow(String head, String amount, double ratio) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Text(head, style: const TextStyle(fontWeight: FontWeight.w700)),
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
          Text(amount,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.brandNavy)),
        ],
      ),
    );
  }
}
