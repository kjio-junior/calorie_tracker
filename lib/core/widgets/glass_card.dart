import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';

/// The app's standard card: solid themed surface, 1px border, small radius,
/// and a very soft shadow on light themes. (Kept under its old name so every
/// existing screen picks up the new look automatically.)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.blur = 0, // no longer used; kept for compatibility
    this.onTap,
    this.tint,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;

  /// Colour wash over the surface, e.g. to highlight a state.
  final Color? tint;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final shape = BorderRadius.circular(radius);
    final fill = tint == null ? t.surface : Color.alphaBlend(tint!, t.surface);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: shape,
        border: Border.all(color: borderColor ?? t.border),
        boxShadow: t.isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0F101828),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
