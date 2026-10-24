import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';
import 'clay_container.dart';

class AdaptiveColumn<T> {
  final String title;
  final Widget Function(T item) cellBuilder;
  final double? flex;
  final double? width;
  final TextAlign textAlign;

  const AdaptiveColumn({
    required this.title,
    required this.cellBuilder,
    this.flex = 1.0,
    this.width,
    this.textAlign = TextAlign.left,
  });
}

/// Adaptive layout component that renders a dense, interactive clay table on
/// desktop/tablet viewports, and automatically transforms into tactile clay cards
/// on compact mobile viewports to prevent horizontal clipping.
class AdaptiveDataView<T> extends StatelessWidget {
  final List<T> items;
  final List<AdaptiveColumn<T>> columns;
  final Widget Function(BuildContext context, T item)? mobileCardBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final Widget? headerAction;
  final double mobileBreakpoint;
  final EdgeInsetsGeometry padding;

  const AdaptiveDataView({
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
      return ClayContainer(
        depth: ClayDepth.low,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
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
          return _buildDesktopTable(context);
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

        // Default mobile card representation using columns
        return ClayContainer(
          depth: ClayDepth.medium,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((col) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
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

  Widget _buildDesktopTable(BuildContext context) {
    return ClayContainer(
      depth: ClayDepth.medium,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ClayTheme.radiusMd),
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
            // Header Row
            TableRow(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(color: AppColors.borderLight, width: 1.5),
                ),
              ),
              children: columns.map((col) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

            // Data Rows
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
    );
  }
}
