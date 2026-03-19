// lib/presentation/providers/schedule_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/models/collection_schedule.dart';

/// Provider pour gérer l'état du calendrier de collecte
class ScheduleProvider with ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();

  List<CollectionSchedule> _schedules = [];
  CollectionSchedule? _nextSchedule;
  DateTime _selectedMonth = DateTime.now();
  String _currentDistrict = 'Akpakpa';
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CollectionSchedule> get schedules => _schedules;
  CollectionSchedule? get nextSchedule => _nextSchedule;
  DateTime get selectedMonth => _selectedMonth;
  String get currentDistrict => _currentDistrict;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Change le quartier et recharge les données
  Future<void> setDistrict(String district) async {
    _currentDistrict = district;
    await loadSchedules();
    await loadNextSchedule();
  }

  /// Change le mois sélectionné et recharge
  Future<void> setMonth(DateTime month) async {
    _selectedMonth = month;
    await loadSchedules();
  }

  /// Change au mois suivant
  Future<void> nextMonth() async {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    await setMonth(newMonth);
  }

  /// Change au mois précédent
  Future<void> previousMonth() async {
    final newMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    await setMonth(newMonth);
  }

  /// Charge les collectes du mois
  Future<void> loadSchedules() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      _schedules = await _repository.getSchedulesByDistrict(
        district: _currentDistrict,
        month: _selectedMonth,
      );

      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Charge la prochaine collecte
  Future<void> loadNextSchedule() async {
    try {
      _nextSchedule = await _repository.getNextSchedule(
        district: _currentDistrict,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement prochaine collecte: $e');
    }
  }

  /// Charge les prochaines collectes (pour le dashboard)
  Future<List<CollectionSchedule>> getUpcomingSchedules({int limit = 5}) async {
    try {
      return await _repository.getUpcomingSchedules(
        district: _currentDistrict,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Erreur chargement collectes à venir: $e');
      return [];
    }
  }

  /// Obtient les collectes d'une date spécifique
  List<CollectionSchedule> getSchedulesForDate(DateTime date) {
    return _schedules.where((schedule) {
      return schedule.collectionDate.year == date.year &&
             schedule.collectionDate.month == date.month &&
             schedule.collectionDate.day == date.day;
    }).toList();
  }

  /// Vérifie si une date a des collectes
  bool hasScheduleOnDate(DateTime date) {
    return getSchedulesForDate(date).isNotEmpty;
  }

  /// Rafraîchit toutes les données
  Future<void> refresh() async {
    await loadSchedules();
    await loadNextSchedule();
  }

  /// Efface le message d'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}