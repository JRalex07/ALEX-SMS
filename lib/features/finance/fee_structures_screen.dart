import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/dialogs/staff_portal_dialogs.dart';
import '../../shared/widgets/currency_display.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Fee Structures & Heads
/// Route: /fees/structures
class FeeStructuresScreen extends ConsumerStatefulWidget {
  const FeeStructuresScreen({super.key});

  @override
  ConsumerState<FeeStructuresScreen> createState() =>
      _FeeStructuresScreenState();
}

class _FeeStructuresScreenState extends ConsumerState<FeeStructuresScreen> {
  @override
  Widget build(BuildContext context) {
    final structuresAsync = ref.watch(feeStructuresStreamProvider);

    return ResponsiveScaffold(
      title: 'Fee Structures & Heads',
      currentRoute: AppRoutes.feeStructures,
      actions: [
        ErpButton(
          label: 'Create Fee Structure',
          icon: Icons.add,
          isDense: true,
          onPressed: () => CreateFeeStructureDialog.show(context),
        ),
      ],
      body: structuresAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brandNavy),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (structures) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Institutional Tuition & Service Fee Schemas',
                subtitle:
                    'Grade-specific fee components with zero-loss integer paise accounting',
                child: ErpMetricStrip(
                  metrics: [
                    MetricItem(
                      label: 'Configured Plans',
                      value: '${structures.length}',
                      accentColor: AppColors.brandNavy,
                    ),
                    const MetricItem(
                      label: 'Academic Session',
                      value: 'AY 2026-2027',
                      accentColor: AppColors.tealSuccess,
                    ),
                    const MetricItem(
                      label: 'Accounting Standard',
                      value: 'Integer Paise Strict',
                      accentColor: AppColors.warningAmber,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Fee Structure Registry (${structures.length})',
                child: structures.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No fee structures configured.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: structures.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final fs = structures[idx];
                          final totalPaise = fs.components.fold<int>(
                              0, (sum, c) => sum + c.amountPaise);

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.brandNavy.withValues(alpha: 0.1),
                              child: const Icon(Icons.account_balance,
                                  color: AppColors.brandNavy),
                            ),
                            title: Text(fs.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              'Standard: Class ${fs.classId} • Components: ${fs.components.length} heads\n'
                              'Frequency: ${fs.frequency.toUpperCase()} • Year: ${fs.academicYearId}',
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CurrencyDisplay(
                                  amountPaise: totalPaise,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: AppColors.brandNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fs.frequency.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
