import 'package:flutter/material.dart';

import '../theme/theme_context.dart';

enum AppButtonKind { primary, secondary, tonal, text, destructive }

/// One button for the whole app, so enabled buttons always look enabled and
/// all of them share height, radius and typography (set in the theme).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.kind = AppButtonKind.primary,
    this.expanded = false,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonKind kind;
  final bool expanded;

  /// Slightly shorter button for tight places such as card headers.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final Widget? ic = icon == null ? null : Icon(icon, size: 20);
    final ButtonStyle? sizeStyle = dense
        ? const ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 40)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 14),
            ),
          )
        : null;

    Widget button;
    switch (kind) {
      case AppButtonKind.primary:
        button = ic == null
            ? FilledButton(
                onPressed: onPressed,
                style: sizeStyle,
                child: Text(label),
              )
            : FilledButton.icon(
                onPressed: onPressed,
                style: sizeStyle,
                icon: ic,
                label: Text(label),
              );
      case AppButtonKind.tonal:
        button = ic == null
            ? FilledButton.tonal(
                onPressed: onPressed,
                style: sizeStyle,
                child: Text(label),
              )
            : FilledButton.tonalIcon(
                onPressed: onPressed,
                style: sizeStyle,
                icon: ic,
                label: Text(label),
              );
      case AppButtonKind.secondary:
        button = ic == null
            ? OutlinedButton(
                onPressed: onPressed,
                style: sizeStyle,
                child: Text(label),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                style: sizeStyle,
                icon: ic,
                label: Text(label),
              );
      case AppButtonKind.text:
        button = ic == null
            ? TextButton(
                onPressed: onPressed,
                style: sizeStyle,
                child: Text(label),
              )
            : TextButton.icon(
                onPressed: onPressed,
                style: sizeStyle,
                icon: ic,
                label: Text(label),
              );
      case AppButtonKind.destructive:
        final style = FilledButton.styleFrom(
          backgroundColor: t.danger,
          foregroundColor: Colors.white,
        );
        button = ic == null
            ? FilledButton(
                onPressed: onPressed,
                style: style,
                child: Text(label),
              )
            : FilledButton.icon(
                onPressed: onPressed,
                style: style,
                icon: ic,
                label: Text(label),
              );
    }

    return expanded
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }
}
