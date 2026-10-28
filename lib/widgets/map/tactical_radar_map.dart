import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/geofence_math.dart';

enum MapTileTheme {
  voyager('Tactical Light', 'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png'),
  street('Street Map', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
  satellite('Satellite', 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}');

  final String label;
  final String urlTemplate;
  const MapTileTheme(this.label, this.urlTemplate);
}

class TacticalRadarMap extends StatefulWidget {
  final EventModel event;
  final GeoPoint userLocation;
  final GeoPoint? customCenter;
  final double height;
  final bool isInteractive;
  final String? eventLabel;
  final VoidCallback? onExpand;
  final ValueChanged<GeoPoint>? onLocationSelected;

  const TacticalRadarMap({
    super.key,
    required this.event,
    required this.userLocation,
    this.customCenter,
    this.height = 240,
    this.isInteractive = true,
    this.eventLabel,
    this.onExpand,
    this.onLocationSelected,
  });

  @override
  State<TacticalRadarMap> createState() => _TacticalRadarMapState();
}

class _TacticalRadarMapState extends State<TacticalRadarMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  MapTileTheme _currentTheme = MapTileTheme.voyager;
  bool _showLayerPicker = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void didUpdateWidget(TacticalRadarMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCenter = oldWidget.customCenter ?? oldWidget.event.center;
    final newCenter = widget.customCenter ?? widget.event.center;
    final oldRadius = oldWidget.event.radiusMeters;
    final newRadius = widget.event.radiusMeters;

    if (oldCenter.latitude != newCenter.latitude ||
        oldCenter.longitude != newCenter.longitude ||
        oldRadius != newRadius) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final targetZoom = _calculateZoom(newRadius, newCenter.latitude);
        _mapController.move(LatLng(newCenter.latitude, newCenter.longitude), targetZoom);
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  GeoPoint get _activeCenter => widget.customCenter ?? widget.event.center;

  double _calculateZoom(double radiusMeters, double latitude) {
    if (radiusMeters <= 0) return 14.0;
    final latRad = latitude * pi / 180.0;
    final effectiveHeight = (widget.height.isInfinite || widget.height <= 0) ? 280.0 : widget.height;
    final targetPixels = max(effectiveHeight * 0.65, 140.0);
    final metersPerPixel = (radiusMeters * 2.0) / targetPixels;
    if (metersPerPixel <= 0) return 14.0;
    final zoom = log((156543.03392 * cos(latRad)) / metersPerPixel) / ln2;
    if (zoom.isNaN || zoom.isInfinite) return 14.0;
    return zoom.clamp(2.0, 18.0);
  }

  void _recenter() {
    final center = _activeCenter;
    final zoom = _calculateZoom(widget.event.radiusMeters, center.latitude);
    _mapController.move(LatLng(center.latitude, center.longitude), zoom);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom + 1).clamp(2.0, 18.0));
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, (currentZoom - 1).clamp(2.0, 18.0));
  }

  @override
  Widget build(BuildContext context) {
    final center = _activeCenter;
    final centerLatLng = LatLng(center.latitude, center.longitude);
    final userLatLng = LatLng(widget.userLocation.latitude, widget.userLocation.longitude);
    final initialZoom = _calculateZoom(widget.event.radiusMeters, center.latitude);

    final distanceToUser = GeofenceMath.distanceBetweenPoints(center, widget.userLocation);
    final showSeparateUserMarker = distanceToUser > 30.0;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Live FlutterMap
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: initialZoom,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: widget.isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
              ),
              onTap: (tapPosition, point) {
                if (widget.onLocationSelected != null) {
                  widget.onLocationSelected!(
                    GeoPoint(point.latitude, point.longitude, 'Selected on Map'),
                  );
                }
              },
            ),
            children: [
              // 1. Live Tile Layer
              TileLayer(
                urlTemplate: _currentTheme.urlTemplate,
                userAgentPackageName: 'com.groundtruth.app',
                maxZoom: 19,
              ),

              // 2. Geofence Boundary Circles & Live Radar Wave
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final pulseProgress = _pulseController.value;
                  final pulseRadius = widget.event.radiusMeters * (0.2 + (pulseProgress * 0.8));
                  final pulseAlpha = (1.0 - pulseProgress) * 0.25;

                  return CircleLayer(
                    circles: [
                      // Pulsing radar sweep circle
                      CircleMarker(
                        point: centerLatLng,
                        radius: pulseRadius,
                        useRadiusInMeter: true,
                        color: const Color(0xFF2563EB).withValues(alpha: pulseAlpha),
                        borderColor: const Color(0xFF2563EB).withValues(alpha: (1.0 - pulseProgress) * 0.5),
                        borderStrokeWidth: 1.2,
                      ),
                      // Core Geofence Boundary
                      CircleMarker(
                        point: centerLatLng,
                        radius: widget.event.radiusMeters,
                        useRadiusInMeter: true,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderColor: const Color(0xFF2563EB),
                        borderStrokeWidth: 2.0,
                      ),
                    ],
                  );
                },
              ),

              // 3. Dynamic Markers on Real Coordinates
              MarkerLayer(
                markers: [
                  // Center Anchor Marker
                  Marker(
                    point: centerLatLng,
                    width: 150,
                    height: 100,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Animated Center Radar Pulse
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final p = _pulseController.value;
                            return Container(
                              width: 18 + (p * 26),
                              height: 18 + (p * 26),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF0038A8).withValues(alpha: (1.0 - p) * 0.45),
                              ),
                            );
                          },
                        ),

                        // Solid Center Pin Dot (White ring with Navy center)
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0038A8),
                              ),
                            ),
                          ),
                        ),

                        // Post Count Pill (top-left)
                        if (widget.event.totalPosts > 0)
                          Positioned(
                            top: 14,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF86EFAC),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${widget.event.totalPosts} posts',
                                style: const TextStyle(
                                  color: Color(0xFF14532D),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),

                        // Hotspot / Tag Name Pill (bottom-right)
                        Positioned(
                          bottom: 16,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0038A8),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.event.tagName.isNotEmpty && widget.event.tagName != '#NewTag'
                                  ? widget.event.tagName
                                  : 'Hotspot',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User physical GPS location marker (if away from anchor)
                  if (showSeparateUserMarker)
                    Marker(
                      point: userLatLng,
                      width: 80,
                      height: 55,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Your GPS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFF15803D), width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Top Label Pill if specified (e.g. "CENTRAL PLAZA EVENT")
          if (widget.eventLabel != null)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 5),
                    Text(
                      widget.eventLabel!.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Layer Picker Dropdown / Flyout
          if (_showLayerPicker)
            Positioned(
              right: 52,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: MapTileTheme.values.map((theme) {
                    final isSelected = _currentTheme == theme;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _currentTheme = theme;
                          _showLayerPicker = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 14,
                              color: isSelected ? AppColors.primaryNavy : AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              theme.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected ? AppColors.primaryNavy : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Map Control Buttons (Right side: Zoom, Recenter, Layers)
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControl(Icons.add_rounded, _zoomIn, tooltip: 'Zoom In'),
                const SizedBox(height: 6),
                _buildMapControl(Icons.remove_rounded, _zoomOut, tooltip: 'Zoom Out'),
                const SizedBox(height: 6),
                _buildMapControl(
                  Icons.my_location_rounded,
                  _recenter,
                  tooltip: 'Recenter on Geofence',
                ),
                const SizedBox(height: 6),
                _buildMapControl(
                  Icons.layers_rounded,
                  () {
                    setState(() {
                      _showLayerPicker = !_showLayerPicker;
                    });
                  },
                  tooltip: 'Switch Map Style',
                  isActive: _showLayerPicker,
                ),
                if (widget.onExpand != null) ...[
                  const SizedBox(height: 6),
                  _buildMapControl(
                    Icons.fullscreen_rounded,
                    widget.onExpand!,
                    tooltip: 'Expand Map',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(
    IconData icon,
    VoidCallback onTap, {
    String? tooltip,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFF3B82F6) : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? const Color(0xFF1D4ED8) : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
