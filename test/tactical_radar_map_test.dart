import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:groundtruth/models/event_model.dart';
import 'package:groundtruth/utils/geofence_math.dart';
import 'package:groundtruth/widgets/map/tactical_radar_map.dart';

void main() {
  testWidgets('TacticalRadarMap renders live FlutterMap with geofence and controls', (tester) async {
    final event = EventModel(
      id: 'test_event',
      title: 'Protest Rally',
      tagName: '#ProtestRally',
      description: 'Live test event',
      category: EventCategory.protest,
      riskLevel: RiskLevel.high,
      status: EventStatus.active,
      city: 'Kochi',
      country: 'India',
      center: const GeoPoint(10.1304, 76.2940),
      radiusMeters: 2500.0,
      bannerImageUrl: '',
      startTime: DateTime.now(),
      activeContributors: 10,
      totalPosts: 124,
      totalVideos: 5,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TacticalRadarMap(
            event: event,
            userLocation: const GeoPoint(10.1304, 76.2940),
            height: 250,
          ),
        ),
      ),
    );

    // Initial pump and animation settle
    await tester.pump();

    // Verify FlutterMap is rendered
    expect(find.byType(FlutterMap), findsOneWidget);

    // Verify TileLayer is present
    expect(find.byType(TileLayer), findsOneWidget);

    // Verify CircleLayer (geofence boundary) is present
    expect(find.byType(CircleLayer), findsOneWidget);

    // Verify map controls are present
    expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);

    // Verify post count pill or tag pill is rendered
    expect(find.text('124 posts'), findsOneWidget);
  });
}

