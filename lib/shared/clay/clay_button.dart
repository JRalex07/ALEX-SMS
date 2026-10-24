import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';

enum ClayButtonVariant {
  primary,
  secondary,
  outline,
  danger,
  subtle,
}

class ClayButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final ClayButtonVariant variant;
  final Color? customColor;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const ClayButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = ClayButtonVariant.primary,
    this.customColor,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 46.0,
    this.borderRadius = ClayTheme.radiusMd,
    this.padding,
  });

  @override
  State<ClayButton> createState() => _ClayButtonState();
}

class _ClayButtonState extends State<ClayButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (widget.variant) {
      case ClayButtonVariant.primary:
        backgroundColor = widget.customColor ?? AppColors.brandNavy;
        textColor = Colors.white;
        borderColor = Colors.white.withValues(alpha: 0.25);
        break;
      case ClayButtonVariant.secondary:
        backgroundColor = const Color(0xFFE2E8F0);
        textColor = AppColors.textPrimary;
        borderColor = Colors.white.withValues(alpha: 0.9);
        break;
      case ClayButtonVariant.outline:
        backgroundColor = Colors.white;
        textColor = widget.customColor ?? AppColors.brandNavy;
        borderColor =
            (widget.customColor ?? AppColors.brandNavy).withValues(alpha: 0.4);
        break;
      case ClayButtonVariant.danger:
        backgroundColor = AppColors.dangerRed;
        textColor = Colors.white;
        borderColor = Colors.white.withValues(alpha: 0.3);
        break;
      case ClayButtonVariant.subtle:
        backgroundColor = Colors.white.withValues(alpha: 0.7);
        textColor = AppColors.textSecondary;
        borderColor = AppColors.borderLight;
        break;
    }

    if (!isEnabled) {
      backgroundColor = const Color(0xFFCBD5E1);
      textColor = const Color(0xFF94A3B8);
      borderColor = null;
    }

    final effectiveDepth = !isEnabled
        ? ClayDepth.flat
        : (_isPressed
            ? ClayDepth.low
            : (_isHovered ? ClayDepth.high : ClayDepth.medium));

    final shadows = !isEnabled
        ? <BoxShadow>[]
        : ClayTheme.getShadows(
            depth: effectiveDepth,
            accentTint: widget.variant == ClayButtonVariant.primary
                ? widget.customColor ?? AppColors.brandNavy
                : null,
            isPressed: _isPressed,
          );

    Widget content = Container(
      height: widget.height,
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.2)
            : null,
        boxShadow: shadows,
        gradient: isEnabled
            ? ClayTheme.getSurfaceGradient(baseColor: backgroundColor)
            : null,
      ),
      child: Center(
        child: widget.isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisSize:
                    widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(widget.trailingIcon, size: 18, color: textColor),
                  ],
                ],
              ),
      ),
    );

    if (widget.isFullWidth) {
      content = SizedBox(width: double.infinity, child: content);
    }

    if (!isEnabled) return content;

    return MouseRegion(
      cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}
