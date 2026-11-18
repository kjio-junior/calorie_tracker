import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_themes.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/widgets/glass_card.dart';

/// Dark and light theme groups, four columns, with a clear selected state.
class ThemePicker extends StatelessWidget {
  const ThemePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>();
    final t = c.theme;
    final text = Theme.of(context).textTheme;
    final dark = AppThemes.all.where((e) => e.isDark).toList();
    final light = AppThemes.all.where((e) => !e.isDark).toList();

    Widget group(String label, List<AppThemeData> themes) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: text.labelLarge?.copyWith(
                color: t.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _ThemeGrid(themes: themes, selectedId: t.id),
          ],
        );

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Pick a look. The whole app updates instantly.',
            style: text.bodySmall?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 16),
          group('Dark', dark),
          const SizedBox(height: 14),
          Divider(color: t.divider),
          const SizedBox(height: 14),
          group('Light', light),
        ],
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.themes, required this.selectedId});

  final List<AppThemeData> themes;
  final String selectedId;

  static const _columns = 4;
  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<ThemeController>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - _spacing * (_columns - 1)) / _columns;
        return Wrap(
          spacing: _spacing,
          runSpacing: 14,
          children: [
            for (final th in themes)
              SizedBox(
                width: width,
                child: _ThemeTile(
                  data: th,
                  selected: th.id == selectedId,
                  onTap: () => controller.setTheme(th),
                ),
              ),
          ],
        );
      },
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

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [data.backgroundAlt, data.background],
                    ),
                    border: Border.all(
                      color: selected ? data.accent : current.border,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: data.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: data.border),
                      ),
                      child: Center(
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: data.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: data.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: current.surface, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: data.onAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall?.copyWith(
                fontSize: 11.5,
                height: 1.2,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? current.textPrimary : current.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
