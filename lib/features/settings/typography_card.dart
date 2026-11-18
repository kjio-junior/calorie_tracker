import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/widgets/glass_card.dart';
import 'font_download_tile.dart';

/// Font choice (two even columns), offline download, text size and a live
/// preview that updates with both.
class TypographyCard extends StatelessWidget {
  const TypographyCard({super.key});

  static const _spacing = 8.0;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ThemeController>();
    final t = c.theme;
    final text = Theme.of(context).textTheme;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Typography',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            'Choose a font and text size.',
            style: text.bodySmall?.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - _spacing) / 2;
              return Wrap(
                spacing: _spacing,
                runSpacing: _spacing,
                children: [
                  for (final f in ThemeController.fontOptions)
                    SizedBox(
                      width: width,
                      child: _FontOption(
                        name: f,
                        selected: c.fontFamily == f,
                        onTap: () => c.setFont(f),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          const FontDownloadTile(),
          const SizedBox(height: 16),
          Divider(color: t.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Text size',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: t.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${(c.textScale * 100).round()}%',
                  style: text.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
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
                  onChanged: c.setTextScale,
                ),
              ),
              Text('A', style: text.titleLarge),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.inputFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: t.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: text.labelSmall?.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Chicken rice bowl',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Lunch  |  620 kcal  |  42 g protein',
                  style: text.bodyMedium?.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  'The quick brown fox jumps over the lazy dog. 0123456789',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FontOption extends StatelessWidget {
  const _FontOption({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? t.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? t.accent : t.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, size: 18, color: t.accent),
          ],
        ),
      ),
    );
  }
}
