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

/// Opens a URL *over* the app — Chrome Custom Tabs on Android, Safari View
/// Controller on iOS — so the person stays in FitBox and comes back with the
/// system's own back/close button.
///
/// This is how the shop is opened, in preference to the two obvious
/// alternatives. Handing the URL to the browser bounces the user out into
/// another app, which the owner didn't want; embedding a `WebView` keeps them
/// in but means shipping and maintaining a second rendering engine — a heavier
/// binary, a slower first paint, and *our* problem every time the shop's
/// checkout, payment sheet or login misbehaves inside it. The in-app browser
/// view is the real browser: full speed, its own cookies and autofill, nothing
/// for this app to maintain, and the shop stays the shop's responsibility.
///
/// Falls back to the external browser on the rare device with no Custom Tabs
/// provider, so the link always works.
Future<void> openInAppBrowser(BuildContext context, String url) async {
  final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(context);
  final Uri uri = Uri.parse(url);
  bool ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && messenger != null) {
    messenger.showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
