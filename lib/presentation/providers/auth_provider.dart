// lib/presentation/providers/auth_provider.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';

export '../../data/services/auth_service.dart' show SignUpResult;

/// Source de vérité unique pour l'utilisateur connecté et son profil.
/// Le profil est écouté en temps réel : toute écriture (édition, réglages
/// de notifications…) se reflète automatiquement.
class AuthProvider with ChangeNotifier {
  final UserRepository _userRepository;
  late final AuthService _authService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AuthChangeEvent>? _eventSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;

  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _streakChecked = false;
  bool _passwordRecovery = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  /// Vrai quand l'app a été ouverte par un lien « mot de passe oublié » :
  /// l'utilisateur doit choisir un nouveau mot de passe.
  bool get isPasswordRecovery => _passwordRecovery;

  AuthProvider({GoTrueClient? auth, UserRepository? userRepository})
    : _userRepository = userRepository ?? UserRepository() {
    _authService = AuthService(
      auth ?? Supabase.instance.client.auth,
      _userRepository,
    );
    _onAuthChanged(_authService.currentUser);
    _authSubscription = _authService.authStateChanges.listen(
      _onAuthChanged,
      // Hors connexion, le rafraîchissement du jeton émet une erreur ici
      onError: (e) => debugPrint('Erreur de session : $e'),
    );
    _eventSubscription = _authService.authEvents.listen((event) {
      if (event == AuthChangeEvent.passwordRecovery) {
        _passwordRecovery = true;
        notifyListeners();
      }
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _eventSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }

  /// Réagit à la connexion / déconnexion
  void _onAuthChanged(User? user) {
    if (user?.id == _user?.id && _profileSubscription != null) {
      _user = user; // simple rafraîchissement de jeton
      return;
    }

    _user = user;
    _userProfile = null;
    _streakChecked = false;
    _profileSubscription?.cancel();
    _profileSubscription = null;

    if (user != null) {
      _profileSubscription = _userRepository
          .getUserProfileStream(user.id)
          .listen(
            _onProfile,
            onError: (e) => debugPrint('Erreur chargement profil : $e'),
          );
    }
    notifyListeners();
  }

  void _onProfile(UserProfile? profile) {
    if (profile == null) return;
    _userProfile = profile;
    notifyListeners();
    _updateStreakOncePerDay(profile);
  }

  /// Met à jour les jours consécutifs, au plus une écriture par jour
  Future<void> _updateStreakOncePerDay(UserProfile profile) async {
    if (_streakChecked) return;
    _streakChecked = true;

    final last = profile.statistics.lastActive;
    final now = DateTime.now();
    final sameDay =
        last.year == now.year && last.month == now.month && last.day == now.day;
    // Profil tout neuf ({} en base) : on initialise aussi les statistiques
    if (sameDay && profile.statistics.consecutiveDays > 0) return;

    try {
      await _userRepository.updateUserProfile(
        profile.updateStatistics(profile.statistics.updateConsecutiveDays()),
      );
    } catch (e) {
      debugPrint('Erreur mise à jour des jours consécutifs : $e');
    }
  }

  /// Inscription avec email. Renvoie null en cas d'échec ([errorMessage]).
  Future<SignUpResult?> signUp({
    required String email,
    required String password,
    required String name,
    required String district,
  }) {
    return _run(
      () => _authService.signUpWithEmail(
        email: email,
        password: password,
        name: name,
        district: district,
      ),
    );
  }

  /// Connexion avec email
  Future<bool> signIn({required String email, required String password}) async {
    final ok = await _run(() async {
      await _authService.signInWithEmail(email: email, password: password);
      return true;
    });
    return ok ?? false;
  }

  /// Déconnexion
  Future<void> signOut() => _run(_authService.signOut);

  /// Envoie l'email de réinitialisation du mot de passe
  Future<bool> resetPassword(String email) async {
    final ok = await _run(() async {
      await _authService.resetPassword(email);
      return true;
    });
    return ok ?? false;
  }

  /// Renvoie l'email de confirmation d'inscription
  Future<bool> resendConfirmation(String email) async {
    final ok = await _run(() async {
      await _authService.resendConfirmation(email);
      return true;
    });
    return ok ?? false;
  }

  /// Enregistre le nouveau mot de passe après un lien de réinitialisation
  Future<bool> updatePassword(String newPassword) async {
    final ok = await _run(() async {
      await _authService.updatePassword(newPassword);
      return true;
    });
    if (ok == true) {
      _passwordRecovery = false;
      notifyListeners();
    }
    return ok ?? false;
  }

  /// Met à jour le profil utilisateur. Renvoie `false` si l'écriture échoue.
  Future<bool> updateProfile(UserProfile profile) async {
    final ok = await _run(() async {
      await _userRepository.updateUserProfile(profile);
      _userProfile = profile;
      return true;
    });
    return ok ?? false;
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Exécute une action en gérant chargement et message d'erreur.
  /// Renvoie null si l'action a échoué.
  Future<T?> _run<T>(Future<T> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } catch (e) {
      // AuthService lève des String déjà traduites
      _errorMessage = e is String
          ? e
          : e is PostgrestException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
