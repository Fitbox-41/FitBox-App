import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import 'models/wallet.dart';

/// Reads the shared wallet from the app backend (`GET /api/wallet`).
class WalletRepository {
  WalletRepository(this._dio);

  final Dio _dio;

  Future<WalletData> fetch() async {
    final res = await _dio.get('/wallet');
    return WalletData.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => WalletRepository(ref.watch(appDioProvider)),
);
