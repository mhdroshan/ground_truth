import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:groundtruth/providers/app_state.dart';
import 'package:groundtruth/providers/location_service.dart';
import 'package:groundtruth/screens/create_post_screen.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  group('CreatePostScreen Media Buttons Test', () {
    testWidgets('Shows Photo, Video, Voice buttons and excludes file attachment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
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

      // Find Photo, Video, Voice buttons
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Voice'), findsOneWidget);

      // Verify file upload clip button is NOT present
      expect(find.byIcon(Icons.attach_file), findsNothing);

      // Verify no 'Attach Verified Photo' bottom sheet is shown on launch
      expect(find.text('Attach Verified Photo'), findsNothing);
    });

    testWidgets('Tapping Voice button activates live audio recorder studio', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
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

      // Find and tap Voice button
      final voiceBtn = find.text('Voice');
      expect(voiceBtn, findsOneWidget);
      await tester.tap(voiceBtn);
      await tester.pumpAndSettle();

      // Voice studio card should appear
      expect(find.text('ON-SITE AUDIO RECORDER'), findsOneWidget);
      expect(find.text('Start Recording'), findsOneWidget);
    });

    testWidgets('Tapping Photo button triggers direct uploader without modal sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();
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
