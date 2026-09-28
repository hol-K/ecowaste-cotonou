// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/services/notification_service.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/guide_provider.dart';
import 'presentation/providers/home_navigation_provider.dart';
import 'presentation/providers/map_provider.dart';
import 'presentation/providers/reminder_scheduler.dart';
import 'presentation/providers/schedule_provider.dart';
import 'presentation/screens/auth/update_password_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';

void main() async {
  // Assure que les bindings Flutter sont initialisés
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase (restaure la session), les formats de date français
  // et les notifications locales
  await Future.wait([
    Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    ),
    initializeDateFormatting('fr_FR'),
    NotificationService.instance.init(),
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
        // Rappels de collecte : suivent le quartier et les réglages du profil
        ProxyProvider<AuthProvider, ReminderScheduler>(
          lazy: false,
          create: (_) => ReminderScheduler(),
          update: (_, auth, scheduler) =>
              scheduler!..onProfileChanged(auth.userProfile),
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
    // Ouvert depuis un lien « mot de passe oublié » : on demande le nouveau
    // mot de passe avant tout le reste.
    final isPasswordRecovery = context.select<AuthProvider, bool>(
      (auth) => auth.isPasswordRecovery,
    );

    return MaterialApp(
      title: 'EcoWaste Cotonou',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      builder: (context, child) => isPasswordRecovery
          ? Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const UpdatePasswordScreen(),
              ),
            )
          : child!,
    );
  }
}
