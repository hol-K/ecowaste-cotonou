import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_schedule.dart';
import '../models/recycling_guide_item.dart';
import '../models/collection_point.dart';
import '../models/waste_type.dart';

/// Service pour peupler Firestore avec des données initiales
class FirebaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Peuple toutes les collections
  Future<void> seedAll() async {
    print('Début du peuplement de Firestore...\n');

    try {
      await seedSchedules();
      await seedGuideItems();
      await seedCollectionPoints();

      print('\n Peuplement terminé avec succès !');
    } catch (e) {
      print('\n Erreur lors du peuplement: $e');
      rethrow;
    }
  }

  /// Peuple les calendriers de collecte
  Future<void> seedSchedules() async {
    print('Peuplement des calendriers de collecte...');

    final quartiers = [
      'Akpakpa',
      'Cadjèhoun',
      'Fidjrossè',
      'Godomey',
      'Agla',
      'Vossa',
    ];

    int count = 0;

    for (var quartier in quartiers) {
      // Générer des collectes pour les 3 prochains mois
      final now = DateTime.now();

      for (int month = 0; month < 3; month++) {
        final currentMonth = DateTime(now.year, now.month + month, 1);

        // Ordures ménagères : Lundi et Jeudi
        for (int day = 1; day <= 31; day++) {
          try {
            final date = DateTime(currentMonth.year, currentMonth.month, day);
            if (date.month != currentMonth.month) break;

            if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday) {
              final schedule = CollectionSchedule(
                id: '',
                district: quartier,
                wasteType: WasteType.general,
                collectionDate: date,
                collectionTime: '06:00 - 10:00',
                instructions: 'Sortez vos poubelles la veille au soir. Fermez bien les sacs.',
                isRecurring: true,
                recurrencePattern: 'weekly',
              );

              await _firestore.collection('schedules').add(schedule.toMap());
              count++;
            }
          } catch (e) {
            // Ignore les dates invalides
          }
        }

        // Recyclables : Mardi
        for (int day = 1; day <= 31; day++) {
          try {
            final date = DateTime(currentMonth.year, currentMonth.month, day);
            if (date.month != currentMonth.month) break;

            if (date.weekday == DateTime.tuesday) {
              final schedule = CollectionSchedule(
                id: '',
                district: quartier,
                wasteType: WasteType.recyclable,
                collectionDate: date,
                collectionTime: '06:00 - 10:00',
                instructions: 'Triez plastique, papier et carton. Rincez les contenants.',
                isRecurring: true,
                recurrencePattern: 'weekly',
              );

              await _firestore.collection('schedules').add(schedule.toMap());
              count++;
            }
          } catch (e) {}
        }

        // Verre : 1er et 15 du mois
        for (int day in [1, 15]) {
          try {
            final date = DateTime(currentMonth.year, currentMonth.month, day);
            if (date.month != currentMonth.month) break;

            final schedule = CollectionSchedule(
              id: '',
              district: quartier,
              wasteType: WasteType.glass,
              collectionDate: date,
              collectionTime: '08:00 - 12:00',
              instructions: 'Vider et rincer les bouteilles. Retirer les bouchons.',
              isRecurring: true,
              recurrencePattern: 'monthly',
            );

            await _firestore.collection('schedules').add(schedule.toMap());
            count++;
          } catch (e) {}
        }
      }
    }

    print(' $count horaires créés');
  }

  /// Peuple le guide de recyclage
  Future<void> seedGuideItems() async {
    print('Peuplement du guide de recyclage...');

    final items = [
      // PLASTIQUES
      RecyclingGuideItem(
        id: '',
        name: 'Bouteille en plastique',
        category: RecyclingCategory.plastic,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Bouteilles d\'eau, de soda ou de jus en plastique PET',
        instructions: [
          'Vider complètement',
          'Rincer à l\'eau claire',
          'Enlever le bouchon',
          'Écraser pour gagner de la place',
        ],
        environmentalImpact: '1 tonne de plastique recyclé = 830 litres de pétrole économisés',
        keywords: ['bouteille', 'plastique', 'pet', 'eau', 'soda'],
        alternatives: [
          'Utiliser une gourde réutilisable',
          'Acheter en vrac',
        ],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Sachet plastique',
        category: RecyclingCategory.plastic,
        wasteType: WasteType.general,
        imageUrl: '',
        description: 'Sacs plastiques fins pour courses',
        instructions: [
          'Jeter dans les ordures ménagères',
          'Ne pas mettre dans les recyclables',
        ],
        environmentalImpact: 'Un sac plastique met 400 ans à se dégrader',
        keywords: ['sac', 'sachet', 'plastique', 'courses'],
        alternatives: [
          'Utiliser des sacs réutilisables en tissu',
          'Privilégier les paniers',
        ],
      ),

      // PAPIER & CARTON
      RecyclingGuideItem(
        id: '',
        name: 'Carton d\'emballage',
        category: RecyclingCategory.paper,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Boîtes en carton, emballages',
        instructions: [
          'Aplatir les cartons',
          'Retirer le scotch et les agrafes',
          'Garder au sec',
        ],
        environmentalImpact: '1 tonne de carton recyclé = 2,5 tonnes de bois sauvées',
        keywords: ['carton', 'boite', 'emballage'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Journal / Magazine',
        category: RecyclingCategory.paper,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Journaux, magazines, prospectus',
        instructions: [
          'Retirer les films plastiques',
          'Ne pas froisser',
          'Garder au sec',
        ],
        environmentalImpact: '1 tonne de papier recyclé = 17 arbres sauvés',
        keywords: ['journal', 'magazine', 'papier', 'prospectus'],
      ),

      // VERRE
      RecyclingGuideItem(
        id: '',
        name: 'Bouteille en verre',
        category: RecyclingCategory.glass,
        wasteType: WasteType.glass,
        imageUrl: '',
        description: 'Bouteilles de vin, bière, jus',
        instructions: [
          'Vider complètement',
          'Rincer rapidement',
          'Retirer le bouchon',
          'Ne pas casser',
        ],
        environmentalImpact: 'Le verre se recycle à l\'infini sans perte de qualité',
        keywords: ['verre', 'bouteille', 'vin', 'biere'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Bocal en verre',
        category: RecyclingCategory.glass,
        wasteType: WasteType.glass,
        imageUrl: '',
        description: 'Pots de confiture, bocaux de conservation',
        instructions: [
          'Vider et rincer',
          'Retirer le couvercle métallique',
          'Ne pas casser',
        ],
        environmentalImpact: 'Recycler un bocal économise l\'énergie équivalente à 4h d\'ampoule',
        keywords: ['bocal', 'pot', 'verre', 'confiture'],
      ),

      // MÉTAUX
      RecyclingGuideItem(
        id: '',
        name: 'Canette aluminium',
        category: RecyclingCategory.metal,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Canettes de soda, bière',
        instructions: [
          'Vider complètement',
          'Rincer',
          'Écraser',
        ],
        environmentalImpact: 'Recycler l\'aluminium économise 95% de l\'énergie nécessaire',
        keywords: ['canette', 'aluminium', 'soda', 'biere'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Boîte de conserve',
        category: RecyclingCategory.metal,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Conserves métalliques',
        instructions: [
          'Vider et rincer',
          'Enlever l\'étiquette',
          'Écraser si possible',
        ],
        environmentalImpact: '1 tonne d\'acier recyclé = 1 tonne de minerai économisée',
        keywords: ['conserve', 'boite', 'metal', 'acier'],
      ),

      // ORGANIQUE
      RecyclingGuideItem(
        id: '',
        name: 'Épluchures de légumes',
        category: RecyclingCategory.organic,
        wasteType: WasteType.organic,
        imageUrl: '',
        description: 'Restes de fruits et légumes',
        instructions: [
          'Mettre dans un composteur',
          'Ou dans les ordures ménagères',
        ],
        environmentalImpact: 'Le compost enrichit le sol naturellement',
        keywords: ['epluchure', 'legume', 'fruit', 'compost'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Marc de café',
        category: RecyclingCategory.organic,
        wasteType: WasteType.organic,
        imageUrl: '',
        description: 'Résidus de café moulu',
        instructions: [
          'Excellent pour le compost',
          'Peut servir d\'engrais',
        ],
        environmentalImpact: 'Le marc de café enrichit le sol en azote',
        keywords: ['cafe', 'marc', 'compost'],
      ),

      // DANGEREUX
      RecyclingGuideItem(
        id: '',
        name: 'Pile usagée',
        category: RecyclingCategory.dangerous,
        wasteType: WasteType.dangerous,
        imageUrl: '',
        description: 'Piles alcalines, rechargeables',
        instructions: [
          'Ne JAMAIS jeter avec les ordures',
          'Apporter dans un point de collecte spécialisé',
          'Conserver dans l\'emballage d\'origine',
        ],
        environmentalImpact: '1 pile jetée pollue 1m³ de terre pendant 50 ans',
        keywords: ['pile', 'batterie', 'dangereux'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Ampoule',
        category: RecyclingCategory.dangerous,
        wasteType: WasteType.dangerous,
        imageUrl: '',
        description: 'Ampoules basse consommation, LED',
        instructions: [
          'Ne pas jeter avec le verre',
          'Apporter en déchetterie',
          'Ne pas casser',
        ],
        environmentalImpact: 'Les ampoules contiennent du mercure toxique',
        keywords: ['ampoule', 'led', 'lumiere'],
      ),

      // ÉLECTRONIQUE
      RecyclingGuideItem(
        id: '',
        name: 'Téléphone portable',
        category: RecyclingCategory.electronic,
        wasteType: WasteType.electronic,
        imageUrl: '',
        description: 'Smartphones, téléphones',
        instructions: [
          'Supprimer toutes les données',
          'Retirer la carte SIM',
          'Apporter dans un point DEEE',
        ],
        environmentalImpact: '80% des matériaux d\'un téléphone sont recyclables',
        keywords: ['telephone', 'smartphone', 'portable', 'mobile'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Ordinateur',
        category: RecyclingCategory.electronic,
        wasteType: WasteType.electronic,
        imageUrl: '',
        description: 'PC, ordinateurs portables',
        instructions: [
          'Effacer toutes les données',
          'Apporter en déchetterie',
          'Possibilité de don si fonctionnel',
        ],
        environmentalImpact: 'Recycler 1 ordinateur récupère métaux précieux et plastiques',
        keywords: ['ordinateur', 'pc', 'laptop'],
      ),
    ];

    int count = 0;
    for (var item in items) {
      await _firestore.collection('recyclingGuide').add(item.toMap());
      count++;
    }

    print('    $count items créés');
  }

  /// Peuple les points de collecte
  Future<void> seedCollectionPoints() async {
    print('Peuplement des points de collecte...');

    final points = [
      CollectionPoint(
        id: '',
        name: 'Déchetterie Municipale d\'Akpakpa',
        latitude: 6.3667,
        longitude: 2.4333,
        address: 'Route de Porto-Novo, Akpakpa, Cotonou',
        acceptedWasteTypes: [
          WasteType.general,
          WasteType.recyclable,
          WasteType.glass,
          WasteType.organic,
          WasteType.dangerous,
          WasteType.electronic,
        ],
        openingHours: 'Lundi - Samedi: 08:00 - 18:00',
        phone: '+229 21 30 00 00',
        description: 'Déchetterie principale acceptant tous types de déchets',
        isPublic: true,
        rating: 4.5,
      ),
      CollectionPoint(
        id: '',
        name: 'Point de Collecte Recyclable Cadjèhoun',
        latitude: 6.3703,
        longitude: 2.3912,
        address: 'Avenue Steinmetz, Cadjèhoun, Cotonou',
        acceptedWasteTypes: [
          WasteType.recyclable,
          WasteType.glass,
        ],
        openingHours: 'Lundi - Vendredi: 09:00 - 17:00',
        phone: '+229 21 31 00 00',
        description: 'Collecte de recyclables et verre uniquement',
        isPublic: true,
        rating: 4.0,
      ),
      CollectionPoint(
        id: '',
        name: 'Centre de Tri de Godomey',
        latitude: 6.4000,
        longitude: 2.3500,
        address: 'Route de Ouidah, Godomey, Cotonou',
        acceptedWasteTypes: [
          WasteType.general,
          WasteType.recyclable,
          WasteType.glass,
        ],
        openingHours: 'Lundi - Samedi: 07:00 - 19:00',
        phone: '+229 21 32 00 00',
        description: 'Centre de tri principal de la zone ouest',
        isPublic: true,
        rating: 4.2,
      ),
      CollectionPoint(
        id: '',
        name: 'Point de Collecte DEEE Fidjrossè',
        latitude: 6.3833,
        longitude: 2.4167,
        address: 'Boulevard de la Marina, Fidjrossè, Cotonou',
        acceptedWasteTypes: [
          WasteType.electronic,
          WasteType.dangerous,
        ],
        openingHours: 'Mardi - Samedi: 10:00 - 16:00',
        phone: '+229 21 33 00 00',
        description: 'Spécialisé dans les déchets électroniques et dangereux',
        isPublic: true,
        rating: 4.8,
      ),
      CollectionPoint(
        id: '',
        name: 'Recyclerie Communautaire de Vossa',
        latitude: 6.3500,
        longitude: 2.4000,
        address: 'Quartier Vossa, Cotonou',
        acceptedWasteTypes: [
          WasteType.recyclable,
          WasteType.glass,
          WasteType.organic,
        ],
        openingHours: 'Lundi - Vendredi: 08:00 - 16:00',
        phone: '+229 21 34 00 00',
        description: 'Initiative communautaire de recyclage',
        isPublic: true,
        rating: 4.3,
      ),
      CollectionPoint(
        id: '',
        name: 'Déchetterie d\'Agla',
        latitude: 6.3900,
        longitude: 2.3700,
        address: 'Quartier Agla, Cotonou',
        acceptedWasteTypes: [
          WasteType.general,
          WasteType.recyclable,
        ],
        openingHours: 'Lundi - Samedi: 08:00 - 17:00',
        phone: '+229 21 35 00 00',
        description: 'Point de collecte de proximité',
        isPublic: true,
        rating: 3.8,
      ),
    ];

    int count = 0;
    for (var point in points) {
      await _firestore.collection('collectionPoints').add(point.toMap());
      count++;
    }

    print('    $count points créés');
  }

  /// Vérifie si les collections sont déjà peuplées
  Future<bool> isDatabaseSeeded() async {
    final schedulesCount = await _firestore.collection('schedules').count().get();
    final guideCount = await _firestore.collection('recyclingGuide').count().get();
    final pointsCount = await _firestore.collection('collectionPoints').count().get();

    return (schedulesCount.count ?? 0) > 0 &&
           (guideCount.count ?? 0) > 0 &&
           (pointsCount.count ?? 0) > 0;
  }

  /// Nettoie toutes les collections (ATTENTION: supprime toutes les données)
  Future<void> clearAll() async {
    print(' Nettoyage des collections...');

    await _clearCollection('schedules');
    await _clearCollection('recyclingGuide');
    await _clearCollection('collectionPoints');

    print('    Collections nettoyées');
  }

  Future<void> _clearCollection(String collectionName) async {
    final snapshot = await _firestore.collection(collectionName).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}