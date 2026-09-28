// lib/data/repositories/guide_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/recycling_guide_item.dart';
import '../models/waste_type.dart';

/// Repository du guide de recyclage (table `recycling_guide_items`).
/// Lecture seule depuis l'app, sauf le compteur de vues (fonction RPC).
class GuideRepository {
  GuideRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'recycling_guide_items';

  /// Tous les items du guide, triés par nom, en temps réel
  Stream<List<RecyclingGuideItem>> getAllItems() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('name', ascending: true)
        .map((rows) => rows.map(RecyclingGuideItem.fromMap).toList());
  }

  /// Récupère un item par ID
  Future<RecyclingGuideItem?> getItemById(String id) async {
    final row = await _client.from(_table).select().eq('id', id).maybeSingle();
    return row == null ? null : RecyclingGuideItem.fromMap(row);
  }

  /// Incrémente le compteur de vues (fonction `increment_guide_view`)
  Future<void> incrementViewCount(String id) {
    return _client.rpc('increment_guide_view', params: {'item_id': id});
  }

  /// Compte les items par catégorie
  Future<Map<RecyclingCategory, int>> getItemsCountByCategory() async {
    final rows = await _client.from(_table).select('category');
    final counts = {for (final category in RecyclingCategory.values) category: 0};
    for (final row in rows) {
      final category = RecyclingCategory.values.asNameMap()[row['category']];
      if (category != null) counts[category] = counts[category]! + 1;
    }
    return counts;
  }
}
