// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/guide_provider.dart';
import 'presentation/providers/home_navigation_provider.dart';
import 'presentation/providers/map_provider.dart';
import 'presentation/providers/schedule_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  // Assure que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase et les formats de date français (calendrier)
  await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    initializeDateFormatting('fr_FR'),
  ]);

  // Lance l'application
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeNavigationProvider()),
        // Le calendrier suit le quartier du profil connecté
        ChangeNotifierProxyProvider<AuthProvider, ScheduleProvider>(
          create: (_) => ScheduleProvider(),
          update: (_, auth, schedule) =>
              schedule!..syncDistrict(auth.userProfile?.district),
        ),
        ChangeNotifierProvider(create: (_) => GuideProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),
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
      home: const SplashScreen(),
    );
  }
}
