// lib/presentation/providers/schedule_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/models/collection_schedule.dart';

/// Provider du calendrier de collecte : collectes du mois affiché,
/// jour sélectionné et prochaine collecte du quartier de l'utilisateur.
class ScheduleProvider with ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();

  List<CollectionSchedule> _schedules = [];
  CollectionSchedule? _nextSchedule;
  DateTime _selectedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String _currentDistrict = 'Akpakpa';
  bool _isLoading = false;
  bool _initialized = false;
  String? _errorMessage;

  // Getters
  List<CollectionSchedule> get schedules => _schedules;
  CollectionSchedule? get nextSchedule => _nextSchedule;
  DateTime get selectedMonth => _selectedMonth;
  DateTime get selectedDay => _selectedDay;
  String get currentDistrict => _currentDistrict;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Charge les données une seule fois (appelé par les écrans au montage)
  Future<void> ensureLoaded() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  /// Synchronise le quartier avec le profil utilisateur.
  /// Appelé depuis un ProxyProvider pendant un build : le rechargement est
  /// donc différé pour ne pas notifier les listeners en plein build.
  void syncDistrict(String? district) {
    if (district == null || district == _currentDistrict) return;
    _currentDistrict = district;
    if (_initialized) Future.microtask(refresh);
  }

  /// Change le quartier et recharge les données
  Future<void> setDistrict(String district) async {
    _currentDistrict = district;
    await refresh();
  }

  /// Change le mois affiché et recharge
  Future<void> setMonth(DateTime month) async {
    if (month.year == _selectedMonth.year &&
        month.month == _selectedMonth.month) {
      return;
    }
    _selectedMonth = month;
    await loadSchedules();
  }

  /// Sélectionne un jour du calendrier
  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
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

  /// Obtient les collectes d'une date spécifique
  List<CollectionSchedule> getSchedulesForDate(DateTime date) {
    return _schedules.where((schedule) {
      return schedule.collectionDate.year == date.year &&
          schedule.collectionDate.month == date.month &&
          schedule.collectionDate.day == date.day;
    }).toList();
  }

  /// Rafraîchit toutes les données
  Future<void> refresh() async {
    await Future.wait([loadSchedules(), loadNextSchedule()]);
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
