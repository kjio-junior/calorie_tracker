import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// One macronutrient: label, "intake / goal g", and an animated progress bar.
/// With [compact] the label and value are stacked so three bars fit in a row.
class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.compact = false,
  });

  final String label;
  final double value;
  final int goal;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    final progress =
        goal <= 0 ? 0.0 : (value / goal).clamp(0.0, 1.0).toDouble();
    final valueText = '${value.round()} / $goal g';

    final bar = TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 6,
          color: color,
          backgroundColor: color.withValues(alpha: 0.16),
        ),
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall?.copyWith(color: t.textSecondary)),
          const SizedBox(height: 2),
          Text(
            valueText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          bar,
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              valueText,
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        bar,
      ],
    );
  }
}
