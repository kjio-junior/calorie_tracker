import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

/// Holds the user's look & feel (gradient theme, font, text scale),
/// persists it in shared_preferences and exposes a ready-made [ThemeData].
class ThemeController extends ChangeNotifier {
  static const systemFont = 'System default';
  static const fontOptions = <String>[
    systemFont,
    'Inter',
    'Poppins',
    'Nunito',
    'Lexend',
    'Roboto Mono',
  ];

  static const double minTextScale = 0.8;
  static const double maxTextScale = 1.3;

  static const _kThemeId = 'theme_id';
  static const _kFont = 'font_family';
  static const _kTextScale = 'text_scale';

  ThemeController._(this._prefs, this._theme, this._font, this._textScale) {
    _material = _buildMaterialTheme();
  }

  final SharedPreferences _prefs;
  AppThemeData _theme;
  String _font;
  double _textScale;
  late ThemeData _material;

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString(_kFont);
    final scale = (prefs.getDouble(_kTextScale) ?? 1.0)
        .clamp(minTextScale, maxTextScale)
        .toDouble();
    return ThemeController._(
      prefs,
      AppThemes.byId(prefs.getString(_kThemeId)),
      fontOptions.contains(savedFont) ? savedFont! : systemFont,
      scale,
    );
  }

  AppThemeData get theme => _theme;
  String get fontFamily => _font;
  double get textScale => _textScale;
  ThemeData get materialTheme => _material;

  void setTheme(AppThemeData value) {
    if (value.id == _theme.id) return;
    _theme = value;
    _material = _buildMaterialTheme();
    notifyListeners();
    _prefs.setString(_kThemeId, value.id);
  }

  void setFont(String value) {
    if (value == _font || !fontOptions.contains(value)) return;
    _font = value;
    _material = _buildMaterialTheme();
    notifyListeners();
    _prefs.setString(_kFont, value);
  }

  void setTextScale(double value) {
    final v = value.clamp(minTextScale, maxTextScale).toDouble();
    if (v == _textScale) return;
    _textScale = v;
    notifyListeners();
    _prefs.setDouble(_kTextScale, v);
  }

  /// Applies a Google font to every style in [t]. Done per style (instead of
  /// GoogleFonts.getTextTheme) so it works with Flutter's own TextTheme type.
  TextTheme _withGoogleFont(String family, TextTheme t) {
    TextStyle? f(TextStyle? s) =>
        s == null ? null : GoogleFonts.getFont(family, textStyle: s);
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }

  ThemeData _buildMaterialTheme() {
    final t = _theme;
    final base = ThemeData(brightness: t.brightness, useMaterial3: true);
    final coloredText = base.textTheme.apply(
      bodyColor: t.textColor,
      displayColor: t.textColor,
    );
    final TextTheme textTheme =
      _font == systemFont ? coloredText : _withGoogleFont(_font, coloredText);

    final scheme = ColorScheme.fromSeed(
      seedColor: t.accent,
      brightness: t.brightness,
    ).copyWith(primary: t.accent, onSurface: t.textColor);

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      // Transparent so the gradient behind the Navigator shows through.
      scaffoldBackgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: t.textColor),
      dividerColor: t.textColor.withValues(alpha: 0.12),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: t.textColor,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: t.textColor,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.accent,
        thumbColor: t.accent,
        inactiveTrackColor: t.accent.withValues(alpha: 0.25),
        overlayColor: t.accent.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        selectedColor: t.accent.withValues(alpha: 0.35),
        backgroundColor: Colors.transparent,
        side: BorderSide(color: t.textColor.withValues(alpha: 0.2)),
        checkmarkColor: t.textColor,
        labelStyle: textTheme.bodyMedium?.copyWith(color: t.textColor),
      ),
    );
  }
}
