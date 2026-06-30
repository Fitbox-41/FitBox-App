import 'package:flutter/material.dart';

/// Root widget for the FitBox application.
///
/// This is an intentionally minimal shell. Screens, navigation, theming and
/// state management are introduced once the app's features are defined.
class FitBoxApp extends StatelessWidget {
  const FitBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitBox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _HomePlaceholder(),
    );
  }
}

class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('FitBox'),
      ),
    );
  }
}
