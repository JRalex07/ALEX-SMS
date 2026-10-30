import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Holidays Management
/// Route: /academics/holidays
class HolidaysManagementScreen extends ConsumerStatefulWidget {
  const HolidaysManagementScreen({super.key});

  @override
  ConsumerState<HolidaysManagementScreen> createState() =>
      _HolidaysManagementScreenState();
}

class _HolidaysManagementScreenState
    extends ConsumerState<HolidaysManagementScreen> {
  final List<Map<String, dynamic>> _holidays = [
    {
      'name': 'Diwali / Deepavali Break',
      'fromDate': '01 Nov 2026',
      'toDate': '05 Nov 2026',
      'totalDays': 5,
      'type': 'Gazetted Festival',
    },
    {
      'name': 'Guru Nanak Jayanti',
      'fromDate': '15 Nov 2026',
      'toDate': '15 Nov 2026',
      'totalDays': 1,
      'type': 'Gazetted Holiday',
    },
    {
      'name': 'Christmas & Winter Vacation',
      'fromDate': '24 Dec 2026',
      'toDate': '02 Jan 2027',
      'totalDays': 10,
      'type': 'Institutional Vacation',
    },
    {
      'name': 'Republic Day',
      'fromDate': '26 Jan 2027',
      'toDate': '26 Jan 2027',
      'totalDays': 1,
      'type': 'National Holiday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Holidays & Vacations',
      currentRoute: AppRoutes.academicsHolidays,
      actions: [
        ErpButton(
          label: 'Declare Holiday',
          icon: Icons.add,
          isDense: true,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Holiday declaration form active.')),
            );
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ErpCard(
            title: 'Official Holiday Schedule — AY 2026-2027',
            subtitle:
                'Statutory national holidays, gazetted festivals, and school recess dates',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Configured Holidays',
                  value: '${_holidays.length} Periods',
                  accentColor: AppColors.brandNavy,
                ),
                const MetricItem(
                  label: 'Total Vacation Days',
                  value: '17 Days',
                  accentColor: AppColors.warningAmber,
                ),
                const MetricItem(
                  label: 'Next Holiday',
                  value: 'Diwali (01 Nov)',
                  accentColor: AppColors.tealSuccess,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Institutional Holidays & Closures (${_holidays.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _holidays.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final h = _holidays[idx];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.warningAmber.withValues(alpha: 0.15),
                    child: const Icon(Icons.beach_access,
                        color: AppColors.warningAmber, size: 20),
                  ),
                  title: Text(h['name'],
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Dates: ${h['fromDate']} to ${h['toDate']} (${h['totalDays']} ${h['totalDays'] == 1 ? "day" : "days"})\n'
                      'Classification: ${h['type']}'),
                  isThreeLine: true,
                  trailing: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Holiday circular for ${h['name']}')),
                      );
                    },
                    child: const Text('Circular'),
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
