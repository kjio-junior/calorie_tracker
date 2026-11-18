import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_themes.dart';

/// Which time period the card represents.
enum SharePeriod {
  daily('Today'),
  weekly('This Week'),
  monthly('This Month');

  const SharePeriod(this.label);
  final String label;
}

/// Data bag for the share card – decoupled from controllers so the widget is
/// a pure, stateless renderer (which also makes the RepaintBoundary capture
/// deterministic).
class ShareCardData {
  const ShareCardData({
    required this.name,
    required this.dateLabel,
    required this.period,
    required this.caloriesEaten,
    required this.caloriesBurned,
    required this.calorieTarget,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.streak,
    this.daysLogged,
    this.weightText,
    this.goalWeightText,
    this.weightChangeText,
  });

  final String name;
  final String dateLabel;
  final SharePeriod period;
  final int caloriesEaten;
  final int caloriesBurned;
  final int calorieTarget;
  final double protein;
  final double carbs;
  final double fat;
  final int streak;
  final int? daysLogged;
  final String? weightText;
  final String? goalWeightText;
  final String? weightChangeText;

  bool get isMultiDay => period != SharePeriod.daily;
}

/// Which optional sections to show on the card.
class ShareCardOptions {
  const ShareCardOptions({
    this.showCalories = true,
    this.showMacros = true,
    this.showBurned = true,
    this.showWeight = false,
    this.showStreak = true,
  });

  final bool showCalories;
  final bool showMacros;
  final bool showBurned;
  final bool showWeight;
  final bool showStreak;

  ShareCardOptions copyWith({
    bool? showCalories,
    bool? showMacros,
    bool? showBurned,
    bool? showWeight,
    bool? showStreak,
  }) =>
      ShareCardOptions(
        showCalories: showCalories ?? this.showCalories,
        showMacros: showMacros ?? this.showMacros,
        showBurned: showBurned ?? this.showBurned,
        showWeight: showWeight ?? this.showWeight,
        showStreak: showStreak ?? this.showStreak,
      );
}

/// Instagram-story-sized card (9:16). Rendered off-screen inside a
/// RepaintBoundary to be captured as an image.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.data,
    required this.options,
    required this.theme,
  });

  final ShareCardData data;
  final ShareCardOptions options;
  final AppThemeData theme;

  static const double width = 1080;
  static const double height = 1920;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final multi = data.isMultiDay;

    final bgGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [t.backgroundAlt, t.background, t.surface],
    );

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          children: [
            // ---- subtle accent glow ----
            Positioned(
              top: -200,
              right: -120,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      t.accent.withValues(alpha: 0.18),
                      t.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -180,
              left: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      t.secondary.withValues(alpha: 0.12),
                      t.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // ---- content ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 90),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header
                  Text(
                    data.dateLabel.toUpperCase(),
                    style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    multi ? '${data.period.label} Summary' : 'Daily Summary',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        data.name,
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 30,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (multi && data.daysLogged != null) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: t.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${data.daysLogged} days logged',
                            style: TextStyle(
                              color: t.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 56),

                  // ---- calorie ring ----
                  if (options.showCalories) ...[
                    Center(
                      child: _CalorieRing(
                        eaten: data.caloriesEaten,
                        target: data.calorieTarget,
                        theme: t,
                        isAverage: multi,
                      ),
                    ),
                    const SizedBox(height: 56),
                  ],

                  // ---- burned ----
                  if (options.showBurned)
                    _StatTile(
                      icon: Icons.local_fire_department_rounded,
                      label: multi ? 'Avg burned / day' : 'Burned',
                      value: '${data.caloriesBurned} kcal',
                      theme: t,
                    ),
                  if (options.showBurned) const SizedBox(height: 20),

                  // ---- macros ----
                  if (options.showMacros) ...[
                    _SectionLabel(
                      multi ? 'Avg Macros / Day' : 'Macros',
                      theme: t,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MacroPill(
                            label: 'Protein',
                            grams: data.protein,
                            color: t.protein,
                            theme: t,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _MacroPill(
                            label: 'Carbs',
                            grams: data.carbs,
                            color: t.carbs,
                            theme: t,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _MacroPill(
                            label: 'Fat',
                            grams: data.fat,
                            color: t.fat,
                            theme: t,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ---- weight ----
                  if (options.showWeight) ...[
                    _SectionLabel('Weight', theme: t),
                    const SizedBox(height: 18),
                    if (multi && data.weightChangeText != null)
                      _StatTile(
                        icon: Icons.trending_down_rounded,
                        label: 'Change',
                        value: data.weightChangeText!,
                        theme: t,
                      )
                    else if (!multi && data.weightText != null)
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.monitor_weight_rounded,
                              label: 'Current',
                              value: data.weightText!,
                              theme: t,
                            ),
                          ),
                          if (data.goalWeightText != null) ...[
                            const SizedBox(width: 20),
                            Expanded(
                              child: _StatTile(
                                icon: Icons.flag_rounded,
                                label: 'Goal',
                                value: data.goalWeightText!,
                                theme: t,
                              ),
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 28),
                  ],

                  // ---- streak ----
                  if (options.showStreak && data.streak > 0)
                    _StatTile(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Logging streak',
                      value: '${data.streak} days',
                      theme: t,
                      accentIcon: true,
                    ),

                  const Spacer(),

                  // ---- watermark ----
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: t.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'made by kijo',
                          style: TextStyle(
                            color: t.textSecondary.withValues(alpha: 0.7),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────── inner widgets

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.eaten,
    required this.target,
    required this.theme,
    this.isAverage = false,
  });

  final int eaten;
  final int target;
  final AppThemeData theme;
  final bool isAverage;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final progress = (eaten / target).clamp(0.0, 1.0);
    final remaining = target - eaten;
    final over = remaining < 0;

    return SizedBox(
      width: 320,
      height: 320,
      child: CustomPaint(
        painter: _ShareRingPainter(
          progress: progress,
          color: over ? t.danger : t.accent,
          trackColor: (over ? t.danger : t.accent).withValues(alpha: 0.14),
          strokeWidth: 24,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAverage)
                Text(
                  'AVG',
                  style: TextStyle(
                    color: t.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              Text(
                '$eaten',
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 68,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                isAverage ? 'kcal / day' : (over ? 'kcal over' : 'kcal left'),
                style: TextStyle(color: t.textSecondary, fontSize: 24),
              ),
              const SizedBox(height: 8),
              Text(
                isAverage
                    ? 'target $target'
                    : '$eaten / $target',
                style: TextStyle(
                  color: t.textSecondary.withValues(alpha: 0.7),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareRingPainter extends CustomPainter {
  _ShareRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_ShareRingPainter old) =>
      old.progress != progress || old.color != color;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {required this.theme});

  final String text;
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: theme.textSecondary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
    this.accentIcon = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppThemeData theme;
  final bool accentIcon;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: t.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: accentIcon ? t.warning : t.textSecondary,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: t.textSecondary, fontSize: 20),
              ),
              Text(
                value,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  const _MacroPill({
    required this.label,
    required this.grams,
    required this.color,
    required this.theme,
  });

  final String label;
  final double grams;
  final Color color;
  final AppThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '${grams.round()}g',
            style: TextStyle(
              color: t.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
