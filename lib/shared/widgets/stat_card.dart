import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../clay/clay_stat_card.dart';

/// Upgraded StatCard backed by the Claymorphism design system.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? trend;
  final bool isPositiveTrend;
  final Widget? trailingBadge;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor = AppColors.brandNavy,
    this.onTap,
    this.trend,
    this.isPositiveTrend = true,
    this.trailingBadge,
  });

  @override
  Widget build(BuildContext context) {
    return ClayStatCard(
      title: title,
      value: value,
      subtitle: subtitle,
      icon: icon,
      iconColor: iconColor,
      onTap: onTap,
      trend: trend,
      isPositiveTrend: isPositiveTrend,
      trailingBadge: trailingBadge,
    );
  }
}
