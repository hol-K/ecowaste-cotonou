// lib/data/repositories/user_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

/// Repository des profils utilisateurs (table `profiles`).
///
/// Le profil est créé par la base à l'inscription (trigger
/// `on_auth_user_created`) ; la RLS limite chaque utilisateur à sa ligne.
/// Les erreurs remontent à l'appelant, qui décide quoi afficher.
class UserRepository {
  UserRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'profiles';

  /// Récupère le profil d'un utilisateur (null s'il n'existe pas)
  Future<UserProfile?> getUserProfile(String userId) async {
    final row = await _client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return row == null ? null : UserProfile.fromMap(row);
  }

  /// Écoute le profil en temps réel
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : UserProfile.fromMap(rows.first));
  }

  /// Met à jour les champs modifiables du profil
  Future<void> updateUserProfile(UserProfile profile) {
    return _client.from(_table).update(profile.toMap()).eq('id', profile.id);
  }

  /// Supprime le compte de l'utilisateur connecté (profil supprimé en cascade)
  Future<void> deleteOwnAccount() {
    return _client.rpc('delete_own_account');
  }
}
