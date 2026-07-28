import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'run_notifier.dart';

/// Background/terminated-state message handler — must be a top-level function
/// annotated for the AOT entry point. Notification messages are drawn by the OS;
/// we only need this registered so data messages don't get dropped.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

/// Initializes Firebase and registers the background message handler. Called
/// once at startup; a no-op on web / where Firebase isn't configured.
Future<void> bootstrapFirebase() async {
  if (kIsWeb) return;
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (_) {/* Firebase not configured on this platform */}
}

/// Registers this device for FCM push and keeps its token synced with the
/// backend. Wired to run whenever the user signs in (see app.dart).
class PushService {
  PushService(this._ref);

  final Ref _ref;
  bool _wired = false;

  Future<void> register() async {
    if (kIsWeb) return;
    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final String? token = await messaging.getToken();
      if (token != null && token.isNotEmpty) await _send(token);

      if (!_wired) {
        _wired = true;
        messaging.onTokenRefresh.listen(_send);
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      }
    } catch (_) {/* messaging unavailable on this device */}
  }

  Future<void> _send(String token) async {
    try {
      await _ref.read(appDioProvider).post<dynamic>(
        '/push/register',
        data: <String, dynamic>{
          'token': token,
          'platform': defaultTargetPlatform.name,
        },
      );
    } catch (_) {/* offline or not signed in — retried next launch */}
  }

  /// FCM doesn't show notifications while the app is foregrounded, so we surface
  /// them ourselves via the local-notification plumbing.
  void _onForegroundMessage(RemoteMessage message) {
    final RemoteNotification? n = message.notification;
    if (n == null) return;
    _ref.read(runNotifierProvider).alert(
          title: n.title ?? 'FitBox',
          body: n.body ?? '',
        );
  }

  Future<void> unregister() async {
    if (kIsWeb) return;
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _ref.read(appDioProvider).post<dynamic>(
          '/push/unregister',
          data: <String, dynamic>{'token': token},
        );
      }
    } catch (_) {/* best effort */}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));
