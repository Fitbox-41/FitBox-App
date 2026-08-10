import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in the browser, telling the user if it couldn't be opened.
///
/// The legal pages (privacy policy, terms) must be genuinely reachable from the
/// app — app stores require it for an app that collects location — so a link
/// that silently does nothing is worse than no link at all.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  bool ok = false;
  try {
    ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    ok = false;
  }
  if (!ok && messenger != null) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not open $url')),
    );
  }
}
