import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/clay_theme.dart';

/// Custom painter that renders authentic, fine-grained molded clay texture,
/// directional diffuse highlights, and subtle molded ambient rim shading.
///
/// Designed to run with zero remote network assets, zero excessive blur,
/// and deterministic single-pass painting for 60/120 FPS performance.
class ClayTexturePainter extends CustomPainter {
  final ClayDepth depth;
  final double borderRadius;
  final Color surfaceColor;
  final Color? accentTint;
  final bool isPressed;
  final bool enableTexture;

  ClayTexturePainter({
    required this.depth,
    required this.borderRadius,
    required this.surfaceColor,
    this.accentTint,
    this.isPressed = false,
    this.enableTexture = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    canvas.clipRRect(rrect);

    final isInset = depth == ClayDepth.inset || isPressed;

    // 1. Directional Tonal Molding (Simulates 3D curved clay surface)
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isInset
            ? [
                (accentTint ?? const Color(0xFF0F172A)).withValues(alpha: 0.05),
                Colors.white.withValues(alpha: 0.4),
              ]
            : [
                Colors.white.withValues(alpha: 0.35),
                (accentTint ?? const Color(0xFF0F172A)).withValues(alpha: 0.03),
              ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(rrect, gradientPaint);

    // 2. Soft Molded Specular Rim (Top-Left Lip Highlight)
    if (!isInset) {
      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x66FFFFFF),
            Color(0x15FFFFFF),
            Color(0x00FFFFFF),
          ],
          stops: [0.0, 0.45, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawRRect(rrect, rimPaint);
    }

    // 3. Fine-grained Microtexture (Irregular, low-contrast matte grain)
    if (enableTexture && ClayTheme.enableMicrotexture) {
      _paintMicrograin(canvas, size);
    }
  }

  void _paintMicrograin(Canvas canvas, Size size) {
    // Ultra-low contrast, subtle matte noise dots
    final grainLight = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final grainDark = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.015)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;

    // Deterministic pseudo-random distribution based on container dimensions
    // to guarantee no jitter during re-renders or scrolling
    const int step = 14;
    final int xSteps = (width / step).ceil();
    final int ySteps = (height / step).ceil();

    final lightPoints = <Offset>[];
    final darkPoints = <Offset>[];

    for (int x = 0; x < xSteps; x++) {
      for (int y = 0; y < ySteps; y++) {
        // Fast hash for deterministic pseudo-random offset
        final hash = (x * 73856093 ^ y * 19349663) & 0x7FFFFFFF;
        final dx = x * step + (hash % 10);
        final dy = y * step + ((hash >> 4) % 10);

        if (dx < width && dy < height) {
          if ((hash & 1) == 0) {
            lightPoints.add(Offset(dx.toDouble(), dy.toDouble()));
          } else if ((hash & 3) == 3) {
            darkPoints.add(Offset(dx.toDouble(), dy.toDouble()));
          }
        }
      }
    }

    if (lightPoints.isNotEmpty) {
      canvas.drawPoints(PointMode.points, lightPoints, grainLight);
    }
    if (darkPoints.isNotEmpty) {
      canvas.drawPoints(PointMode.points, darkPoints, grainDark);
    }
  }

  @override
  bool shouldRepaint(covariant ClayTexturePainter oldDelegate) {
    return oldDelegate.depth != depth ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.accentTint != accentTint ||
        oldDelegate.isPressed != isPressed ||
        oldDelegate.enableTexture != enableTexture;
  }
}
