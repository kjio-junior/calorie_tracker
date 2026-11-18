import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Compact empty state: small tinted icon plus one line of text.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: t.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: t.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
