import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/theme/clay_theme.dart';

class ClaySegmentItem {
  final String label;
  final IconData? icon;
  final String? badge;

  const ClaySegmentItem({
    required this.label,
    this.icon,
    this.badge,
  });
}

class ClaySegmentedControl extends StatelessWidget {
  final List<ClaySegmentItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;
  final Color? activeColor;
  final double height;

  const ClaySegmentedControl({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    this.activeColor,
    this.height = 46.0,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? AppColors.brandNavy;

    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(ClayTheme.radiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.2),
        boxShadow: ClayTheme.getShadows(depth: ClayDepth.inset),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == selectedIndex;

          return Expanded(
            child: MouseRegion(
              cursor: kIsWeb ? SystemMouseCursors.click : MouseCursor.defer,
              child: GestureDetector(
                onTap: () => onSelectedIndexChanged(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(ClayTheme.radiusPill),
                    border: isSelected
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.2,
                          )
                        : null,
                    boxShadow: isSelected
                        ? ClayTheme.getShadows(
                            depth: ClayDepth.low,
                            accentTint: active,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.icon != null) ...[
                          Icon(
                            item.icon,
                            size: 16,
                            color: isSelected ? active : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? active : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (item.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? active.withValues(alpha: 0.12)
                                  : AppColors.borderLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? active : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
