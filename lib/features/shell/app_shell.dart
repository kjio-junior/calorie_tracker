import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/theme_controller.dart';
import '../../state/history_controller.dart';
import '../../state/nav_controller.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// Bottom navigation: Today, History, Settings. Each tab keeps its state.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _pages = [HomeScreen(), HistoryScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final t = context.watch<ThemeController>().theme;

    final navTheme = NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: t.accent.withValues(alpha: 0.25),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? t.accent : t.textColor.withValues(alpha: 0.65),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          color: selected ? t.accent : t.textColor.withValues(alpha: 0.65),
        );
      }),
    );

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
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.glassFill,
                  border: Border(top: BorderSide(color: t.glassBorder)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(navigationBarTheme: navTheme),
                  child: NavigationBar(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
