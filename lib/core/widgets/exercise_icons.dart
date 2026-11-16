import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/activity.dart';
import '../theme/theme_controller.dart';

/// Body silhouette with the trained muscle group highlighted (custom vector).
class MuscleGroupIcon extends StatelessWidget {
  const MuscleGroupIcon({super.key, required this.group, this.size = 32});

  final MuscleGroup group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MusclePainter(
          group,
          t.accent,
          t.textColor.withValues(alpha: 0.5),
        ),
      ),
    );
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

/// Simple vector icons for each type of equipment.
class EquipmentIcon extends StatelessWidget {
  const EquipmentIcon({super.key, required this.equipment, this.size = 28});

  final Equipment equipment;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EquipmentPainter(
          equipment,
          t.textColor.withValues(alpha: 0.85),
          t.accent,
        ),
      ),
    );
  }
}

class _EquipmentPainter extends CustomPainter {
  _EquipmentPainter(this.equipment, this.ink, this.accent);

  final Equipment equipment;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = ink;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = accent;
    final inkFill = Paint()
      ..style = PaintingStyle.fill
      ..color = ink;

    RRect box(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));

    switch (equipment) {
      case Equipment.barbell:
        canvas.drawLine(const Offset(6, 50), const Offset(94, 50), line);
        canvas.drawRRect(box(20, 24, 9, 52, 3), fill);
        canvas.drawRRect(box(71, 24, 9, 52, 3), fill);
        canvas.drawRRect(box(10, 34, 7, 32, 3), fill);
        canvas.drawRRect(box(83, 34, 7, 32, 3), fill);
      case Equipment.dumbbell:
        canvas.drawLine(const Offset(28, 50), const Offset(72, 50), line);
        canvas.drawRRect(box(10, 28, 18, 44, 5), fill);
        canvas.drawRRect(box(72, 28, 18, 44, 5), fill);
      case Equipment.machine:
        for (var i = 0; i < 4; i++) {
          canvas.drawRRect(box(14, 18 + i * 16.0, 36, 11, 3), fill);
        }
        canvas.drawLine(const Offset(32, 8), const Offset(32, 90), line);
        canvas.drawRRect(box(58, 58, 30, 9, 3), inkFill);
        canvas.drawLine(const Offset(86, 58), const Offset(86, 30), line);
      case Equipment.cable:
        canvas.drawLine(const Offset(50, 6), const Offset(50, 16), line);
        canvas.drawCircle(const Offset(50, 28), 12, line);
        canvas.drawLine(const Offset(38, 28), const Offset(38, 70), line);
        canvas.drawRRect(box(24, 70, 28, 10, 4), fill);
      case Equipment.bodyweight:
        canvas.drawCircle(const Offset(50, 18), 9, line);
        canvas.drawLine(const Offset(50, 28), const Offset(50, 62), line);
        canvas.drawLine(const Offset(50, 36), const Offset(28, 50), line);
        canvas.drawLine(const Offset(50, 36), const Offset(72, 50), line);
        canvas.drawLine(const Offset(50, 62), const Offset(36, 90), line);
        canvas.drawLine(const Offset(50, 62), const Offset(64, 90), line);
      case Equipment.kettlebell:
        canvas.drawCircle(const Offset(50, 62), 26, fill);
        final handle = Path()
          ..moveTo(34, 46)
          ..cubicTo(30, 8, 70, 8, 66, 46);
        canvas.drawPath(handle, line);
    }
  }

  @override
  bool shouldRepaint(_EquipmentPainter old) =>
      old.equipment != equipment || old.ink != ink || old.accent != accent;
}
