import 'waste_type.dart';

/// Représente un item du guide de recyclage
class RecyclingGuideItem {
  final String id;
  final String name; // Nom du déchet (ex: "Bouteille en plastique")
  final RecyclingCategory category; // Catégorie
  final WasteType wasteType; // Type de poubelle correspondante
  final String imageUrl; // URL de l'image
  final String description; // Description détaillée
  final List<String> instructions; // Instructions de préparation (étapes)
  final String environmentalImpact; // Impact environnemental positif
  final List<String> keywords; // Mots-clés pour la recherche
  final List<String>? alternatives;

  RecyclingGuideItem({
    required this.id,
    required this.name,
    required this.category,
    required this.wasteType,
    required this.imageUrl,
    required this.description,
    required this.instructions,
    required this.environmentalImpact,
    required this.keywords,
    this.alternatives,
  });

  //MÉTHODES UTILES

  /// Vérifie si l'item correspond à une recherche
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();

    // Recherche dans le nom
    if (name.toLowerCase().contains(lowerQuery)) return true;

    // Recherche dans la description
    if (description.toLowerCase().contains(lowerQuery)) return true;

    // Recherche dans les keywords
    for (var keyword in keywords) {
      if (keyword.toLowerCase().contains(lowerQuery)) return true;
    }

    // Recherche dans la catégorie
    if (category.displayName.toLowerCase().contains(lowerQuery)) return true;

    return false;
  }

  /// Vérifie si l'item appartient à une catégorie spécifique
  bool belongsToCategory(RecyclingCategory cat) => category == cat;

  /// Obtient un résumé court pour l'affichage en liste
  String getShortDescription() {
    if (description.length <= 80) return description;
    return '${description.substring(0, 77)}...';
  }

  /// Obtient le nombre d'étapes d'instructions
  int get instructionsCount => instructions.length;

  /// Vérifie si des alternatives écologiques sont disponibles
  bool get hasAlternatives => alternatives != null && alternatives!.isNotEmpty;

  //SÉRIALISATION SUPABASE (table recycling_guide_items)

  /// Conversion depuis une ligne Supabase. Les colonnes category et
  /// waste_type sont des enums Postgres aux mêmes valeurs que les enums Dart.
  factory RecyclingGuideItem.fromMap(Map<String, dynamic> map) {
    return RecyclingGuideItem(
      id: map['id'] as String,
      name: map['name'] ?? '',
      category: RecyclingCategory.values.asNameMap()[map['category']] ??
          RecyclingCategory.plastic,
      wasteType: WasteType.values.asNameMap()[map['waste_type']] ??
          WasteType.general,
      imageUrl: map['image_url'] ?? '',
      description: map['description'] ?? '',
      instructions: List<String>.from(map['instructions'] ?? const []),
      environmentalImpact: map['environmental_impact'] ?? '',
      keywords: List<String>.from(map['keywords'] ?? const []),
      alternatives: map['alternatives'] != null
          ? List<String>.from(map['alternatives'])
          : null,
    );
  }

  /// Conversion vers une ligne Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.name,
      'waste_type': wasteType.name,
      'image_url': imageUrl,
      'description': description,
      'instructions': instructions,
      'environmental_impact': environmentalImpact,
      'keywords': keywords,
      'alternatives': alternatives,
    };
  }

  /// CopyWith pour créer une copie modifiée
  RecyclingGuideItem copyWith({
    String? id,
    String? name,
    RecyclingCategory? category,
    WasteType? wasteType,
    String? imageUrl,
    String? description,
    List<String>? instructions,
    String? environmentalImpact,
    List<String>? keywords,
    List<String>? alternatives,
  }) {
    return RecyclingGuideItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      wasteType: wasteType ?? this.wasteType,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      keywords: keywords ?? this.keywords,
      alternatives: alternatives ?? this.alternatives,
    );
  }

  @override
  String toString() {
    return 'RecyclingGuideItem(id: $id, name: $name, category: ${category.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecyclingGuideItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
