import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';

/// Professional School ERP Visual Design Components
/// Clean, structured, high-density enterprise UI components.

class ErpCard extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? headerTrailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const ErpCard({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.headerTrailing,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || icon != null || headerTrailing != null;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            offset: Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (iconColor ?? AppColors.brandNavy)
                            .withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(icon,
                          size: 16, color: iconColor ?? AppColors.brandNavy),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (headerTrailing != null) headerTrailing!,
                ],
              ),
            ),
          ],
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: card,
      );
    }
    return card;
  }
}

class ErpMetricItem {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositive;

  const ErpMetricItem({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    this.color = AppColors.brandNavy,
    this.trend,
    this.isPositive = true,
  });
}

class ErpMetricStrip extends StatelessWidget {
  final List<ErpMetricItem> metrics;

  const ErpMetricStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final isMedium = constraints.maxWidth < 1100;

        if (isCompact) {
          return Column(
            children: metrics
                .map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildMetricTile(m),
                    ))
                .toList(),
          );
        }

        final count = metrics.length;
        return Row(
          children: List.generate(count, (idx) {
            final m = metrics[idx];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: idx < count - 1 ? 12 : 0,
                ),
                child: _buildMetricTile(m, isMedium: isMedium),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMetricTile(ErpMetricItem item, {bool isMedium = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(item.icon, size: 16, color: item.color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (item.subtitle != null || item.trend != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (item.trend != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.isPositive
                          ? AppColors.successBg
                          : AppColors.dangerBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      item.trend!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: item.isPositive
                            ? AppColors.successGreen
                            : AppColors.dangerRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (item.subtitle != null)
                  Expanded(
                    child: Text(
                      item.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class ErpStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const ErpStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory ErpStatusBadge.success(String label, {IconData? icon}) {
    return ErpStatusBadge(
      label: label,
      backgroundColor: AppColors.successBg,
      textColor: AppColors.successGreen,
      icon: icon ?? Icons.check_circle,
    );
  }

  factory ErpStatusBadge.warning(String label, {IconData? icon}) {
    return ErpStatusBadge(
      label: label,
      backgroundColor: AppColors.warningBg,
      textColor: AppColors.warningAmber,
      icon: icon ?? Icons.pending,
    );
  }

  factory ErpStatusBadge.danger(String label, {IconData? icon}) {
    return ErpStatusBadge(
      label: label,
      backgroundColor: AppColors.dangerBg,
      textColor: AppColors.dangerRed,
      icon: icon ?? Icons.error_outline,
    );
  }

  factory ErpStatusBadge.info(String label, {IconData? icon}) {
    return ErpStatusBadge(
      label: label,
      backgroundColor: AppColors.infoBg,
      textColor: AppColors.infoSky,
      icon: icon ?? Icons.info_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class ErpSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final Widget? trailing;

  const ErpSearchBar({
    super.key,
    this.hintText = 'Search records...',
    this.onChanged,
    this.onClear,
    this.controller,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderLight, width: 1),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                hintText: hintText,
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.textSecondary),
                border: InputBorder.none,
                suffixIcon: controller != null && controller!.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 16, color: AppColors.textMuted),
                        onPressed: () {
                          controller!.clear();
                          onClear?.call();
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 10),
          trailing!,
        ],
      ],
    );
  }
}

class ErpButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final Color? color;
  final bool isDestructive;
  final bool isDense;

  const ErpButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isPrimary = true,
    this.color,
    this.isDestructive = false,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isDestructive ? AppColors.dangerRed : (color ?? AppColors.brandNavy);

    if (isPrimary) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? 12 : 16,
            vertical: isDense ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 14 : 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isDense ? 12 : 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    } else {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          side: BorderSide(
              color: effectiveColor.withValues(alpha: 0.4), width: 1),
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? 12 : 16,
            vertical: isDense ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 14 : 16),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: isDense ? 12 : 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
    }
  }
}
