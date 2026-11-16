import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/notification_service.dart';

enum ReminderKind {
  breakfast(1, 'Breakfast', 'Time to log breakfast',
      'Add what you ate to keep your streak going.', 8, 0),
  lunch(2, 'Lunch', 'Time to log lunch',
      'Add what you ate to keep your streak going.', 12, 30),
  dinner(3, 'Dinner', 'Time to log dinner',
      'Add what you ate to keep your streak going.', 18, 30),
  weighIn(4, 'Weekly weigh-in', 'Weekly weigh-in',
      'Step on the scale and log your weight.', 7, 30);

  const ReminderKind(
    this.id,
    this.label,
    this.title,
    this.body,
    this.defaultHour,
    this.defaultMinute,
  );

  final int id;
  final String label;
  final String title;
  final String body;
  final int defaultHour;
  final int defaultMinute;
}

class ReminderConfig {
  const ReminderConfig({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderConfig copyWith({bool? enabled, int? hour, int? minute}) =>
      ReminderConfig(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

/// Customisable local reminders (all work offline). Settings live in
/// shared_preferences; everything is rescheduled on each app start.
class ReminderController extends ChangeNotifier {
  ReminderController._(this._prefs);

  final SharedPreferences _prefs;
  final Map<ReminderKind, ReminderConfig> _configs = {};
  int _weekday = DateTime.monday;
  bool _allowed = true;

  static Future<ReminderController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final c = ReminderController._(prefs);
    for (final k in ReminderKind.values) {
      c._configs[k] = ReminderConfig(
        enabled: prefs.getBool('rem_${k.name}_on') ?? false,
        hour: prefs.getInt('rem_${k.name}_h') ?? k.defaultHour,
        minute: prefs.getInt('rem_${k.name}_m') ?? k.defaultMinute,
      );
    }
    c._weekday = prefs.getInt('rem_weekday') ?? DateTime.monday;

    await NotificationService.instance.init();
    c._allowed = await NotificationService.instance.areEnabled();
    await c.rescheduleAll();
    return c;
  }

  ReminderConfig config(ReminderKind k) => _configs[k]!;
  int get weighInWeekday => _weekday;

  /// False when Android notification permission is off for this app.
  bool get notificationsAllowed => _allowed;
  bool get available => NotificationService.instance.ready;

  /// Returns false if the user has not allowed notifications.
  Future<bool> setEnabled(ReminderKind k, bool on) async {
    if (on) {
      final ok = await NotificationService.instance.requestPermission();
      _allowed = ok;
      if (!ok) {
        notifyListeners();
        return false;
      }
    }
    _configs[k] = config(k).copyWith(enabled: on);
    await _prefs.setBool('rem_${k.name}_on', on);
    await _apply(k);
    notifyListeners();
    return true;
  }

  Future<void> setTime(ReminderKind k, int hour, int minute) async {
    _configs[k] = config(k).copyWith(hour: hour, minute: minute);
    await _prefs.setInt('rem_${k.name}_h', hour);
    await _prefs.setInt('rem_${k.name}_m', minute);
    await _apply(k);
    notifyListeners();
  }

  Future<void> setWeekday(int weekday) async {
    _weekday = weekday;
    await _prefs.setInt('rem_weekday', weekday);
    await _apply(ReminderKind.weighIn);
    notifyListeners();
  }

  Future<bool> sendTest() async {
    final ok = await NotificationService.instance.requestPermission();
    _allowed = ok;
    notifyListeners();
    if (!ok) return false;
    await NotificationService.instance.showTest();
    return true;
  }

  Future<void> rescheduleAll() async {
    for (final k in ReminderKind.values) {
      await _apply(k);
    }
  }

  Future<void> _apply(ReminderKind k) async {
    final svc = NotificationService.instance;
    final c = config(k);
    if (!c.enabled) {
      await svc.cancel(k.id);
      return;
    }
    if (k == ReminderKind.weighIn) {
      await svc.scheduleWeekly(
        id: k.id,
        title: k.title,
        body: k.body,
        hour: c.hour,
        minute: c.minute,
        weekday: _weekday,
      );
    } else {
      await svc.scheduleDaily(
        id: k.id,
        title: k.title,
        body: k.body,
        hour: c.hour,
        minute: c.minute,
      );
    }
  }
}
