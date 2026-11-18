import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

class OfflineBadge extends StatelessWidget {
  const OfflineBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: t.warning.withValues(alpha: 0.14),
        border: Border.all(color: t.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 14, color: t.warning),
          const SizedBox(width: 6),
          Text(
            'Offline',
            style: text.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
