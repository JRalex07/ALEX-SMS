import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';

class ClayStatusBadge extends StatelessWidget {
  final String status;
  final String? customLabel;
  final IconData? icon;

  const ClayStatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData defaultIcon;

    final s = status.toLowerCase().trim();
    if (s == 'paid' || s == 'approved' || s == 'finalized' || s == 'enrolled' || s == 'active') {
      bg = AppColors.successBg;
      fg = AppColors.successGreen;
      defaultIcon = Icons.check_circle_outline;
    } else if (s == 'pending' || s == 'draft' || s == 'partial') {
      bg = AppColors.warningBg;
      fg = AppColors.warningAmber;
      defaultIcon = Icons.access_time;
    } else if (s == 'overdue' || s == 'suspended' || s == 'absent' || s == 'inactive') {
      bg = AppColors.dangerBg;
      fg = AppColors.dangerRed;
      defaultIcon = Icons.error_outline;
    } else {
      bg = AppColors.infoBg;
      fg = AppColors.infoSky;
      defaultIcon = Icons.info_outline;
    }

    final label = customLabel ?? status.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(ClayTheme.radiusPill),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: fg.withValues(alpha: 0.08),
            offset: const Offset(1, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? defaultIcon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
