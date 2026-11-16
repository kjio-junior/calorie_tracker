import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_card.dart';
import '../../state/ui_prefs.dart';

class DisplayCard extends StatelessWidget {
  const DisplayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = context.watch<UiPrefs>();
    final text = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modules and dashboard',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cardio activity log'),
            subtitle: const Text('Strava-style runs, rides, walks and more'),
            value: ui.cardioEnabled,
            onChanged: ui.setCardioEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Strength workouts'),
            subtitle: const Text('Lyfta-style exercises, sets, reps and weight'),
            value: ui.workoutsEnabled,
            onChanged: ui.setWorkoutsEnabled,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Add burned calories to my allowance'),
            subtitle: const Text(
              'Off = stricter deficit. Burned calories are still logged but '
              'not added to what you can eat.',
            ),
            value: ui.burnedAddsBack,
            onChanged: ui.setBurnedAddsBack,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show streaks'),
            subtitle: const Text('Logging, calorie and protein streaks'),
            value: ui.showStreaks,
            onChanged: ui.setShowStreaks,
          ),
        ],
      ),
    );
  }
}
