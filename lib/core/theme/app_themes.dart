import 'package:flutter/material.dart';

/// One selectable look: a 3-stop gradient background plus the colors
/// used by glass cards and text on top of it.
class AppThemeData {
  const AppThemeData({
    required this.id,
    required this.name,
    required this.brightness,
    required this.gradient,
    required this.accent,
    required this.textColor,
    required this.glassFill,
    required this.glassBorder,
  });

  final String id;
  final String name;
  final Brightness brightness;
  final List<Color> gradient;
  final Color accent;
  final Color textColor;
  final Color glassFill;
  final Color glassBorder;

  bool get isDark => brightness == Brightness.dark;
}

class AppThemes {
  AppThemes._();

  static const _darkText = Color(0xFFF2F3F5);
  static const _darkFill = Color(0x14FFFFFF); // ~8% white
  static const _darkBorder = Color(0x2EFFFFFF); // ~18% white
  static const _lightFill = Color(0x8CFFFFFF); // ~55% white
  static const _lightBorder = Color(0xB3FFFFFF); // ~70% white

  static const List<AppThemeData> all = [
    // ---- Dark ----
    AppThemeData(
      id: 'midnight_blurple',
      name: 'Midnight Blurple',
      brightness: Brightness.dark,
      gradient: [Color(0xFF0A0B1F), Color(0xFF1C1F5C), Color(0xFF4752C4)],
      accent: Color(0xFF7983F5),
      textColor: _darkText,
      glassFill: _darkFill,
      glassBorder: _darkBorder,
    ),
    AppThemeData(
      id: 'crimson_dusk',
      name: 'Crimson Dusk',
      brightness: Brightness.dark,
      gradient: [Color(0xFF1A0508), Color(0xFF4A0E1C), Color(0xFF9B2335)],
      accent: Color(0xFFFF6B7A),
      textColor: _darkText,
      glassFill: _darkFill,
      glassBorder: _darkBorder,
    ),
    AppThemeData(
      id: 'emerald_dark',
      name: 'Emerald Dark',
      brightness: Brightness.dark,
      gradient: [Color(0xFF03140F), Color(0xFF0B3D2E), Color(0xFF1F7A5C)],
      accent: Color(0xFF3DDC97),
      textColor: _darkText,
      glassFill: _darkFill,
      glassBorder: _darkBorder,
    ),
    AppThemeData(
      id: 'cyber_violet',
      name: 'Cyber Violet',
      brightness: Brightness.dark,
      gradient: [Color(0xFF120626), Color(0xFF3A0F6B), Color(0xFF7B2FF7)],
      accent: Color(0xFFC084FF),
      textColor: _darkText,
      glassFill: _darkFill,
      glassBorder: _darkBorder,
    ),
    // ---- Light ----
    AppThemeData(
      id: 'clean_daylight',
      name: 'Clean Daylight',
      brightness: Brightness.light,
      gradient: [Color(0xFFF5F8FF), Color(0xFFE3ECFF), Color(0xFFCFDBFF)],
      accent: Color(0xFF5865F2),
      textColor: Color(0xFF1B1E3A),
      glassFill: _lightFill,
      glassBorder: _lightBorder,
    ),
    AppThemeData(
      id: 'sunset_peach',
      name: 'Sunset Peach',
      brightness: Brightness.light,
      gradient: [Color(0xFFFFF1E6), Color(0xFFFFD3B8), Color(0xFFFFA9A3)],
      accent: Color(0xFFE4572E),
      textColor: Color(0xFF3A1F1A),
      glassFill: _lightFill,
      glassBorder: _lightBorder,
    ),
    AppThemeData(
      id: 'frost_mint',
      name: 'Frost Mint',
      brightness: Brightness.light,
      gradient: [Color(0xFFF0FFFA), Color(0xFFD2F5EA), Color(0xFFA8E6D6)],
      accent: Color(0xFF0E9F7B),
      textColor: Color(0xFF0F2E27),
      glassFill: _lightFill,
      glassBorder: _lightBorder,
    ),
  ];

  static AppThemeData byId(String? id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}
