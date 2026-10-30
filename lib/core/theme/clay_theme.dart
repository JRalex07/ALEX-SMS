import 'package:flutter/material.dart';
import '../constants/role_colors.dart';
export 'apple_design_system.dart';

enum ClayDepth {
  inset,
  flat,
  low,
  medium,
  high,
}

class ClayTheme {
  ClayTheme._();

  // Claymorphism Surface Backgrounds
  static const Color clayCanvas = Color(0xFFF1F5F9); // Soft clay slate
  static const Color claySurface = Color(0xFFFFFFFF); // Crisp white clay
  static const Color claySurfaceSubtle = Color(0xFFF8FAFC);
  static const Color claySurfaceInset =
      Color(0xFFEEF2F6); // Shallow recessed field
  static const Color claySurfaceDark = Color(0xFF0F172A);
  static const Color surfaceSoft = Color(0xFFFFFFFF);
  static const Color surfacePressed = Color(0xFFE2E8F0);
  static const Color borderLight = AppColors.borderLight;

  /// Global toggle for fine-grained tactile microtexture (enabled by default;
  /// can be disabled for reduced-contrast or low-power modes)
  static bool enableMicrotexture = true;

  // Corner Radii Tokens - Clean Enterprise Scale
  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;
  static const double radiusXl = 18.0;
  static const double radiusPill = 999.0;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
  static final BorderRadius borderRadiusXl = BorderRadius.circular(radiusXl);
  static final BorderRadius borderRadiusPill =
      BorderRadius.circular(radiusPill);

  // Modern Enterprise Shadows (Subtle, crisp, layered)
  static List<BoxShadow> getShadows({
    ClayDepth depth = ClayDepth.medium,
    Color? accentTint,
    bool isPressed = false,
  }) {
    if (isPressed) {
      return [
        BoxShadow(
          color:
              (accentTint ?? const Color(0xFF0F172A)).withValues(alpha: 0.08),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ];
    }

    switch (depth) {
      case ClayDepth.inset:
        return [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
            spreadRadius: 0,
          ),
        ];

      case ClayDepth.flat:
        return [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ];

      case ClayDepth.low:
        return [
          BoxShadow(
            color:
                (accentTint ?? const Color(0xFF0F172A)).withValues(alpha: 0.04),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ];

      case ClayDepth.medium:
        return [
          BoxShadow(
            color:
                (accentTint ?? const Color(0xFF0F172A)).withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ];

      case ClayDepth.high:
        return [
          BoxShadow(
            color:
                (accentTint ?? const Color(0xFF0F172A)).withValues(alpha: 0.08),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            offset: const Offset(0, 1),
            blurRadius: 3,
          ),
        ];
    }
  }

  // Modern Enterprise Border
  static Border getBorder({
    Color? borderColor,
    double width = 1.0,
    bool isHighlight = false,
  }) {
    return Border.all(
      color: borderColor ?? AppColors.borderLight,
      width: width,
    );
  }

  // Subtle Enterprise Surface Gradient
  static LinearGradient getSurfaceGradient({
    Color? baseColor,
    bool isReverse = false,
  }) {
    final base = baseColor ?? Colors.white;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [base, base],
    );
  }
}
