import 'package:flutter/widgets.dart';

/// Non-web platforms use the native `authenticate()` flow, so this is a no-op.
Widget googleSignInWebButton() => const SizedBox.shrink();
