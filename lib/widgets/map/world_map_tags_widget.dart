import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../screens/event_detail_screen.dart';

class WorldMapTagsWidget extends StatefulWidget {
  final List<EventModel> events;
  final Function(EventModel)? onSelectEvent;

  const WorldMapTagsWidget({
    super.key,
    required this.events,
    this.onSelectEvent,
  });

  @override
  State<WorldMapTagsWidget> createState() => _WorldMapTagsWidgetState();
}

class _WorldMapTagsWidgetState extends State<WorldMapTagsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  EventModel? _selectedEvent;
  double _zoom = 1.0;
  Offset _panOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    if (widget.events.isNotEmpty) {
      _selectedEvent = widget.events.first;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark tactical map background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Map Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'GLOBAL GEOFENCE RADAR',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF334155),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.events.length} ACTIVE HOTSPOTS',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                // Zoom & reset controls
                Row(
                  children: [
                    _buildMiniButton(Icons.add, () {
                      setState(() {
                        _zoom = (_zoom * 1.25).clamp(0.8, 3.0);
                      });
                    }),
                    const SizedBox(width: 6),
                    _buildMiniButton(Icons.remove, () {
                      setState(() {
                        _zoom = (_zoom / 1.25).clamp(0.8, 3.0);
                      });
                    }),
                    const SizedBox(width: 6),
                    _buildMiniButton(Icons.restart_alt, () {
                      setState(() {
                        _zoom = 1.0;
                        _panOffset = Offset.zero;
                      });
                    }),
                  ],
                ),
              ],
            ),
          ),

          // Map Canvas with Animated Beacons
          SizedBox(
            height: 250,
            width: double.infinity,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _panOffset += details.delta;
                });
              },
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: _WorldMapCustomPainter(
                          events: widget.events,
                          selectedEvent: _selectedEvent,
                          pulseProgress: _pulseController.value,
                          zoom: _zoom,
                          panOffset: _panOffset,
                        ),
                        child: _buildInteractivePinsOverlay(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Selected Event Preview Card at Bottom of Map
          if (_selectedEvent != null)
            _buildSelectedEventCard(context, _selectedEvent!),
        ],
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF334155),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildInteractivePinsOverlay(double width, double height) {
    return Stack(
      children: widget.events.map((ev) {
        // Project lat/lng to canvas coordinates
        final xNorm = (ev.center.longitude + 180.0) / 360.0;
        final yNorm = (90.0 - ev.center.latitude) / 180.0;

        final rawX = xNorm * width;
        final rawY = yNorm * height;

        final cx = width / 2;
        final cy = height / 2;
        final transformedX = cx + (rawX - cx) * _zoom + _panOffset.dx;
        final transformedY = cy + (rawY - cy) * _zoom + _panOffset.dy;

        final isSel = _selectedEvent?.id == ev.id;

        return Positioned(
          left: transformedX - 60,
          top: transformedY - 34,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedEvent = ev);
              widget.onSelectEvent?.call(ev);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tag Name Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF2563EB) : const Color(0xFF1E293B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? const Color(0xFF60A5FA) : const Color(0xFF475569),
                      width: isSel ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ev.category == EventCategory.protest
                            ? Icons.campaign_rounded
                            : (ev.category == EventCategory.naturalDisaster
                                ? Icons.warning_rounded
                                : (ev.category == EventCategory.fire
                                    ? Icons.local_fire_department_rounded
                                    : Icons.tag_rounded)),
                        size: 10,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ev.tagName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSel ? 10.5 : 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                // Glowing Pin Center
                Container(
                  width: isSel ? 12 : 9,
                  height: isSel ? 12 : 9,
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF38BDF8) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (isSel ? const Color(0xFF38BDF8) : const Color(0xFFEF4444)).withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedEventCard(BuildContext context, EventModel ev) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Row(
        children: [
          // Banner Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              ev.bannerImageUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 54,
                height: 54,
                color: const Color(0xFF334155),
                child: const Icon(Icons.public, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ev.tagName,
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFEF4444), width: 0.8),
                      ),
                      child: Text(
                        ev.status.label,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${ev.city}, ${ev.country} • ${ev.activeContributors} contributors',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(eventId: ev.id),
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Explore', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldMapCustomPainter extends CustomPainter {
  final List<EventModel> events;
  final EventModel? selectedEvent;
  final double pulseProgress;
  final double zoom;
  final Offset panOffset;

  _WorldMapCustomPainter({
    required this.events,
    required this.selectedEvent,
    required this.pulseProgress,
    required this.zoom,
    required this.panOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // Ocean / Dark Canvas Background
    final oceanPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), oceanPaint);

    // Apply zoom & pan centered
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.translate(cx + panOffset.dx, cy + panOffset.dy);
    canvas.scale(zoom);
    canvas.translate(-cx, -cy);

    // Latitude & Longitude Subtle Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.6)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Meridians
    for (int i = 1; i <= 5; i++) {
      final x = size.width * (i / 6.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Parallels (Equator, Tropics)
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Equator highlight
    final equatorPaint = Paint()
      ..color = const Color(0xFF334155).withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), equatorPaint);

    // Stylized Continents Outlines
    final landPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;

    final landBorderPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // 1. North America
    final na = Path();
    na.moveTo(w * 0.12, h * 0.18);
    na.lineTo(w * 0.28, h * 0.16);
    na.lineTo(w * 0.32, h * 0.28);
    na.lineTo(w * 0.24, h * 0.42);
    na.lineTo(w * 0.18, h * 0.45);
    na.lineTo(w * 0.14, h * 0.32);
    na.close();
    canvas.drawPath(na, landPaint);
    canvas.drawPath(na, landBorderPaint);

    // 2. South America
    final sa = Path();
    sa.moveTo(w * 0.26, h * 0.48);
    sa.lineTo(w * 0.35, h * 0.52);
    sa.lineTo(w * 0.32, h * 0.74);
    sa.lineTo(w * 0.28, h * 0.82);
    sa.lineTo(w * 0.24, h * 0.62);
    sa.close();
    canvas.drawPath(sa, landPaint);
    canvas.drawPath(sa, landBorderPaint);

    // 3. Europe
    final eu = Path();
    eu.moveTo(w * 0.46, h * 0.20);
    eu.lineTo(w * 0.56, h * 0.18);
    eu.lineTo(w * 0.54, h * 0.34);
    eu.lineTo(w * 0.45, h * 0.33);
    eu.close();
    canvas.drawPath(eu, landPaint);
    canvas.drawPath(eu, landBorderPaint);

    // 4. Africa
    final af = Path();
    af.moveTo(w * 0.46, h * 0.38);
    af.lineTo(w * 0.58, h * 0.38);
    af.lineTo(w * 0.59, h * 0.56);
    af.lineTo(w * 0.54, h * 0.72);
    af.lineTo(w * 0.46, h * 0.55);
    af.close();
    canvas.drawPath(af, landPaint);
    canvas.drawPath(af, landBorderPaint);

    // 5. Asia & India
    final as = Path();
    as.moveTo(w * 0.57, h * 0.16);
    as.lineTo(w * 0.88, h * 0.18);
    as.lineTo(w * 0.86, h * 0.46);
    as.lineTo(w * 0.72, h * 0.54);
    // Indian subcontinent peninsula
    as.lineTo(w * 0.69, h * 0.52);
    as.lineTo(w * 0.67, h * 0.44);
    as.lineTo(w * 0.58, h * 0.34);
    as.close();
    canvas.drawPath(as, landPaint);
    canvas.drawPath(as, landBorderPaint);

    // 6. Australia
    final au = Path();
    au.moveTo(w * 0.78, h * 0.62);
    au.lineTo(w * 0.89, h * 0.64);
    au.lineTo(w * 0.87, h * 0.80);
    au.lineTo(w * 0.76, h * 0.78);
    au.close();
    canvas.drawPath(au, landPaint);
    canvas.drawPath(au, landBorderPaint);

    // Radar pulsing circles around tag locations
    for (final ev in events) {
      final xNorm = (ev.center.longitude + 180.0) / 360.0;
      final yNorm = (90.0 - ev.center.latitude) / 180.0;

      final px = xNorm * size.width;
      final py = yNorm * size.height;

      final isSel = selectedEvent?.id == ev.id;
      final pulseRadius = (16.0 + (pulseProgress * 28.0));
      final pulseAlpha = (1.0 - pulseProgress).clamp(0.0, 1.0);

      final pulsePaint = Paint()
        ..color = (isSel ? const Color(0xFF38BDF8) : const Color(0xFFEF4444)).withValues(alpha: pulseAlpha * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(px, py), pulseRadius, pulsePaint);

      // Inner pulse
      final innerRadius = (8.0 + (pulseProgress * 12.0));
      final innerPulsePaint = Paint()
        ..color = (isSel ? const Color(0xFF38BDF8) : const Color(0xFFEF4444)).withValues(alpha: pulseAlpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(Offset(px, py), innerRadius, innerPulsePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorldMapCustomPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.zoom != zoom ||
        oldDelegate.panOffset != panOffset ||
        oldDelegate.selectedEvent?.id != selectedEvent?.id;
  }
}
