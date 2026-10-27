import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/main.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/main_navigation_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest();
  }
}

class _MockHttpClientRequest extends Fake implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }
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
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GroundTruth app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocationService()),
          ChangeNotifierProvider(create: (_) => AppState()),
        ],
        child: const GroundTruthApp(),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify MainNavigationShell is mounted
    expect(find.byType(MainNavigationShell), findsOneWidget);

    // Verify Bottom Navigation items exist (Home, Read, Write, Profile)
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Write'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Tap Read tab
    await tester.tap(find.text('Read'));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify ReadScreen header and trending posts exist
    expect(find.text('Global Read & Discover'), findsOneWidget);
    expect(find.text('Worldwide Trending Posts'), findsOneWidget);

    // Verify World Map Tag View is removed
    expect(find.text('World Map Tag View'), findsNothing);
  });
}
