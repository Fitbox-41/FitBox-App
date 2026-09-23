import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';

/// How a player appears to everyone else on the territory map.
///
/// Separate from the account name on purpose: that one belongs to the shop and
/// goes on deliveries, so renaming yourself on the map must not rename the
/// person a parcel is addressed to.
class MapIdentity {
  const MapIdentity({
    required this.accountName,
    required this.displayName,
    required this.tag,
  });

  factory MapIdentity.fromJson(Map<String, dynamic> j) => MapIdentity(
        accountName: (j['accountName'] as String?) ?? '',
        displayName: (j['displayName'] as String?) ?? '',
        tag: (j['tag'] as String?) ?? '',
      );

  final String accountName;

  /// Empty means "use the account name" — the map falls back to it.
  final String displayName;
  final String tag;

  String get effectiveName =>
      displayName.isNotEmpty ? displayName : (accountName.isNotEmpty ? accountName : 'Runner');
}

class MapIdentityRepository {
  MapIdentityRepository(this._dio);
  final Dio _dio;

  Future<MapIdentity> fetch() async {
    final Response<dynamic> res = await _dio.get<dynamic>('/account/profile');
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    return MapIdentity.fromJson(
        Map<String, dynamic>.from(data['profile'] as Map));
  }

  Future<MapIdentity> save({String? displayName, String? tag}) async {
    final Response<dynamic> res = await _dio.patch<dynamic>(
      '/account/profile',
      // Only the fields actually supplied are sent: omitting one leaves it
      // untouched server-side, while sending an empty string clears it.
      data: <String, dynamic>{
        'displayName': ?displayName,
        'tag': ?tag,
      },
    );
    final Map<dynamic, dynamic> data = res.data as Map<dynamic, dynamic>;
    return MapIdentity.fromJson(
        Map<String, dynamic>.from(data['profile'] as Map));
  }
}

final mapIdentityRepositoryProvider = Provider<MapIdentityRepository>(
  (ref) => MapIdentityRepository(ref.watch(appDioProvider)),
);

final mapIdentityProvider = FutureProvider<MapIdentity>(
  (ref) async => ref.watch(mapIdentityRepositoryProvider).fetch(),
);
