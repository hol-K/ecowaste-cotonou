import 'package:ecowaste_cotonou/data/models/guide_item.dart';
import 'package:flutter/material.dart';

/// Écran de détail d'un item du guide de recyclage
class GuideDetailScreen extends StatelessWidget {
  final GuideItem item;

  const GuideDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A3329),
      body: CustomScrollView(
        slivers: [
          // AppBar avec image
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
                      item.color.withOpacity(0.3),
                      const Color(0xFF2D5F4F),
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'guide_${item.name}',
                    child: Icon(item.icon, size: 120, color: item.color),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: Partager
                },
              ),
            ],
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
                      color: item.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Tri
                  _buildSection(
                    icon: Icons.delete_outline,
                    title: 'Où jeter ?',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: item.color, width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: item.color, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'À jeter dans la poubelle ${item.wasteType.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.wasteType,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: item.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section Instructions
                  _buildSection(
                    icon: Icons.list_alt,
                    title: 'Comment préparer ?',
                    child: _buildInstructionsList(),
                  ),

                  const SizedBox(height: 24),

                  // Section Impact environnemental
                  _buildSection(
                    icon: Icons.eco,
                    title: 'Impact positif',
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF66BB6A).withOpacity(0.2),
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
                              _getEnvironmentalImpact(),
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

                  const SizedBox(height: 24),

                  // Section Alternatives
                  if (_hasAlternatives()) ...[
                    _buildSection(
                      icon: Icons.lightbulb_outline,
                      title: 'Alternatives écologiques',
                      child: _buildAlternativesList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Bouton d'action
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Naviguer vers la carte
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ouverture de la carte...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
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
    final instructions = _getInstructions();

    return Column(
      children: instructions.asMap().entries.map((entry) {
        final index = entry.key;
        final instruction = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A9B7F),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
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
                  instruction,
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
    final alternatives = _getAlternatives();

    return Column(
      children: alternatives.map((alternative) {
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

  /// Obtient les instructions selon le type de déchet
  List<String> _getInstructions() {
    switch (item.category) {
      case 'Plastique':
        return [
          'Vider complètement le contenu',
          'Rincer à l\'eau claire',
          'Enlever le bouchon et l\'étiquette si possible',
          'Écraser pour gagner de la place',
        ];
      case 'Verre':
        return [
          'Vider le contenu complètement',
          'Rincer rapidement',
          'Retirer les bouchons et capsules',
          'Ne pas casser le verre',
        ];
      case 'Papier':
        return [
          'Retirer les parties non-papier (plastique, métal)',
          'Aplatir les cartons',
          'Garder au sec',
          'Ne pas froisser excessivement',
        ];
      case 'Dangereux':
        return [
          'Ne jamais jeter avec les ordures ménagères',
          'Conserver dans l\'emballage d\'origine',
          'Apporter dans un point de collecte spécialisé',
          'Éviter tout contact avec d\'autres déchets',
        ];
      default:
        return [
          'Séparer des autres types de déchets',
          'Nettoyer si nécessaire',
          'Placer dans le bon conteneur',
        ];
    }
  }

  /// Obtient l'impact environnemental
  String _getEnvironmentalImpact() {
    switch (item.category) {
      case 'Plastique':
        return '1 tonne de plastique recyclé = 830 litres de pétrole économisés et 2,3 tonnes de CO₂ évitées. Le recyclage du plastique réduit considérablement la pollution marine.';
      case 'Verre':
        return '1 tonne de verre recyclé = 1 tonne de matières premières économisées. Le verre peut être recyclé à l\'infini sans perte de qualité.';
      case 'Papier':
        return '1 tonne de papier recyclé = 17 arbres sauvés et 26 500 litres d\'eau économisés. Recycler le papier réduit de 74% la pollution de l\'air.';
      case 'Organique':
        return 'Le compostage réduit les émissions de méthane et produit un engrais naturel excellent pour les plantes. Il diminue de 30% le volume des déchets ménagers.';
      default:
        return 'Recycler ce type de déchet contribue à préserver les ressources naturelles et à réduire l\'impact environnemental.';
    }
  }

  /// Vérifie si des alternatives existent
  bool _hasAlternatives() {
    return ['Plastique', 'Papier'].contains(item.category);
  }

  /// Obtient les alternatives écologiques
  List<String> _getAlternatives() {
    switch (item.category) {
      case 'Plastique':
        return [
          'Utiliser des gourdes réutilisables en inox',
          'Privilégier les contenants en verre',
          'Acheter en vrac pour éviter les emballages',
          'Opter pour des sacs réutilisables',
        ];
      case 'Papier':
        return [
          'Utiliser des supports numériques quand possible',
          'Imprimer recto-verso',
          'Réutiliser le papier comme brouillon',
          'Choisir du papier recyclé',
        ];
      default:
        return [];
    }
  }
}
