import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import '../repositories/user_repository.dart';

/// Service d'authentification Firebase, gérant la communication avec l'API Firebase.
class AuthService {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  // Les dépendances sont maintenant injectées via le constructeur.
  AuthService(this._auth, this._userRepository);

  /// Stream de l'état d'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté
  User? get currentUser => _auth.currentUser;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => currentUser != null;

  /// Inscription avec email et mot de passe
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String district,
  }) async {
    try {
      // Créer le compte Firebase Auth
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) throw Exception('Erreur lors de la création du compte');

      // Mettre à jour le nom d'affichage
      await user.updateDisplayName(name);

      // Créer le profil utilisateur dans Firestore
      final profile = UserProfile.initial(
        id: user.uid,
        email: email,
        name: name,
        district: district,
      );

      await _userRepository.createUserProfile(profile);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }

  /// Connexion avec email et mot de passe
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la connexion: $e');
    }
  }

  /// Connexion avec Google
  Future<User?> signInWithGoogle() async {
    try {
      // Nécessite google_sign_in package et configuration
      throw UnimplementedError('Google Sign-In non implémenté');
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Suppression du compte
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      // Le profil doit être supprimé tant que l'utilisateur est encore
      // authentifié (règles Firestore). Si la suppression Auth échoue
      // (ex: requires-recent-login), on restaure le profil pour ne pas
      // laisser un compte sans profil.
      final profile = await _userRepository.getUserProfile(user.uid);
      await _userRepository.deleteUserProfile(user.uid);

      try {
        await user.delete();
      } catch (_) {
        if (profile != null) await _userRepository.createUserProfile(profile);
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Erreur lors de la suppression du compte: $e');
    }
  }

  /// Envoie un email de vérification
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Aucun utilisateur connecté');

      if (!user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email: $e');
    }
  }

  /// Recharge les informations de l'utilisateur
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      throw Exception('Erreur lors du rechargement: $e');
    }
  }

  /// Gestion des erreurs Firebase Auth
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Le mot de passe est trop faible. Utilisez au moins 6 caractères.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé par un autre compte.';
      case 'invalid-email':
        return 'L\'adresse email est invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'network-request-failed':
        return 'Pas de connexion internet. Vérifiez votre réseau.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion n\'est pas activée.';
      case 'requires-recent-login':
        return 'Cette opération nécessite une reconnexion récente.';
      default:
        return 'Erreur d\'authentification: ${e.message}';
    }
  }
}
