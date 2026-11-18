import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'app_themes.dart';
import 'theme_controller.dart';

/// `context.appTheme` gives the current palette (and rebuilds on change).
extension AppThemeContext on BuildContext {
  AppThemeData get appTheme => watch<ThemeController>().theme;
}
