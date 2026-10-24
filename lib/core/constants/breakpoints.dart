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
