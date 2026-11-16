import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications. Everything here works
/// offline. Reminders use inexact scheduling, so no exact-alarm permission is
/// needed (they may arrive a few minutes late when the phone is idle).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get ready => _ready;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminders',
      'Reminders',
      channelDescription: 'Meal and weigh-in reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _configureLocalZone();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_notify'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
  }

  Future<void> _configureLocalZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return;
    } catch (_) {
      // Fall through to the offset-based guess below.
    }
    final now = DateTime.now();
    final offsetMs = now.timeZoneOffset.inMilliseconds;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (loc.timeZone(now.millisecondsSinceEpoch).offset == offsetMs) {
        tz.setLocalLocation(loc);
        return;
      }
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Android 13+ shows a permission prompt. Earlier versions return true.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    return (await _android?.requestNotificationsPermission()) ?? false;
  }

  Future<bool> areEnabled() async {
    if (!_ready) return false;
    return (await _android?.areNotificationsEnabled()) ?? false;
  }

  tz.TZDateTime _nextTime(int hour, int minute, {int? weekday}) {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (d.isBefore(now) || (weekday != null && d.weekday != weekday)) {
      d = d.add(const Duration(days: 1));
    }
    return d;
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextTime(hour, minute),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// [weekday] uses DateTime.monday (1) to DateTime.sunday (7).
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
  }) async {
    if (!_ready) return;
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextTime(hour, minute, weekday: weekday),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }

  Future<void> showTest() async {
    if (!_ready) return;
    await _plugin.show(
      id: 99,
      title: 'Calorie Tracker',
      body: 'Reminders are working.',
      notificationDetails: _details,
    );
  }
}
