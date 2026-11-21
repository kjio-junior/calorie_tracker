import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/ui/app_button.dart';
import '../../core/utils/meal_guess.dart';
import '../../state/history_controller.dart';
import '../../state/nav_controller.dart';
import '../food/add_food_screen.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom navigation: Today, History, Settings. Each tab keeps its state.
///
/// The bar is a compact custom widget (instead of Material's NavigationBar,
/// whose built-in padding made it tall) so the spacing is exactly controlled:
/// on the Today tab the "Log food" button sits right above the three tabs in
/// one block, and the space under the tabs is only as tall as the phone's
/// gesture area needs.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = [HomeScreen(), HistoryScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final t = context.watch<ThemeController>().theme;

    // Gesture navigation reports a small inset (about 24 dp): the thin
    // gesture line only needs part of it. With 3-button navigation the inset
    // is larger and must be kept in full so the buttons never cover the tabs.
    final inset = MediaQuery.paddingOf(context).bottom;
    final bottomPad = inset <= 32 ? math.max(inset - 10, 6.0) : inset;

    void openLogFood() => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddFoodScreen(initialMeal: guessMeal()),
          ),
        );

    void select(int i) {
      nav.go(i);
      if (i == 1) context.read<HistoryController>().refresh();
    }

    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: IndexedStack(index: nav.index, children: _pages),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: t.navBackground,
              border: Border(top: BorderSide(color: t.border)),
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    alignment: Alignment.bottomCenter,
                    child: nav.index == 0
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                            child: AppButton(
                              label: 'Log food',
                              icon: Icons.add_rounded,
                              expanded: true,
                              onPressed: openLogFood,
                            ),
                          )
                        : const SizedBox(width: double.infinity, height: 4),
                  ),
                  Row(
                    children: [
                      _NavItem(
                        icon: Icons.today_outlined,
                        selectedIcon: Icons.today_rounded,
                        label: 'Today',
                        selected: nav.index == 0,
                        onTap: () => select(0),
                      ),
                      _NavItem(
                        icon: Icons.calendar_month_outlined,
                        selectedIcon: Icons.calendar_month_rounded,
                        label: 'History',
                        selected: nav.index == 1,
                        onTap: () => select(1),
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: 'Settings',
                        selected: nav.index == 2,
                        onTap: () => select(2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<ThemeController>().theme;
    final text = Theme.of(context).textTheme;
    final color = selected ? t.accent : t.textSecondary;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? t.accent.withValues(alpha: t.isDark ? 0.24 : 0.14)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  style: text.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
