import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/parent_services_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/parent_child_switcher.dart';
import '../../shared/widgets/responsive_scaffold.dart';

class TransportResourceScreen extends ConsumerStatefulWidget {
  const TransportResourceScreen({super.key});

  @override
  ConsumerState<TransportResourceScreen> createState() =>
      _TransportResourceScreenState();
}

class _TransportResourceScreenState
    extends ConsumerState<TransportResourceScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final isParent = role == UserRoles.parentGuardian;

    final transportAsync = ref.watch(childTransportProvider);

    return ResponsiveScaffold(
      title: 'School Transport & Fleet Route Desk',
      currentRoute: AppRoutes.transport,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (isParent) ...[
            const ParentChildSwitcher(),
            const SizedBox(height: 16),
          ],
          transportAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) => ErpCard(
              title: 'Transport Service Status',
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Transport details unavailable: $err',
                    style: const TextStyle(color: AppColors.dangerRed)),
              ),
            ),
            data: (info) {
              return Column(
                children: [
                  ErpCard(
                    title: 'Allocated Bus Route & Vehicle Profile',
                    subtitle:
                        'Authorized institutional fleet details for current academic term',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor:
                                AppColors.parentBlue.withValues(alpha: 0.1),
                            child: const Icon(Icons.directions_bus,
                                color: AppColors.parentBlue),
                          ),
                          title: Text(
                            'Bus Number: ${info.busNumber}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                          subtitle: Text('Assigned Route: ${info.routeName}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.successGreen
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ACTIVE ROUTE',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.successGreen)),
                          ),
                        ),
                        const Divider(height: 24, color: AppColors.borderLight),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                'Morning Pick-up Stop',
                                info.pickupStop,
                                'Scheduled: ${info.pickupTime}',
                                Icons.access_time,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoItem(
                                'Afternoon Drop Stop',
                                info.dropStop,
                                'Scheduled: ${info.dropTime}',
                                Icons.departure_board,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ErpCard(
                    title: 'Driver & Attendant Safety Contacts',
                    subtitle: 'Direct contact numbers for school transport fleet',
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            title: 'Primary Vehicle Driver',
                            name: info.driverName,
                            phone: info.driverPhone,
                            icon: Icons.person_pin,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildContactCard(
                            title: 'Bus Conductor / Attendant',
                            name: info.conductorName,
                            phone: info.conductorPhone,
                            icon: Icons.support_agent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ErpCard(
                    title: 'Transport Exception / Stop Modification',
                    subtitle:
                        'Submit stop relocation or emergency route change requests',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Need to alter regular pickup or drop stop?',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              SizedBox(height: 2),
                              Text(
                                  'Requires 24-hour advance notice for transport department review.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                          FilledButton.icon(
                            icon: const Icon(Icons.edit_location_alt, size: 16),
                            label: const Text('Request Stop Change'),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.parentBlue),
                            onPressed: _showStopChangeDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
      String label, String value, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.parentBlue),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required String title,
    required String name,
    required String phone,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brandNavy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Helpline: $phone',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.parentBlue)),
        ],
      ),
    );
  }

  Future<void> _showStopChangeDialog() async {
    final stopController = TextEditingController();
    final dateController = TextEditingController(text: '2026-11-01');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Bus Stop Relocation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stopController,
              decoration: const InputDecoration(
                labelText: 'Requested New Stop Location',
                hintText: 'e.g., Gate 3, Green Park Residency',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: 'Effective Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.parentBlue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Stop relocation request submitted to transport administrator.'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}

