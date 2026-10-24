import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';
import 'clay_container.dart';

/// Reusable Claymorphism content card with optional header, icon badge, and actions
class ClayCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? headerAction;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final ClayDepth depth;
  final double borderRadius;
  final Color? surfaceColor;
  final Color? accentTint;
  final VoidCallback? onTap;

  const ClayCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.headerAction,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.depth = ClayDepth.medium,
    this.borderRadius = ClayTheme.radiusMd,
    this.surfaceColor,
    this.accentTint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || icon != null || headerAction != null;

    return ClayContainer(
      depth: depth,
      borderRadius: borderRadius,
      surfaceColor: surfaceColor,
      accentTint: accentTint,
      margin: margin,
      padding: padding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Row(
              children: [
                if (icon != null) ...[
                  ClayContainer(
                    depth: ClayDepth.low,
                    borderRadius: ClayTheme.radiusSm,
                    surfaceColor: (iconColor ?? AppColors.brandNavy).withValues(alpha: 0.1),
                    borderColor: (iconColor ?? AppColors.brandNavy).withValues(alpha: 0.25),
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? AppColors.brandNavy,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (headerAction != null) headerAction!,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }
}
