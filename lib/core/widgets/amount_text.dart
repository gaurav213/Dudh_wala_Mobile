import 'package:flutter/material.dart';

import '../formatters/indian_formatters.dart';
import '../../app/theme/app_theme.dart';

class AmountText extends StatelessWidget {
  const AmountText(this.amount, {super.key, this.style, this.large = false});

  final num amount;
  final TextStyle? style;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final base = large
        ? Theme.of(context).textTheme.headlineSmall
        : Theme.of(context).textTheme.titleMedium;
    return Text(
      formatRupees(amount),
      style: (style ?? base)?.copyWith(
        color: AppColors.leafDark,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
