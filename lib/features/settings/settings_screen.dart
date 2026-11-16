import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/select_tile.dart';
import '../../domain/user_profile.dart';
import '../../state/profile_controller.dart';
import 'backup_card.dart';
import 'display_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>();
    final t = c.theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.7);
    final dark = AppThemes.all.where((e) => e.isDark).toList();
    final light = AppThemes.all.where((e) => !e.isDark).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const _GoalsCard(),
            const SizedBox(height: 16),
            const DisplayCard(),
            const SizedBox(height: 16),
            const BackupCard(),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Text('Dark', style: text.labelLarge?.copyWith(color: muted)),
                  const SizedBox(height: 10),
                  _ThemeWrap(themes: dark, selectedId: t.id),
                  const SizedBox(height: 16),
                  Text('Light', style: text.labelLarge?.copyWith(color: muted)),
                  const SizedBox(height: 10),
                  _ThemeWrap(themes: light, selectedId: t.id),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Typography',
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in ThemeController.fontOptions)
                        ChoiceChip(
                          label: Text(f),
                          selected: c.fontFamily == f,
                          onSelected: (_) => c.setFont(f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Text size: ${(c.textScale * 100).round()}%',
                    style: text.labelLarge?.copyWith(color: muted),
                  ),
                  Row(
                    children: [
                      Text('A', style: text.bodySmall),
                      Expanded(
                        child: Slider(
                          value: c.textScale,
                          min: ThemeController.minTextScale,
                          max: ThemeController.maxTextScale,
                          divisions: 10,
                          label: '${(c.textScale * 100).round()}%',
                          onChanged: c.setTextScale,
                        ),
                      ),
                      Text('A', style: text.titleLarge),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.glassBorder),
                    ),
                    child: Text(
                      'Chicken rice bowl\n620 kcal  |  42 g protein',
                      style: text.bodyLarge,
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

class _ThemeWrap extends StatelessWidget {
  const _ThemeWrap({required this.themes, required this.selectedId});

  final List<AppThemeData> themes;
  final String selectedId;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ThemeController>();
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final th in themes)
          _ThemeTile(
            data: th,
            selected: th.id == selectedId,
            onTap: () => controller.setTheme(th),
          ),
      ],
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final AppThemeData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final current = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      width: 72,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: data.gradient,
                ),
                border: Border.all(
                  color: selected
                      ? data.accent
                      : current.textColor.withValues(alpha: 0.25),
                  width: selected ? 3 : 1,
                ),
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      color: data.isDark ? Colors.white : data.textColor,
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              data.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
