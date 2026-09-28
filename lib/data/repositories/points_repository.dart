// lib/data/repositories/points_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection_point.dart';

/// Repository des points de collecte (table `collection_points`).
/// Lecture seule depuis l'app ; la RLS ne renvoie que les points publics.
class PointsRepository {
  PointsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'collection_points';

  /// Tous les points de collecte, triés par nom, en temps réel
  Stream<List<CollectionPoint>> getAllPoints() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((rows) => rows.map(CollectionPoint.fromMap).toList());
  }

  /// Récupère un point par ID
  Future<CollectionPoint?> getPointById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : CollectionPoint.fromMap(row);
  }
}
