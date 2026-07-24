import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/geo_point.dart';

/// The app's Google Map surface — dark-styled to match the brand, draws the run
/// route in red, and either follows the runner live or fits the whole route.
/// Kept as the single map widget so a later swap (e.g. Mapbox) is one file.
class LiveRunMap extends StatefulWidget {
  const LiveRunMap({
    super.key,
    this.route = const <GeoPoint>[],
    this.follow = false,
    this.interactive = true,
    this.showMyLocation = true,
  });

  /// Route points recorded so far (grows live during a run).
  final List<GeoPoint> route;

  /// Camera tracks the latest point (live run). When false, fits the route.
  final bool follow;

  /// Whether map gestures are enabled.
  final bool interactive;

  /// Show the blue "my location" dot.
  final bool showMyLocation;

  @override
  State<LiveRunMap> createState() => _LiveRunMapState();
}

class _LiveRunMapState extends State<LiveRunMap> {
  GoogleMapController? _controller;
  // Fallback camera (India) until we have a fix or a route.
  static const LatLng _fallback = LatLng(20.5937, 78.9629);

  List<LatLng> get _points =>
      widget.route.map((GeoPoint g) => LatLng(g.lat, g.lng)).toList();

  @override
  void didUpdateWidget(covariant LiveRunMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final List<LatLng> pts = _points;
    if (pts.isEmpty || _controller == null) return;
    if (widget.follow) {
      _controller!.animateCamera(CameraUpdate.newLatLng(pts.last));
    }
  }

  Future<void> _onCreated(GoogleMapController controller) async {
    _controller = controller;
    final List<LatLng> pts = _points;
    if (pts.isEmpty) {
      // Center on the user's last-known location for a useful first view.
      try {
        final Position? pos = await Geolocator.getLastKnownPosition();
        if (pos != null && mounted) {
          await _controller?.animateCamera(CameraUpdate.newLatLngZoom(
              LatLng(pos.latitude, pos.longitude), 16));
        }
      } catch (_) {/* no fix yet — my-location dot appears once available */}
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
    final List<LatLng> pts = _points;
    final CameraPosition initial = CameraPosition(
      target: pts.isNotEmpty ? pts.last : _fallback,
      zoom: pts.isNotEmpty ? 16 : 4,
    );
    return GoogleMap(
      initialCameraPosition: initial,
      style: _darkMapStyle,
      myLocationEnabled: widget.showMyLocation,
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

/// A restrained dark map style (roads visible, low chrome) matching the app's
/// "engine bay" look so the red route pops.
const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#12151a"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8a8f98"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#12151a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#22262d"}]},
  {"featureType":"road","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2b3038"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0c0f"}]}
]
''';
