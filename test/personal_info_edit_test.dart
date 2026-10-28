import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/models/user_model.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/edit_personal_info_screen.dart';
import 'package:groundtruth/screens/settings_screen.dart';
import 'package:groundtruth/widgets/common/safe_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _transparent1x1Png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

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
  HttpHeaders get headers => _MockHttpHeaders();

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

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

Widget createTestApp(Widget child, {AppState? appState, LocationService? locationService}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AppState>(create: (_) => appState ?? AppState()),
      ChangeNotifierProvider<LocationService>(create: (_) => locationService ?? LocationService()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('Personal Info & Profile Picture Tests', () {
    test('getUserAvatarProvider handles base64 data URLs and http URLs without crashing', () {
      final base64Provider = getUserAvatarProvider('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==');
      expect(base64Provider, isA<MemoryImage>());

      final httpProvider = getUserAvatarProvider('https://example.com/avatar.jpg');
      expect(httpProvider, isA<NetworkImage>());

      final nullProvider = getUserAvatarProvider(null);
      expect(nullProvider, isNull);

      final emptyProvider = getUserAvatarProvider('');
      expect(emptyProvider, isNull);
    });

    test('AppState.updateCurrentUserProfile updates profile fields and persists session', () async {
      final appState = AppState();

      expect(appState.currentUser.name, isNotEmpty);

      final success = await appState.updateCurrentUserProfile(
        name: 'Jane Doe',
        handle: 'janereports', // should be formatted to @janereports
        email: 'jane@groundtruth.org',
        avatarUrl: 'https://example.com/jane.jpg',
        bio: 'Investigative field journalist in Mumbai',
        location: 'Mumbai, India',
        organization: 'Independent Press',
      );

      expect(success, isTrue);
      expect(appState.currentUser.name, 'Jane Doe');
      expect(appState.currentUser.handle, '@janereports');
      expect(appState.currentUser.email, 'jane@groundtruth.org');
      expect(appState.currentUser.avatarUrl, 'https://example.com/jane.jpg');
      expect(appState.currentUser.bio, 'Investigative field journalist in Mumbai');
      expect(appState.currentUser.location, 'Mumbai, India');
      expect(appState.currentUser.organization, 'Independent Press');

      // Verify persistence in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedUserJson = prefs.getString('groundtruth_user_data');
      expect(savedUserJson, isNotNull);
      final decoded = json.decode(savedUserJson!);
      expect(decoded['name'], 'Jane Doe');
      expect(decoded['handle'], '@janereports');
    });

    testWidgets('SettingsScreen displays Personal Info option and navigates to EditPersonalInfoScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      final appState = AppState();

      await tester.pumpWidget(createTestApp(const SettingsScreen(), appState: appState));
      await tester.pumpAndSettle();

      // Check for Personal Info option in Settings
      expect(find.text('Personal Info'), findsOneWidget);
      expect(find.text('Update your name, photo, and contact details'), findsOneWidget);

      // Tap on Personal Info
      await tester.tap(find.text('Personal Info'));
      await tester.pumpAndSettle();

      // Should have navigated to EditPersonalInfoScreen
      expect(find.byType(EditPersonalInfoScreen), findsOneWidget);
      expect(find.text('Change Profile Picture'), findsOneWidget);
      expect(find.text('Save Personal Info'), findsOneWidget);
    });

    testWidgets('EditPersonalInfoScreen allows editing fields and saving changes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      final appState = AppState();

      await tester.pumpWidget(createTestApp(const EditPersonalInfoScreen(), appState: appState));
      await tester.pumpAndSettle();

      // Verify fields exist
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Handle / Public Username'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Coverage Location / Region'), findsOneWidget);
      expect(find.text('Organization / Publication'), findsOneWidget);
      expect(find.text('Eyewitness Bio / Focus'), findsOneWidget);
      expect(find.text('Change Profile Picture'), findsOneWidget);

      // Tap Change Profile Picture to check bottom sheet options
      await tester.tap(find.text('Change Profile Picture'));
      await tester.pumpAndSettle();

      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Choose Preset Avatar'), findsOneWidget);
      expect(find.text('Enter Image URL'), findsOneWidget);

      // Tap Preset Avatar
      await tester.tap(find.text('Choose Preset Avatar'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a Verified Avatar Preset'), findsOneWidget);

      // Select 'Field Reporter' preset
      await tester.tap(find.text('Field Reporter'));
      await tester.pumpAndSettle();

      // Edit name and bio
      final nameField = find.widgetWithText(TextFormField, appState.currentUser.name);
      await tester.enterText(nameField, 'Arjun Varma');

      // Click Save in AppBar
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Profile should be updated in AppState
      expect(appState.currentUser.name, 'Arjun Varma');
      expect(appState.currentUser.avatarUrl, contains('1507003211169'));
    });
  });
}
