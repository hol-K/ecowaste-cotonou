// lib/data/repositories/schedule_repository.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/collection_schedule.dart';

/// Repository du calendrier de collecte (table `collection_schedules`).
/// Lecture seule depuis l'app : les plannings se gèrent dans le tableau
/// de bord Supabase.
class ScheduleRepository {
  ScheduleRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _table = 'collection_schedules';

  /// Format de la colonne `date` Postgres : "2026-09-28"
  static String _day(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .substring(0, 10);

  /// Collectes d'un quartier pour un mois
  Future<List<CollectionSchedule>> getSchedulesByDistrict({
    required String district,
    required DateTime month,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('district', district)
        .gte('collection_date', _day(DateTime(month.year, month.month, 1)))
        .lte('collection_date', _day(DateTime(month.year, month.month + 1, 0)))
        .order('collection_date', ascending: true);

    return rows.map(CollectionSchedule.fromMap).toList();
  }

  /// Prochaines collectes d'un quartier (à partir d'aujourd'hui)
  Future<List<CollectionSchedule>> getUpcomingSchedules({
    required String district,
    int limit = 5,
  }) async {
    final rows = await _client
        .from(_table)
        .select()
        .eq('district', district)
        .gte('collection_date', _day(DateTime.now()))
        .order('collection_date', ascending: true)
        .limit(limit);

    return rows.map(CollectionSchedule.fromMap).toList();
  }

  /// Prochaine collecte d'un quartier
  Future<CollectionSchedule?> getNextSchedule({required String district}) async {
    final schedules = await getUpcomingSchedules(district: district, limit: 1);
    return schedules.isNotEmpty ? schedules.first : null;
  }
}
