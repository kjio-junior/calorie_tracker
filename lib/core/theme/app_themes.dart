import 'package:flutter/material.dart';

/// One complete, coordinated palette. Every screen reads its colours from
/// here (through ThemeData or `context.appTheme`), so switching theme
/// restyles the whole app consistently.
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.brightness,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceElevated,
    required this.inputFill,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.secondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.navBackground,
  });

  final String id;
  final String name;
  final Brightness brightness;

  // Surfaces
  final Color background; // page colour (bottom of the subtle gradient)
  final Color backgroundAlt; // page colour (top of the subtle gradient)
  final Color surface; // cards
  final Color surfaceElevated; // sheets, dialogs
  final Color inputFill; // text fields
  final Color navBackground; // bottom navigation
  final Color border;
  final Color divider;

  // Text
  final Color textPrimary;
  final Color textSecondary;

  // Brand and state colours
  final Color accent; // primary
  final Color secondary;
  final Color success;
  final Color warning;
  final Color danger;

  // Nutrition colours
  final Color protein;
  final Color carbs;
  final Color fat;

  bool get isDark => brightness == Brightness.dark;

  /// Text/icon colour that stays readable on top of [accent].
  Color get onAccent => _readableOn(accent);
  Color get onSecondary => _readableOn(secondary);

  /// A soft, opaque tint of the accent (selected chips, tonal buttons).
  Color get accentSoft =>
      Color.alphaBlend(accent.withValues(alpha: isDark ? 0.22 : 0.14), surface);

  List<Color> get gradient => [backgroundAlt, background];

  // Older names still used by some widgets.
  Color get textColor => textPrimary;
  Color get glassFill => surface;
  Color get glassBorder => border;

  static Color _readableOn(Color c) {
    final white = 1.05 / (c.computeLuminance() + 0.05);
    return white >= 4.5 ? Colors.white : const Color(0xFF101114);
  }
}

class AppThemes {
  AppThemes._();

  // Nutrition colours shared by all dark / all light themes.
  static const _dProtein = Color(0xFF6EA8FE);
  static const _dCarbs = Color(0xFFFFC857);
  static const _dFat = Color(0xFFFF8FA3);
  static const _lProtein = Color(0xFF3B6FD9);
  static const _lCarbs = Color(0xFFC77D00);
  static const _lFat = Color(0xFFD6456B);

  static const List<AppThemeData> all = [
    // ---------------------------------------------------------- Dark
    AppThemeData(
      id: 'midnight_blurple',
      name: 'Midnight Blurple',
      brightness: Brightness.dark,
      background: Color(0xFF0E1020),
      backgroundAlt: Color(0xFF171A38),
      surface: Color(0xFF1A1D3A),
      surfaceElevated: Color(0xFF232750),
      inputFill: Color(0xFF14172F),
      border: Color(0xFF2F3468),
      divider: Color(0xFF262A55),
      textPrimary: Color(0xFFF2F3FA),
      textSecondary: Color(0xFFA6AAD0),
      accent: Color(0xFF7983F5),
      secondary: Color(0xFF4FC3F7),
      success: Color(0xFF3DDC97),
      warning: Color(0xFFFFB020),
      danger: Color(0xFFFF6B6B),
      protein: _dProtein,
      carbs: _dCarbs,
      fat: _dFat,
      navBackground: Color(0xFF14172F),
    ),
    AppThemeData(
      id: 'crimson_dusk',
      name: 'Crimson Dusk',
      brightness: Brightness.dark,
      background: Color(0xFF1A0D10),
      backgroundAlt: Color(0xFF29141A),
      surface: Color(0xFF2A1519),
      surfaceElevated: Color(0xFF371C21),
      inputFill: Color(0xFF211013),
      border: Color(0xFF4A282E),
      divider: Color(0xFF3C2025),
      textPrimary: Color(0xFFF6EEEF),
      textSecondary: Color(0xFFC9A8AD),
      accent: Color(0xFFFF6B7A),
      secondary: Color(0xFFFFA26B),
      success: Color(0xFF3DDC97),
      warning: Color(0xFFFFB020),
      danger: Color(0xFFFF8A8A),
      protein: _dProtein,
      carbs: _dCarbs,
      fat: _dFat,
      navBackground: Color(0xFF211013),
    ),
    AppThemeData(
      id: 'emerald_dark',
      name: 'Emerald Dark',
      brightness: Brightness.dark,
      background: Color(0xFF08150F),
      backgroundAlt: Color(0xFF0F2219),
      surface: Color(0xFF11271D),
      surfaceElevated: Color(0xFF183327),
      inputFill: Color(0xFF0C1D15),
      border: Color(0xFF244838),
      divider: Color(0xFF1C382C),
      textPrimary: Color(0xFFEDF7F1),
      textSecondary: Color(0xFF9CC4B0),
      accent: Color(0xFF3DDC97),
      secondary: Color(0xFF5BC0EB),
      success: Color(0xFF3DDC97),
      warning: Color(0xFFFFB020),
      danger: Color(0xFFFF6B6B),
      protein: _dProtein,
      carbs: _dCarbs,
      fat: _dFat,
      navBackground: Color(0xFF0C1D15),
    ),
    AppThemeData(
      id: 'cyber_violet',
      name: 'Cyber Violet',
      brightness: Brightness.dark,
      background: Color(0xFF120A22),
      backgroundAlt: Color(0xFF1D1136),
      surface: Color(0xFF21143D),
      surfaceElevated: Color(0xFF2C1B50),
      inputFill: Color(0xFF190F2F),
      border: Color(0xFF3D2968),
      divider: Color(0xFF30205A),
      textPrimary: Color(0xFFF3EEFB),
      textSecondary: Color(0xFFB9A6DA),
      accent: Color(0xFFC084FF),
      secondary: Color(0xFF6EE7F9),
      success: Color(0xFF3DDC97),
      warning: Color(0xFFFFB020),
      danger: Color(0xFFFF6B8A),
      protein: _dProtein,
      carbs: _dCarbs,
      fat: _dFat,
      navBackground: Color(0xFF190F2F),
    ),

    // --------------------------------------------------------- Light
    AppThemeData(
      id: 'clean_daylight',
      name: 'Clean Daylight',
      brightness: Brightness.light,
      background: Color(0xFFF5F7FC),
      backgroundAlt: Color(0xFFE9EEFA),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFFFFFF),
      inputFill: Color(0xFFF1F4FB),
      border: Color(0xFFDDE3F2),
      divider: Color(0xFFE8ECF6),
      textPrimary: Color(0xFF181B34),
      textSecondary: Color(0xFF5B6280),
      accent: Color(0xFF4F5BE8),
      secondary: Color(0xFF0EA5E9),
      success: Color(0xFF1F9D6A),
      warning: Color(0xFFC77D00),
      danger: Color(0xFFD93A3A),
      protein: _lProtein,
      carbs: _lCarbs,
      fat: _lFat,
      navBackground: Color(0xFFFFFFFF),
    ),
    AppThemeData(
      id: 'sunset_peach',
      name: 'Sunset Peach',
      brightness: Brightness.light,
      background: Color(0xFFFFF6EF),
      backgroundAlt: Color(0xFFFFE8DA),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFFFBF8),
      inputFill: Color(0xFFFFF1E8),
      border: Color(0xFFF2D8C9),
      divider: Color(0xFFF7E4D8),
      textPrimary: Color(0xFF2E1B16),
      textSecondary: Color(0xFF7A5A4F),
      accent: Color(0xFFD9481F),
      secondary: Color(0xFFC77D00),
      success: Color(0xFF1F9D6A),
      warning: Color(0xFFB86E00),
      danger: Color(0xFFC62828),
      protein: _lProtein,
      carbs: _lCarbs,
      fat: _lFat,
      navBackground: Color(0xFFFFFFFF),
    ),
    AppThemeData(
      id: 'frost_mint',
      name: 'Frost Mint',
      brightness: Brightness.light,
      background: Color(0xFFF1FBF8),
      backgroundAlt: Color(0xFFE0F4EE),
      surface: Color(0xFFFFFFFF),
      surfaceElevated: Color(0xFFFFFFFF),
      inputFill: Color(0xFFEAF7F2),
      border: Color(0xFFCFE8DF),
      divider: Color(0xFFDDEFE8),
      textPrimary: Color(0xFF0E2A24),
      textSecondary: Color(0xFF4D7068),
      accent: Color(0xFF0B8F6F),
      secondary: Color(0xFF2B8CBE),
      success: Color(0xFF0B8F6F),
      warning: Color(0xFFC77D00),
      danger: Color(0xFFD93A3A),
      protein: _lProtein,
      carbs: _lCarbs,
      fat: _lFat,
      navBackground: Color(0xFFFFFFFF),
    ),
  ];

  static AppThemeData byId(String? id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}
