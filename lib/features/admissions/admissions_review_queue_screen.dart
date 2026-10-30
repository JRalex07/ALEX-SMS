import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/role_colors.dart';
import '../../providers/feature_providers.dart';
import '../../shared/widgets/erp_components.dart';
import '../../shared/widgets/responsive_scaffold.dart';

/// Dedicated Screen: Admissions Review Queue
/// Route: /admissions/review
class AdmissionsReviewQueueScreen extends ConsumerStatefulWidget {
  const AdmissionsReviewQueueScreen({super.key});

  @override
  ConsumerState<AdmissionsReviewQueueScreen> createState() =>
      _AdmissionsReviewQueueScreenState();
}

class _AdmissionsReviewQueueScreenState
    extends ConsumerState<AdmissionsReviewQueueScreen> {
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
      title: 'Admissions Review Queue',
      currentRoute: AppRoutes.admissionsReview,
      body: enquiriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.admissionsTeal),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (enquiries) {
          final queue = enquiries.where((e) {
            final st = (e['status'] ?? '').toString();
            return st == 'enquiry' || st == 'applied' || st == 'under_review';
          }).toList();

          final q = _searchController.text.trim().toLowerCase();
          final filtered = queue.where((e) {
            final name = (e['applicantName'] ?? '').toString().toLowerCase();
            return q.isEmpty || name.contains(q);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ErpCard(
                title: 'Review Queue Pipeline (${queue.length} Pending Actions)',
                subtitle:
                    'Applications requiring officer screening and academic eligibility checks',
                child: ErpSearchBar(
                  controller: _searchController,
                  hintText: 'Filter review queue by applicant name...',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 24),
              ErpCard(
                title: 'Pending Review Candidates (${filtered.length})',
                child: filtered.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'All submitted applications have been evaluated.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
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
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.warningAmber,
                              child: Icon(Icons.rate_review,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(
                              app['applicantName'] ?? 'Unknown',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                                'Target Class: ${app['targetClass'] ?? "N/A"} • Submitted: ${app['createdAt'] ?? "Recent"}'),
                            trailing: ErpButton(
                              label: 'Start Review',
                              icon: Icons.assignment_outlined,
                              isDense: true,
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
