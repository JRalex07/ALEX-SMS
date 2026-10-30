import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';
import '../constants/role_colors.dart';

/// Apple Design System typography specifications, optical tracking,
/// proportional line-heights, and responsive text scaling bounds.
class AppleTypography {
  AppleTypography._();

  // Optical Tracking Tokens (em-based letter spacing)
  static const double trackingDisplay = -0.03;
  static const double trackingTitle = -0.02;
  static const double trackingHeadline = -0.01;
  static const double trackingBody = 0.0;
  static const double trackingSubheadline = 0.01;
  static const double trackingFootnote = 0.02;
  static const double trackingCaption = 0.03;
  static const double trackingBadge = 0.04;

  // Proportional Leading (Line Height multipliers)
  static const double leadingTight = 1.15;
  static const double leadingHeading = 1.25;
  static const double leadingBody = 1.45;
  static const double leadingLoose = 1.55;

  /// Large Display Title (>= 28pt)
  static TextStyle largeTitle({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: 28 * trackingDisplay,
        height: leadingTight,
        color: color,
      );

  /// Primary Screen / Section Title (22pt)
  static TextStyle title1({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 22 * trackingTitle,
        height: leadingHeading,
        color: color,
      );

  /// Subsection / Card Title (18pt)
  static TextStyle title2({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 18 * trackingTitle,
        height: leadingHeading,
        color: color,
      );

  /// Sub-heading (16pt)
  static TextStyle title3({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 16 * trackingTitle,
        height: leadingHeading,
        color: color,
      );

  /// Emphasized Item Header (14-15pt)
  static TextStyle headline({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 15 * trackingHeadline,
        height: 1.35,
        color: color,
      );

  /// Standard Body Text (14pt)
  static TextStyle body({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 14 * trackingBody,
        height: leadingBody,
        color: color,
      );

  /// Semibold Body Text (14pt)
  static TextStyle bodyMedium({Color color = AppColors.textPrimary}) =>
      TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 14 * trackingBody,
        height: leadingBody,
        color: color,
      );

  /// Callout / Action Text (13pt)
  static TextStyle callout({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.0,
        height: 1.35,
        color: color,
      );

  /// Subheadline / Secondary Detail (12pt)
  static TextStyle subheadline({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 12 * trackingSubheadline,
        height: 1.35,
        color: color,
      );

  /// Footnote / Form Helper (11pt)
  static TextStyle footnote({Color color = AppColors.textSecondary}) =>
      TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 11 * trackingFootnote,
        height: 1.30,
        color: color,
      );

  /// Caption / Small Timestamp (10pt)
  static TextStyle caption({Color color = AppColors.textMuted}) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 10 * trackingCaption,
        height: 1.25,
        color: color,
      );

  /// Upper-case Badge / Tag (10pt)
  static TextStyle badge({Color color = AppColors.textPrimary}) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 10 * trackingBadge,
        height: 1.20,
        color: color,
      );

  /// Scales font size within accessible min/max constraints
  static double responsiveSize(
    BuildContext context, {
    required double base,
    double min = 10.0,
    double max = 32.0,
  }) {
    return AppResponsive.responsiveFontSize(context,
        base: base, min: min, max: max);
  }
}

/// Apple Materials & Depth: Translucency, refined dual-layer soft elevation,
/// surface weights, and subtle border highlights.
class AppleMaterials {
  AppleMaterials._();

  // Translucent Material Surfaces (Frosted Acrylic/Glass)
  static const Color ultraThin = Color(0x8CFFFFFF); // ~55% opacity
  static const Color thin = Color(0xB3FFFFFF); // ~70% opacity
  static const Color regular = Color(0xD9FFFFFF); // ~85% opacity
  static const Color thick = Color(0xF2FFFFFF); // ~95% opacity
  static const Color solid = Color(0xFFFFFFFF);

  // Background Canvas Tint (Clean institutional grey-white)
  static const Color canvas = Color(0xFFF6F8FA);
  static const Color cardSurface = Colors.white;

  // Frosted Glass Blur Filters
  static ImageFilter get glassBlur =>
      ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0);
  static ImageFilter get subtleBlur =>
      ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0);

  // Apple Layered Natural Dual Shadows
  static List<BoxShadow> get elevationSubtle => const [
        BoxShadow(
          color: Color(0x060F172A),
          offset: Offset(0, 1),
          blurRadius: 3,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevationCard => const [
        BoxShadow(
          color: Color(0x080F172A),
          offset: Offset(0, 1),
          blurRadius: 4,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Color(0x040F172A),
          offset: Offset(0, 4),
          blurRadius: 12,
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get elevationFloating => const [
        BoxShadow(
          color: Color(0x0A0F172A),
          offset: Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: Color(0x080F172A),
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  // Subtle Border
  static Border get borderSubtle => Border.all(
        color: AppColors.borderLight,
        width: 1.0,
      );

  static Border get borderHighlight => Border.all(
        color: Colors.white.withValues(alpha: 0.6),
        width: 1.0,
      );
}

/// 8pt Grid Spatial Rhythm & Accessible Touch Targets
class AppleSpatial {
  AppleSpatial._();

  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Minimum Human Interface Touch Target (48x48pt)
  static const double minTouchTarget = 48.0;
  static const BoxConstraints touchTargetConstraints = BoxConstraints(
    minWidth: minTouchTarget,
    minHeight: minTouchTarget,
  );

  // Standard Corner Radii
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 20.0;
  static const double radiusPill = 999.0;
}

/// Physical feedback and spring motion parameters
class AppleMotion {
  AppleMotion._();

  static const Duration pressDuration = Duration(milliseconds: 90);
  static const Duration releaseDuration = Duration(milliseconds: 240);
  static const Duration transitionDuration = Duration(milliseconds: 280);

  static const Curve curvePress = Curves.easeOutCubic;
  static const Curve curveRelease = Curves.easeOutBack;
  static const Curve curveTransition = Curves.easeInOutCubic;

  static const double pressScale = 0.98;

  /// Returns true if animations should run, false if user requested reduced motion
  static bool canAnimate(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }
}
