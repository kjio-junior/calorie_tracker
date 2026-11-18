import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import '../../core/theme/theme_context.dart';
import '../../core/utils/formatters.dart';
import '../../data/period_stats_service.dart';
import '../../state/activity_controller.dart';
import '../../state/food_controller.dart';
import '../../state/profile_controller.dart';
import 'share_card.dart';

/// Bottom sheet that shows a live preview of the share card with toggles
/// for each section and a period selector, then captures and shares as PNG.
class ShareSheet extends StatefulWidget {
  const ShareSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const ShareSheet._(),
    );
  }

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _repaintKey = GlobalKey();
  var _options = const ShareCardOptions();
  var _period = SharePeriod.daily;
  var _sharing = false;

  // Cached period stats for weekly/monthly.
  PeriodStats? _periodStats;
  bool _loadingStats = false;

  @override
  void initState() {
    super.initState();
    // No need to load anything for daily – it comes from controllers.
  }

  /// Build daily data directly from the in-memory controllers.
  ShareCardData _buildDailyData(BuildContext context) {
    final food = context.read<FoodController>();
    final activity = context.read<ActivityController>();
    final pc = context.read<ProfileController>();
    final profile = pc.profile!;
    final targets = pc.targets!;
    final useLbs = profile.useLbs;
    final currentKg = pc.currentKg ?? pc.startKg;

    return ShareCardData(
      name: profile.name,
      dateLabel: Fmt.shortDate(DateTime.now()),
      period: SharePeriod.daily,
      caloriesEaten: food.calories.round(),
      caloriesBurned: activity.burnedToday.round(),
      calorieTarget: targets.calorieTarget,
      protein: food.protein,
      carbs: food.carbs,
      fat: food.fat,
      streak: food.streaks.logging,
      weightText: Units.weight(currentKg, useLbs),
      goalWeightText: Units.weight(profile.goalWeightKg, useLbs),
    );
  }

  /// Build weekly/monthly data from pre-fetched [PeriodStats].
  ShareCardData _buildPeriodData(
      BuildContext context, PeriodStats stats) {
    final pc = context.read<ProfileController>();
    final food = context.read<FoodController>();
    final profile = pc.profile!;
    final useLbs = profile.useLbs;

    String? weightChangeText;
    final change = stats.weightChange;
    if (change != null) {
      final v = Units.fromKg(change.abs(), useLbs);
      final sign = change <= 0 ? '↓' : '↑';
      weightChangeText =
          '$sign ${v.toStringAsFixed(1)} ${Units.unit(useLbs)}';
    }

    return ShareCardData(
      name: profile.name,
      dateLabel: stats.dateRangeLabel,
      period: _period,
      caloriesEaten: stats.avgCalories,
      caloriesBurned: stats.avgBurned,
      calorieTarget: stats.avgCalorieTarget,
      protein: stats.avgProtein,
      carbs: stats.avgCarbs,
      fat: stats.avgFat,
      streak: food.streaks.logging,
      daysLogged: stats.daysLogged,
      weightChangeText: weightChangeText,
      weightText: stats.endWeightKg != null
          ? Units.weight(stats.endWeightKg!, useLbs)
          : null,
      goalWeightText: Units.weight(profile.goalWeightKg, useLbs),
    );
  }

  ShareCardData _currentData(BuildContext context) {
    if (_period == SharePeriod.daily) return _buildDailyData(context);
    if (_periodStats != null) return _buildPeriodData(context, _periodStats!);
    // Loading – return daily as placeholder.
    return _buildDailyData(context);
  }

  void _onPeriodChanged(SharePeriod p) {
    setState(() => _period = p);
    if (p == SharePeriod.daily) return;
    _loadStats(p);
  }

  Future<void> _loadStats(SharePeriod p) async {
    setState(() {
      _loadingStats = true;
      _periodStats = null;
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime start;

    switch (p) {
      case SharePeriod.daily:
        return;
      case SharePeriod.weekly:
        start = today.subtract(const Duration(days: 6));
      case SharePeriod.monthly:
        start = DateTime(today.year, today.month - 1, today.day + 1);
    }

    final stats = await PeriodStatsService.fetch(
      start: start,
      end: today,
    );

    if (mounted && _period == p) {
      setState(() {
        _periodStats = stats;
        _loadingStats = false;
      });
    }
  }

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _repaintKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/kijo_${_period.name}_summary.png');
      await file.writeAsBytes(bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: '🔥 My ${_period.label.toLowerCase()} summary – made by kijo',
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final data = _currentData(context);
    final text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return Column(
          children: [
            // ---- drag handle ----
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ---- title ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Share your day',
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---- period selector ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _PeriodSelector(
                selected: _period,
                onChanged: _onPeriodChanged,
              ),
            ),
            const SizedBox(height: 14),

            // ---- preview + toggles (scrollable) ----
            Expanded(
              child: _loadingStats
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: t.accent),
                          const SizedBox(height: 16),
                          Text(
                            'Crunching your numbers…',
                            style: text.bodyMedium
                                ?.copyWith(color: t.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // ---- card preview ----
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: t.border),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: AspectRatio(
                                aspectRatio: 9 / 16,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: RepaintBoundary(
                                    key: _repaintKey,
                                    child: ShareCard(
                                      data: data,
                                      options: _options,
                                      theme: t,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ---- toggle section ----
                        Text(
                          'CUSTOMIZE',
                          style: text.labelMedium?.copyWith(
                            color: t.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Toggle(
                          label: 'Calories',
                          subtitle: _period == SharePeriod.daily
                              ? 'Ring with eaten / target'
                              : 'Average daily intake ring',
                          value: _options.showCalories,
                          onChanged: (v) => setState(
                            () => _options =
                                _options.copyWith(showCalories: v),
                          ),
                        ),
                        _Toggle(
                          label: 'Burned',
                          subtitle: _period == SharePeriod.daily
                              ? 'Calories burned today'
                              : 'Average calories burned / day',
                          value: _options.showBurned,
                          onChanged: (v) => setState(
                            () => _options =
                                _options.copyWith(showBurned: v),
                          ),
                        ),
                        _Toggle(
                          label: 'Macros',
                          subtitle: _period == SharePeriod.daily
                              ? 'Protein, carbs & fat'
                              : 'Average daily macros',
                          value: _options.showMacros,
                          onChanged: (v) => setState(
                            () => _options =
                                _options.copyWith(showMacros: v),
                          ),
                        ),
                        _Toggle(
                          label: 'Weight',
                          subtitle: _period == SharePeriod.daily
                              ? 'Current & goal weight'
                              : 'Weight change over the period',
                          value: _options.showWeight,
                          onChanged: (v) => setState(
                            () => _options =
                                _options.copyWith(showWeight: v),
                          ),
                        ),
                        _Toggle(
                          label: 'Streak',
                          subtitle: 'Logging streak days',
                          value: _options.showStreak,
                          onChanged: (v) => setState(
                            () => _options =
                                _options.copyWith(showStreak: v),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
            ),

            // ---- share button ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: (_sharing || _loadingStats) ? null : _share,
                    icon: _sharing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(_sharing ? 'Saving...' : 'Share'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ───────────────────────── period selector

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.onChanged,
  });

  final SharePeriod selected;
  final ValueChanged<SharePeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          for (final p in SharePeriod.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected == p
                        ? t.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.label,
                    style: text.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selected == p
                          ? t.onAccent
                          : t.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── toggle row

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(
          label,
          style: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: text.bodySmall?.copyWith(color: t.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
