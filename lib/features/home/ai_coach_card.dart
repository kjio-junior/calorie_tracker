import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/offline_badge.dart';
import '../../domain/coach_prompt.dart';
import '../../state/activity_controller.dart';
import '../../state/ai_coach_controller.dart';
import '../../state/connectivity_controller.dart';
import '../../state/food_controller.dart';
import '../../state/profile_controller.dart';
import '../../state/ui_prefs.dart';
import '../settings/settings_screen.dart';

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
  );
}

class AiCoachCard extends StatelessWidget {
  const AiCoachCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AiCoachController>();
    final online = context.watch<ConnectivityController>().isOnline;
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    final latest = ai.latest;
    final isToday =
        latest != null && latest.date == Fmt.dateKey(DateTime.now());

    String buttonLabel;
    if (ai.loading) {
      buttonLabel = 'Thinking...';
    } else if (!online) {
      buttonLabel = 'Offline: new summary unavailable';
    } else {
      buttonLabel = isToday ? 'Refresh summary' : 'Generate summary';
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: t.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Daily coach',
                  style: text.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (!online) const OfflineBadge(),
            ],
          ),
          const SizedBox(height: 10),
          if (latest != null) ...[
            Text(latest.text, style: text.bodyMedium),
            const SizedBox(height: 6),
            Text(
              isToday
                  ? 'Updated today'
                  : 'Saved summary from ${Fmt.shortDate(Fmt.parseKey(latest.date))}',
              style: text.labelSmall?.copyWith(color: muted),
            ),
          ] else
            Text(
              'Get a short, motivating summary of your calories, protein, '
              'weight trend and workouts.',
              style: text.bodySmall?.copyWith(color: muted),
            ),
          if (ai.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                ai.error!,
                style: text.bodySmall?.copyWith(color: const Color(0xFFFF6B6B)),
              ),
            ),
          const SizedBox(height: 12),
          if (!ai.ready)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.key_rounded),
                label: const Text('Add your free API key'),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: (online && !ai.loading)
                    ? () => ai.generate(_buildSnapshot(context))
                    : null,
                icon: ai.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(buttonLabel),
              ),
            ),
        ],
      ),
    );
  }
}
