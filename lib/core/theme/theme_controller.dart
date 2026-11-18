import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_themes.dart';

/// Holds the user's look and feel (theme, font, text scale), persists it in
/// shared_preferences and builds one complete [ThemeData] from the palette so
/// buttons, inputs, chips, sheets, dialogs and navigation all match.
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

  OutlineInputBorder _outline(Color c, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: width),
      );

  ThemeData _buildMaterialTheme() {
    final t = _theme;
    final base = ThemeData(brightness: t.brightness, useMaterial3: true);
    final colored = base.textTheme.apply(
      bodyColor: t.textPrimary,
      displayColor: t.textPrimary,
    );
    final TextTheme textTheme =
        _font == systemFont ? colored : _withGoogleFont(_font, colored);

    final scheme = ColorScheme(
      brightness: t.brightness,
      primary: t.accent,
      onPrimary: t.onAccent,
      primaryContainer: t.accentSoft,
      onPrimaryContainer: t.textPrimary,
      secondary: t.secondary,
      onSecondary: t.onSecondary,
      secondaryContainer: t.accentSoft,
      onSecondaryContainer: t.textPrimary,
      error: t.danger,
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.textPrimary,
      onSurfaceVariant: t.textSecondary,
      surfaceContainerLowest: t.background,
      surfaceContainerLow: t.surface,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surfaceElevated,
      surfaceContainerHighest: t.surfaceElevated,
      outline: t.border,
      outlineVariant: t.divider,
      surfaceTint: Colors.transparent,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    final label = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 15,
    );
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final disabledBg = t.textSecondary.withValues(alpha: 0.14);
    final disabledFg = t.textSecondary.withValues(alpha: 0.55);

    return base.copyWith(
      colorScheme: scheme,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      // Transparent so the page gradient behind the Navigator shows through.
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: t.surface,
      iconTheme: IconThemeData(color: t.textPrimary),
      dividerColor: t.divider,
      dividerTheme: DividerThemeData(color: t.divider, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: t.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: t.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: t.border),
        ),
      ),

      // ---- buttons ----
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.onAccent,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledFg,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.textPrimary,
          disabledForegroundColor: disabledFg,
          side: BorderSide(color: t.border, width: 1.2),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: buttonShape,
          textStyle: label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.accent,
          disabledForegroundColor: disabledFg,
          minimumSize: const Size(48, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: buttonShape,
          textStyle: label?.copyWith(fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: t.textPrimary,
          disabledForegroundColor: disabledFg,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        elevation: 2,
      ),

      // ---- inputs ----
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _outline(t.border),
        enabledBorder: _outline(t.border),
        disabledBorder: _outline(t.border.withValues(alpha: 0.5)),
        focusedBorder: _outline(t.accent, 1.6),
        errorBorder: _outline(t.danger),
        focusedErrorBorder: _outline(t.danger, 1.6),
        labelStyle: TextStyle(color: t.textSecondary),
        floatingLabelStyle: TextStyle(color: t.accent),
        hintStyle: TextStyle(color: t.textSecondary.withValues(alpha: 0.7)),
        helperStyle: TextStyle(color: t.textSecondary),
        errorStyle: TextStyle(color: t.danger),
        prefixIconColor: t.textSecondary,
        suffixIconColor: t.textSecondary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.accent,
        selectionColor: t.accent.withValues(alpha: 0.3),
        selectionHandleColor: t.accent,
      ),

      // ---- selection controls ----
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        selectedColor: t.accentSoft,
        disabledColor: disabledBg,
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: textTheme.labelLarge?.copyWith(color: t.textPrimary),
        checkmarkColor: t.accent,
        showCheckmark: true,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.onAccent : t.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.accent : t.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.accent,
        inactiveTrackColor: t.border,
        thumbColor: t.accent,
        overlayColor: t.accent.withValues(alpha: 0.15),
        valueIndicatorColor: t.accent,
        valueIndicatorTextStyle: TextStyle(color: t.onAccent),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.accent,
        linearTrackColor: t.accent.withValues(alpha: 0.16),
        circularTrackColor: t.accent.withValues(alpha: 0.16),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: t.textSecondary,
        textColor: t.textPrimary,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.accent,
        unselectedLabelColor: t.textSecondary,
        indicatorColor: t.accent,
        dividerColor: t.border,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        unselectedLabelStyle: textTheme.labelLarge,
      ),

      // ---- overlays ----
      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: t.border),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: t.textPrimary,
        ),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: t.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceElevated,
        modalBackgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.isDark ? t.surfaceElevated : t.textPrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: t.isDark ? t.textPrimary : t.surface,
        ),
        actionTextColor: t.isDark ? t.accent : t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: t.isDark ? BorderSide(color: t.border) : BorderSide.none,
        ),
      ),

      // ---- bottom navigation ----
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: t.accent.withValues(alpha: t.isDark ? 0.24 : 0.14),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? t.accent : t.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          final selected = s.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? t.accent : t.textSecondary,
          );
        }),
      ),
    );
  }
}
