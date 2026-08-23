import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'map_view_stub.dart'
    if (dart.library.html) 'map_view_web.dart'
    as map_impl;

enum MapStyle { streets, satellite, dark }

class EmbeddedGoogleMapView extends StatefulWidget {
  final String mapQuery;
  final String facilityName;
  final String address;
  final String distance;
  final String driveTime;
  final double latitude;
  final double longitude;

  const EmbeddedGoogleMapView({
    super.key,
    required this.mapQuery,
    required this.facilityName,
    required this.address,
    required this.distance,
    required this.driveTime,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<EmbeddedGoogleMapView> createState() => _EmbeddedGoogleMapViewState();
}

class _EmbeddedGoogleMapViewState extends State<EmbeddedGoogleMapView> {
  late String _viewId;
  late final MapController _mapController;
  MapStyle _currentStyle = MapStyle.streets;

  @override
  void initState() {
    super.initState();
    _updateViewId();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitRoute();
    });
  }

  @override
  void didUpdateWidget(covariant EmbeddedGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapQuery != widget.mapQuery) {
      _updateViewId();
    }
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _fitRoute();
    }
  }

  void _updateViewId() {
    _viewId =
        'gmaps_iframe_${widget.mapQuery.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _fitRoute() {
    try {
      final userLoc = LatLng(36.0800, -80.2650);
      final facilityLoc = LatLng(widget.latitude, widget.longitude);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([userLoc, facilityLoc]),
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } catch (_) {}
  }

  String _getTileUrl() {
    switch (_currentStyle) {
      case MapStyle.streets:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapStyle.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapStyle.dark:
        return 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
  }

  Future<void> _openFullGoogleMaps() async {
    final encoded = Uri.encodeComponent(widget.mapQuery);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) await launchUrl(url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            // Top Status Bar Badge Above Map (Unobstructed View)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF334155))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '📍 Live Location Pin Drop: ${widget.facilityName} (${widget.distance})',
                      style: AppFonts.googleSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openFullGoogleMaps,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1244A2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Full Screen ↗',
                        style: AppFonts.googleSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Live Embedded WebView Map Canvas Layer
            Expanded(
              child:
                  kIsWeb
                      ? map_impl.buildGoogleMapsIframe(
                        mapQuery: widget.mapQuery,
                        viewId: _viewId,
                      )
                      : _buildFallbackInteractiveMap(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackInteractiveMap() {
    final facilityLoc = LatLng(widget.latitude, widget.longitude);
    final userLoc = LatLng(36.0800, -80.2650);

    // Generate street-style perpendicular Turns
    final midY = (userLoc.latitude + facilityLoc.latitude) / 2;
    final midX = (userLoc.longitude + facilityLoc.longitude) / 2;
    final routePoints = [
      userLoc,
      LatLng(midY, userLoc.longitude),
      LatLng(midY, midX),
      LatLng(facilityLoc.latitude, midX),
      facilityLoc,
    ];

    final isPharmacy = widget.facilityName.toLowerCase().contains('pharmacy');
    final accentColor =
        isPharmacy ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: facilityLoc, initialZoom: 14.0),
            children: [
              TileLayer(
                urlTemplate: _getTileUrl(),
                userAgentPackageName: 'com.alternea.app',
              ),
              PolylineLayer(
                polylines: [
                  // Outer glowing route line
                  Polyline(
                    points: routePoints,
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.3),
                    strokeWidth: 8.0,
                  ),
                  // Inner neon cyan route path
                  Polyline(
                    points: routePoints,
                    color: const Color(0xFF0EA5E9),
                    strokeWidth: 3.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // User Location (Teal Pulsing Dot)
                  Marker(
                    point: userLoc,
                    width: 40,
                    height: 40,
                    child: _UserLocationMarker(),
                  ),
                  // Hospital Location (Blue/Green/Red glowing icon pin with concentric pulsing rings)
                  Marker(
                    point: facilityLoc,
                    width: 70,
                    height: 70,
                    child: _PulsingMarker(
                      color: accentColor,
                      icon:
                          isPharmacy
                              ? Icons.local_pharmacy_rounded
                              : Icons.local_hospital_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // HUD overlay in the top-left corner (Compass/GPS telemetry status)
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE GPS ROUTING',
                  style: AppFonts.googleSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF38BDF8),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Map HUD controllers on the right side
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHudButton(
                icon: Icons.add_rounded,
                tooltip: 'Zoom In',
                onPressed: () {
                  final newZoom = (_mapController.camera.zoom + 1.0).clamp(
                    1.0,
                    20.0,
                  );
                  _mapController.move(_mapController.camera.center, newZoom);
                },
              ),
              const SizedBox(height: 6),
              _buildHudButton(
                icon: Icons.remove_rounded,
                tooltip: 'Zoom Out',
                onPressed: () {
                  final newZoom = (_mapController.camera.zoom - 1.0).clamp(
                    1.0,
                    20.0,
                  );
                  _mapController.move(_mapController.camera.center, newZoom);
                },
              ),
              const SizedBox(height: 6),
              _buildHudButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Recenter Route',
                onPressed: _fitRoute,
              ),
              const SizedBox(height: 6),
              _buildHudButton(
                icon:
                    _currentStyle == MapStyle.streets
                        ? Icons.map_rounded
                        : (_currentStyle == MapStyle.satellite
                            ? Icons.satellite_rounded
                            : Icons.dark_mode_rounded),
                tooltip: 'Switch Map Style',
                onPressed: () {
                  setState(() {
                    if (_currentStyle == MapStyle.streets) {
                      _currentStyle = MapStyle.satellite;
                    } else if (_currentStyle == MapStyle.satellite) {
                      _currentStyle = MapStyle.dark;
                    } else {
                      _currentStyle = MapStyle.streets;
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // Floating controls/info overlay at the bottom
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(
                0xFF0F172A,
              ).withValues(alpha: 0.9), // Glassmorphism dark theme
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.facilityName,
                        style: AppFonts.googleSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.address} • ${widget.distance} (${widget.driveTime})',
                        style: AppFonts.googleSans(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openFullGoogleMaps,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1244A2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.navigation_rounded, size: 14),
                  label: Text(
                    'GPS',
                    style: AppFonts.googleSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHudButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class _PulsingMarker extends StatefulWidget {
  final Color color;
  final IconData icon;
  const _PulsingMarker({required this.color, required this.icon});

  @override
  State<_PulsingMarker> createState() => _PulsingMarkerState();
}

class _PulsingMarkerState extends State<_PulsingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            Container(
              width: 60 * _controller.value,
              height: 60 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: 0.25 * (1 - _controller.value),
                ),
              ),
            ),
            // Inner pulsing ring
            Container(
              width: 40 * _controller.value,
              height: 40 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(
                  alpha: 0.45 * (1 - _controller.value),
                ),
              ),
            ),
            // Center marker background shadow
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
            ),
            // Center marker circle
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                shape: BoxShape.circle,
                border: Border.all(color: widget.color, width: 2),
              ),
              child: Center(
                child: Icon(widget.icon, color: widget.color, size: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(
                0xFF0EA5E9,
              ).withValues(alpha: 0.15 + 0.25 * _controller.value),
            ),
            child: Center(
              child: Container(
                width: 11,
                height: 11,
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF38BDF8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
