import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme/clay_theme.dart';
import 'clay_texture_painter.dart';

/// Universal tactile Claymorphism container supporting raised and inset depths,
/// smooth hover transitions on web/desktop, tactile press feedback, and
/// realistic fine-grained molded clay texture.
class ClayContainer extends StatefulWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final ClayDepth depth;
  final double borderRadius;
  final Color? surfaceColor;
  final Color? accentTint;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool enableHover;
  final bool enableTexture;
  final BoxConstraints? constraints;

  const ClayContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.depth = ClayDepth.medium,
    this.borderRadius = ClayTheme.radiusMd,
    this.surfaceColor,
    this.accentTint,
    this.borderColor,
    this.borderWidth = 1.2,
    this.onTap,
    this.enableHover = true,
    this.enableTexture = true,
    this.constraints,
  });

  @override
  State<ClayContainer> createState() => _ClayContainerState();
}

class _ClayContainerState extends State<ClayContainer> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveDepth = _isPressed
        ? ClayDepth.low
        : (_isHovered ? ClayDepth.high : widget.depth);

    final shadows = ClayTheme.getShadows(
      depth: effectiveDepth,
      accentTint: widget.accentTint,
      isPressed: _isPressed,
    );

    final border = ClayTheme.getBorder(
      borderColor: widget.borderColor,
      width: widget.borderWidth,
    );

    final surfaceColor = widget.surfaceColor ?? ClayTheme.claySurface;
    final r = BorderRadius.circular(widget.borderRadius);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: r,
        border: border,
        boxShadow: shadows,
        gradient: ClayTheme.getSurfaceGradient(baseColor: surfaceColor),
      ),
      child: widget.enableTexture
          ? CustomPaint(
              painter: ClayTexturePainter(
                depth: effectiveDepth,
                borderRadius: widget.borderRadius,
                surfaceColor: surfaceColor,
                accentTint: widget.accentTint,
                isPressed: _isPressed,
                enableTexture: widget.enableTexture,
              ),
              child: widget.child,
            )
          : widget.child,
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        cursor: widget.enableHover && kIsWeb
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) {
          if (widget.enableHover) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (widget.enableHover) setState(() => _isHovered = false);
        },
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return content;
  }
}
