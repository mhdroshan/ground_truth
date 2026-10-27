import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/models/event_model.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/profile_screen.dart';
import 'package:groundtruth/utils/geofence_math.dart';

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
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  testWidgets('ProfileScreen displays verified location card when location is fetched properly', (WidgetTester tester) async {
    final locationService = LocationService();
    final appState = AppState();

    // Add a real tag near the user
    appState.createTag(
      title: 'KochiProtest',
      description: 'Public eyewitness tag for testing',
      category: EventCategory.protest,
      scope: EventScope.cityWide,
      radiusValue: 2.0,
      radiusUnit: 'km',
      center: const GeoPoint(9.9420, 76.2660),
      city: 'Kochi',
      country: 'India',
    );

    // 1. Set real GPS fix (location fetched properly)
    locationService.setLocationFix(
      9.9406,
      76.2653,
      4.2,
      label: 'Kochi, Kerala, India',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocationService>.value(value: locationService),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify User identity exists
    expect(find.text(appState.currentUser.name), findsOneWidget);

    // Verify Verified Location pill under handle exists
    expect(find.text('Kochi, Kerala, India'), findsAtLeastNWidgets(1));
    expect(find.text('±4m'), findsOneWidget);

    // Verify the dedicated "CURRENT PHYSICAL PRESENCE" card exists
    expect(find.text('CURRENT PHYSICAL PRESENCE'), findsOneWidget);
    expect(find.text('Verified Ground Location'), findsOneWidget);
    expect(find.text('±4.2m'), findsOneWidget);

    // Verify coordinate string is shown
    expect(find.textContaining('9.9406° N, 76.2653° E'), findsOneWidget);

    // Verify security & attestation badges
    expect(find.text('No Mock GPS'), findsOneWidget);
    expect(find.text('Hardware Attested'), findsOneWidget);
    expect(find.text('Cell & Wi-Fi Matched'), findsOneWidget);

    // Because (9.9406, 76.2653) is within 2km of (9.9420, 76.2660) (about 175 meters away),
    // the user is physically INSIDE the tag!
    expect(find.text('On-Site Eyewitness Clearance: ACTIVE'), findsOneWidget);
    expect(find.textContaining('You are physically inside #KochiProtest'), findsOneWidget);
  });

  testWidgets('ProfileScreen displays acquire prompt when location is not yet fetched', (WidgetTester tester) async {
    final locationService = LocationService();
    final appState = AppState();

    // Do NOT set location fix, so hasRealGpsFix is false initially (or error)
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocationService>.value(value: locationService),
          ChangeNotifierProvider<AppState>.value(value: appState),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();

    // Should display the "Verify Ground Presence" prompt and "Acquire" button
    expect(find.text('Verify Ground Presence'), findsOneWidget);
    expect(find.text('Acquire'), findsOneWidget);
  });
}
