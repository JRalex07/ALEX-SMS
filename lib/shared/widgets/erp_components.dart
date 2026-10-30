import 'package:flutter/material.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/apple_design_system.dart';

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
        borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppleMaterials.elevationCard,
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
              child: LayoutBuilder(
                builder: (context, headerConstraints) {
                  final isNarrow = headerConstraints.maxWidth < 440;
                  if (isNarrow && headerTrailing != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                                    size: 16,
                                    color: iconColor ?? AppColors.brandNavy),
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: headerTrailing!,
                        ),
                      ],
                    );
                  }

                  return Row(
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
                              size: 16,
                              color: iconColor ?? AppColors.brandNavy),
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
                      if (headerTrailing != null) ...[
                        const SizedBox(width: 10),
                        headerTrailing!,
                      ],
                    ],
                  );
                },
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

typedef MetricItem = ErpMetricItem;
typedef MetricStrip = ErpMetricStrip;

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
    IconData? icon,
    Color? color,
    Color? accentColor,
    this.trend,
    this.isPositive = true,
  })  : icon = icon ?? Icons.insights_rounded,
        color = accentColor ?? color ?? AppColors.brandNavy;
}

class ErpMetricStrip extends StatelessWidget {
  final List<ErpMetricItem> metrics;

  const ErpMetricStrip({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return AdaptiveGrid(
      minTileWidth: 220.0,
      spacing: 12.0,
      runSpacing: 10.0,
      maxColumns: metrics.length,
      children: metrics.map((m) => _buildMetricTile(m)).toList(),
    );
  }

  Widget _buildMetricTile(ErpMetricItem item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppleMaterials.elevationCard,
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
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (item.trend != null)
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
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppleSpatial.radiusPill),
        border: Border.all(color: textColor.withValues(alpha: 0.22), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
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
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
              border: Border.all(color: AppColors.borderLight, width: 1.0),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                hintText: hintText,
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
          minimumSize: Size(isDense ? 40 : 44, isDense ? 36 : 44),
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? 12 : 16,
            vertical: isDense ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleSpatial.radiusMd)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 14 : 16),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isDense ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          minimumSize: Size(isDense ? 40 : 44, isDense ? 36 : 44),
          side: BorderSide(
              color: effectiveColor.withValues(alpha: 0.35), width: 1.2),
          padding: EdgeInsets.symmetric(
            horizontal: isDense ? 12 : 16,
            vertical: isDense ? 8 : 12,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppleSpatial.radiusMd)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: isDense ? 14 : 16),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isDense ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// Enterprise column definition for data tables.
class ErpColumn<T> {
  final String title;
  final Widget Function(T item) cellBuilder;
  final double? flex;
  final double? width;
  final TextAlign textAlign;

  const ErpColumn({
    required this.title,
    required this.cellBuilder,
    this.flex = 1.0,
    this.width,
    this.textAlign = TextAlign.left,
  });
}

/// Adaptive ERP data view component that renders a dense, interactive enterprise table on
/// desktop/tablet viewports, and automatically transforms into crisp, border-outlined ERP cards
/// on compact mobile viewports to prevent horizontal clipping.
class ErpDataView<T> extends StatelessWidget {
  final List<T> items;
  final List<ErpColumn<T>> columns;
  final Widget Function(BuildContext context, T item)? mobileCardBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? headerAction;
  final double mobileBreakpoint;
  final EdgeInsetsGeometry padding;

  const ErpDataView({
    super.key,
    required this.items,
    required this.columns,
    this.mobileCardBuilder,
    this.emptyMessage = 'No records found.',
    this.emptyIcon = Icons.inbox_outlined,
    this.headerAction,
    this.mobileBreakpoint = 768.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(emptyIcon, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < mobileBreakpoint;

        if (isMobile) {
          return _buildMobileCardList(context);
        } else {
          return _buildDesktopTable(context, constraints);
        }
      },
    );
  }

  Widget _buildMobileCardList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = items[index];
        if (mobileCardBuilder != null) {
          return mobileCardBuilder!(ctx, item);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
            border: Border.all(color: AppColors.borderLight, width: 1.0),
            boxShadow: AppleMaterials.elevationSubtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((col) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 110, minWidth: 70),
                      child: Text(
                        col.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: col.cellBuilder(item)),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable(
      BuildContext context, BoxConstraints parentConstraints) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
        border: Border.all(color: AppColors.borderLight, width: 1.0),
        boxShadow: AppleMaterials.elevationCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppleSpatial.radiusMd),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: parentConstraints.maxWidth),
            child: Table(
              columnWidths: {
                for (int i = 0; i < columns.length; i++)
                  if (columns[i].width != null)
                    i: FixedColumnWidth(columns[i].width!)
                  else
                    i: FlexColumnWidth(columns[i].flex ?? 1.0),
              },
              border: TableBorder(
                horizontalInside: BorderSide(
                  color: AppColors.borderLight.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom:
                          BorderSide(color: AppColors.borderLight, width: 1.5),
                    ),
                  ),
                  children: columns.map((col) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Text(
                        col.title.toUpperCase(),
                        textAlign: col.textAlign,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                ...items.map((item) {
                  return TableRow(
                    children: columns.map((col) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: col.textAlign == TextAlign.right
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: col.cellBuilder(item),
                        ),
                      );
                    }).toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
