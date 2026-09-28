// lib/presentation/providers/map_provider.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/collection_point.dart';
import '../../data/models/waste_type.dart';
import '../../data/repositories/points_repository.dart';

/// Provider pour gérer l'état de la carte
class MapProvider extends ChangeNotifier {
  MapProvider({PointsRepository? repository})
    : _repository = repository ?? PointsRepository();

  final PointsRepository _repository;
  StreamSubscription<List<CollectionPoint>>? _subscription;

  // ========== ÉTAT ==========

  List<CollectionPoint> _allPoints = [];
  List<CollectionPoint> _filteredPoints = [];
  WasteType? _selectedFilter;
  LatLng? _userLocation;
  LatLng _mapCenter = const LatLng(6.3654, 2.4183); // Centre de Cotonou par défaut
  double _mapZoom = 12.0;
  bool _isLoadingPoints = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  CollectionPoint? _selectedPoint;

  // ========== GETTERS ==========

  List<CollectionPoint> get allPoints => _allPoints;
  List<CollectionPoint> get filteredPoints => _filteredPoints;
  WasteType? get selectedFilter => _selectedFilter;
  LatLng? get userLocation => _userLocation;
  LatLng get mapCenter => _mapCenter;
  double get mapZoom => _mapZoom;
  bool get isLoadingPoints => _isLoadingPoints;
  bool get isLoadingLocation => _isLoadingLocation;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasUserLocation => _userLocation != null;
  CollectionPoint? get selectedPoint => _selectedPoint;
  int get filteredPointsCount => _filteredPoints.length;

  // ========== MÉTHODES PUBLIQUES ==========

  /// Charge tous les points de collecte (écoute temps réel, un seul abonnement)
  Future<void> loadAllPoints() async {
    _setLoadingPoints(true);
    _clearError();

    await _subscription?.cancel();
    _subscription = _repository.getAllPoints().listen((points) {
      _allPoints = points;
      _applyFilter();
      _setLoadingPoints(false);
    }, onError: (error) {
      _setError('Erreur lors du chargement des points: $error');
      _setLoadingPoints(false);
    });
  }

  /// Charge les points une seule fois (appelé par l'écran au montage)
  Future<void> ensureLoaded() async {
    if (_subscription != null) return;
    await loadAllPoints();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Filtre les points par type de déchet
  void filterByWasteType(WasteType? type) {
    _selectedFilter = type;
    _applyFilter();
    notifyListeners();
  }

  /// Réinitialise les filtres
  void resetFilter() {
    _selectedFilter = null;
    _applyFilter();
    notifyListeners();
  }

  /// Obtient la position GPS de l'utilisateur
  Future<void> getUserLocation() async {
    _setLoadingLocation(true);
    _clearError();

    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Permission de localisation refusée');
          _setLoadingLocation(false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Permission de localisation refusée définitivement. Activez-la dans les paramètres.');
        _setLoadingLocation(false);
        return;
      }

      // Obtenir la position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _userLocation = LatLng(position.latitude, position.longitude);
      _mapCenter = _userLocation!;
      _mapZoom = 15.0;
      _setLoadingLocation(false);
      notifyListeners();
    } catch (e) {
      _setError('Erreur lors de la récupération de la position: $e');
      _setLoadingLocation(false);
    }
  }

  /// Centre la carte sur la position de l'utilisateur
  void centerOnUserLocation() {
    if (_userLocation != null) {
      _mapCenter = _userLocation!;
      _mapZoom = 15.0;
      notifyListeners();
    } else {
      getUserLocation();
    }
  }

  /// Centre la carte sur un point spécifique
  void centerOnPoint(CollectionPoint point) {
    _mapCenter = LatLng(point.latitude, point.longitude);
    _mapZoom = 16.0;
    _selectedPoint = point;
    notifyListeners();
  }

  /// Met à jour le centre de la carte
  void updateMapCenter(LatLng center, double zoom) {
    _mapCenter = center;
    _mapZoom = zoom;
    notifyListeners();
  }

  /// Sélectionne un point
  void selectPoint(CollectionPoint? point) {
    _selectedPoint = point;
    notifyListeners();
  }

  /// Calcule la distance entre deux points
  double calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  /// Formate la distance en texte
  String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }

  /// Obtient les points triés par distance depuis la position utilisateur
  List<CollectionPoint> getPointsSortedByDistance() {
    if (_userLocation == null) return _filteredPoints;

    final pointsWithDistance = _filteredPoints.map((point) {
      final distance = calculateDistance(
        _userLocation!,
        LatLng(point.latitude, point.longitude),
      );
      return {'point': point, 'distance': distance};
    }).toList();

    pointsWithDistance.sort((a, b) => 
      (a['distance'] as double).compareTo(b['distance'] as double)
    );

    return pointsWithDistance
        .map((item) => item['point'] as CollectionPoint)
        .toList();
  }

  /// Obtient le point le plus proche
  CollectionPoint? getNearestPoint() {
    if (_userLocation == null || _filteredPoints.isEmpty) return null;

    final sortedPoints = getPointsSortedByDistance();
    return sortedPoints.first;
  }

  /// Récupère un point par ID
  Future<CollectionPoint?> getPointById(String id) async {
    try {
      return await _repository.getPointById(id);
    } catch (e) {
      _setError('Erreur lors de la récupération du point: $e');
      return null;
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// Applique le filtre sur la liste complète
  void _applyFilter() {
    if (_selectedFilter == null) {
      _filteredPoints = List.from(_allPoints);
    } else {
      _filteredPoints = _allPoints
          .where((point) => point.acceptsWasteType(_selectedFilter!))
          .toList();
    }
  }

  /// Définit l'état de chargement des points
  void _setLoadingPoints(bool value) {
    _isLoadingPoints = value;
    notifyListeners();
  }

  /// Définit l'état de chargement de la localisation
  void _setLoadingLocation(bool value) {
    _isLoadingLocation = value;
    notifyListeners();
  }

  /// Définit un message d'erreur
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Efface le message d'erreur
  void _clearError() {
    _errorMessage = null;
  }

  // ========== MÉTHODES UTILITAIRES ==========

  /// Obtient les types de déchets disponibles dans les points
  List<WasteType> getAvailableWasteTypes() {
    final types = <WasteType>{};
    for (var point in _allPoints) {
      types.addAll(point.acceptedWasteTypes);
    }
    return types.toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  /// Vérifie si un filtre est actif
  bool get hasActiveFilter => _selectedFilter != null;

  /// Obtient le texte du filtre actuel
  String get filterText {
    if (_selectedFilter == null) return 'Tous';
    return _selectedFilter!.displayName;
  }
}