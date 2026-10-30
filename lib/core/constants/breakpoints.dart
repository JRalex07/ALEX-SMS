import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Legacy 3-tier device categorization for backward compatibility with existing tests
enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}

/// Modern 4-tier adaptive responsive classification mandated by the UI/UX blueprint:
/// - Compact: < 600px (Mobile Phones)
/// - Medium: 600px - 1023px (Tablets in portrait or small landscape)
/// - Wide: 1024px - 1439px (Laptops, Desktops, Large Tablets in landscape)
/// - Extra-Wide: >= 1440px (High-resolution monitors, 4K displays)
enum ResponsiveTier {
  compact,
  medium,
  wide,
  extraWide,
}

class AppBreakpoints {
  AppBreakpoints._();

  // Breakpoint thresholds in logical pixels
  static const double compactMax = 599.0;
  static const double mediumMin = 600.0;
  static const double mediumMax = 1023.0;
  static const double wideMin = 1024.0;
  static const double wideMax = 1439.0;
  static const double extraWideMin = 1440.0;

  // Maximum readable content width for ultra-wide displays
  static const double maxContentWidth = 1440.0;
  static const double maxFormWidth = 680.0;
  static const double maxCardWidth = 480.0;

  // Backward compatibility alias constants
  static const double mobileMax = compactMax;
  static const double tabletMin = mediumMin;
  static const double tabletMax = mediumMax;
  static const double desktopMin = wideMin;

  /// Returns legacy 3-tier type (mobile, tablet, desktop)
  static DeviceScreenType getDeviceType(double width) {
    if (width < tabletMin) {
      return DeviceScreenType.mobile;
    } else if (width <= tabletMax) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }

  /// Returns the modern 4-tier responsive category
  static ResponsiveTier getTier(double width) {
    if (width < mediumMin) {
      return ResponsiveTier.compact;
    } else if (width <= mediumMax) {
      return ResponsiveTier.medium;
    } else if (width < extraWideMin) {
      return ResponsiveTier.wide;
    } else {
      return ResponsiveTier.extraWide;
    }
  }

  // --- Context-based convenience queries ---
  static ResponsiveTier tierOf(BuildContext context) =>
      getTier(MediaQuery.sizeOf(context).width);

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mediumMin;

  static bool isMedium(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mediumMin && w <= mediumMax;
  }

  static bool isWide(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= wideMin && w < extraWideMin;
  }

  static bool isExtraWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= extraWideMin;

  // Backward compatibility methods
  static bool isMobile(BuildContext context) => isCompact(context);
  static bool isTablet(BuildContext context) => isMedium(context);
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wideMin;

  // Platform capabilities
  static bool get isWeb => kIsWeb;
  static bool get isMobilePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  static bool get isDesktopPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// Optimal grid columns based on available width
  static int getGridColumnCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    if (width < 1600) return 4;
    return 4;
  }
}

/// Centralized responsive sizing and layout utilities
class AppResponsive {
  AppResponsive._();

  /// Clamps content width between a safe minimum and [AppBreakpoints.maxContentWidth] (1440.0),
  /// without exceeding [availableWidth] (preventing any horizontal overflow).
  static double contentWidth(double availableWidth) {
    if (availableWidth <= 0) return 0;
    return availableWidth.clamp(
      (availableWidth < 320.0 ? availableWidth : 320.0),
      AppBreakpoints.maxContentWidth,
    );
  }

  /// Adaptive horizontal/vertical screen padding based on available width
  static EdgeInsets screenPadding(double availableWidth) {
    if (availableWidth < AppBreakpoints.mediumMin) {
      // Mobile: 16px horizontal, 14px vertical
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    } else if (availableWidth < AppBreakpoints.wideMin) {
      // Tablet: 20px horizontal, 18px vertical
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 18);
    } else {
      // Desktop: 24px horizontal, 20px vertical
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
  }

  /// Adaptive content gap based on available width
  static double gap(double availableWidth) {
    if (availableWidth < AppBreakpoints.mediumMin) return 12.0;
    if (availableWidth < AppBreakpoints.wideMin) return 16.0;
    return 20.0;
  }

  /// Dynamic grid columns: 1 column on < 600px, 2 on < 960px, 3 on < 1300px, 4+ on >= 1300px.
  static int gridColumns(
    double availableWidth, {
    double minTileWidth = 260.0,
    int maxColumns = 4,
  }) {
    if (availableWidth <= 0) return 1;
    final cols = (availableWidth / minTileWidth).floor();
    return cols.clamp(1, maxColumns);
  }

  /// Dialog sizing constraints respecting screen limits and max readable width
  static BoxConstraints dialogConstraints(
    BuildContext context, {
    double maxWidth = 640.0,
    double maxHeightFraction = 0.9,
  }) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final effectiveMaxWidth = screenWidth < (maxWidth + 32)
        ? (screenWidth - 32).clamp(280.0, maxWidth)
        : maxWidth;
    return BoxConstraints(
      minWidth: 0,
      maxWidth: effectiveMaxWidth,
      maxHeight: screenHeight * maxHeightFraction,
    );
  }

  /// Responsive typography that respects system text scaling and applies min/max bounds
  static double responsiveFontSize(
    BuildContext context, {
    required double base,
    double min = 10.0,
    double max = 32.0,
  }) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaled = textScaler.scale(base);
    return scaled.clamp(min, max);
  }
}

/// Adaptive form row that stacks children vertically on compact screens (< 600px)
/// and arranges them in an evenly expanded horizontal Row on wider viewports.
class AdaptiveFormRow extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final bool? isCompact;

  const AdaptiveFormRow({
    super.key,
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 14.0,
    this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    if (isCompact != null) {
      return _buildForCompact(isCompact!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < AppBreakpoints.mediumMin;
        return _buildForCompact(compact);
      },
    );
  }

  Widget _buildForCompact(bool compact) {
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: runSpacing),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Responsive grid that automatically reflows its children into optimal column counts
/// based on available width and minimum tile width, preventing horizontal clipping.
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final double runSpacing;
  final int maxColumns;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 260.0,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cols = AppResponsive.gridColumns(
          availableWidth,
          minTileWidth: minTileWidth,
          maxColumns: maxColumns,
        );

        if (cols <= 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        // Multi-column distribution
        final List<List<Widget>> rows = [];
        for (var i = 0; i < children.length; i += cols) {
          final end = (i + cols < children.length) ? i + cols : children.length;
          rows.add(children.sublist(i, end));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int r = 0; r < rows.length; r++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int c = 0; c < rows[r].length; c++) ...[
                    Expanded(child: rows[r][c]),
                    if (c < rows[r].length - 1) SizedBox(width: spacing),
                  ],
                  // Fill remaining space if last row has fewer items
                  for (int empty = 0; empty < cols - rows[r].length; empty++) ...[
                    if (rows[r].isNotEmpty) SizedBox(width: spacing),
                    const Expanded(child: SizedBox.shrink()),
                  ],
                ],
              ),
              if (r < rows.length - 1) SizedBox(height: runSpacing),
            ],
          ],
        );
      },
    );
  }
}

/// Declarative widget for building responsive UI across the 4 tiers
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) compact;
  final Widget Function(BuildContext context)? medium;
  final Widget Function(BuildContext context)? wide;
  final Widget Function(BuildContext context)? extraWide;

  const ResponsiveBuilder({
    super.key,
    required this.compact,
    this.medium,
    this.wide,
    this.extraWide,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tier = AppBreakpoints.getTier(constraints.maxWidth);
        switch (tier) {
          case ResponsiveTier.compact:
            return compact(context);
          case ResponsiveTier.medium:
            return (medium ?? compact)(context);
          case ResponsiveTier.wide:
            return (wide ?? medium ?? compact)(context);
          case ResponsiveTier.extraWide:
            return (extraWide ?? wide ?? medium ?? compact)(context);
        }
      },
    );
  }
}

/// Content wrapper that prevents excessive horizontal stretching on extra-wide monitors
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Align(
      alignment: alignment,
      child: content,
    );
  }
}
