import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'responsive_scaffold.dart';

/// Legacy AppScaffold now delegating to full-featured ResponsiveScaffold
/// with Mobile (<600px), Tablet (600-1023px), and Desktop (>=1024px) support.
class AppScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int selectedNavIndex;
  final ValueChanged<int>? onNavIndexChanged;
  final List<NavigationDestination>? navDestinations;
  final String currentRoute;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.selectedNavIndex = 0,
    this.onNavIndexChanged,
    this.navDestinations,
    this.currentRoute = '/dashboard',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveScaffold(
      title: title,
      body: body,
      actions: actions,
      floatingActionButton: floatingActionButton,
      currentRoute: currentRoute,
      selectedNavIndex: selectedNavIndex,
      onNavIndexChanged: onNavIndexChanged,
      navDestinations: navDestinations,
    );
  }
}
