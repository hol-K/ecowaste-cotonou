// lib/data/repositories/schedule_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_schedule.dart';

/// Repository pour gérer les calendriers de collecte dans Firestore
class ScheduleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'schedules';

  /// Récupère toutes les collectes d'un quartier pour un mois
  Future<List<CollectionSchedule>> getSchedulesByDistrict({
    required String district,
    required DateTime month,
  }) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final snapshot = await _firestore
          .collection(_collection)
          .where('district', isEqualTo: district)
          .where('collectionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('collectionDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('collectionDate')
          .get();

      return snapshot.docs
          .map((doc) => CollectionSchedule.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des collectes: $e');
    }
  }

  /// Récupère les prochaines collectes d'un quartier
  Future<List<CollectionSchedule>> getUpcomingSchedules({
    required String district,
    int limit = 5,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final snapshot = await _firestore
          .collection(_collection)
          .where('district', isEqualTo: district)
          .where('collectionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .orderBy('collectionDate')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CollectionSchedule.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des prochaines collectes: $e');
    }
  }

  /// Récupère la prochaine collecte d'un quartier
  Future<CollectionSchedule?> getNextSchedule({
    required String district,
  }) async {
    try {
      final schedules = await getUpcomingSchedules(district: district, limit: 1);
      return schedules.isNotEmpty ? schedules.first : null;
    } catch (e) {
      throw Exception('Erreur lors de la récupération de la prochaine collecte: $e');
    }
  }

  /// Stream des collectes d'un quartier
  Stream<List<CollectionSchedule>> getSchedulesStream({
    required String district,
    required DateTime month,
  }) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('district', isEqualTo: district)
        .where('collectionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('collectionDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('collectionDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CollectionSchedule.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Crée une collecte (Admin uniquement)
  Future<void> createSchedule(CollectionSchedule schedule) async {
    try {
      await _firestore.collection(_collection).add(schedule.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la création de la collecte: $e');
    }
  }

  /// Met à jour une collecte (Admin uniquement)
  Future<void> updateSchedule(CollectionSchedule schedule) async {
    try {
      await _firestore.collection(_collection).doc(schedule.id).update(schedule.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de la collecte: $e');
    }
  }

  /// Supprime une collecte (Admin uniquement)
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _firestore.collection(_collection).doc(scheduleId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de la collecte: $e');
    }
  }
}