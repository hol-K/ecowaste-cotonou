import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calendar_event.dart';

/// Repository pour gérer les données du calendrier depuis Firestore
class CalendarRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'schedules'; // Adaptez selon votre structure

  /// Récupérer tous les événements d'un mois donné
  /// Optimisé : requête uniquement sur la plage de dates
  Future<List<CalendarEvent>> getEventsForMonth(DateTime month) async {
    try {
      // Calculer le début et la fin du mois
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => CalendarEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements: $e');
    }
  }

  /// Récupérer les événements d'une journée spécifique
  Future<List<CalendarEvent>> getEventsForDay(DateTime day) async {
    try {
      // Début et fin de la journée
      final startOfDay = DateTime(day.year, day.month, day.day);
      final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('date')
          .get();

      return querySnapshot.docs
          .map((doc) => CalendarEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des événements du jour: $e');
    }
  }

  /// Stream pour écouter les changements en temps réel (optionnel)
  Stream<List<CalendarEvent>> streamEventsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection(_collectionName)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(doc))
            .toList());
  }
}