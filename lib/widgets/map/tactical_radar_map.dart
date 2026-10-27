import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/geofence_math.dart';

class TacticalRadarMap extends StatefulWidget {
  final EventModel event;
  final GeoPoint userLocation;
  final GeoPoint? customCenter;
  final double height;
  final bool isInteractive;
  final String? eventLabel;
  final VoidCallback? onExpand;

  const TacticalRadarMap({
    super.key,
    required this.event,
    required this.userLocation,
    this.customCenter,
    this.height = 240,
    this.isInteractive = false,
    this.eventLabel,
    this.onExpand,
  });

  @override
  State<TacticalRadarMap> createState() => _TacticalRadarMapState();
}

class _TacticalRadarMapState extends State<TacticalRadarMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          // Light Map Canvas
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _FigmaMapPainter(
                  pulseValue: _pulseController.value,
                ),
              );
            },
          ),

          // Top Label Pill if specified (e.g. "CENTRAL PLAZA EVENT")
          if (widget.eventLabel != null)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primaryNavy),
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

          // Map Action Buttons (Right side)
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapControl(Icons.my_location, () {}),
                const SizedBox(height: 8),
                _buildMapControl(Icons.layers_outlined, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}

class _FigmaMapPainter extends CustomPainter {
  final double pulseValue;

  _FigmaMapPainter({required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);

    // 1. Draw light map background land & roads
    final landPaint = Paint()..color = const Color(0xFFF3F5F9);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    // River / water body
    final waterPaint = Paint()..color = const Color(0xFFDCEAF7);
    final waterPath = Path();
    waterPath.moveTo(size.width * 0.1, 0);
    waterPath.quadraticBezierTo(size.width * 0.18, size.height * 0.5, size.width * 0.08, size.height);
    waterPath.lineTo(0, size.height);
    waterPath.lineTo(0, 0);
    waterPath.close();
    canvas.drawPath(waterPath, waterPaint);

    // Park / Greenery area
    final parkPaint = Paint()..color = const Color(0xFFE2F0D9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.3, size.height * 0.35),
        const Radius.circular(20),
      ),
      parkPaint,
    );

    // Roads (Main arterial white roads with subtle gray edges)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke;

    // Road 1: diagonal top-left to bottom-right
    final road1 = Path();
    road1.moveTo(0, size.height * 0.3);
    road1.lineTo(size.width, size.height * 0.85);
    canvas.drawPath(road1, roadBorderPaint);
    canvas.drawPath(road1, roadPaint);

    // Road 2: vertical curve
    final road2 = Path();
    road2.moveTo(size.width * 0.42, 0);
    road2.lineTo(size.width * 0.48, size.height);
    canvas.drawPath(road2, roadBorderPaint);
    canvas.drawPath(road2, roadPaint);

    // Road 3: horizontal
    final road3 = Path();
    road3.moveTo(0, size.height * 0.62);
    road3.lineTo(size.width, size.height * 0.58);
    canvas.drawPath(road3, roadBorderPaint);
    canvas.drawPath(road3, roadPaint);

    // Secondary smaller streets
    final streetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width * 0.2, size.height), streetPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), streetPaint);
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.2), streetPaint);

    // 2. Circular Geofence Boundary (Figma Blue Circle with translucent fill)
    final geofenceRadius = min(size.width, size.height) * 0.38;

    final geofenceFill = Paint()
      ..color = const Color(0xFF2563EB).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, geofenceRadius, geofenceFill);

    final geofenceBorder = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, geofenceRadius, geofenceBorder);

    // 3. User Radar Pulse Beacon
    final pulseRadius = 10.0 + (pulseValue * 22.0);
    final pulsePaint = Paint()
      ..color = const Color(0xFF0038A8).withValues(alpha: (1.0 - pulseValue) * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius, pulsePaint);

    // User center solid pin
    final centerOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, centerOuter);

    final centerInner = Paint()
      ..color = const Color(0xFF0038A8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6, centerInner);

    // 4. Hotspot Pill & Post Count Pill (As in Figma Screen 1)
    _drawPill(canvas, Offset(center.dx - 30, center.dy - geofenceRadius * 0.65), '124 posts', const Color(0xFF86EFAC), const Color(0xFF14532D));
    _drawPill(canvas, Offset(center.dx + 48, center.dy + 12), 'Hotspot', const Color(0xFF0038A8), Colors.white);
  }

  void _drawPill(Canvas canvas, Offset offset, String text, Color bgColor, Color textColor) {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 9.5,
      fontWeight: FontWeight.w800,
      fontFamily: 'Inter',
    );

    final textSpan = TextSpan(
      text: text,
      style: textStyle.copyWith(color: textColor),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 12;
    final pillHeight = textPainter.height + 6;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: offset, width: pillWidth, height: pillHeight),
      const Radius.circular(10),
    );

    final paint = Paint()..color = bgColor;
    canvas.drawRRect(rect, paint);

    textPainter.paint(
      canvas,
      Offset(offset.dx - textPainter.width / 2, offset.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FigmaMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}
