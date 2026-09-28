// lib/presentation/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../onboarding/onboarding_screen.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
/// Écran de démarrage (Splash Screen)
/// Affiché pendant 3 secondes au lancement de l'app
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configuration des animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    
    // Démarre l'animation
    _controller.forward();
    
    // Navigation après 3 secondes
    _navigateToNextScreen();
  }

  /// Vérifie si c'est la première fois que l'utilisateur ouvre l'app
  /// Si oui → Onboarding, sinon → Login ou Home (si connecté)
  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    
    if (!mounted) return;
    
    // Vérifier si l'utilisateur est connecté (session restaurée par Firebase)
    final isAuthenticated = FirebaseAuth.instance.currentUser != null;
    
    Widget nextScreen;
    
    if (!hasSeenOnboarding) {
      // Première fois → Onboarding
      nextScreen = const OnboardingScreen();
    } else if (isAuthenticated) {
      // Déjà vu onboarding ET connecté → Home
      nextScreen = const HomeScreen();
    } else {
      // Déjà vu onboarding MAIS pas connecté → Login
      nextScreen = const LoginScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A3329), // background
              Color(0xFF2D5F4F), // primary
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo (icône recyclage pour l'instant)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A9B7F).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.recycling_rounded,
                      size: 80,
                      color: Color(0xFF4A9B7F), // accent
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Nom de l'application
                  const Text(
                    'EcoWaste',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  const Text(
                    'COTONOU',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF4A9B7F),
                      letterSpacing: 4,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Slogan
                  const Text(
                    'Triez intelligent, préservez Cotonou',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB8C5C0),
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 64),
                  
                  // Indicateur de chargement
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4A9B7F),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Chargement...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB8C5C0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}