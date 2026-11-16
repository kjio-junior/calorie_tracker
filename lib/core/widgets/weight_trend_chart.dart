import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/weight_repository.dart';
import '../utils/formatters.dart';

/// Weight line chart: faint raw weigh-ins plus a smoothed 7-entry moving
/// average, so daily water-weight noise doesn't hide the real trend.
class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.entries,
    required this.useLbs,
    required this.color,
    required this.textColor,
    this.height = 190,
    this.maxPoints = 60,
  });

  final List<WeightEntry> entries;
  final bool useLbs;
  final Color color;
  final Color textColor;
  final double height;
  final int maxPoints;

  @override
  Widget build(BuildContext context) {
    final shown = entries.length > maxPoints
        ? entries.sublist(entries.length - maxPoints)
        : entries;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _ChartPainter(
          dates: shown.map((e) => e.date).toList(),
          values: shown.map((e) => Units.fromKg(e.weightKg, useLbs)).toList(),
          color: color,
          textColor: textColor,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.dates,
    required this.values,
    required this.color,
    required this.textColor,
  });

  final List<DateTime> dates;
  final List<double> values;
  final Color color;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const left = 40.0, right = 10.0, top = 10.0, bottom = 24.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    if (hi - lo < 1) {
      hi += 0.5;
      lo -= 0.5;
    }
    final pad = (hi - lo) * 0.15;
    lo -= pad;
    hi += pad;

    final t0 = dates.first.millisecondsSinceEpoch.toDouble();
    final span = math.max(
      1.0,
      dates.last.millisecondsSinceEpoch.toDouble() - t0,
    );

    Offset pointAt(int i, double v) => Offset(
          left + w * ((dates[i].millisecondsSinceEpoch - t0) / span),
          top + h * (1 - (v - lo) / (hi - lo)),
        );

    // Grid + y labels.
    final grid = Paint()
      ..color = textColor.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    for (var i = 0; i <= 2; i++) {
      final y = top + h * i / 2;
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      final v = hi - (hi - lo) * i / 2;
      _drawText(canvas, v.toStringAsFixed(1), Offset(left - 6, y),
          alignRight: true, centerY: true);
    }

    // x labels.
    _drawText(canvas, Fmt.shortDate(dates.first), Offset(left, top + h + 6));
    _drawText(canvas, Fmt.shortDate(dates.last), Offset(left + w, top + h + 6),
        alignRight: true);

    // Raw weigh-ins.
    final rawPts = [for (var i = 0; i < values.length; i++) pointAt(i, values[i])];
    final rawLine = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.3);
    final rawPath = Path()..moveTo(rawPts.first.dx, rawPts.first.dy);
    for (final p in rawPts.skip(1)) {
      rawPath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(rawPath, rawLine);
    final dot = Paint()..color = color.withValues(alpha: 0.6);
    for (final p in rawPts) {
      canvas.drawCircle(p, 3, dot);
    }

    // Moving average (trailing window of 7 entries).
    final trend = <double>[];
    for (var i = 0; i < values.length; i++) {
      final from = math.max(0, i - 6);
      final window = values.sublist(from, i + 1);
      trend.add(window.reduce((a, b) => a + b) / window.length);
    }
    final pts = [for (var i = 0; i < trend.length; i++) pointAt(i, trend[i])];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final mx = (a.dx + b.dx) / 2;
      line.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    final area = Path.from(line)
      ..lineTo(pts.last.dx, top + h)
      ..lineTo(pts.first.dx, top + h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(left, top, w, h)),
    );
    canvas.drawPath(
      line,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  void _drawText(
    Canvas canvas,
    String s,
    Offset at, {
    bool alignRight = false,
    bool centerY = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: 10,
          color: textColor.withValues(alpha: 0.65),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight ? at.dx - tp.width : at.dx;
    final dy = centerY ? at.dy - tp.height / 2 : at.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_ChartPainter old) => true;
}
