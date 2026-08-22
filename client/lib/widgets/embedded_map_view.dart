import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'map_view_stub.dart'
    if (dart.library.html) 'map_view_web.dart' as map_impl;

class EmbeddedGoogleMapView extends StatefulWidget {
  final String mapQuery;
  final String facilityName;
  final String address;
  final String distance;
  final String driveTime;

  const EmbeddedGoogleMapView({
    super.key,
    required this.mapQuery,
    required this.facilityName,
    required this.address,
    required this.distance,
    required this.driveTime,
  });

  @override
  State<EmbeddedGoogleMapView> createState() => _EmbeddedGoogleMapViewState();
}

class _EmbeddedGoogleMapViewState extends State<EmbeddedGoogleMapView> {
  late String _viewId;

  @override
  void initState() {
    super.initState();
    _updateViewId();
  }

  @override
  void didUpdateWidget(covariant EmbeddedGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapQuery != widget.mapQuery) {
      _updateViewId();
    }
  }

  void _updateViewId() {
    _viewId = 'gmaps_iframe_${widget.mapQuery.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _openFullGoogleMaps() async {
    final encoded = Uri.encodeComponent(widget.mapQuery);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(url);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final encodedQuery = Uri.encodeComponent(widget.mapQuery);

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
                      style: GoogleFonts.inter(
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1244A2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Full Screen ↗',
                        style: GoogleFonts.inter(
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
              child: kIsWeb
                  ? map_impl.buildGoogleMapsIframe(
                      mapQuery: widget.mapQuery,
                      viewId: _viewId,
                    )
                  : _buildFallbackInteractiveMap(encodedQuery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackInteractiveMap(String encodedQuery) {
    return Stack(
      children: [
        // Dark Map Grid Theme
        Positioned.fill(
          child: Container(
            color: const Color(0xFF0B132B),
            child: CustomPaint(
              painter: _EmbeddedMapGridPainter(),
            ),
          ),
        ),

        // Center Pin with Facility Details
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1244A2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1244A2).withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF475569)),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.facilityName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.address} • ${widget.distance} (${widget.driveTime})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _openFullGoogleMaps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1244A2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 16),
                label: Text(
                  'Launch Google Maps GPS',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmbeddedMapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = 1.0;

    final roadPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..cubicTo(size.width * 0.3, size.height * 0.4, size.width * 0.7, size.height * 0.6, size.width, size.height * 0.5);
    canvas.drawPath(path, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
