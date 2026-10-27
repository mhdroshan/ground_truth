import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/location_service.dart';
import '../theme/app_colors.dart';
import '../utils/geofence_math.dart';
import '../widgets/map/tactical_radar_map.dart';
import '../widgets/common/risk_badge.dart';
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
        title: const Text('Tactical GeoFence Radar'),
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

          // Event Selector Slider & Detail Card
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(top: BorderSide(color: AppColors.border, width: 1.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.verifiedGreen.withValues(alpha: 0.2)
                                    : AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSel ? AppColors.verifiedGreen : AppColors.border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isSel ? AppColors.verifiedGreen : AppColors.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    ev.tagName,
                                    style: TextStyle(
                                      color: isSel ? AppColors.verifiedGreen : AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
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
                  const SizedBox(height: 14),

                  // Selected Event Info Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD0E1FD),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      activeEvent.formattedRadius,
                                      style: const TextStyle(
                                        color: AppColors.primaryNavy,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: (isInside ? AppColors.verifiedGreen : AppColors.alertAmber).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isInside ? 'YOU ARE IN GEOFENCE' : '${GeofenceMath.formatDistance(distance)} AWAY',
                                  style: TextStyle(
                                    color: isInside ? AppColors.verifiedGreen : AppColors.alertAmber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${activeEvent.tagName} — ${activeEvent.title}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
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
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
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
                                  label: const Text('OPEN EVENT FEED', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
