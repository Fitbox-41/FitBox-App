import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/secure_storage.dart';

const String _onboardingKey = 'onboarding_seen';

/// Whether the user has completed onboarding. Defaults to `true` (so returning
/// users never flash the intro), then hydrates from storage — first-run users
/// resolve to `false` and get routed to onboarding.
class OnboardingSeen extends Notifier<bool> {
  @override
  bool build() {
    _hydrate();
    return true;
  }

  Future<void> _hydrate() async {
    final String? v = await ref.read(secureStorageProvider).read(_onboardingKey);
    if (v != 'true') state = false;
  }

  Future<void> markSeen() async {
    await ref.read(secureStorageProvider).write(_onboardingKey, 'true');
    state = true;
  }
}

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeen, bool>(OnboardingSeen.new);
