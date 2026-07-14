// Exposes `fetchHealthStats()` backed by Health Connect / HealthKit on mobile,
// and a no-op on web (health uses dart:io and has no web support).
export 'health_source_stub.dart'
    if (dart.library.io) 'health_source_io.dart';
