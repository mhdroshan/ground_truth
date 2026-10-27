import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/models/event_model.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/create_post_screen.dart';
import 'package:groundtruth/screens/write_screen.dart';
import 'package:groundtruth/utils/geofence_math.dart';
import 'package:shared_preferences/shared_preferences.dart';



class _MockHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _MockHttpClientRequest();
  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = 0;
  @override
  bool persistentConnection = false;
  @override
  bool bufferOutput = true;
  @override
  void add(List<int> data) {}
  @override
  void write(Object? obj) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  static final _body = utf8.encode('{"data": []}');

  @override
  int get statusCode => 200;
  @override
  bool get isRedirect => false;
  @override
  String get reasonPhrase => 'OK';
  @override
  List<RedirectInfo> get redirects => const [];
  @override
  bool get persistentConnection => false;
  @override
  int get contentLength => _body.length;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_body).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
  });

  group('Presence Simulator Removal & Geofence Post Gate Tests', () {
    testWidgets('CreatePostScreen allows editing if user is inside event radius',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();
      // Default location is at Delhi Farmers Protest (Jantar Mantar)
      final delhiEvent = appState.events.firstWhere((e) => e.id == 'delhi_protest_2026');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<LocationService>.value(value: locationService),
          ],
          child: MaterialApp(
            home: CreatePostScreen(event: delhiEvent),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show the composer
      expect(find.text('Report Draft'), findsOneWidget);
      expect(find.text('POSTING TO: '), findsOneWidget);
      expect(find.text('Publish'), findsOneWidget);
      expect(find.text('Posting Restricted'), findsNothing);
    });

    testWidgets('CreatePostScreen restricts and blocks entry if user is outside event radius',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();
      // London Fire event is thousands of miles away from Delhi
      final londonEvent = appState.events.firstWhere((e) => e.id == 'london_fire_2026');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<LocationService>.value(value: locationService),
          ],
          child: MaterialApp(
            home: CreatePostScreen(event: londonEvent),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should be blocked by Physical Geofence Gate
      expect(find.text('Posting Restricted'), findsOneWidget);
      expect(find.text('Physical Geofence Gate'), findsOneWidget);
      expect(find.textContaining('outside radius'), findsOneWidget);
      expect(find.text('Back to Tags Feed'), findsOneWidget);
      // Publish button must not be visible on restricted screen
      expect(find.text('Publish'), findsNothing);
    });

    testWidgets('WriteScreen locks post entry for outside events and shows geofence rule',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();
      appState.events.add(
        EventModel(
          id: 'test_outside_event_lock',
          title: 'Remote Lock Test Tag',
          tagName: '#RemoteLockTag',
          description: 'A test tag far away from user location',
          category: EventCategory.protest,
          riskLevel: RiskLevel.high,
          status: EventStatus.live,
          city: 'Remote City',
          country: 'Test Country',
          center: const GeoPoint(10.0, 10.0, 'Remote Center'),
          radiusMeters: 500,
          bannerImageUrl: 'https://example.com/test.jpg',
          startTime: DateTime.now(),
          activeContributors: 10,
          totalPosts: 5,
          totalVideos: 1,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<LocationService>.value(value: locationService),
          ],
          child: const MaterialApp(
            home: WriteScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that no presence simulation buttons exist
      expect(find.text('ENTER ZONE'), findsNothing);
      expect(find.text('Simulated presence'), findsNothing);

      // Verify that events outside user location have locked buttons
      expect(find.text('Outside Radius • Post Locked'), findsWidgets);

      // Tapping a locked button triggers restriction SnackBar and does NOT navigate to CreatePostScreen
      await tester.tap(find.text('Outside Radius • Post Locked').first);
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Cannot enter: You must be physically inside'), findsOneWidget);
      expect(find.text('Report Draft'), findsNothing);
    });

    testWidgets('WriteScreen unlocks post entry for #Namleveed when user location is at event coordinates',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();

      // Simulate real device GPS fix at user location for #Namleveed
      locationService.setLocationFix(
        10.13039,
        76.29412,
        4.0,
        label: 'Sandeepsadan house, Kerala',
      );

      final namleveedEvent = EventModel(
        id: 'namleveed_tag_id',
        title: 'Namle veed',
        tagName: '#Namleveed',
        description: 'Verified Ground Tag',
        category: EventCategory.publicGathering,
        riskLevel: RiskLevel.high,
        status: EventStatus.live,
        city: 'Sandeepsadan house',
        country: 'Verified Ground',
        center: const GeoPoint(10.13039, 76.29412, 'Sandeepsadan house'),
        radiusMeters: 3507.0,
        bannerImageUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205',
        startTime: DateTime.now(),
        activeContributors: 1,
        totalPosts: 0,
        totalVideos: 0,
      );
      appState.events.add(namleveedEvent);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<LocationService>.value(value: locationService),
          ],
          child: const MaterialApp(
            home: WriteScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show unlocked simplified CTA button with Write Post (no tag in CTA)
      expect(find.text('Write Post'), findsOneWidget);
      expect(find.text('Write Post Under #Namleveed'), findsNothing);
      expect(find.text('View Feed'), findsNothing);
      expect(find.text('Inside Geofence Boundary'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsOneWidget);

      // Subtitle should not contain "Verified Ground"
      expect(find.textContaining('Verified Ground'), findsNothing);
      expect(find.textContaining('Sandeepsadan house • 1 contributor • 0 posts'), findsOneWidget);

      // Tapping on the tag chip opens EventDetailScreen
      await tester.tap(find.text('#Namleveed').last);
      await tester.pumpAndSettle();
      expect(find.text('#Namleveed'), findsWidgets);
    });

    testWidgets('WriteScreen sorts tags placing inside geofence tags first',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();

      locationService.setLocationFix(10.0, 10.0, 4.0, label: 'Test Origin');

      final outsideTag = EventModel(
        id: 'outside_tag',
        title: 'Far Away Event',
        tagName: '#FarAway',
        description: 'Outside geofence tag',
        category: EventCategory.protest,
        riskLevel: RiskLevel.low,
        status: EventStatus.live,
        city: 'Far City',
        country: 'Far Country',
        center: const GeoPoint(10.5, 10.5, 'Far Point'),
        radiusMeters: 1000.0,
        bannerImageUrl: 'https://example.com/banner.jpg',
        startTime: DateTime.now(),
        activeContributors: 2,
        totalPosts: 1,
        totalVideos: 0,
      );

      final insideTag = EventModel(
        id: 'inside_tag',
        title: 'Inside Zone Event',
        tagName: '#InsideZone',
        description: 'Inside geofence tag',
        category: EventCategory.publicGathering,
        riskLevel: RiskLevel.low,
        status: EventStatus.live,
        city: 'Local City',
        country: 'Local Country',
        center: const GeoPoint(10.0, 10.0, 'Center Point'),
        radiusMeters: 2000.0,
        bannerImageUrl: 'https://example.com/banner.jpg',
        startTime: DateTime.now(),
        activeContributors: 5,
        totalPosts: 3,
        totalVideos: 1,
      );

      // Add outside tag first, then inside tag
      appState.events.add(outsideTag);
      appState.events.add(insideTag);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>.value(value: appState),
            ChangeNotifierProvider<LocationService>.value(value: locationService),
          ],
          child: const MaterialApp(
            home: WriteScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final insideFinder = find.text('#InsideZone').last;
      final outsideFinder = find.text('#FarAway');
      expect(insideFinder, findsOneWidget);
      expect(outsideFinder, findsOneWidget);

      // Inside tag card must appear vertically above outside tag card
      final insideY = tester.getTopLeft(insideFinder).dy;
      final outsideY = tester.getTopLeft(outsideFinder).dy;
      expect(insideY, lessThan(outsideY));

      // Boundary UI checks
      expect(find.text('Inside Geofence Boundary'), findsOneWidget);
      expect(find.text('UNLOCKED'), findsOneWidget);
      expect(find.text('LOCKED'), findsWidgets);
    });
  });
}
