// lib/presentation/providers/auth_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';

/// Source de vérité unique pour l'utilisateur connecté et son profil.
/// Le profil est écouté en temps réel : toute écriture dans Firestore
/// (édition, réglages de notifications…) se reflète automatiquement.
class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository;
  late final AuthService _authService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isSigningUp = false;
  bool _streakChecked = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider({FirebaseAuth? auth, UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository() {
    _authService = AuthService(auth ?? FirebaseAuth.instance, _userRepository);
    _authSubscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  /// Réagit à la connexion / déconnexion
  void _onAuthChanged(User? user) {
    _user = user;
    _userProfile = null;
    _streakChecked = false;
    _profileSubscription?.cancel();
    _profileSubscription = null;

    if (user != null) {
      _profileSubscription = _userRepository
          .getUserProfileStream(user.uid)
          .listen(
            (profile) => _onProfile(user, profile),
            onError: (e) => debugPrint('Erreur chargement profil: $e'),
          );
    }
    notifyListeners();
  }

  Future<void> _onProfile(User user, UserProfile? profile) async {
    if (profile == null) {
      // Compte Auth sans profil (ex: inscription interrompue) : on le recrée.
      // Pendant une inscription, c'est signUp() qui écrit le profil complet.
      if (!_isSigningUp) {
        try {
          await _userRepository.createUserProfile(
            UserProfile.initial(
              id: user.uid,
              email: user.email,
              name: user.displayName,
            ),
          );
        } catch (e) {
          debugPrint('Erreur création profil: $e');
        }
      }
      return; // le stream renverra le profil créé
    }

    _userProfile = profile;
    notifyListeners();
    await _updateStreakOncePerDay(profile);
  }

  /// Met à jour les jours consécutifs, au plus une écriture par jour
  Future<void> _updateStreakOncePerDay(UserProfile profile) async {
    if (_streakChecked) return;
    _streakChecked = true;

    final last = profile.statistics.lastActive;
    final now = DateTime.now();
    final sameDay =
        last.year == now.year && last.month == now.month && last.day == now.day;
    if (sameDay) return;

    try {
      await _userRepository.updateUserProfile(
        profile.updateStatistics(profile.statistics.updateConsecutiveDays()),
      );
    } catch (e) {
      debugPrint('Erreur mise à jour des jours consécutifs: $e');
    }
  }

  /// Inscription avec email
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String district,
  }) async {
    _isSigningUp = true;
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
      _errorMessage = _readableError(e);
      _setLoading(false);
      return false;
    } finally {
      _isSigningUp = false;
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
      _errorMessage = _readableError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _setLoading(false);
    } catch (e) {
      _errorMessage = _readableError(e);
      _setLoading(false);
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
      _errorMessage = _readableError(e);
      _setLoading(false);
      return false;
    }
  }

  /// Met à jour le profil utilisateur. Renvoie `false` si l'écriture échoue.
  Future<bool> updateProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      await _userRepository.updateUserProfile(profile);
      _userProfile = profile;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _readableError(e);
      _setLoading(false);
      return false;
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

  /// AuthService lève des String (messages traduits) ou des Exception
  String _readableError(Object e) =>
      e is String ? e : e.toString().replaceFirst('Exception: ', '');
}
