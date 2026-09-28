// Types de déchets gérés par l'application EcoWaste Cotonou
enum WasteType {
  general('Ordures ménagères'), // Ordures ménagères
  recyclable('Recyclables'), // Recyclables (plastique, papier, carton)
  glass('Verre'), // Verre
  organic('Organique'), // Déchets organiques (compost)
  dangerous('Dangereux'), // Déchets dangereux (piles, produits chimiques)
  electronic('Électronique'); // Déchets électroniques (appareils électriques)

  final String displayName;
  const WasteType(this.displayName);
}

/// Extension pour obtenir les informations visuelles de chaque type
extension WasteTypeExtension on WasteType {
  /// Couleur associée au type de déchet (code hex)
  String get color {
    switch (this) {
      case WasteType.general:
        return '#4A9B7F'; // Vert émeraude (le #2D5F4F était illisible sur le fond sombre)
      case WasteType.recyclable:
        return '#42A5F5'; // Bleu
      case WasteType.glass:
        return '#FFA726'; // Jaune-Orange
      case WasteType.organic:
        return '#66BB6A'; // Vert clair
      case WasteType.dangerous:
        return '#EF5350'; // Rouge
      case WasteType.electronic:
        return '#AB47BC'; // Violet
    }
  }

  /// Nom lisible en français
  String get displayName {
    switch (this) {
      case WasteType.general:
        return 'Ordures ménagères';
      case WasteType.recyclable:
        return 'Recyclables';
      case WasteType.glass:
        return 'Verre';
      case WasteType.organic:
        return 'Organique';
      case WasteType.dangerous:
        return 'Dangereux';
      case WasteType.electronic:
        return 'Électronique';
    }
  }

  /// Icône associée (nom de l'icône Lucide)
  String get iconName {
    switch (this) {
      case WasteType.general:
        return 'trash-2';
      case WasteType.recyclable:
        return 'recycle';
      case WasteType.glass:
        return 'wine';
      case WasteType.organic:
        return 'leaf';
      case WasteType.dangerous:
        return 'alert-triangle';
      case WasteType.electronic:
        return 'monitor';
    }
  }

  /// Description courte du type
  String get description {
    switch (this) {
      case WasteType.general:
        return 'Déchets ménagers non recyclables';
      case WasteType.recyclable:
        return 'Plastique, papier, carton';
      case WasteType.glass:
        return 'Bouteilles et bocaux en verre';
      case WasteType.organic:
        return 'Déchets alimentaires et végétaux';
      case WasteType.dangerous:
        return 'Piles, produits chimiques';
      case WasteType.electronic:
        return 'Appareils électriques et électroniques';
    }
  }
}

/// Catégories pour le guide de recyclage
enum RecyclingCategory {
  plastic, // Plastiques
  paper, // Papier et carton
  glass, // Verre
  metal, // Métaux
  organic, // Organique
  dangerous, // Dangereux
  electronic, // Électronique
}

extension RecyclingCategoryExtension on RecyclingCategory {
  /// Nom lisible en français
  String get displayName {
    switch (this) {
      case RecyclingCategory.plastic:
        return 'Plastiques';
      case RecyclingCategory.paper:
        return 'Papier & Carton';
      case RecyclingCategory.glass:
        return 'Verre';
      case RecyclingCategory.metal:
        return 'Métaux';
      case RecyclingCategory.organic:
        return 'Organique';
      case RecyclingCategory.dangerous:
        return 'Dangereux';
      case RecyclingCategory.electronic:
        return 'Électronique';
    }
  }

  /// Icône associée
  String get iconName {
    switch (this) {
      case RecyclingCategory.plastic:
        return 'bottle';
      case RecyclingCategory.paper:
        return 'file-text';
      case RecyclingCategory.glass:
        return 'wine';
      case RecyclingCategory.metal:
        return 'hammer';
      case RecyclingCategory.organic:
        return 'leaf';
      case RecyclingCategory.dangerous:
        return 'alert-octagon';
      case RecyclingCategory.electronic:
        return 'cpu';
    }
  }

  /// Couleur associée
  String get color {
    switch (this) {
      case RecyclingCategory.plastic:
        return '#42A5F5';
      case RecyclingCategory.paper:
        return '#FFA726';
      case RecyclingCategory.glass:
        return '#66BB6A';
      case RecyclingCategory.metal:
        return '#BDBDBD';
      case RecyclingCategory.organic:
        return '#8BC34A';
      case RecyclingCategory.dangerous:
        return '#EF5350';
      case RecyclingCategory.electronic:
        return '#AB47BC';
    }
  }
}
