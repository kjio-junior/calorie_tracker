import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../../state/reminder_controller.dart';

class RemindersCard extends StatelessWidget {
  const RemindersCard({super.key});

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final rc = context.watch<ReminderController>();
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);

    void snack(String msg) => ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));

    Future<void> pickTime(ReminderKind k) async {
      final c = rc.config(k);
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: c.hour, minute: c.minute),
      );
      if (picked != null) await rc.setTime(k, picked.hour, picked.minute);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminders',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Notification banners that work offline.',
            style: text.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 10),
          if (!rc.available)
            Text(
              'Notifications could not start on this device.',
              style: text.bodySmall?.copyWith(color: t.danger),
            )
          else ...[
            for (final k in ReminderKind.values) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      k.label,
                      style: text.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => pickTime(k),
                    child: Text(
                      TimeOfDay(
                        hour: rc.config(k).hour,
                        minute: rc.config(k).minute,
                      ).format(context),
                    ),
                  ),
                  Switch(
                    value: rc.config(k).enabled,
                    onChanged: (v) async {
                      final ok = await rc.setEnabled(k, v);
                      if (!ok) {
                        snack(
                          'Allow notifications for this app in Android '
                          'settings to use reminders.',
                        );
                      }
                    },
                  ),
                ],
              ),
              if (k == ReminderKind.weighIn)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < 7; i++)
                        ChoiceChip(
                          label: Text(_days[i]),
                          selected: rc.weighInWeekday == i + 1,
                          onSelected: (_) => rc.setWeekday(i + 1),
                        ),
                    ],
                  ),
                ),
            ],
            if (!rc.notificationsAllowed)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Notifications are turned off for this app. Enable them in '
                  'Android Settings > Apps > Calorie Tracker > Notifications.',
                  style: text.bodySmall
                      ?.copyWith(color: t.warning),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await rc.sendTest();
                if (!ok) {
                  snack('Allow notifications for this app first.');
                }
              },
              icon: const Icon(Icons.notifications_active_rounded),
              label: const Text('Send a test notification'),
            ),
            const SizedBox(height: 6),
            Text(
              'Reminders can arrive a few minutes late when your phone is '
              'idle or in battery saver.',
              style: text.labelSmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }
}
