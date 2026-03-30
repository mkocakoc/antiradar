import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/radar.dart';
import '../../domain/entities/speed_tunnel.dart';
import '../../utility/polyline_mapper.dart';
import '../../engine/services/adaptive_location_service.dart';
import 'radar_icon_factory.dart';
import 'radar_map_style.dart';

class RadarMapPage extends StatefulWidget {
  const RadarMapPage({
    super.key,
    required this.radars,
    required this.speedTunnels,
    this.stylePreset = RadarMapStylePreset.night,
  });

  final List<Radar> radars;
  final List<SpeedTunnel> speedTunnels;
  final RadarMapStylePreset stylePreset;

  @override
  State<RadarMapPage> createState() => _RadarMapPageState();
}

class _RadarMapPageState extends State<RadarMapPage> {
  final PolylineMapper _polylineMapper = const PolylineMapper();
  final AdaptiveLocationService _locationService = AdaptiveLocationService();

  GoogleMapController? _controller;
  StreamSubscription<Position>? _positionSubscription;
  BitmapDescriptor _radarIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

  GeoPoint? _userLocation;
  Radar? _approachingRadar;
  double? _approachingDistanceMeters;

  String? _lastAnimatedRadarId;
  DateTime? _lastAnimationAt;
  bool _pendingOverviewFocus = false;
  bool _locationServiceEnabled = true;
  LocationPermission? _locationPermission;

  @override
  void initState() {
    super.initState();
    _prepareMapAssets();
    _listenLocation();
    _pendingOverviewFocus = _hasRenderableRouteData();
  }

  @override
  void didUpdateWidget(covariant RadarMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldSignature = _routeSignature(oldWidget.radars, oldWidget.speedTunnels);
    final newSignature = _routeSignature(widget.radars, widget.speedTunnels);

    if (oldSignature != newSignature) {
      _pendingOverviewFocus = _hasRenderableRouteData();
      _focusRouteOverviewIfNeeded();
    }
  }

  Future<void> _prepareMapAssets() async {
    final icon = await RadarIconFactory.create();
    if (!mounted) return;
    setState(() => _radarIcon = icon);
  }

  Future<void> _listenLocation() async {
    try {
      _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      _locationPermission = await Geolocator.checkPermission();

      if (!_locationServiceEnabled) {
        if (mounted) setState(() {});
        return;
      }

      if (_locationPermission == LocationPermission.denied) {
        _locationPermission = await Geolocator.requestPermission();
      }

      if (_locationPermission == LocationPermission.denied ||
          _locationPermission == LocationPermission.deniedForever) {
        if (mounted) setState(() {});
        return;
      }

      _positionSubscription = _locationService.stream.listen(_onPosition);
      await _locationService.start();
    } catch (_) {
      // keep map usable even if location is denied
      if (mounted) setState(() {});
    }
  }

  void _onPosition(Position position) {
    final current = GeoPoint(lat: position.latitude, lng: position.longitude);

    Radar? nearest;
    double nearestDistance = double.infinity;

    for (final radar in widget.radars.where((radar) => radar.path.isNotEmpty)) {
      final start = radar.path.first;
      final distance = Geolocator.distanceBetween(
        current.lat,
        current.lng,
        start.lat,
        start.lng,
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = radar;
      }
    }

    if (mounted) {
      setState(() {
        _userLocation = current;
        _approachingRadar = nearest;
        _approachingDistanceMeters = nearestDistance.isFinite ? nearestDistance : null;
      });
    }

    if (nearest != null && nearestDistance <= 1000) {
      _animateToRadarIfNeeded(nearest, nearestDistance);
    }
  }

  Future<void> _animateToRadarIfNeeded(Radar radar, double distanceMeters) async {
    final startPoint = radar.path.first;
    final now = DateTime.now();

    final recentlyAnimated = _lastAnimationAt != null && now.difference(_lastAnimationAt!) < const Duration(seconds: 12);
    final sameRadar = _lastAnimatedRadarId == radar.id;
    if (sameRadar && recentlyAnimated) return;

    final targetZoom = distanceMeters < 350 ? 16.8 : 15.2;

    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(startPoint.lat, startPoint.lng),
          zoom: targetZoom,
          tilt: 45,
          bearing: 20,
        ),
      ),
    );

    _lastAnimatedRadarId = radar.id;
    _lastAnimationAt = now;
  }

  String _routeSignature(List<Radar> radars, List<SpeedTunnel> speedTunnels) {
    final firstRadarId = radars.isNotEmpty ? radars.first.id : 'none';
    final firstTunnelId = speedTunnels.isNotEmpty ? speedTunnels.first.id : 'none';
    return '${radars.length}|${speedTunnels.length}|$firstRadarId|$firstTunnelId';
  }

  bool _hasRenderableRouteData() {
    final hasRadarPath = widget.radars.any((item) => item.path.isNotEmpty);
    final hasTunnelPath = widget.speedTunnels.any((item) => item.path.isNotEmpty);
    return hasRadarPath || hasTunnelPath;
  }

  List<GeoPoint> _allRoutePoints() {
    final points = <GeoPoint>[];
    for (final radar in widget.radars) {
      points.addAll(radar.path);
    }
    for (final tunnel in widget.speedTunnels) {
      points.addAll(tunnel.path);
    }
    return points;
  }

  Future<void> _focusRouteOverviewIfNeeded() async {
    if (!_pendingOverviewFocus || _controller == null) return;

    final points = _allRoutePoints();
    if (points.isEmpty) {
      _pendingOverviewFocus = false;
      return;
    }

    final first = points.first;
    var minLat = first.lat;
    var maxLat = first.lat;
    var minLng = first.lng;
    var maxLng = first.lng;

    for (final point in points.skip(1)) {
      if (point.lat < minLat) minLat = point.lat;
      if (point.lat > maxLat) maxLat = point.lat;
      if (point.lng < minLng) minLng = point.lng;
      if (point.lng > maxLng) maxLng = point.lng;
    }

    try {
      if ((maxLat - minLat).abs() < 0.0005 && (maxLng - minLng).abs() < 0.0005) {
        await _controller?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(first.lat, first.lng), 12.8),
        );
      } else {
        await _controller?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            64,
          ),
        );
      }
      _pendingOverviewFocus = false;
    } catch (_) {
      // Map size may not be ready yet, try once more shortly.
      Future<void>.delayed(const Duration(milliseconds: 300), _focusRouteOverviewIfNeeded);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _locationService.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _initialCameraTarget();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            style: RadarMapStyle.byPreset(widget.stylePreset),
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 10.8,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            markers: _buildRadarMarkers(),
            polylines: {
              ..._buildSpeedTunnelPolylines(),
              ..._buildRadarPolylines(),
            },
            onMapCreated: (controller) {
              _controller = controller;
              _focusRouteOverviewIfNeeded();
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      'Radar View',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildFloatingRadarCard(context),
        ],
      ),
    );
  }

  Set<Marker> _buildRadarMarkers() {
    return widget.radars
        .where((radar) => radar.path.isNotEmpty)
        .map(
          (radar) => Marker(
            markerId: MarkerId(radar.id),
            position: LatLng(radar.path.first.lat, radar.path.first.lng),
            icon: _radarIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: radar.label ?? 'Radar Noktası',
              snippet: radar.road ?? radar.district,
            ),
          ),
        )
        .toSet();
  }

  Set<Polyline> _buildSpeedTunnelPolylines() {
    return widget.speedTunnels
        .where((tunnel) => tunnel.path.length >= 2)
        .map(
          (tunnel) => Polyline(
            polylineId: PolylineId('speed-${tunnel.id}'),
            points: _polylineMapper.toLatLngList(tunnel.path),
            width: 6,
            color: const Color(0xFF0EA5E9),
            patterns: [
              PatternItem.dash(20),
              PatternItem.gap(12),
            ],
            geodesic: true,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        )
        .toSet();
  }

  Set<Polyline> _buildRadarPolylines() {
    return widget.radars
        .where((radar) => radar.path.length >= 2)
        .map(
          (radar) => Polyline(
            polylineId: PolylineId('radar-${radar.id}'),
            points: _polylineMapper.toLatLngList(radar.path),
            width: 4,
            color: const Color(0xFFFB7185),
            geodesic: true,
          ),
        )
        .toSet();
  }

  LatLng _initialCameraTarget() {
    if (widget.radars.isNotEmpty && widget.radars.first.path.isNotEmpty) {
      final p = widget.radars.first.path.first;
      return LatLng(p.lat, p.lng);
    }

    if (widget.speedTunnels.isNotEmpty && widget.speedTunnels.first.path.isNotEmpty) {
      final p = widget.speedTunnels.first.path.first;
      return LatLng(p.lat, p.lng);
    }

    return const LatLng(39.9255, 32.8663);
  }

  Widget _buildFloatingRadarCard(BuildContext context) {
    final radar = _approachingRadar;
    final distance = _approachingDistanceMeters;

    final isActive = radar != null && distance != null && distance <= 1000;
    final activeRadar = radar;
    final activeDistance = distance;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F172A) : const Color(0xCC111827),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isActive ? const Color(0xFFF43F5E) : const Color(0xFF374151),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0x33F43F5E) : const Color(0x3322D3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isActive ? Icons.radar : Icons.route,
                  color: isActive ? const Color(0xFFF43F5E) : const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? (activeRadar!.label ?? 'Yaklaşan Radar')
                          : 'Yaklaşan radar bekleniyor',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isActive
                          ? 'Kalan mesafe: ${activeDistance!.round()} m'
          : _buildIdleLocationMessage(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFD1D5DB),
                          ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFF43F5E),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildIdleLocationMessage() {
    if (!_locationServiceEnabled) {
      return 'Konum servisi kapalı. GPS açınca radar takibi aktif olur.';
    }

    if (_locationPermission == LocationPermission.deniedForever) {
      return 'Konum izni kalıcı reddedildi. Ayarlardan izin verin.';
    }

    if (_locationPermission == LocationPermission.denied) {
      return 'Konum izni bekleniyor. İzin verince canlı takip başlar.';
    }

    if (_userLocation == null) {
      return 'Canlı konum bekleniyor...';
    }

    return '1000 m içine girildiğinde otomatik odaklanır';
  }
}
