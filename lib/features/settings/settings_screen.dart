import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/ui/screen_title.dart';
import '../../core/ui/section_header.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/select_tile.dart';
import '../../domain/user_profile.dart';
import '../../state/profile_controller.dart';
import 'ai_card.dart';
import 'backup_card.dart';
import 'display_card.dart';
import 'profile_card.dart';
import 'reminders_card.dart';
import 'theme_picker.dart';
import 'typography_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 12);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [
            ScreenTitle(
              'Settings',
              subtitle: 'Profile, appearance, features and data',
            ),
            SectionHeader('Account', top: 4),
            ProfileCard(),
            gap,
            _GoalsCard(),
            SectionHeader('Appearance'),
            ThemePicker(),
            gap,
            TypographyCard(),
            SectionHeader('Features'),
            DisplayCard(),
            gap,
            RemindersCard(),
            gap,
            AiCard(),
            SectionHeader('Data'),
            BackupCard(),
          ],
        ),
      ),
    );
  }
}

/// Units, deficit pace and protein mode. Any change recalculates targets.
class _GoalsCard extends StatefulWidget {
  const _GoalsCard();

  @override
  State<_GoalsCard> createState() => _GoalsCardState();
}

class _GoalsCardState extends State<_GoalsCard> {
  double? _perKg; // local while dragging, saved on release

  @override
  Widget build(BuildContext context) {
    final pc = context.watch<ProfileController>();
    final t = context.watch<ThemeController>().theme;
    final profile = pc.profile!;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final perKg = _perKg ?? profile.proteinPerKg;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Goals and units',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          Text('Weight unit', style: text.labelLarge?.copyWith(color: muted)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('kg')),
              ButtonSegment(value: true, label: Text('lb')),
            ],
            selected: {profile.useLbs},
            onSelectionChanged: (s) =>
                pc.updateProfile(profile.copyWith(useLbs: s.first)),
          ),
          const SizedBox(height: 16),
          Text('Deficit pace', style: text.labelLarge?.copyWith(color: muted)),
          const SizedBox(height: 8),
          for (final p in DeficitPace.values)
            SelectTile(
              title: '${p.label}: ${p.kgPerWeek} kg/week',
              subtitle: 'About ${p.dailyDeficitKcal} kcal/day deficit',
              selected: profile.pace == p,
              onTap: () => pc.updateProfile(profile.copyWith(pace: p)),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Protein tracker'),
            subtitle: const Text('Goal based on your current body weight'),
            value: profile.proteinMode,
            onChanged: (v) =>
                pc.updateProfile(profile.copyWith(proteinMode: v)),
          ),
          if (profile.proteinMode) ...[
            Text(
              '${perKg.toStringAsFixed(1)} g per kg of body weight',
              style: text.labelLarge?.copyWith(color: muted),
            ),
            Slider(
              value: perKg,
              min: 1.6,
              max: 2.2,
              divisions: 6,
              label: '${perKg.toStringAsFixed(1)} g/kg',
              onChanged: (v) => setState(() => _perKg = v),
              onChangeEnd: (v) async {
                await pc.updateProfile(profile.copyWith(proteinPerKg: v));
                if (mounted) setState(() => _perKg = null);
              },
            ),
          ],
        ],
      ),
    );
  }
}
