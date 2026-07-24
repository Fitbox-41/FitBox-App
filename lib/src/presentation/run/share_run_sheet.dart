import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/geo_point.dart';
import '../../data/models/run_activity.dart';

enum _CardStyle { map, story, transparent }

/// Strava-style "Share Activity" screen. First snapshots the run's route on a
/// real Google map (a live map can't be captured by RepaintBoundary), then lets
/// you swipe between share-card styles and share the selected one as an image.
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

  Uint8List? _mapBytes;
  late bool _preparing;

  bool get _hasRoute => widget.run.route.length >= 2;

  @override
  void initState() {
    super.initState();
    _preparing = _hasRoute; // snapshot the map first when there's a route
  }

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
      final Directory dir = await getTemporaryDirectory();
      final File file = File(
          '${dir.path}/fitbox_run_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(data.buffer.asUint8List());
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
      body: _preparing ? _preparingView() : _carouselView(cs),
    );
  }

  // Renders a real map of the route off-to-the-side and snapshots it once ready.
  Widget _preparingView() {
    return Stack(
      children: <Widget>[
        // The map must be laid out + visible to load tiles; keep it faint under
        // the overlay while it snapshots.
        Opacity(
          opacity: 0.25,
          child: _SnapshotMap(
            route: widget.run.route,
            onSnapshot: (Uint8List? bytes) {
              if (!mounted) return;
              setState(() {
                _mapBytes = bytes;
                _preparing = false;
              });
            },
          ),
        ),
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6)),
              SizedBox(height: 14),
              Text('Preparing your cards…'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _carouselView(ColorScheme cs) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 8),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (int i) => setState(() => _index = i),
            itemCount: _styles.length,
            itemBuilder: (BuildContext context, int i) {
              final _CardStyle style = _styles[i];
              final Widget card = RepaintBoundary(
                key: _keys[i],
                child: _ShareCard(
                    run: widget.run, style: style, mapBytes: _mapBytes),
              );
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    // Transparent style: show a checkerboard BEHIND (not captured)
                    // so it's clear the exported PNG is see-through.
                    child: style == _CardStyle.transparent
                        ? DecoratedBox(
                            decoration: const BoxDecoration(),
                            child: CustomPaint(
                              painter: _CheckerPainter(),
                              child: card,
                            ),
                          )
                        : card,
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
    );
  }
}

/// A live map used only to produce a snapshot image of the route.
class _SnapshotMap extends StatefulWidget {
  const _SnapshotMap({required this.route, required this.onSnapshot});

  final List<GeoPoint> route;
  final ValueChanged<Uint8List?> onSnapshot;

  @override
  State<_SnapshotMap> createState() => _SnapshotMapState();
}

class _SnapshotMapState extends State<_SnapshotMap> {
  GoogleMapController? _controller;
  bool _done = false;

  List<LatLng> get _pts =>
      widget.route.map((GeoPoint g) => LatLng(g.lat, g.lng)).toList();

  LatLngBounds _bounds(List<LatLng> pts) {
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final LatLng p in pts) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _capture() async {
    if (_done) return;
    _done = true;
    try {
      final Uint8List? bytes = await _controller?.takeSnapshot();
      widget.onSnapshot(bytes);
    } catch (_) {
      widget.onSnapshot(null);
    }
  }

  Future<void> _onCreated(GoogleMapController c) async {
    _controller = c;
    final List<LatLng> pts = _pts;
    await Future<void>.delayed(const Duration(milliseconds: 250));
    try {
      await c.animateCamera(CameraUpdate.newLatLngBounds(_bounds(pts), 56));
    } catch (_) {}
    // Give tiles time to load, then snapshot.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    await _capture();
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> pts = _pts;
    // Safety net: if the map never settles, proceed without it.
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (!_done) _capture();
    });
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: pts.first, zoom: 15),
      style: _darkMapStyle,
      liteModeEnabled: false,
      myLocationEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      onMapCreated: _onCreated,
      polylines: <Polyline>{
        Polyline(
          polylineId: const PolylineId('r'),
          points: pts,
          color: FitBoxColors.red,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      },
    );
  }
}

/// One share-card style, rendered at a fixed 9:16 aspect for capture.
class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.run, required this.style, this.mapBytes});

  final RunActivity run;
  final _CardStyle style;
  final Uint8List? mapBytes;

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

  bool get _hasMap => mapBytes != null;

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

  Widget _mapImageOr(Widget fallback) => _hasMap
      ? Image.memory(mapBytes!, fit: BoxFit.cover)
      : fallback;

  Widget _trace({double stroke = 5}) =>
      CustomPaint(painter: _RoutePainter(run.route, stroke: stroke));

  // 1) Map-style — real map (or trace fallback), stats over a bottom scrim.
  Widget _mapCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _mapImageOr(
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF15181C), Color(0xFF0B0D10)],
                ),
              ),
              child: Stack(fit: StackFit.expand, children: <Widget>[
                CustomPaint(painter: _GridPainter()),
                Padding(padding: const EdgeInsets.all(22), child: _trace(stroke: 6)),
              ]),
            ),
          ),
          // Bottom scrim for legibility.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: <Color>[Color(0x00000000), Color(0xE6000000)],
              ),
            ),
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
                const SizedBox(height: 8),
                Text(run.title.toUpperCase(),
                    style:
                        AppTypography.heading(size: 22, color: Colors.white)),
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
    );
  }

  // 2) Story-style — branded dark card with a map/route panel + stats.
  Widget _storyCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        color: const Color(0xFF0A0C0F),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(painter: _StripePainter()),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 40, 22, 28),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _mapImageOr(
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10)),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.all(18),
                          child: _trace(stroke: 5),
                        ),
                      ),
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

  // 3) Transparent — genuinely transparent PNG (no background painted).
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
    final List<Offset> pts =
        route.map((GeoPoint g) => Offset(g.lng * cosLat, -g.lat)).toList();
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
    final double offX = (size.width - spanX * scale) / 2;
    final double offY = (size.height - spanY * scale) / 2;
    final Path path = Path();
    for (int i = 0; i < pts.length; i++) {
      final double x = offX + (pts[i].dx - minX) * scale;
      final double y = offY + (pts[i].dy - minY) * scale;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
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

/// Grey checkerboard shown behind the transparent card in the PREVIEW only, so
/// the see-through nature is obvious (it is not part of the exported image).
class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double c = 22;
    final Paint a = Paint()..color = const Color(0xFF2A2E33);
    final Paint b = Paint()..color = const Color(0xFF20242A);
    for (int y = 0; y * c < size.height; y++) {
      for (int x = 0; x * c < size.width; x++) {
        canvas.drawRect(
          Rect.fromLTWH(x * c, y * c, c, c),
          (x + y).isEven ? a : b,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#12151a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#12151a"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#22262d"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0c0f"}]}
]
''';
