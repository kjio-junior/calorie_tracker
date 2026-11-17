import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/activity.dart';
import '../theme/theme_controller.dart';

/// Rounded tinted square that gives every icon the same look and size.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.17),
      decoration: BoxDecoration(
        color: t.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: t.accent.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

/// Body silhouette with the trained muscle group highlighted (custom vector).
/// With [badge] it sits in the same tinted square as [EquipmentIcon].
class MuscleGroupIcon extends StatelessWidget {
  const MuscleGroupIcon({
    super.key,
    required this.group,
    this.size = 32,
    this.badge = false,
  });

  final MuscleGroup group;
  final double size;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final paint = CustomPaint(
      painter: _MusclePainter(
        group,
        t.accent,
        t.textColor.withValues(alpha: 0.5),
      ),
    );
    if (!badge) return SizedBox(width: size, height: size, child: paint);
    return _IconBadge(size: size, child: paint);
  }
}

class _MusclePainter extends CustomPainter {
  _MusclePainter(this.group, this.color, this.outlineColor);

  final MuscleGroup group;
  final Color color;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = outlineColor;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    RRect box(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    final torso = Path()
      ..moveTo(32, 28)
      ..lineTo(68, 28)
      ..lineTo(62, 64)
      ..lineTo(38, 64)
      ..close();
    final upperL = box(19, 28, 9, 24, 4.5);
    final upperR = box(72, 28, 9, 24, 4.5);
    final foreL = box(17, 54, 8, 24, 4);
    final foreR = box(75, 54, 8, 24, 4);
    final legL = box(37, 66, 12, 32, 5);
    final legR = box(51, 66, 12, 32, 5);

    switch (group) {
      case MuscleGroup.chest:
        canvas.drawRRect(box(33, 30, 16, 13, 5), fill);
        canvas.drawRRect(box(51, 30, 16, 13, 5), fill);
      case MuscleGroup.back:
        canvas.drawPath(
          torso,
          Paint()
            ..style = PaintingStyle.fill
            ..color = color.withValues(alpha: 0.55),
        );
        canvas.drawLine(
          const Offset(50, 28),
          const Offset(50, 64),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      case MuscleGroup.legs:
        canvas.drawRRect(legL, fill);
        canvas.drawRRect(legR, fill);
      case MuscleGroup.shoulders:
        canvas.drawCircle(const Offset(27, 32), 8, fill);
        canvas.drawCircle(const Offset(73, 32), 8, fill);
      case MuscleGroup.arms:
        canvas.drawRRect(upperL, fill);
        canvas.drawRRect(upperR, fill);
        canvas.drawRRect(foreL, fill);
        canvas.drawRRect(foreR, fill);
      case MuscleGroup.core:
        canvas.drawRRect(box(41, 45, 18, 19, 4), fill);
    }

    canvas.drawCircle(const Offset(50, 13), 8, outline);
    canvas.drawPath(torso, outline);
    for (final r in [upperL, upperR, foreL, foreR, legL, legR]) {
      canvas.drawRRect(r, outline);
    }
  }

  @override
  bool shouldRepaint(_MusclePainter old) =>
      old.group != group ||
      old.color != color ||
      old.outlineColor != outlineColor;
}

/// Equipment icons: one stroke width, one colour, one size, one badge, so
/// the whole set looks like a matching family.
class EquipmentIcon extends StatelessWidget {
  const EquipmentIcon({super.key, required this.equipment, this.size = 40});

  final Equipment equipment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    return _IconBadge(
      size: size,
      child: CustomPaint(painter: _EquipmentPainter(equipment, t.accent)),
    );
  }
}

class _EquipmentPainter extends CustomPainter {
  _EquipmentPainter(this.equipment, this.color);

  final Equipment equipment;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    RRect box(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    switch (equipment) {
      case Equipment.barbell:
        canvas.drawLine(const Offset(6, 50), const Offset(94, 50), line);
        canvas.drawRRect(box(22, 24, 11, 52, 4), line);
        canvas.drawRRect(box(67, 24, 11, 52, 4), line);
      case Equipment.dumbbell:
        canvas.drawLine(const Offset(28, 50), const Offset(72, 50), line);
        canvas.drawRRect(box(8, 30, 20, 40, 7), line);
        canvas.drawRRect(box(72, 30, 20, 40, 7), line);
      case Equipment.machine:
        canvas.drawRRect(box(8, 14, 36, 14, 4), line);
        canvas.drawRRect(box(8, 43, 36, 14, 4), line);
        canvas.drawRRect(box(8, 72, 36, 14, 4), line);
        canvas.drawLine(const Offset(26, 6), const Offset(26, 94), line);
        canvas.drawLine(const Offset(58, 72), const Offset(92, 72), line);
        canvas.drawLine(const Offset(92, 72), const Offset(92, 30), line);
      case Equipment.cable:
        canvas.drawLine(const Offset(50, 6), const Offset(50, 14), line);
        canvas.drawCircle(const Offset(50, 28), 14, line);
        canvas.drawLine(const Offset(36, 28), const Offset(36, 68), line);
        canvas.drawRRect(box(22, 68, 28, 16, 6), line);
      case Equipment.bodyweight:
        canvas.drawCircle(const Offset(50, 20), 10, line);
        canvas.drawLine(const Offset(50, 31), const Offset(50, 62), line);
        canvas.drawLine(const Offset(50, 40), const Offset(26, 56), line);
        canvas.drawLine(const Offset(50, 40), const Offset(74, 56), line);
        canvas.drawLine(const Offset(50, 62), const Offset(34, 92), line);
        canvas.drawLine(const Offset(50, 62), const Offset(66, 92), line);
      case Equipment.kettlebell:
        canvas.drawCircle(const Offset(50, 64), 26, line);
        final handle = Path()
          ..moveTo(36, 42)
          ..cubicTo(28, 6, 72, 6, 64, 42);
        canvas.drawPath(handle, line);
    }
  }

  @override
  bool shouldRepaint(_EquipmentPainter old) =>
      old.equipment != equipment || old.color != color;
}
