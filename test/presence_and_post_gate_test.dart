import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/create_post_screen.dart';
import 'package:groundtruth/screens/write_screen.dart';

final _transparent1x1Png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

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
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();
}

class _MockHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}
}

class _MockHttpClientResponse extends Fake implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _transparent1x1Png.length;
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
    return Stream<List<int>>.value(_transparent1x1Png).listen(
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
  });

  group('Presence Simulator Removal & Geofence Post Gate Tests', () {
    testWidgets('CreatePostScreen allows editing if user is inside event radius',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
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

      final appState = AppState();
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

      final appState = AppState();
      final locationService = LocationService();

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
  });
}
