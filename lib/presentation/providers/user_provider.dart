// lib/presentation/providers/user_provider.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/user_statistics.dart';
import '../../data/models/notification_settings.dart';
import '../../data/models/waste_type.dart';
import '../../data/repositories/user_repository.dart';

/// Provider pour gérer l'état de l'utilisateur
class UserProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== ÉTAT ==========

  UserProfile? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // ========== GETTERS ==========

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get userId => _currentUser?.id;
  String? get userName => _currentUser?.name;
  String? get userEmail => _currentUser?.email;
  String get userDistrict => _currentUser?.district ?? 'Akpakpa';
  UserStatistics? get statistics => _currentUser?.statistics;
  NotificationSettings? get notificationSettings =>
      _currentUser?.notificationSettings;

  // ========== INITIALISATION ==========

  /// Initialise le provider et vérifie l'authentification
  Future<void> initialize() async {
    _setLoading(true);

    // Écouter les changements d'authentification
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        _isAuthenticated = true;
        await _loadUserProfile(firebaseUser.uid);
      } else {
        _isAuthenticated = false;
        _currentUser = null;
        notifyListeners();
      }
    });

    _setLoading(false);
  }

  /// Charge le profil utilisateur depuis Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      final profile = await _repository.getUserProfile(uid);
      if (profile != null) {
        _currentUser = profile;
        // Mettre à jour les jours consécutifs
        await _updateConsecutiveDays();
      } else {
        // Créer un nouveau profil
        await _createNewUserProfile(uid);
      }
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors du chargement du profil: $e');
    }
  }

  /// Crée un nouveau profil utilisateur
  Future<void> _createNewUserProfile(String uid) async {
    try {
      final firebaseUser = _auth.currentUser;
      final newProfile = UserProfile.initial(
        id: uid,
        email: firebaseUser?.email,
        name: firebaseUser?.displayName,
      );

      await _repository.createUserProfile(newProfile);
      _currentUser = newProfile;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la création du profil: $e');
    }
  }

  // ========== AUTHENTIFICATION ==========

  /// Connexion avec email/password
  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Erreur de connexion: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Inscription avec email/password
  Future<bool> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _setLoading(true);
    _clearError();

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        _setLoading(false);
        return true;
      }

      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Erreur d\'inscription: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la déconnexion: $e');
    }
  }

  // ========== MISE À JOUR DU PROFIL ==========

  /// Met à jour les informations de base
  Future<bool> updateBasicInfo({
    String? name,
    String? phone,
    String? photoUrl,
    String? district,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final updatedProfile = _currentUser!.updateBasicInfo(
        name: name,
        phone: phone,
        photoUrl: photoUrl,
        district: district,
      );

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Change le quartier
  Future<bool> changeDistrict(String district) async {
    return await updateBasicInfo(district: district);
  }

  // ========== STATISTIQUES ==========

  /// Met à jour les jours consécutifs
  Future<void> _updateConsecutiveDays() async {
    if (_currentUser == null) return;

    try {
      final updatedStats = _currentUser!.statistics.updateConsecutiveDays();
      final updatedProfile = _currentUser!.updateStatistics(updatedStats);

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      notifyListeners();
    } catch (e) {
      print('Erreur lors de la mise à jour des jours consécutifs: $e');
    }
  }

  /// Incrémente les consultations du calendrier
  Future<void> incrementCalendarViews() async {
    if (_currentUser == null) return;

    try {
      final updatedStats = _currentUser!.statistics.incrementCalendarViews();
      final updatedProfile = _currentUser!.updateStatistics(updatedStats);

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      notifyListeners();
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Incrémente les recherches dans le guide
  Future<void> incrementGuideSearches() async {
    if (_currentUser == null) return;

    try {
      final updatedStats = _currentUser!.statistics.incrementGuideSearches();
      final updatedProfile = _currentUser!.updateStatistics(updatedStats);

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      notifyListeners();
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Incrémente les consultations de la carte
  Future<void> incrementMapViews() async {
    if (_currentUser == null) return;

    try {
      final updatedStats = _currentUser!.statistics.incrementMapViews();
      final updatedProfile = _currentUser!.updateStatistics(updatedStats);

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      notifyListeners();
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Ajoute des déchets recyclés
  Future<void> addRecycledWaste(double kg) async {
    if (_currentUser == null) return;

    try {
      final updatedStats = _currentUser!.statistics.addRecycledWaste(kg);
      final updatedProfile = _currentUser!.updateStatistics(updatedStats);

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      notifyListeners();
    } catch (e) {
      print('Erreur: $e');
    }
  }

  // ========== PARAMÈTRES DE NOTIFICATIONS ==========

  /// Met à jour les paramètres de notifications
  Future<bool> updateNotificationSettings(NotificationSettings settings) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    try {
      final updatedProfile = _currentUser!.updateNotificationSettings(settings);

      await _repository.updateUserProfile(updatedProfile);
      _currentUser = updatedProfile;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur lors de la mise à jour des notifications: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Active/désactive les notifications globalement
  Future<void> toggleNotifications(bool enabled) async {
    if (notificationSettings == null) return;

    final updated = notificationSettings!.copyWith(enabled: enabled);
    await updateNotificationSettings(updated);
  }

  /// Active/désactive les notifications pour un type de déchet
  Future<void> toggleWasteTypeNotification(WasteType type) async {
    if (notificationSettings == null) return;

    final updated = notificationSettings!.toggleWasteType(type);
    await updateNotificationSettings(updated);
  }

  // ========== MÉTHODES UTILITAIRES ==========

  /// Obtient le message de bienvenue personnalisé
  String getWelcomeMessage() {
    if (_currentUser == null) return 'Bonjour';
    return _currentUser!.getWelcomeMessage();
  }

  /// Obtient les initiales pour l'avatar
  String getInitials() {
    if (_currentUser == null) return '?';
    return _currentUser!.getInitials();
  }

  /// Vérifie si le profil est complet
  bool get isProfileComplete => _currentUser?.isComplete ?? false;

  // ========== GESTION D'ÉTAT ==========

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
