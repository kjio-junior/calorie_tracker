import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';
import '../utils/formatters.dart';

/// Month grid (Sunday first). Days with data get a dot; future days are
/// disabled.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.marked,
    this.cheatDates = const {},
    required this.onSelect,
    required this.onMonthChanged,
  });

  final DateTime month;
  final DateTime selected;
  final Set<String> marked;
  final Set<String> cheatDates;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final muted = t.textColor.withValues(alpha: 0.6);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = DateTime(month.year, month.month, 1);
    final lead = first.weekday % 7; // Sunday = 0
    final days = DateTime(month.year, month.month + 1, 0).day;
    final rows = ((lead + days) / 7).ceil();
    final canGoNext = !DateTime(month.year, month.month + 1, 1).isAfter(today);
    final onAccent =
        ThemeData.estimateBrightnessForColor(t.accent) == Brightness.dark
            ? Colors.white
            : Colors.black87;

    Widget cell(int index) {
      final dayNumber = index - lead + 1;
      if (dayNumber < 1 || dayNumber > days) return const SizedBox.shrink();

      final d = DateTime(month.year, month.month, dayNumber);
      final isFuture = d.isAfter(today);
      final isSelected = d.year == selected.year &&
          d.month == selected.month &&
          d.day == selected.day;
      final isToday = d == today;
      final hasData = marked.contains(Fmt.dateKey(d));
      final isCheat = cheatDates.contains(Fmt.dateKey(d));

      return Padding(
        padding: const EdgeInsets.all(2),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: isFuture ? null : () => onSelect(d),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? t.accent : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: t.accent, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$dayNumber',
                  style: text.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? onAccent
                        : (isFuture
                            ? t.textColor.withValues(alpha: 0.3)
                            : t.textColor),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (hasData || isCheat)
                        ? (isSelected
                            ? onAccent
                            : (isCheat ? const Color(0xFFFFB020) : t.accent))
                        : Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () =>
                  onMonthChanged(DateTime(month.year, month.month - 1)),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_months[month.month - 1]} ${month.year}',
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: canGoNext
                  ? () => onMonthChanged(DateTime(month.year, month.month + 1))
                  : null,
            ),
          ],
        ),
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: text.labelSmall?.copyWith(color: muted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1,
          children: [for (var i = 0; i < rows * 7; i++) cell(i)],
        ),
      ],
    );
  }
}
