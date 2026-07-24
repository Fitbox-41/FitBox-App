import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/geo_point.dart';
import '../../data/models/run_activity.dart';

enum _CardStyle { map, story, transparent }

/// Strava-style "Share Activity" screen: swipe between share-card styles, then
/// share the selected one as an image to any app (Instagram, WhatsApp, …).
class ShareRunSheet extends StatefulWidget {
  const ShareRunSheet({super.key, required this.run});

  final RunActivity run;

  @override
  State<ShareRunSheet> createState() => _ShareRunSheetState();
}

class _ShareRunSheetState extends State<ShareRunSheet> {
  final PageController _controller = PageController(viewportFraction: 0.82);
  final List<GlobalKey> _keys =
      List<GlobalKey>.generate(3, (_) => GlobalKey());
  static const List<_CardStyle> _styles = <_CardStyle>[
    _CardStyle.map,
    _CardStyle.story,
    _CardStyle.transparent,
  ];
  int _index = 0;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final RenderRepaintBoundary boundary = _keys[_index]
          .currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? data =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      final Uint8List bytes = data.buffer.asUint8List();
      final Directory dir = await getTemporaryDirectory();
      final File file = File(
          '${dir.path}/fitbox_run_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        <XFile>[XFile(file.path)],
        text: 'My FitBox run — run, capture, earn. 🏃',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't create the share image.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Activity'),
        leading: const CloseButton(),
      ),
      body: Column(
        children: <Widget>[
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (int i) => setState(() => _index = i),
              itemCount: _styles.length,
              itemBuilder: (BuildContext context, int i) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: RepaintBoundary(
                        key: _keys[i],
                        child: _ShareCard(run: widget.run, style: _styles[i]),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List<Widget>.generate(_styles.length, (int i) {
              final bool active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active
                      ? FitBoxColors.red
                      : cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 16, 20, 20 + MediaQuery.paddingOf(context).bottom),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.ios_share),
                label: Text(_busy ? 'Preparing…' : 'Share'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One share-card style, rendered at a fixed 9:16 aspect for capture.
class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.run, required this.style});

  final RunActivity run;
  final _CardStyle style;

  String get _distance => '${run.distanceKm.toStringAsFixed(2)} km';
  String get _time {
    final int s = run.duration.inSeconds;
    return '${s ~/ 60}m ${s % 60}s';
  }

  String get _pace {
    final double p = run.paceMinPerKm;
    if (p <= 0) return "0'00";
    final int m = p.floor();
    final int sec = ((p - m) * 60).round();
    return "$m'${sec.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case _CardStyle.map:
        return _mapCard();
      case _CardStyle.story:
        return _storyCard();
      case _CardStyle.transparent:
        return _transparentCard();
    }
  }

  Widget _brand({Color color = Colors.white}) => Text('FITBOX SPORTS',
      style: AppTypography.brand(
          size: 15, weight: FontWeight.w700, letterSpacing: 1.5, color: color));

  Widget _trace({double stroke = 5}) =>
      CustomPaint(painter: _RoutePainter(run.route, stroke: stroke));

  // 1) Map-style — route trace over the app's dark "map" gradient, stats bottom.
  Widget _mapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF15181C), Color(0xFF0B0D10)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(painter: _GridPainter()),
            Padding(
              padding: const EdgeInsets.all(22),
              child: _trace(stroke: 6),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Icon(Icons.directions_run,
                          color: Colors.white, size: 22),
                      _brand(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(run.title.toUpperCase(),
                      style: AppTypography.heading(size: 22, color: Colors.white)),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      _stat('DISTANCE', _distance),
                      const SizedBox(width: 22),
                      _stat('TIME', _time),
                      const SizedBox(width: 22),
                      _stat('PACE', '$_pace /km'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2) Story-style — branded dark card, centered route panel, stats + tagline.
  Widget _storyCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF0A0C0F),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Brand accent stripes across the top corner.
            CustomPaint(painter: _StripePainter()),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 40, 22, 28),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: _trace(stroke: 5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(run.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.heading(size: 24, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _stat('DISTANCE', _distance, center: true),
                      _stat('TIME', _time, center: true),
                      _stat('PACE', _pace, center: true),
                    ],
                  ),
                  const Spacer(),
                  Text('RUN · CAPTURE · EARN',
                      style: AppTypography.label(
                          size: 10,
                          color: Colors.white.withValues(alpha: 0.5))),
                  const SizedBox(height: 8),
                  _brand(color: FitBoxColors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3) Transparent — no background (transparent PNG) to drop onto any story.
  Widget _transparentCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _bigStat('DISTANCE', _distance),
          const SizedBox(height: 22),
          _bigStat('TIME', _time),
          const SizedBox(height: 22),
          _bigStat('PACE', '$_pace /km'),
          const SizedBox(height: 24),
          SizedBox(height: 150, child: _trace(stroke: 6)),
          const SizedBox(height: 16),
          _brand(),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {bool center = false}) {
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: <Widget>[
        Text(label,
            style: AppTypography.label(
                size: 9, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 3),
        Text(value,
            style: AppTypography.brand(
                size: 18,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Colors.white)),
      ],
    );
  }

  Widget _bigStat(String label, String value) {
    return Column(
      children: <Widget>[
        Text(label,
            style: AppTypography.label(
                size: 12, color: Colors.white.withValues(alpha: 0.85))),
        const SizedBox(height: 4),
        Text(value,
            style: AppTypography.brand(
                size: 34,
                weight: FontWeight.w700,
                letterSpacing: -0.3,
                color: Colors.white)),
      ],
    );
  }
}

/// Draws the run route, normalized + aspect-correct, as a glowing red line.
class _RoutePainter extends CustomPainter {
  _RoutePainter(this.route, {this.stroke = 5});

  final List<GeoPoint> route;
  final double stroke;
  static const Color color = FitBoxColors.red;

  @override
  void paint(Canvas canvas, Size size) {
    if (route.length < 2) return;
    final double midLat = route
            .map((GeoPoint g) => g.lat)
            .reduce((double a, double b) => a + b) /
        route.length;
    final double cosLat = math.cos(midLat * math.pi / 180).abs().clamp(0.01, 1);

    // Project to a flat, aspect-correct space.
    final List<Offset> pts = route
        .map((GeoPoint g) => Offset(g.lng * cosLat, -g.lat))
        .toList();
    double minX = pts.first.dx, maxX = pts.first.dx;
    double minY = pts.first.dy, maxY = pts.first.dy;
    for (final Offset o in pts) {
      minX = math.min(minX, o.dx);
      maxX = math.max(maxX, o.dx);
      minY = math.min(minY, o.dy);
      maxY = math.max(maxY, o.dy);
    }
    final double spanX = math.max(maxX - minX, 1e-9);
    final double spanY = math.max(maxY - minY, 1e-9);
    const double pad = 16;
    final double scale = math.min(
        (size.width - pad * 2) / spanX, (size.height - pad * 2) / spanY);
    final double drawW = spanX * scale;
    final double drawH = spanY * scale;
    final double offX = (size.width - drawW) / 2;
    final double offY = (size.height - drawH) / 2;

    final Path path = Path();
    for (int i = 0; i < pts.length; i++) {
      final double x = offX + (pts[i].dx - minX) * scale;
      final double y = offY + (pts[i].dy - minY) * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke + 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;
    const double step = 40;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()..color = FitBoxColors.red.withValues(alpha: 0.9);
    for (int i = 0; i < 2; i++) {
      final double y = -40.0 + i * 46;
      final Path path = Path()
        ..moveTo(size.width * 0.55, y)
        ..lineTo(size.width * 1.1, y)
        ..lineTo(size.width * 1.1, y + 26)
        ..lineTo(size.width * 0.55 + 40, y + 26)
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
