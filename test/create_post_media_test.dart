import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/create_post_screen.dart';



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
  });

  group('CreatePostScreen Media Buttons Test', () {
    testWidgets('Shows Photo, Video, Poll buttons and excludes Voice option and file attachment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();
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

      // Find Photo, Video, Poll buttons
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Poll'), findsOneWidget);

      // Verify Voice option is completely removed
      expect(find.text('Voice'), findsNothing);
      expect(find.text('ON-SITE AUDIO RECORDER'), findsNothing);

      // Verify file upload clip button is NOT present
      expect(find.byIcon(Icons.attach_file), findsNothing);

      // Verify no 'Attach Verified Photo' bottom sheet is shown on launch
      expect(find.text('Attach Verified Photo'), findsNothing);
    });

    testWidgets('Tapping Photo button triggers direct uploader without modal sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState(autoLoadRemote: false);
      final locationService = LocationService();
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

      // Tap Photo button
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Verify no "Attach Verified Photo" modal sheet opens
      expect(find.text('Attach Verified Photo'), findsNothing);
    });
  });
}
