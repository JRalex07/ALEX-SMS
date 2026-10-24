import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.success(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.successBg,
      textColor: AppColors.successGreen,
      icon: icon,
    );
  }

  factory StatusBadge.warning(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.warningBg,
      textColor: AppColors.warningAmber,
      icon: icon,
    );
  }

  factory StatusBadge.danger(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.dangerBg,
      textColor: AppColors.dangerRed,
      icon: icon,
    );
  }

  factory StatusBadge.info(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      backgroundColor: AppColors.infoBg,
      textColor: AppColors.infoSky,
      icon: icon,
    );
  }

  factory StatusBadge.attendance(String status) {
    switch (status) {
      case 'P':
        return StatusBadge.success('Present');
      case 'A':
        return StatusBadge.danger('Absent');
      case 'L':
        return StatusBadge.warning('Late');
      case 'E':
        return StatusBadge.info('Excused');
      default:
        return StatusBadge.info(status);
    }
  }

  factory StatusBadge.invoice(String status) {
    switch (status) {
      case 'paid':
        return StatusBadge.success('Paid');
      case 'partially_paid':
        return StatusBadge.warning('Partially Paid');
      case 'unpaid':
        return StatusBadge.info('Unpaid');
      case 'overdue':
        return StatusBadge.danger('Overdue');
      default:
        return StatusBadge.info(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.08),
            offset: const Offset(1, 2),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.85),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
