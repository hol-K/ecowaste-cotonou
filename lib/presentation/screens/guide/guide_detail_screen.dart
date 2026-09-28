import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/recycling_guide_item.dart';
import '../../../data/models/waste_type.dart';
import '../../providers/home_navigation_provider.dart';
import '../../providers/map_provider.dart';
import '../../widgets/waste_visuals.dart';

/// Écran de détail d'un item du guide de recyclage
class GuideDetailScreen extends StatelessWidget {
  final RecyclingGuideItem item;

  const GuideDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.wasteType.uiColor;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3329),
      body: CustomScrollView(
        slivers: [
          // AppBar avec icône
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF2D5F4F),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color.withValues(alpha: 0.3),
                      const Color(0xFF2D5F4F),
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'guide_${item.id}',
                    child: Icon(item.category.icon, size: 120, color: color),
                  ),
                ),
              ),
            ),
          ),

          // Contenu
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du déchet
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFB8C5C0),
                        height: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Section Tri
                  _buildSection(
                    icon: Icons.delete_outline,
                    title: 'Où jeter ?',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(item.wasteType.icon, color: color, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Poubelle : ${item.wasteType.displayName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.wasteType.description,
                                  style: TextStyle(fontSize: 14, color: color),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (item.instructions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.list_alt,
                      title: 'Comment préparer ?',
                      child: _buildInstructionsList(),
                    ),
                  ],

                  if (item.environmentalImpact.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.eco,
                      title: 'Impact positif',
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.energy_savings_leaf,
                              color: Color(0xFF66BB6A),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.environmentalImpact,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Section Alternatives
                  if (item.hasAlternatives) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Alternatives écologiques',
                      child: _buildAlternativesList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bouton d'action : ouvre la carte filtrée sur ce type
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<MapProvider>().filterByWasteType(
                          item.wasteType,
                        );
                        context.read<HomeNavigationProvider>().goTo(
                          HomeTab.map,
                        );
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Trouver un point de collecte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A9B7F),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section avec titre et icône
  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF4A9B7F), size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  /// Liste des instructions
  Widget _buildInstructionsList() {
    return Column(
      children: item.instructions.asMap().entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A9B7F),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB8C5C0),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Liste des alternatives
  Widget _buildAlternativesList() {
    return Column(
      children: item.alternatives!.map((alternative) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF66BB6A),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alternative,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFB8C5C0),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
