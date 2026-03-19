import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/guide_provider.dart';
import '../../../data/models/waste_type.dart';
import 'package:ecowaste_cotonou/presentation/screens/guide/guide_detail_screen.dart';

/// Écran du guide de recyclage connecté à Firebase
class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GuideProvider>();
      provider.loadAllItems();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3329),
      appBar: AppBar(
        title: const Text('Guide de Tri'),
        backgroundColor: const Color(0xFF2D5F4F),
        elevation: 0,
        actions: [
          // Bouton pour initialiser les données (en développement)
          if (context.watch<GuideProvider>().totalItemsCount == 0)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                final provider = context.read<GuideProvider>();
                final success = await provider.initializeGuideData();
                if (success && mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Données du guide initialisées !'),
                      backgroundColor: Color(0xFF66BB6A),
                    ),
                  );
                }
              },
              tooltip: 'Initialiser les données',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),

          // Filtres par catégorie
          _buildCategoryFilters(),

          // Liste des items OU état de chargement/erreur
          Expanded(
            child: Consumer<GuideProvider>(
              builder: (context, provider, child) {
                // État de chargement
                if (provider.isLoading) {
                  return _buildLoadingState();
                }

                // État d'erreur
                if (provider.hasError) {
                  return _buildErrorState(provider.errorMessage!);
                }

                // État vide (aucun item)
                if (provider.isEmpty) {
                  return _buildEmptyState();
                }

                // Liste des items
                return _buildItemsList(provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Barre de recherche
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF2D5F4F),
      child: Consumer<GuideProvider>(
        builder: (context, provider, child) {
          return TextField(
            controller: _searchController,
            onChanged: (value) {
              provider.search(value);
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher un déchet...',
              hintStyle: const TextStyle(color: Color(0xFFB8C5C0)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFB8C5C0)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFFB8C5C0)),
                      onPressed: () {
                        _searchController.clear();
                        provider.clearSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0x1AFFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Filtres par catégorie (chips horizontales)
  Widget _buildCategoryFilters() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Consumer<GuideProvider>(
        builder: (context, provider, child) {
          final categories = [
            null, // Pour "Tout"
            ...RecyclingCategory.values,
          ];

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == provider.selectedCategory;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category?.displayName ?? 'Tout'),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.filterByCategory(category);
                  },
                  backgroundColor: const Color(0xFF234037),
                  selectedColor: const Color(0xFF4A9B7F),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFB8C5C0),
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Liste des items du guide
  Widget _buildItemsList(GuideProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.filteredItems.length,
      itemBuilder: (context, index) {
        final item = provider.filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  /// Card d'un item du guide
  // ignore: strict_top_level_inference
  Widget _buildItemCard(item) {
    // Obtenir la couleur selon le type de déchet
    Color getColor() {
      switch (item.actualWasteType) {
        case WasteType.recyclable:
          return const Color(0xFF42A5F5);
        case WasteType.glass:
          return const Color(0xFFFFA726);
        case WasteType.organic:
          return const Color(0xFF66BB6A);
        case WasteType.dangerous:
          return const Color(0xFFEF5350);
        case WasteType.electronic:
          return const Color(0xFFAB47BC);
        default:
          return const Color(0xFF4A9B7F);
      }
    }

    // Obtenir l'icône selon la catégorie
    IconData getIcon() {
      switch (item.category) {
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
        default:
          return Icons.recycling;
      }
    }

    final color = getColor();
    final icon = getIcon();

    return GestureDetector(
      onTap: () {
        // Incrémenter le compteur de vues
        context.read<GuideProvider>().incrementViewCount(item.id);

        // Naviguer vers le détail
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GuideDetailScreen(item: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        ),
        child: Row(
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),

            const SizedBox(width: 16),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.wasteType,
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(Icons.chevron_right, color: Color(0xFFB8C5C0)),
          ],
        ),
      ),
    );
  }

  /// État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF4A9B7F)),
          SizedBox(height: 16),
          Text(
            'Chargement du guide...',
            style: TextStyle(fontSize: 16, color: Color(0xFFB8C5C0)),
          ),
        ],
      ),
    );
  }

  /// État d'erreur
  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              // ignore: deprecated_member_use
              color: const Color(0xFFEF5350).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(fontSize: 14, color: Color(0xFFB8C5C0)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GuideProvider>().loadAllItems();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9B7F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// État vide (aucun résultat)
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            // ignore: deprecated_member_use
            color: const Color(0xFF4A9B7F).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Essayez une autre recherche',
            style: TextStyle(fontSize: 14, color: Color(0xFFB8C5C0)),
          ),
          const SizedBox(height: 24),
          if (context.watch<GuideProvider>().totalItemsCount == 0)
            ElevatedButton.icon(
              onPressed: () async {
                final provider = context.read<GuideProvider>();
                await provider.initializeGuideData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter des données'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A9B7F),
              ),
            ),
        ],
      ),
    );
  }
}
