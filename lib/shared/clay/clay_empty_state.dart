import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';
import 'clay_button.dart';
import 'clay_container.dart';

class ClayEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const ClayEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.brandNavy;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ClayContainer(
          depth: ClayDepth.medium,
          borderRadius: ClayTheme.radiusLg,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClayContainer(
                depth: ClayDepth.low,
                borderRadius: ClayTheme.radiusMd,
                surfaceColor: color.withValues(alpha: 0.1),
                borderColor: color.withValues(alpha: 0.25),
                padding: const EdgeInsets.all(16),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                ClayButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  variant: ClayButtonVariant.primary,
                  customColor: color,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
