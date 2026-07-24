import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/geo_point.dart';

/// The app's Google Map surface — matches the app theme (light map in light
/// mode, dark in dark), draws the run route in red, shows the user's location,
/// and either follows the runner live or fits the whole route. Single map
/// widget so a later swap (e.g. Mapbox) is one file.
class LiveRunMap extends StatefulWidget {
  const LiveRunMap({
    super.key,
    this.route = const <GeoPoint>[],
    this.follow = false,
    this.interactive = true,
    this.showMyLocation = true,
  });

  final List<GeoPoint> route;
  final bool follow;
  final bool interactive;
  final bool showMyLocation;

  @override
  State<LiveRunMap> createState() => _LiveRunMapState();
}

class _LiveRunMapState extends State<LiveRunMap> {
  GoogleMapController? _controller;
  bool _myLocation = false; // true once location permission is granted
  bool _followZoomed = false; // zoomed to street level on the first fix
  static const double _runZoom = 17; // street-level zoom for an active run
  static const LatLng _fallback = LatLng(20.5937, 78.9629); // India

  List<LatLng> get _points =>
      widget.route.map((GeoPoint g) => LatLng(g.lat, g.lng)).toList();

  @override
  void initState() {
    super.initState();
    if (widget.showMyLocation) _ensureLocation();
  }

  /// Requests location permission (if the onboarding screen hasn't already) so
  /// the blue dot + GPS route work, then centers the camera on the user.
  Future<void> _ensureLocation() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      final bool granted = p == LocationPermission.always ||
          p == LocationPermission.whileInUse;
      if (!granted || !mounted) return;
      setState(() => _myLocation = true);
      await _centerOnUser();
    } catch (_) {/* location unavailable */}
  }

  Future<void> _centerOnUser() async {
    if (_controller == null || widget.route.isNotEmpty) return;
    try {
      final Position? pos =
          await Geolocator.getLastKnownPosition() ?? await _currentPosition();
      if (pos != null && mounted && widget.route.isEmpty) {
        await _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
      }
    } catch (_) {}
  }

  Future<Position?> _currentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant LiveRunMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<LatLng> pts = _points;
    if (pts.isEmpty || _controller == null) return;
    if (widget.follow) {
      // First fix: zoom in to street level; after that just pan (so the user
      // can pinch-zoom without us fighting them).
      if (!_followZoomed) {
        _followZoomed = true;
        _controller!.animateCamera(
            CameraUpdate.newLatLngZoom(pts.last, _runZoom));
      } else {
        _controller!.animateCamera(CameraUpdate.newLatLng(pts.last));
      }
    }
  }

  Future<void> _onCreated(GoogleMapController controller) async {
    _controller = controller;
    final List<LatLng> pts = _points;
    if (pts.isEmpty) {
      await _centerOnUser();
    } else if (!widget.follow && pts.length >= 2) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _controller?.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsOf(pts), 48));
    }
  }

  LatLngBounds _boundsOf(List<LatLng> pts) {
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

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<LatLng> pts = _points;
    final CameraPosition initial = CameraPosition(
      target: pts.isNotEmpty ? pts.last : _fallback,
      zoom: pts.isNotEmpty ? 16 : 4,
    );
    return GoogleMap(
      initialCameraPosition: initial,
      // Dark style in dark mode; default (light) map in light mode.
      style: dark ? _darkMapStyle : _lightMapStyle,
      myLocationEnabled: widget.showMyLocation && _myLocation,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      tiltGesturesEnabled: false,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
      onMapCreated: _onCreated,
      polylines: pts.length >= 2
          ? <Polyline>{
              Polyline(
                polylineId: const PolylineId('route'),
                points: pts,
                color: FitBoxColors.red,
                width: 6,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
            }
          : <Polyline>{},
    );
  }
}

/// Dark map ("engine bay" look) so the red route pops.
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#12151a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#12151a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#22262d"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2b3038"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0c0f"}]}
]
''';

/// Clean light map (soft, low-chrome) for light theme.
const String _lightMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f5f6f8"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#e9ebef"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d6e2ef"}]}
]
''';
