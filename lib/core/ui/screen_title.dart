import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Large page title used at the top of History and Settings.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: t.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
