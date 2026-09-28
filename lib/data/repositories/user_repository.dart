// lib/data/repositories/user_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Repository pour gérer les profils utilisateurs
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // ========== LECTURE (READ) ==========

  /// Récupère le profil d'un utilisateur par ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  /// Écoute les changements du profil utilisateur en temps réel
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore.collection(_collection).doc(userId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        return UserProfile.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  // Les écritures laissent remonter les exceptions : c'est à l'appelant
  // d'afficher l'échec (auparavant elles renvoyaient `false`, jamais vérifié).

  // ========== CRÉATION (CREATE) ==========

  /// Crée un nouveau profil utilisateur
  Future<void> createUserProfile(UserProfile profile) {
    return _firestore
        .collection(_collection)
        .doc(profile.id)
        .set(profile.toMap());
  }

  // ========== MISE À JOUR (UPDATE) ==========

  /// Met à jour le profil utilisateur complet
  Future<void> updateUserProfile(UserProfile profile) {
    return _firestore
        .collection(_collection)
        .doc(profile.id)
        .update(profile.toMap());
  }

  /// Met à jour des champs spécifiques
  Future<void> updateFields(String userId, Map<String, dynamic> fields) {
    return _firestore.collection(_collection).doc(userId).update(fields);
  }

  // ========== SUPPRESSION (DELETE) ==========

  /// Supprime un profil utilisateur
  Future<void> deleteUserProfile(String userId) {
    return _firestore.collection(_collection).doc(userId).delete();
  }

  // ========== MÉTHODES UTILITAIRES ==========

  /// Vérifie si un profil existe
  Future<bool> userProfileExists(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      return doc.exists;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// Compte le nombre total d'utilisateurs
  Future<int> getUsersCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.size;
    } catch (e) {
      print('Erreur lors du comptage: $e');
      return 0;
    }
  }
}
