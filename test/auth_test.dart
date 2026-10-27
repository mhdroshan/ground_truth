import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/models/user_model.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/login_screen.dart';

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

void main() {
  setUp(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('UserModel Authentication Tests', () {
    test('UserModel serialization and JSON parsing', () {
      final json = {
        'id': 'user_123',
        'name': 'Test Reporter',
        'email': 'reporter@groundtruth.org',
        'handle': '@test_reporter',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'trustScore': 95,
        'verifiedContributions': 10,
        'accuracyRating': 99.5,
        'helpfulVotes': 150,
        'tier': 'Tier 1 Verified Senior Eyewitness',
        'deviceModel': 'Pixel 9 Pro Hardware Keystore',
        'hasAttestationKey': true,
        'role': 'journalist',
        'xp': 800,
        'level': 3,
        'levelTitle': 'Senior Truth Validator',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 'user_123');
      expect(user.name, 'Test Reporter');
      expect(user.email, 'reporter@groundtruth.org');
      expect(user.handle, '@test_reporter');
      expect(user.trustScore, 95);
      expect(user.role, 'journalist');

      final serialized = user.toJson();
      expect(serialized['email'], 'reporter@groundtruth.org');
      expect(serialized['trustScore'], 95);
    });
  });

  group('AppState Auth State Management Tests', () {
    test('Initial user session is unauthenticated (guest mode)', () {
      final appState = AppState();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.currentUser.handle, '@guest');
      expect(appState.currentUser.tier, 'Guest');
    });

    test('Logout clears session and switches to guest profile', () {
      final appState = AppState();
      appState.logout();
      expect(appState.isLoggedIn, isFalse);
      expect(appState.currentUser.handle, '@guest');
      expect(appState.currentUser.tier, 'Guest');
      expect(appState.authToken, isNull);
    });

    test('Register creates new active session', () async {
      final appState = AppState();
      final success = await appState.register(
        name: 'Kabir Verma',
        email: 'kabir@groundtruth.org',
        handle: '@kabir_field',
        password: 'Password123!',
      );
      expect(success, isTrue);
      expect(appState.isLoggedIn, isTrue);
      expect(appState.currentUser.name, 'Kabir Verma');
      expect(appState.currentUser.handle, '@kabir_field');
    });
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('Renders simple LoginScreen with email, password, and sign-up toggle', (tester) async {
      final appState = AppState();
      final locationService = LocationService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appState),
            ChangeNotifierProvider.value(value: locationService),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header titles
      expect(find.text('Welcome to GroundTruth'), findsOneWidget);
      expect(find.text('Enter your email and password to log in'), findsOneWidget);

      // Check form fields
      expect(find.text('Email or Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Check Log In button
      expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);

      // Toggle to Sign Up mode
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create an Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Create Account'), findsOneWidget);
    });
  });
}

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}
