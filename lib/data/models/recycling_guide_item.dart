import 'package:ecowaste_cotonou/data/models/guide_item.dart';
import 'package:flutter/material.dart';

import 'waste_type.dart';

/// Représente un item du guide de recyclage
class RecyclingGuideItem extends GuideItem {
  final String id;
  final String name; // Nom du déchet (ex: "Bouteille en plastique")
  final RecyclingCategory _category; // Catégorie
  final WasteType _wasteType; // Type de poubelle correspondante

  @override
  String get category => _category.displayName;
  RecyclingCategory get recyclingCategory => _category;
  @override
  String get wasteType => _wasteType.displayName;
  WasteType get actualWasteType => _wasteType;
  
  final String imageUrl; // URL de l'image
  final String description; // Description détaillée
  final List<String> instructions; // Instructions de préparation (étapes)
  final String environmentalImpact; // Impact environnemental positif
  final List<String> keywords; // Mots-clés pour la recherche
  final List<String>? alternatives;

  RecyclingGuideItem({
    required this.id,
    required this.name,
    required RecyclingCategory category,
    required WasteType wasteType,
    required this.imageUrl,
    required this.description,
    required this.instructions,
    required this.environmentalImpact,
    required this.keywords,
    this.alternatives,
  }) : _category = category,
       _wasteType = wasteType,
       super(
         name: name,
         category: category.displayName,
         wasteType: wasteType.toString(),
         color: const Color(0xFF000000),
         icon: Icons.recycling,
       );

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
    if (_category.displayName.toLowerCase().contains(lowerQuery)) return true;

    return false;
  }

  /// Vérifie si l'item appartient à une catégorie spécifique
  bool belongsToCategory(RecyclingCategory cat) {
    return category == cat;
  }

  /// Obtient un résumé court pour l'affichage en liste
  String getShortDescription() {
    if (description.length <= 80) return description;
    return '${description.substring(0, 77)}...';
  }

  /// Obtient le nombre d'étapes d'instructions
  int get instructionsCount => instructions.length;

  /// Vérifie si des alternatives écologiques sont disponibles
  bool get hasAlternatives => alternatives != null && alternatives!.isNotEmpty;

  //SÉRIALISATION FIRESTORE

  /// Conversion depuis Map (Firestore → Dart)
  factory RecyclingGuideItem.fromMap(Map<String, dynamic> map, String id) {
    return RecyclingGuideItem(
      id: id,
      name: map['name'] ?? '',
      category: RecyclingCategory.values.firstWhere(
        (e) => e.toString() == 'RecyclingCategory.${map['category']}',
        orElse: () => RecyclingCategory.plastic,
      ),
      wasteType: WasteType.values.firstWhere(
        (e) => e.toString() == 'WasteType.${map['wasteType']}',
        orElse: () => WasteType.general,
      ),
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      instructions: List<String>.from(map['instructions'] ?? []),
      environmentalImpact: map['environmentalImpact'] ?? '',
      keywords: List<String>.from(map['keywords'] ?? []),
      alternatives: map['alternatives'] != null
          ? List<String>.from(map['alternatives'])
          : null,
    );
  }

  /// Conversion vers Map (Dart → Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category.toString().split('.').last,
      'wasteType': wasteType.toString().split('.').last,
      'imageUrl': imageUrl,
      'description': description,
      'instructions': instructions,
      'environmentalImpact': environmentalImpact,
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
      category: category ?? _category,
      wasteType: wasteType ?? _wasteType,
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
    return 'RecyclingGuideItem(id: $id, name: $name, category: ${_category.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecyclingGuideItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
