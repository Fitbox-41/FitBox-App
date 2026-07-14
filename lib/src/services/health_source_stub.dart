import '../data/models/fitness_stats.dart';

/// Web / unsupported platforms have no Health API.
Future<FitnessStats?> fetchHealthStats() async => null;
