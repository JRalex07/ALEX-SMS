import 'package:flutter/material.dart';
import '../../core/constants/role_colors.dart';
import '../../core/utils/currency_formatter.dart';

class CurrencyDisplay extends StatelessWidget {
  final int? amountPaise;
  final TextStyle? style;
  final bool isCompact;
  final Color? color;

  const CurrencyDisplay({
    super.key,
    required this.amountPaise,
    this.style,
    this.isCompact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = isCompact
        ? CurrencyFormatter.formatPaiseCompact(amountPaise)
        : CurrencyFormatter.formatPaiseToInr(amountPaise);

    final defaultStyle = TextStyle(
      color: color ?? AppColors.textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 16,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Text(
      text,
      style: defaultStyle.merge(style),
    );
  }
}
