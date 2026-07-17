import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A stylised stand-in for the live map (Google Maps ships once the API key is
/// available). Dark grid + a glowing red route, matching the Aerostride look, so
/// the run/territory screens read correctly before real maps arrive.
class MapPlaceholder extends StatelessWidget {
  const MapPlaceholder({super.key, this.showBadge = true});

  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFF15181C), Color(0xFF0B0D10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CustomPaint(painter: _MapPainter()),
          if (showBadge)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Text('LIVE MAP • COMING SOON',
                      style: AppText.labelCaps(context,
                          size: 10, color: Colors.white70)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Faint street grid.
    final Paint grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const double step = 44;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // A glowing red route.
    final Path route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.75)
      ..lineTo(size.width * 0.30, size.height * 0.55)
      ..lineTo(size.width * 0.30, size.height * 0.35)
      ..lineTo(size.width * 0.58, size.height * 0.35)
      ..lineTo(size.width * 0.58, size.height * 0.22)
      ..lineTo(size.width * 0.82, size.height * 0.22);

    canvas.drawPath(
      route,
      Paint()
        ..color = FitBoxColors.red.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawPath(
      route,
      Paint()
        ..color = FitBoxColors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
