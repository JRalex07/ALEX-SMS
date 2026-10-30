import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/status_badge.dart';

/// Dedicated Screen: Attendance Corrections & Approvals
/// Route: /attendance/corrections
class AttendanceCorrectionsScreen extends ConsumerStatefulWidget {
  const AttendanceCorrectionsScreen({super.key});

  @override
  ConsumerState<AttendanceCorrectionsScreen> createState() =>
      _AttendanceCorrectionsScreenState();
}

class _AttendanceCorrectionsScreenState
    extends ConsumerState<AttendanceCorrectionsScreen> {
  final List<Map<String, dynamic>> _correctionRequests = [
    {
      'id': 'REQ_001',
      'student': 'Rohan Deshmukh',
      'class': 'Class 10-A',
      'date': '24 Oct 2026',
      'fromStatus': 'Absent (A)',
      'toStatus': 'Excused (E)',
      'reason': 'Medical Certificate submitted for viral fever',
      'requestedBy': 'Tarun Sharma (Class Teacher)',
      'status': 'pending',
    },
    {
      'id': 'REQ_002',
      'student': 'Aarav Mehta',
      'class': 'Class 9-B',
      'date': '22 Oct 2026',
      'fromStatus': 'Absent (A)',
      'toStatus': 'Present (P)',
      'reason': 'Late entry due to school bus delay; biometric record verified',
      'requestedBy': 'Rajesh Gupta',
      'status': 'pending',
    },
    {
      'id': 'REQ_003',
      'student': 'Meera Sen',
      'class': 'Class 8-A',
      'date': '20 Oct 2026',
      'fromStatus': 'Late (L)',
      'toStatus': 'Excused (E)',
      'reason': 'Inter-school athletics tournament participation',
      'requestedBy': 'Priya Nair',
      'status': 'approved',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Attendance Corrections & Approvals',
      currentRoute: AppRoutes.attendanceCorrections,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const ErpCard(
            title: 'Attendance Modification & Audit Approval Board',
            subtitle:
                'Statutory audit log of teacher status correction requests and administrative approvals',
            child: ErpMetricStrip(
              metrics: [
                MetricItem(
                  label: 'Pending Approvals',
                  value: '2 Requests',
                  accentColor: AppColors.warningAmber,
                ),
                MetricItem(
                  label: 'Approved This Term',
                  value: '1 Request',
                  accentColor: AppColors.successGreen,
                ),
                MetricItem(
                  label: 'Audit Integrity',
                  value: 'Immutable Firestore Log',
                  accentColor: AppColors.brandNavy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ErpCard(
            title: 'Correction Requests Queue (${_correctionRequests.length})',
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _correctionRequests.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (ctx, idx) {
                final req = _correctionRequests[idx];
                final isPending = req['status'] == 'pending';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPending
                        ? AppColors.warningAmber.withValues(alpha: 0.15)
                        : AppColors.successGreen.withValues(alpha: 0.12),
                    child: Icon(
                      isPending ? Icons.pending_actions : Icons.verified,
                      color: isPending
                          ? AppColors.warningAmber
                          : AppColors.successGreen,
                    ),
                  ),
                  title: Text('${req['student']} (${req['class']})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      'Date: ${req['date']} • Change: ${req['fromStatus']} → ${req['toStatus']}\n'
                      'Reason: ${req['reason']} • Requested by: ${req['requestedBy']}'),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusBadge(
                        label: isPending ? 'PENDING AUDIT' : 'APPROVED',
                        type: isPending
                            ? StatusType.warning
                            : StatusType.success,
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            setState(() => req['status'] = 'approved');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Approved attendance correction for ${req['student']}'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          },
                          child: const Text('Approve'),
                        ),
                      ],
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
