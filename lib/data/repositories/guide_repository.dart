// lib/data/repositories/guide_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recycling_guide_item.dart';
import '../models/waste_type.dart';

/// Repository pour gérer les données du guide de recyclage
class GuideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'recyclingGuide';

  // ========== LECTURE (READ) ==========

  /// Récupère tous les items du guide
  Stream<List<RecyclingGuideItem>> getAllItems() {
    return _firestore
        .collection(_collection)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecyclingGuideItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Récupère les items par catégorie
  Stream<List<RecyclingGuideItem>> getItemsByCategory(
      RecyclingCategory category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecyclingGuideItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Récupère un item par ID
  Future<RecyclingGuideItem?> getItemById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return RecyclingGuideItem.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'item: $e');
      return null;
    }
  }

  /// Recherche des items par mots-clés
  Future<List<RecyclingGuideItem>> searchItems(String query) async {
    try {
      // Récupère tous les items (Firestore ne supporte pas la recherche full-text native)
      final snapshot = await _firestore.collection(_collection).get();
      final allItems = snapshot.docs
          .map((doc) => RecyclingGuideItem.fromMap(doc.data(), doc.id))
          .toList();

      // Filtre localement selon la requête
      return allItems.where((item) => item.matchesSearch(query)).toList();
    } catch (e) {
      print('Erreur lors de la recherche: $e');
      return [];
    }
  }

  /// Récupère les items les plus consultés/populaires
  Stream<List<RecyclingGuideItem>> getPopularItems({int limit = 10}) {
    return _firestore
        .collection(_collection)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => RecyclingGuideItem.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ========== CRÉATION (CREATE) ==========

  /// Ajoute un nouvel item au guide
  Future<String?> addItem(RecyclingGuideItem item) async {
    try {
      final docRef = await _firestore.collection(_collection).add(item.toMap());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout de l\'item: $e');
      return null;
    }
  }

  /// Ajoute plusieurs items en batch
  Future<bool> addItemsBatch(List<RecyclingGuideItem> items) async {
    try {
      final batch = _firestore.batch();
      
      for (var item in items) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, item.toMap());
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout en batch: $e');
      return false;
    }
  }

  // ========== MISE À JOUR (UPDATE) ==========

  /// Met à jour un item existant
  Future<bool> updateItem(String id, RecyclingGuideItem item) async {
    try {
      await _firestore.collection(_collection).doc(id).update(item.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour de l\'item: $e');
      return false;
    }
  }

  /// Met à jour des champs spécifiques
  Future<bool> updateFields(String id, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection(_collection).doc(id).update(fields);
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour des champs: $e');
      return false;
    }
  }

  /// Incrémente le compteur de vues
  Future<bool> incrementViewCount(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
      return true;
    } catch (e) {
      print('Erreur lors de l\'incrémentation des vues: $e');
      return false;
    }
  }

  // ========== SUPPRESSION (DELETE) ==========

  /// Supprime un item
  Future<bool> deleteItem(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression de l\'item: $e');
      return false;
    }
  }

  /// Supprime tous les items d'une catégorie
  Future<bool> deleteItemsByCategory(RecyclingCategory category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category.toString().split('.').last)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression par catégorie: $e');
      return false;
    }
  }

  // ========== MÉTHODES UTILITAIRES ==========

  /// Compte le nombre total d'items
  Future<int> getItemsCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.size;
    } catch (e) {
      print('Erreur lors du comptage: $e');
      return 0;
    }
  }

  /// Compte les items par catégorie
  Future<Map<RecyclingCategory, int>> getItemsCountByCategory() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final items = snapshot.docs
          .map((doc) => RecyclingGuideItem.fromMap(doc.data(), doc.id))
          .toList();

      final counts = <RecyclingCategory, int>{};
      for (var category in RecyclingCategory.values) {
        counts[category] = items.where((item) => item.category == category).length;
      }

      return counts;
    } catch (e) {
      print('Erreur lors du comptage par catégorie: $e');
      return {};
    }
  }

  /// Vérifie si un item existe
  Future<bool> itemExists(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      return doc.exists;
    } catch (e) {
      print('Erreur lors de la vérification de l\'existence: $e');
      return false;
    }
  }

  // ========== DONNÉES INITIALES (POUR TESTS) ==========

  /// Initialise le guide avec des données de base
  Future<bool> initializeGuideData() async {
    try {
      // Vérifier si des données existent déjà
      final count = await getItemsCount();
      if (count > 0) {
        print('Le guide contient déjà des données');
        return false;
      }

      // Créer des items de base
      final items = _createSampleItems();
      return await addItemsBatch(items);
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      return false;
    }
  }

  /// Crée des items d'exemple
  List<RecyclingGuideItem> _createSampleItems() {
    return [
      RecyclingGuideItem(
        id: '',
        name: 'Bouteille en plastique',
        category: RecyclingCategory.plastic,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Bouteille d\'eau ou de boisson en plastique PET',
        instructions: [
          'Vider complètement la bouteille',
          'Rincer à l\'eau claire',
          'Enlever le bouchon et l\'étiquette',
          'Écraser pour gagner de la place',
        ],
        environmentalImpact:
            '1 tonne de plastique recyclé = 830 litres de pétrole économisés',
        keywords: ['bouteille', 'plastique', 'PET', 'boisson', 'eau'],
        alternatives: [
          'Utiliser une gourde réutilisable',
          'Acheter en vrac',
        ],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Carton d\'emballage',
        category: RecyclingCategory.paper,
        wasteType: WasteType.recyclable,
        imageUrl: '',
        description: 'Carton de colis, boîte en carton',
        instructions: [
          'Retirer le scotch et les étiquettes',
          'Aplatir le carton',
          'Garder au sec',
        ],
        environmentalImpact: '1 tonne de carton recyclé = 2,5 tonnes de bois économisées',
        keywords: ['carton', 'boîte', 'emballage', 'colis'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Bouteille en verre',
        category: RecyclingCategory.glass,
        wasteType: WasteType.glass,
        imageUrl: '',
        description: 'Bouteille ou bocal en verre',
        instructions: [
          'Vider complètement',
          'Rincer rapidement',
          'Retirer les bouchons',
          'Ne pas casser',
        ],
        environmentalImpact: 'Le verre se recycle à l\'infini sans perte de qualité',
        keywords: ['verre', 'bouteille', 'bocal'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Pile usagée',
        category: RecyclingCategory.dangerous,
        wasteType: WasteType.dangerous,
        imageUrl: '',
        description: 'Pile alcaline, pile rechargeable',
        instructions: [
          'Ne jamais jeter avec les ordures',
          'Conserver dans un récipient',
          'Apporter dans un point de collecte spécialisé',
        ],
        environmentalImpact:
            '1 pile recyclée = récupération de métaux précieux et évite la pollution',
        keywords: ['pile', 'batterie', 'dangereux'],
      ),
      RecyclingGuideItem(
        id: '',
        name: 'Téléphone portable',
        category: RecyclingCategory.electronic,
        wasteType: WasteType.electronic,
        imageUrl: '',
        description: 'Smartphone, téléphone mobile usagé',
        instructions: [
          'Sauvegarder et supprimer les données',
          'Retirer la carte SIM',
          'Apporter dans un point de collecte DEEE',
        ],
        environmentalImpact:
            '1 téléphone recyclé = récupération d\'or, argent et métaux rares',
        keywords: ['téléphone', 'smartphone', 'mobile', 'électronique'],
      ),
    ];
  }
}