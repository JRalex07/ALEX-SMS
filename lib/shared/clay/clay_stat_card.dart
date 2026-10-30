import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';
import 'clay_container.dart';

/// Tactile Claymorphism Metric Card for Dashboards across Web, Tablet, and Mobile.
class ClayStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? trend;
  final bool isPositiveTrend;
  final Widget? trailingBadge;

  const ClayStatCard({
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
    return ClayContainer(
      depth: ClayDepth.medium,
      borderRadius: ClayTheme.radiusMd,
      accentTint: iconColor,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppleTypography.callout(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 8),
              ClayContainer(
                depth: ClayDepth.low,
                borderRadius: ClayTheme.radiusSm,
                surfaceColor: iconColor.withValues(alpha: 0.12),
                borderColor: iconColor.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(9),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppleTypography.largeTitle(color: AppColors.textPrimary),
            ),
          ),
          if (subtitle != null || trend != null || trailingBadge != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trend != null) ...[
                  ClayContainer(
                    depth: ClayDepth.inset,
                    borderRadius: ClayTheme.radiusPill,
                    surfaceColor: isPositiveTrend
                        ? AppColors.successBg
                        : AppColors.dangerBg,
                    borderColor: (isPositiveTrend
                            ? AppColors.successGreen
                            : AppColors.dangerRed)
                        .withValues(alpha: 0.3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveTrend
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 11,
                          color: isPositiveTrend
                              ? AppColors.successGreen
                              : AppColors.dangerRed,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          trend!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isPositiveTrend
                                ? AppColors.successGreen
                                : AppColors.dangerRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (trailingBadge != null) trailingBadge!,
              ],
            ),
          ],
        ],
      ),
    );
  }
}
