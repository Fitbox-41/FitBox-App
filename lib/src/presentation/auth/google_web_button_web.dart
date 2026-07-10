import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// The official Google Identity Services button (web only). Sign-in results
/// arrive through `GoogleSignIn.instance.authenticationEvents`.
Widget googleSignInWebButton() => web.renderButton();
