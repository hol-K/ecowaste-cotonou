import 'package:flutter/foundation.dart';

/// Onglets de la barre de navigation principale (ordre = index affiché).
enum HomeTab { home, calendar, guide, map, profile }

/// Onglet actif de [HomeScreen], pilotable depuis n'importe quel écran
/// (actions rapides, bouton « Trouver un point de collecte », etc.).
class HomeNavigationProvider with ChangeNotifier {
  HomeTab _current = HomeTab.home;

  HomeTab get current => _current;

  void goTo(HomeTab tab) {
    if (tab == _current) return;
    _current = tab;
    notifyListeners();
  }
}
