import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';
import '../widgets/map/tactical_radar_map.dart';
import '../widgets/common/risk_badge.dart';
import '../widgets/common/glass_card.dart';
import 'event_detail_screen.dart';

class MapExplorerScreen extends StatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  State<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends State<MapExplorerScreen> {
  int _selectedEventIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final locationService = context.watch<LocationService>();
    final events = appState.events;

    if (events.isEmpty) {
      return const Scaffold(body: Center(child: Text('No active events')));
    }

    final activeEvent = events[_selectedEventIndex.clamp(0, events.length - 1)];
    final isInside = activeEvent.isUserInside(locationService.currentLocation);
    final distance = activeEvent.distanceFromUser(locationService.currentLocation);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tactical GeoFence Radar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Tactical Map Canvas
          Expanded(
            flex: 6,
            child: TacticalRadarMap(
              event: activeEvent,
              userLocation: locationService.currentLocation,
              height: double.infinity,
              isInteractive: true,
            ),
          ),

          // 2026 Liquid Glass Event Detail Bento Sheet
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag indicator pill
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Horizontal Event Selector Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: events.asMap().entries.map((entry) {
                            final isSel = entry.key == _selectedEventIndex;
                            final ev = entry.value;

                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedEventIndex = entry.key;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? AppColors.primaryNavy
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSel ? AppColors.primaryNavy : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: isSel ? const Color(0xFF10B981) : AppColors.textMuted,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        ev.tagName,
                                        style: TextStyle(
                                          color: isSel ? Colors.white : AppColors.textSecondary,
                                          fontSize: 11.5,
                                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Selected Event Bento Info Box
                      Expanded(
                        child: GlassCard(
                          padding: const EdgeInsets.all(14),
                          borderRadius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      RiskBadge(riskLevel: activeEvent.riskLevel),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          activeEvent.formattedRadius,
                                          style: const TextStyle(
                                            color: Color(0xFF1D4ED8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: isInside ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isInside ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
                                      ),
                                    ),
                                    child: Text(
                                      isInside ? 'YOU ARE IN GEOFENCE' : '${GeofenceMath.formatDistance(distance)} AWAY',
                                      style: TextStyle(
                                        color: isInside ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${activeEvent.tagName} — ${activeEvent.title}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                activeEvent.description,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryNavy,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: () {
                                    appState.selectEvent(activeEvent.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EventDetailScreen(eventId: activeEvent.id),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.forum_outlined, size: 16),
                                  label: const Text(
                                    'OPEN EVENT FEED',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
