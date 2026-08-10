import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/auth/auth_controller.dart';
import '../services/api_client.dart';

/// One event the user was notified about — territory contested, a season
/// settled, a challenge reward. Written server-side whenever a push is sent, so
/// this history is complete even if push was off or the banner was dismissed.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const <String, dynamic>{},
  });

  final String id;

  /// territory | season | challenge | wallet | system — drives the icon.
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['id'] ?? '').toString(),
        type: (j['type'] ?? 'system').toString(),
        title: (j['title'] ?? '').toString(),
        body: (j['body'] ?? '').toString(),
        read: j['read'] == true,
        createdAt:
            DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal() ??
                DateTime.now(),
        data: j['data'] is Map
            ? Map<String, dynamic>.from(j['data'] as Map)
            : const <String, dynamic>{},
      );

  /// "2h ago" — compact relative time for the list.
  String get relativeTime {
    final Duration d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${(d.inDays / 7).floor()}w ago';
  }
}

class NotificationsData {
  const NotificationsData({required this.items, required this.unread});

  final List<AppNotification> items;
  final int unread;
}

class NotificationsRepository {
  NotificationsRepository(this._dio);

  final Dio _dio;

  Future<NotificationsData> fetch() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/notifications');
    final Map<String, dynamic> map =
        Map<String, dynamic>.from(res.data as Map);
    final List<dynamic> list =
        (map['notifications'] as List<dynamic>?) ?? <dynamic>[];
    return NotificationsData(
      items: list
          .map((dynamic e) =>
              AppNotification.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      unread: (map['unread'] as num?)?.toInt() ?? 0,
    );
  }

  /// Marks everything read (or one, when [id] is given).
  Future<void> markRead({String? id}) async {
    await _dio.post<dynamic>('/notifications/read',
        data: <String, dynamic>{'id': ?id});
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.watch(appDioProvider)),
);

/// The signed-in user's notifications. Keyed on the user so switching accounts
/// can't show the previous one's history.
final notificationsProvider = FutureProvider<NotificationsData>((ref) async {
  ref.watch(authControllerProvider.select((AuthState s) => s.user?.id));
  return ref.watch(notificationsRepositoryProvider).fetch();
});
