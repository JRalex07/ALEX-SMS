import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';
import '../../providers/auth_providers.dart';
import '../clay/clay_container.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final List<String> allowedRoles;

  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.allowedRoles,
  });
}

class ResponsiveScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final String currentRoute;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final List<NavigationDestination>? navDestinations;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentRoute = '/dashboard',
    this.selectedNavIndex = 0,
    this.onNavIndexChanged,
    this.navDestinations,
  });

  static const List<NavItem> _allNavItems = [
    NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      route: '/dashboard',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.accountant,
        UserRoles.admissionsOfficer,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Attendance',
      icon: Icons.how_to_reg_outlined,
      selectedIcon: Icons.how_to_reg,
      route: '/attendance',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Academics',
      icon: Icons.menu_book_outlined,
      selectedIcon: Icons.menu_book,
      route: '/academics',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Fee Management',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      route: '/fees',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.accountant,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Students',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/students',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.admissionsOfficer,
        UserRoles.teacher,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Library',
      icon: Icons.local_library_outlined,
      selectedIcon: Icons.local_library,
      route: '/library',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.librarian,
        UserRoles.teacher,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Notices',
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign,
      route: '/notices',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.accountant,
        UserRoles.admissionsOfficer,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
    NavItem(
      label: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      route: '/settings',
      allowedRoles: [
        UserRoles.schoolAdmin,
        UserRoles.teacher,
        UserRoles.accountant,
        UserRoles.admissionsOfficer,
        UserRoles.librarian,
        UserRoles.parentGuardian,
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRoles.parentGuardian;
    final roleColor = AppColors.getRoleColor(role);
    final roleDisplayName = UserRoles.getRoleDisplayName(role);
    final isMobile = AppBreakpoints.isMobile(context);
    final isTablet = AppBreakpoints.isTablet(context);

    // Filter permitted navigation destinations for current user role
    final permittedItems =
        _allNavItems.where((item) => item.allowedRoles.contains(role)).toList();

    int selectedRouteIndex =
        permittedItems.indexWhere((item) => item.route == currentRoute);
    if (selectedRouteIndex < 0) selectedRouteIndex = 0;

    const isWebPlatform = kIsWeb;

    if (isMobile) {
      return _buildMobileLayout(
        context: context,
        ref: ref,
        role: role,
        roleColor: roleColor,
        roleDisplayName: roleDisplayName,
        userEmail: user?.email ?? user?.displayName ?? 'Verified User',
        permittedItems: permittedItems,
        selectedRouteIndex: selectedRouteIndex,
        isWeb: isWebPlatform,
      );
    } else if (isTablet) {
      return _buildTabletLayout(
        context: context,
        ref: ref,
        role: role,
        roleColor: roleColor,
        roleDisplayName: roleDisplayName,
        userEmail: user?.email ?? user?.displayName ?? 'Verified User',
        permittedItems: permittedItems,
        selectedRouteIndex: selectedRouteIndex,
        isWeb: isWebPlatform,
      );
    } else {
      return _buildDesktopLayout(
        context: context,
        ref: ref,
        role: role,
        roleColor: roleColor,
        roleDisplayName: roleDisplayName,
        userEmail: user?.email ?? user?.displayName ?? 'Verified User',
        permittedItems: permittedItems,
        selectedRouteIndex: selectedRouteIndex,
        isWeb: isWebPlatform,
      );
    }
  }

  // --- 1. MOBILE FORM FACTOR (<600px) ---
  Widget _buildMobileLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
    bool isWeb = false,
  }) {
    final hasSubTabs = navDestinations != null && navDestinations!.isNotEmpty;

    return Scaffold(
      backgroundColor: ClayTheme.clayCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    roleDisplayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: ClayTheme.clayCanvas,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.brandNavy,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.brandNavy,
                    AppColors.brandNavyDark,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ClayContainer(
                    depth: ClayDepth.low,
                    borderRadius: ClayTheme.radiusSm,
                    surfaceColor: Colors.white.withValues(alpha: 0.15),
                    borderColor: Colors.white.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(8),
                    child:
                        const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isWeb ? 'LAV Academy • Web Portal' : 'LAV Academy SMS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ...permittedItems.map((item) {
              final isSelected = item.route == currentRoute;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: ClayContainer(
                  depth: isSelected ? ClayDepth.low : ClayDepth.flat,
                  surfaceColor: isSelected
                      ? roleColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderColor: isSelected
                      ? roleColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                  borderRadius: ClayTheme.radiusSm,
                  onTap: () {
                    Navigator.pop(context);
                    if (item.route != currentRoute) {
                      context.go(item.route);
                    }
                  },
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? item.selectedIcon : item.icon,
                      color: isSelected ? roleColor : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? roleColor : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.dangerRed),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: AppColors.dangerRed, fontWeight: FontWeight.w700)),
              onTap: () {
                Navigator.pop(context);
                _confirmSignOut(context, ref);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: body,
      ),
      bottomNavigationBar: hasSubTabs
          ? NavigationBar(
              selectedIndex: selectedNavIndex,
              onDestinationSelected: onNavIndexChanged,
              destinations: navDestinations!,
              backgroundColor: Colors.white,
              indicatorColor: roleColor.withValues(alpha: 0.14),
              elevation: 4,
            )
          : (permittedItems.length > 1
              ? NavigationBar(
                  selectedIndex:
                      selectedRouteIndex < permittedItems.take(4).length
                          ? selectedRouteIndex
                          : 0,
                  onDestinationSelected: (idx) {
                    final target = permittedItems.take(4).toList()[idx];
                    if (target.route != currentRoute) {
                      context.go(target.route);
                    }
                  },
                  destinations: permittedItems
                      .take(4)
                      .map((item) => NavigationDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: item.label,
                          ))
                      .toList(),
                  backgroundColor: Colors.white,
                  indicatorColor: roleColor.withValues(alpha: 0.14),
                  elevation: 4,
                )
              : null),
      floatingActionButton: floatingActionButton,
    );
  }

  // --- 2. TABLET FORM FACTOR (600px - 1023px) ---
  Widget _buildTabletLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
    bool isWeb = false,
  }) {
    final hasSubTabs = navDestinations != null && navDestinations!.isNotEmpty;

    return Scaffold(
      backgroundColor: ClayTheme.clayCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.3,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ClayTheme.radiusPill),
                border: Border.all(color: roleColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                roleDisplayName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: roleColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ...?actions,
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout,
                size: 20, color: AppColors.textSecondary),
            onPressed: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // Tactile NavigationRail for Tablet
          NavigationRail(
            selectedIndex: selectedRouteIndex,
            onDestinationSelected: (idx) {
              final target = permittedItems[idx];
              if (target.route != currentRoute) {
                context.go(target.route);
              }
            },
            labelType: NavigationRailLabelType.selected,
            backgroundColor: Colors.white,
            indicatorColor: roleColor.withValues(alpha: 0.16),
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ClayContainer(
                depth: ClayDepth.low,
                borderRadius: ClayTheme.radiusSm,
                surfaceColor: AppColors.brandNavy,
                padding: EdgeInsets.all(8),
                child: Icon(Icons.school, size: 22, color: Colors.white),
              ),
            ),
            destinations: permittedItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon, color: roleColor),
                      label: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: roleColor,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: AppColors.borderLight),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  if (hasSubTabs)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      color: Colors.white,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              List.generate(navDestinations!.length, (idx) {
                            final dest = navDestinations![idx];
                            final isSel = idx == selectedNavIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(dest.label),
                                selected: isSel,
                                selectedColor:
                                    roleColor.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  fontWeight:
                                      isSel ? FontWeight.w800 : FontWeight.w600,
                                  color:
                                      isSel ? roleColor : AppColors.textPrimary,
                                ),
                                onSelected: (_) => onNavIndexChanged?.call(idx),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  // --- 3. DESKTOP & WIDE FORM FACTOR (>=1024px) ---
  Widget _buildDesktopLayout({
    required BuildContext context,
    required WidgetRef ref,
    required String role,
    required Color roleColor,
    required String roleDisplayName,
    required String userEmail,
    required List<NavItem> permittedItems,
    required int selectedRouteIndex,
    bool isWeb = false,
  }) {
    final hasSubTabs = navDestinations != null && navDestinations!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 260px Modern School ERP Enterprise Sidebar
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppColors.borderLight, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x060F172A),
                  offset: Offset(1, 0),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Institutional Branding Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.brandNavy,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A1E3A8A),
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.school, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LAV Academy',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            Text(
                              isWeb ? 'SMS • Web Portal' : 'SMS • AY 2026-27',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Authenticated Identity Profile Box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                roleDisplayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AY 2026-27',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'INSTITUTIONAL MODULES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: permittedItems.map((item) {
                      final isSelected = item.route == currentRoute;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Material(
                          color: isSelected
                              ? roleColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () {
                              if (item.route != currentRoute) {
                                context.go(item.route);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    size: 18,
                                    color: isSelected
                                        ? roleColor
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? roleColor
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 4,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: roleColor,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Bottom End Session Action
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, size: 16),
                      label: const Text('End Session'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderLight),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () => _confirmSignOut(context, ref),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Desktop Main Workspace Area
          Expanded(
            child: Column(
              children: [
                // Desktop Header Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: AppColors.borderLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'LAV Academy / $roleDisplayName',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (hasSubTabs) ...[
                        const SizedBox(width: 24),
                        Row(
                          children:
                              List.generate(navDestinations!.length, (idx) {
                            final dest = navDestinations![idx];
                            final isSel = idx == selectedNavIndex;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () => onNavIndexChanged?.call(idx),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? roleColor.withValues(alpha: 0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSel
                                          ? roleColor.withValues(alpha: 0.3)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    dest.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSel
                                          ? roleColor
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                      const Spacer(),
                      ...?actions,
                    ],
                  ),
                ),

                // Desktop Content Area
                Expanded(
                  child: Container(
                    color: const Color(0xFFF8FAFC),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppBreakpoints.maxContentWidth,
                        ),
                        child: body,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Session Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? Your authenticated session will be terminated and cached sensitive records cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.dangerRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
