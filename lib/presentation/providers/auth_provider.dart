// lib/presentation/providers/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';

/// Provider pour gérer l'état d'authentification
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService(
    FirebaseAuth.instance,
    UserRepository(),
  );
  final UserRepository _userRepository = UserRepository();

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuth();
  }

  /// Initialise l'écoute des changements d'authentification
  void _initAuth() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Charge le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile(String userId) async {
    try {
      _userProfile = await _userRepository.getUserProfile(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement profil: $e');
    }
  }

  /// Inscription avec email
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String district,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        district: district,
      );

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Connexion avec email
  Future<bool> signIn({required String email, required String password}) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.signInWithEmail(email: email, password: password);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _user = null;
      _userProfile = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _authService.resetPassword(email);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// Met à jour le profil utilisateur
  Future<void> updateProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      await _userRepository.updateUserProfile(profile);
      _userProfile = profile;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Définit l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
