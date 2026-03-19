import 'package:flutter/foundation.dart';
import '../../data/models/calendar_event.dart';
import '../../data/repositories/calendar_repository.dart';

/// Provider pour gérer l'état du calendrier
class CalendarProvider with ChangeNotifier {
  final CalendarRepository _repository = CalendarRepository();

  // État
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Map<DateTime, List<CalendarEvent>> _events = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  DateTime get focusedDay => _focusedDay;
  DateTime get selectedDay => _selectedDay;
  Map<DateTime, List<CalendarEvent>> get events => _events;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Récupérer les événements d'un jour spécifique
  List<CalendarEvent> getEventsForDay(DateTime day) {
    // Normaliser la date (ignorer l'heure)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  /// Changer le jour sélectionné
  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  /// Changer le mois affiché et charger ses données
  Future<void> setFocusedDay(DateTime day) async {
    _focusedDay = day;
    notifyListeners();
    
    // Charger les événements du nouveau mois
    await loadEventsForMonth(day);
  }

  /// Charger tous les événements d'un mois
  Future<void> loadEventsForMonth(DateTime month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final eventsList = await _repository.getEventsForMonth(month);
      
      // Organiser les événements par jour (Map<DateTime, List>)
      _events.clear();
      for (var event in eventsList) {
        final normalizedDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );

        if (_events.containsKey(normalizedDate)) {
          _events[normalizedDate]!.add(event);
        } else {
          _events[normalizedDate] = [event];
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initialisation : charger le mois actuel
  Future<void> initialize() async {
    await loadEventsForMonth(_focusedDay);
  }

  /// Rafraîchir les données
  Future<void> refresh() async {
    await loadEventsForMonth(_focusedDay);
  }
}