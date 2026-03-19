// lib/presentation/providers/points_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/repositories/points_repository.dart';
import '../../data/models/collection_point.dart';
import '../../data/models/waste_type.dart';

/// Provider pour gérer l'état des points de collecte
class PointsProvider with ChangeNotifier {
  final PointsRepository _repository = PointsRepository();

  List<CollectionPoint> _allPoints = [];
  List<CollectionPoint> _filteredPoints = [];
  WasteType? _selectedWasteType;
  double? _userLatitude;
  double? _userLongitude;
  Map<WasteType, int> _wasteTypeCounts = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CollectionPoint> get allPoints => _allPoints;
  List<CollectionPoint> get filteredPoints => _filteredPoints;
  WasteType? get selectedWasteType => _selectedWasteType;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  Map<WasteType, int> get wasteTypeCounts => _wasteTypeCounts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUserLocation => _userLatitude != null && _userLongitude != null;

  /// Charge tous les points
  Future<Object> loadPoints() async {
    try {
      _setLoading(true);
      _errorMessage = null;

      _allPoints = (await _repository.getAllPoints().toList())
          .cast<CollectionPoint>();
      _applyFilters();
      await _loadWasteTypeCounts();

      _setLoading(false);
      return _allPoints;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return [];
    }
  }

  /// Charge le comptage par type de déchet
  Future<void> _loadWasteTypeCounts() async {
    try {
      _wasteTypeCounts = await _repository.countPointsByWasteType();
    } catch (e) {
      debugPrint('Erreur chargement comptage: $e');
    }
  }

  /// Définit le type de déchet sélectionné
  void setWasteType(WasteType? wasteType) {
    _selectedWasteType = wasteType;
    _applyFilters();
  }

  /// Définit la position de l'utilisateur
  void setUserLocation(double latitude, double longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    _applyFilters();
  }

  /// Applique les filtres
  void _applyFilters() {
    _filteredPoints = _allPoints;

    // Filtre par type de déchet
    if (_selectedWasteType != null) {
      _filteredPoints = _filteredPoints
          .where((point) => point.acceptsWasteType(_selectedWasteType!))
          .toList();
    }

    // Trie par distance si position disponible
    if (hasUserLocation) {
      _filteredPoints.sort((a, b) {
        final distA = a.distanceFrom(_userLatitude!, _userLongitude!);
        final distB = b.distanceFrom(_userLatitude!, _userLongitude!);
        return distA.compareTo(distB);
      });
    }

    notifyListeners();
  }

  /// Obtient un point par ID
  Future<CollectionPoint?> getPointById(String id) async {
    try {
      return await _repository.getPointById(id);
    } catch (e) {
      debugPrint('Erreur récupération point: $e');
      return null;
    }
  }

  /// Obtient les points par type de déchet
  Future<Object> getPointsByWasteType(WasteType wasteType) async {
    try {
      return await _repository.getPointsByWasteType(wasteType);
    } catch (e) {
      debugPrint('Erreur points par type: $e');
      return [];
    }
  }

  /// Obtient les points publics uniquement
  Future<Object> getPublicPoints() async {
    try {
      return await _repository.getPublicPoints();
    } catch (e) {
      debugPrint('Erreur points publics: $e');
      return [];
    }
  }

  /// Efface les filtres
  void clearFilters() {
    _selectedWasteType = null;
    _applyFilters();
  }

  /// Rafraîchit toutes les données
  Future<void> refresh() async {
    await loadPoints();
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
