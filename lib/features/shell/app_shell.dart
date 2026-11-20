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
/// On the Today tab the "Log food" button sits directly on top of the
/// navigation bar inside the same block, so the two stay close together and
/// never cover content.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = [HomeScreen(), HistoryScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final t = context.watch<ThemeController>().theme;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.bottomCenter,
                  child: nav.index == 0
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                          child: AppButton(
                            label: 'Log food',
                            icon: Icons.add_rounded,
                            expanded: true,
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddFoodScreen(initialMeal: guessMeal()),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                NavigationBar(
                  selectedIndex: nav.index,
                  onDestinationSelected: (i) {
                    nav.go(i);
                    if (i == 1) context.read<HistoryController>().refresh();
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.today_outlined),
                      selectedIcon: Icon(Icons.today_rounded),
                      label: 'Today',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.calendar_month_outlined),
                      selectedIcon: Icon(Icons.calendar_month_rounded),
                      label: 'History',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
