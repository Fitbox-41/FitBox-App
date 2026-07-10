import 'package:flutter/material.dart';

/// Centres a scrollable form and caps its width, so pages read well on phones
/// (full width) and don't stretch awkwardly on tablets/PC/web.
class ResponsiveFormBody extends StatelessWidget {
  const ResponsiveFormBody({
    super.key,
    required this.child,
    this.maxWidth = 440,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
