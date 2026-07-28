import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A persistent, live-updating notification while a run records (time · distance
/// · pace). Android shows an ongoing notification; iOS shows a standard one —
/// the Dynamic Island Live Activity is a native ActivityKit target added on
/// Codemagic (see ios/ notes).
class RunNotifier {
  RunNotifier();

  static const int _id = 4201;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _plugin.initialize(
          const InitializationSettings(android: android, iOS: darwin));
      _ready = true;
    } catch (_) {/* notifications unavailable */}
  }

  Future<void> update({required String title, required String body}) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready) return;
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'run_tracking',
      'Run tracking',
      channelDescription: 'Live run stats while you record a run',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails darwin = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    try {
      await _plugin.show(_id, title, body,
          const NotificationDetails(android: android, iOS: darwin));
    } catch (_) {/* ignore */}
  }

  Future<void> clear() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(_id);
    } catch (_) {}
  }

  /// A one-off alert (used to surface push messages that arrive while the app is
  /// in the foreground, which the OS otherwise wouldn't display).
  Future<void> alert({required String title, required String body}) async {
    if (kIsWeb) return;
    if (!_ready) await init();
    if (!_ready) return;
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'messages',
      'Notifications',
      channelDescription: 'Challenges, territory and updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const DarwinNotificationDetails darwin = DarwinNotificationDetails();
    try {
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 & 0x7fffffff,
        title,
        body,
        const NotificationDetails(android: android, iOS: darwin),
      );
    } catch (_) {/* ignore */}
  }
}

final runNotifierProvider = Provider<RunNotifier>((ref) => RunNotifier());
