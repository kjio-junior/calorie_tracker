import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';

/// Frosted-glass container: blurred backdrop, translucent fill, 1px border.
/// [tint] adds a colour wash on top of the fill and [borderColor] replaces
/// the border, which is handy to highlight important cards.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.blur = 18,
    this.onTap,
    this.tint,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final Color? tint;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final shape = BorderRadius.circular(radius);
    final fill = tint == null ? t.glassFill : Color.alphaBlend(tint!, t.glassFill);

    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: shape,
            border: Border.all(color: borderColor ?? t.glassBorder, width: 1),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: shape,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
