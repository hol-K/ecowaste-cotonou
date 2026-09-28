
/// Modèle représentant une catégorie de déchets recyclables
class WasteCategory {
  final String id;
  final String name;
  final String description;
  final String iconName; // Nom de l'icône (ex: 'recycling', 'delete', etc.)
  final String color; // Couleur hex
  final List<String> acceptedItems; // Ce qui va dans cette catégorie
  final List<String> refusedItems;  // Ce qui ne va PAS
  final List<String> tips; // Conseils pratiques
  final int sortOrder; // Ordre d'affichage

  WasteCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.color,
    required this.acceptedItems,
    required this.refusedItems,
    required this.tips,
    this.sortOrder = 0,
  });

  /// Convertir depuis une ligne de base de données
  factory WasteCategory.fromMap(Map<String, dynamic> data) {
    return WasteCategory(
      id: data['id'] as String,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconName: data['iconName'] ?? 'recycling',
      color: data['color'] ?? '#4CAF50',
      acceptedItems: List<String>.from(data['acceptedItems'] ?? []),
      refusedItems: List<String>.from(data['refusedItems'] ?? []),
      tips: List<String>.from(data['tips'] ?? []),
      sortOrder: data['sortOrder'] ?? 0,
    );
  }

  /// Convertir vers une ligne de base de données
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'iconName': iconName,
      'color': color,
      'acceptedItems': acceptedItems,
      'refusedItems': refusedItems,
      'tips': tips,
      'sortOrder': sortOrder,
    };
  }

  /// Rechercher un item dans la catégorie
  bool containsItem(String query) {
    final lowerQuery = query.toLowerCase();
    return acceptedItems.any((item) => item.toLowerCase().contains(lowerQuery)) ||
           refusedItems.any((item) => item.toLowerCase().contains(lowerQuery));
  }
}