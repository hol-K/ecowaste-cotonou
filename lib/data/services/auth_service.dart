import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../repositories/user_repository.dart';

/// Résultat d'une inscription
enum SignUpResult {
  /// Compte créé et session ouverte (confirmation d'email désactivée)
  signedIn,

  /// Compte créé : l'utilisateur doit cliquer le lien reçu par email
  confirmationRequired,
}

/// Service d'authentification Supabase.
/// Les erreurs sont levées sous forme de [String] déjà traduite.
class AuthService {
  AuthService(this._auth, this._userRepository);

  final GoTrueClient _auth;
  final UserRepository _userRepository;

  /// Utilisateur à chaque connexion / déconnexion / rafraîchissement
  Stream<User?> get authStateChanges =>
      _auth.onAuthStateChange.map((state) => state.session?.user);

  /// Événements bruts (ex : retour d'un lien de réinitialisation)
  Stream<AuthChangeEvent> get authEvents =>
      _auth.onAuthStateChange.map((state) => state.event);

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Inscription avec email et mot de passe.
  /// Le profil est créé par la base à partir de `name` et `district`.
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String district,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
        data: {'name': name, 'district': district},
      );

      // Protection anti-énumération : pour un email déjà inscrit, Supabase
      // renvoie un faux utilisateur sans identité au lieu d'une erreur.
      if (response.user?.identities?.isEmpty ?? false) {
        throw 'Cet email est déjà utilisé par un autre compte.';
      }

      return response.session != null
          ? SignUpResult.signedIn
          : SignUpResult.confirmationRequired;
    } on AuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Connexion avec email et mot de passe
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Envoie l'email de réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(
        email,
        redirectTo: SupabaseConfig.authRedirectUrl,
      );
    } on AuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Définit un nouveau mot de passe (après un lien de réinitialisation)
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Renvoie l'email de confirmation d'inscription
  Future<void> resendConfirmation(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: SupabaseConfig.authRedirectUrl,
      );
    } on AuthException catch (e) {
      throw _translate(e);
    }
  }

  /// Suppression du compte (profil supprimé en cascade par la base)
  Future<void> deleteAccount() async {
    if (currentUser == null) throw 'Aucun utilisateur connecté.';
    try {
      await _userRepository.deleteOwnAccount();
      await _auth.signOut();
    } on PostgrestException catch (e) {
      throw 'Erreur lors de la suppression du compte : ${e.message}';
    }
  }

  /// Traduit les erreurs Supabase Auth en messages pour l'utilisateur
  String _translate(AuthException e) {
    if (e is AuthRetryableFetchException) {
      return 'Pas de connexion internet. Vérifiez votre réseau.';
    }
    switch (e.code) {
      case 'invalid_credentials':
        return 'Email ou mot de passe incorrect.';
      case 'email_not_confirmed':
        return 'Confirmez d\'abord votre email : cliquez sur le lien reçu.';
      case 'user_already_exists':
      case 'email_exists':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'weak_password':
        return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
      case 'email_address_invalid':
      case 'validation_failed':
        return 'L\'adresse email est invalide.';
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'same_password':
        return 'Le nouveau mot de passe doit être différent de l\'ancien.';
      case 'user_banned':
        return 'Ce compte a été désactivé.';
      default:
        return 'Erreur d\'authentification : ${e.message}';
    }
  }
}
