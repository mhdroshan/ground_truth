import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'providers/location_service.dart';
import 'screens/main_navigation_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final appState = AppState();
  // Restore persisted session before UI mount so eyewitness stays logged in seamlessly
  await appState.loadPersistedSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider.value(value: appState),
      ],
      child: const GroundTruthApp(),
    ),
  );
}

class GroundTruthApp extends StatelessWidget {
  const GroundTruthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroundTruth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigationShell(),
    );
  }
}
