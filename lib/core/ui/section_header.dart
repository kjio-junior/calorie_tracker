import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

/// Heading that sits between groups of cards.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.top = 24});

  final String title;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(4, top, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: t.textPrimary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
