// lib/main.dart

import 'package:ecowaste_cotonou/presentation/providers/calendar_provider.dart';
import 'package:ecowaste_cotonou/presentation/providers/map_provider.dart';
import 'package:ecowaste_cotonou/presentation/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/schedule_provider.dart';
import 'presentation/providers/guide_provider.dart';
import 'presentation/providers/points_provider.dart';
import 'presentation/screens/splash/splash_screen.dart' as presentation;

void main() async {
  // Assure que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Lance l'application
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => GuideProvider()),
        ChangeNotifierProvider(create: (_) => PointsProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoWaste Cotonou',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const presentation.SplashScreen(),
    );
  }
}
