import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Document Verification Desk
/// Route: /admissions/verification
class AdmissionsDocumentVerificationScreen extends ConsumerStatefulWidget {
  const AdmissionsDocumentVerificationScreen({super.key});

  @override
  ConsumerState<AdmissionsDocumentVerificationScreen> createState() =>
      _AdmissionsDocumentVerificationScreenState();
}

class _AdmissionsDocumentVerificationScreenState
    extends ConsumerState<AdmissionsDocumentVerificationScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enquiriesAsync = ref.watch(admissionsEnquiriesStreamProvider);

    return ResponsiveScaffold(
      title: 'Document Verification Desk',
      currentRoute: AppRoutes.admissionsVerification,
      body: enquiriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.admissionsTeal),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (enquiries) {
          final query = _searchController.text.trim().toLowerCase();
          final filtered = enquiries.where((e) {
            final name = (e['applicantName'] ?? '').toString().toLowerCase();
            return query.isEmpty || name.contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Mandatory Document Verification Checklist',
                subtitle:
                    'Audit candidate proof of birth, prior school transfer certificates, and identity papers',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Search candidate to verify certificates...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Verification Roster (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text('No applications pending verification.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, color: AppColors.borderLight),
                        itemBuilder: (ctx, idx) {
                          final app = filtered[idx];
                          final id = app['id'] ?? '';
                          final isVerified =
                              app['status'] == 'documents_verified' ||
                                  app['status'] == 'approved' ||
                                  app['status'] == 'enrolled';

                          return ListTile(
                            leading: Icon(
                              isVerified
                                  ? Icons.verified
                                  : Icons.pending_actions_outlined,
                              color: isVerified
                                  ? AppColors.successGreen
                                  : AppColors.warningAmber,
                            ),
                            title: Text(
                              app['applicantName'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Class: ${app['targetClass'] ?? "N/A"} • TC / Birth Certificate Status: ${isVerified ? "Verified" : "Pending Check"}',
                            ),
                            trailing: OutlinedButton.icon(
                              icon: const Icon(Icons.fact_check_outlined,
                                  size: 14),
                              label: Text(
                                  isVerified ? 'Inspect Dossier' : 'Verify'),
                              onPressed: () =>
                                  context.go('${AppRoutes.admissions}/$id'),
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

