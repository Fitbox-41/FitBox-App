import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'secure_storage.dart';

/// A daily reminder to go for a run.
///
/// The Settings toggle used to be local widget state — flipping it changed a
/// bool that nothing read, so the owner's "workout reminder" never actually
/// reminded anyone. This schedules a real repeating notification.
///
/// Scheduled **inexactly** on purpose. Android 12+ puts exact alarms behind the
/// `SCHEDULE_EXACT_ALARM` permission, which Play scrutinises and which is meant
/// for alarm clocks and calendar events. A nudge to go running does not need
/// to fire on the second, so the app asks for no extra permission and lets the
/// system deliver it around the chosen time.
class ReminderService {
  ReminderService(this._storage);

  final SecureStorage _storage;

  static const String _enabledKey = 'reminder_enabled';
  static const String _hourKey = 'reminder_hour';
  static const String _minuteKey = 'reminder_minute';
  static const int _id = 4301;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (kIsWeb || _ready) return;
    tzdata.initializeTimeZones();
    try {
      // The plugin schedules in a named zone, not a raw offset, so it needs the
      // device's actual zone to survive a change of location.
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Keep the default (UTC) rather than failing outright; the reminder still
      // fires, just aligned to UTC on a misconfigured device.
    }
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    try {
      await _plugin.initialize(
          const InitializationSettings(android: android, iOS: darwin));
      _ready = true;
    } catch (_) {/* notifications unavailable */}
  }

  Future<({bool enabled, int hour, int minute})> read() async {
    final String? on = await _storage.read(_enabledKey);
    return (
      enabled: on == '1',
      hour: int.tryParse(await _storage.read(_hourKey) ?? '') ?? 18,
      minute: int.tryParse(await _storage.read(_minuteKey) ?? '') ?? 0,
    );
  }

  /// Turns the reminder on at [hour]:[minute], or off. Always cancels first, so
  /// changing the time can't leave the old one behind.
  Future<void> set({required bool enabled, int hour = 18, int minute = 0}) async {
    await _init();
    await _storage.write(_enabledKey, enabled ? '1' : '0');
    await _storage.write(_hourKey, '$hour');
    await _storage.write(_minuteKey, '$minute');
    if (!_ready) return;

    try {
      await _plugin.cancel(_id);
      if (!enabled) return;
      await _plugin.zonedSchedule(
        _id,
        'Time to move',
        'A short run today keeps your streak — and your territory.',
        _nextOccurrence(hour, minute),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workout_reminder',
            'Workout reminders',
            channelDescription: 'A daily nudge to record a run',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // repeat daily
      );
    } catch (_) {/* leave the stored preference; nothing else to do */}
  }

  /// Today at the chosen time, or tomorrow if that moment has already passed.
  static tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime at = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }
}

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => ReminderService(ref.watch(secureStorageProvider)),
);

/// The stored reminder setting, so Settings shows the real state on open.
final reminderSettingProvider =
    FutureProvider<({bool enabled, int hour, int minute})>(
  (ref) async => ref.watch(reminderServiceProvider).read(),
);
