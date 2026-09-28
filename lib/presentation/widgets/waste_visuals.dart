import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/waste_type.dart';

/// Couleur et icône Flutter associées à chaque type de déchet.
extension WasteTypeVisuals on WasteType {
  Color get uiColor => AppTheme.hexToColor(color);

  IconData get icon {
    switch (this) {
      case WasteType.general:
        return Icons.delete_outline_rounded;
      case WasteType.recyclable:
        return Icons.recycling_rounded;
      case WasteType.glass:
        return Icons.wine_bar;
      case WasteType.organic:
        return Icons.eco;
      case WasteType.dangerous:
        return Icons.warning_amber_rounded;
      case WasteType.electronic:
        return Icons.phone_android;
    }
  }
}

/// Couleur et icône Flutter associées à chaque catégorie du guide.
extension RecyclingCategoryVisuals on RecyclingCategory {
  Color get uiColor => AppTheme.hexToColor(color);

  IconData get icon {
    switch (this) {
      case RecyclingCategory.plastic:
        return Icons.local_drink;
      case RecyclingCategory.paper:
        return Icons.article;
      case RecyclingCategory.glass:
        return Icons.wine_bar;
      case RecyclingCategory.metal:
        return Icons.construction;
      case RecyclingCategory.organic:
        return Icons.eco;
      case RecyclingCategory.dangerous:
        return Icons.warning_amber_rounded;
      case RecyclingCategory.electronic:
        return Icons.phone_android;
    }
  }
}
