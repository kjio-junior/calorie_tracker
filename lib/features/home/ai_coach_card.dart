import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_context.dart';
import '../../core/ui/app_button.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../domain/coach_prompt.dart';
import '../../state/activity_controller.dart';
import '../../state/ai_coach_controller.dart';
import '../../state/cheat_controller.dart';
import '../../state/connectivity_controller.dart';
import '../../state/food_controller.dart';
import '../../state/nav_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/ui_prefs.dart';

CoachSnapshot _buildSnapshot(BuildContext context) {
  final pc = context.read<ProfileController>();
  final food = context.read<FoodController>();
  final activity = context.read<ActivityController>();
  final ui = context.read<UiPrefs>();
  final profile = pc.profile!;
  final targets = pc.targets!;
  final now = DateTime.now();
  final current = pc.currentKg ?? pc.startKg;

  // Weight change across the last 14 days (needs two weigh-ins in range).
  double? change;
  final cutoff = now.subtract(const Duration(days: 14));
  for (final w in pc.weights) {
    if (!w.date.isBefore(cutoff)) {
      if (w.weightKg != current || w != pc.latest) {
        change = current - w.weightKg;
      }
      break;
    }
  }
  if (pc.weights.length < 2) change = null;

  return CoachSnapshot(
    now: now,
    calorieTarget: targets.calorieTarget,
    eatenKcal: food.calories.round(),
    burnedKcal: activity.burnedToday.round(),
    burnedAddsBack: ui.burnedAddsBack,
    proteinGoal: targets.proteinTarget,
    proteinEaten: food.protein.round(),
    startKg: pc.startKg,
    currentKg: current,
    goalKg: profile.goalWeightKg,
    weightChange14dKg: change,
    useLbs: profile.useLbs,
    paceKgPerWeek: profile.pace.kgPerWeek,
    goalReached: targets.goalReached,
    weeksToGoal: targets.weeksToGoal,
    cardioMinutes: activity.cardio
        .fold<double>(0, (s, e) => s + e.durationMin)
        .round(),
    workoutSessions: activity.sessions.length,
    workoutSets: activity.sessions.fold<int>(0, (s, e) => s + e.totalSets),
    loggingStreak: food.streaks.logging,
    isCheatDay: context.read<CheatController>().todayIsCheat,
  );
}

/// Compact daily coach: a short insight and tip, with the longer explanation
/// behind "View more". Uses the same Gemini/Groq integration as before.
class AiCoachCard extends StatefulWidget {
  const AiCoachCard({super.key});

  @override
  State<AiCoachCard> createState() => _AiCoachCardState();
}

class _AiCoachCardState extends State<AiCoachCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiCoachController>();
    final online = context.watch<ConnectivityController>().isOnline;
    final t = context.appTheme;
    final text = Theme.of(context).textTheme;

    final latest = ai.latest;
    final isToday =
        latest != null && latest.date == Fmt.dateKey(DateTime.now());
    final parts = latest == null ? null : CoachParts.parse(latest.text);

    Widget? trailing;
    if (ai.loading) {
      trailing = const Padding(
        padding: EdgeInsets.all(10),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (!online) {
      trailing = const OfflineBadge();
    } else if (ai.ready && latest != null) {
      trailing = IconButton(
        tooltip: 'Refresh summary',
        icon: const Icon(Icons.refresh_rounded),
        onPressed: () => ai.generate(_buildSnapshot(context)),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded, size: 17, color: t.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily coach',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (latest != null)
                      Text(
                        isToday
                            ? 'Updated today'
                            : 'From ${Fmt.shortDate(Fmt.parseKey(latest.date))}',
                        style: text.labelSmall
                            ?.copyWith(color: t.textSecondary),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          if (parts != null) ...[
            Text(
              parts.insight,
              maxLines: _expanded ? null : 3,
              overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (parts.tip != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: t.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      parts.tip!,
                      maxLines: _expanded ? null : 2,
                      overflow:
                          _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: (_expanded && parts.more != null)
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        parts.more!,
                        style: text.bodySmall
                            ?.copyWith(color: t.textSecondary),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
            if (parts.more != null)
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: _expanded ? 'Show less' : 'View more',
                  icon: _expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  kind: AppButtonKind.text,
                  dense: true,
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ),
          ] else
            Text(
              'A short, personal summary of your day with one tip.',
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          if (ai.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ai.error!,
                style: text.bodySmall?.copyWith(color: t.danger),
              ),
            ),
          if (!ai.ready) ...[
            const SizedBox(height: 10),
            AppButton(
              label: 'Add your free API key',
              icon: Icons.key_rounded,
              kind: AppButtonKind.secondary,
              expanded: true,
              dense: true,
              onPressed: () => context.read<NavController>().go(2),
            ),
          ] else if (latest == null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: online ? 'Generate summary' : 'Offline',
              icon: Icons.auto_awesome_rounded,
              kind: AppButtonKind.tonal,
              expanded: true,
              dense: true,
              onPressed: (online && !ai.loading)
                  ? () => ai.generate(_buildSnapshot(context))
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
