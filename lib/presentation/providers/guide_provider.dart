// lib/presentation/providers/guide_provider.dart

import 'package:flutter/material.dart';
import '../../data/models/recycling_guide_item.dart';
import '../../data/models/waste_type.dart';
import '../../data/repositories/guide_repository.dart';

/// Provider pour gérer l'état du guide de recyclage
class GuideProvider extends ChangeNotifier {
  final GuideRepository _repository = GuideRepository();

  // ========== ÉTAT ==========

  List<RecyclingGuideItem> _allItems = [];
  List<RecyclingGuideItem> _filteredItems = [];
  RecyclingCategory? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  // ========== GETTERS ==========

  List<RecyclingGuideItem> get allItems => _allItems;
  List<RecyclingGuideItem> get filteredItems => _filteredItems;
  RecyclingCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _filteredItems.isEmpty && !_isLoading;

  // ========== MÉTHODES PUBLIQUES ==========

  /// Charge tous les items du guide
  Future<void> loadAllItems() async {
    _setLoading(true);
    _clearError();

    try {
      _repository.getAllItems().listen(
        (items) {
          _allItems = items;
          _applyFilters();
          _setLoading(false);
        },
        onError: (error) {
          _setError('Erreur lors du chargement: $error');
          _setLoading(false);
        },
      );
    } catch (e) {
      _setError('Erreur inattendue: $e');
      _setLoading(false);
    }
  }

  /// Filtre par catégorie
  void filterByCategory(RecyclingCategory? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  /// Recherche par mots-clés
  Future<void> search(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _applyFilters();
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final results = await _repository.searchItems(_searchQuery);
      _filteredItems = results;
      _setLoading(false);
    } catch (e) {
      _setError('Erreur lors de la recherche: $e');
      _setLoading(false);
    }
  }

  /// Efface la recherche
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Réinitialise tous les filtres
  void resetFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Récupère un item par ID
  Future<RecyclingGuideItem?> getItemById(String id) async {
    try {
      return await _repository.getItemById(id);
    } catch (e) {
      _setError('Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// Incrémente le compteur de vues d'un item
  Future<void> incrementViewCount(String id) async {
    try {
      await _repository.incrementViewCount(id);
    } catch (e) {
      print('Erreur lors de l\'incrémentation: $e');
    }
  }

  /// Obtient le nombre d'items par catégorie
  Future<Map<RecyclingCategory, int>> getItemsCountByCategory() async {
    try {
      return await _repository.getItemsCountByCategory();
    } catch (e) {
      print('Erreur lors du comptage: $e');
      return {};
    }
  }

  /// Initialise le guide avec des données de base (pour tests)
  Future<bool> initializeGuideData() async {
    _setLoading(true);
    try {
      final success = await _repository.initializeGuideData();
      if (success) {
        await loadAllItems();
      }
      return success;
    } catch (e) {
      _setError('Erreur lors de l\'initialisation: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// Applique les filtres sur la liste complète
  void _applyFilters() {
    List<RecyclingGuideItem> result = List.from(_allItems);

    // Filtre par catégorie
    if (_selectedCategory != null) {
      result = result
          .where((item) => item.category == _selectedCategory)
          .toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((item) => item.matchesSearch(_searchQuery))
          .toList();
    }

    _filteredItems = result;
  }

  /// Définit l'état de chargement
  void _setLoading(bool value) {
    _isLoading = value;
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
    notifyListeners();
  }

  // ========== MÉTHODES UTILITAIRES ==========

  /// Obtient les catégories avec au moins un item
  List<RecyclingCategory> getAvailableCategories() {
    final categories = <RecyclingCategory>{};
    for (var item in _allItems) {
      categories.add(item.category as RecyclingCategory);
    }
    return categories.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
  }

  /// Obtient le nombre d'items filtrés
  int get filteredItemsCount => _filteredItems.length;

  /// Obtient le nombre total d'items
  int get totalItemsCount => _allItems.length;

  /// Vérifie si des filtres sont actifs
  bool get hasActiveFilters =>
      _selectedCategory != null || _searchQuery.isNotEmpty;
}
