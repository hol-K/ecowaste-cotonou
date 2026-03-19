// lib/data/repositories/points_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/collection_point.dart';
import '../models/waste_type.dart';

/// Repository pour gérer les points de collecte
class PointsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'collectionPoints';

  // ========== LECTURE (READ) ==========

  /// Récupère tous les points de collecte
  Stream<List<CollectionPoint>> getAllPoints() {
    return _firestore.collection(_collection).orderBy('name').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => CollectionPoint.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Récupère les points par type de déchet accepté
  Stream<List<CollectionPoint>> getPointsByWasteType(WasteType wasteType) {
    return _firestore
        .collection(_collection)
        .where(
          'acceptedWasteTypes',
          arrayContains: wasteType.toString().split('.').last,
        )
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CollectionPoint.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Récupère un point par ID
  Future<CollectionPoint?> getPointById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return CollectionPoint.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération du point: $e');
      return null;
    }
  }

  /// Récupère les points publics uniquement
  Stream<List<CollectionPoint>> getPublicPoints() {
    return _firestore
        .collection(_collection)
        .where('isPublic', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CollectionPoint.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // ========== CRÉATION (CREATE) ==========

  /// Ajoute un nouveau point de collecte
  Future<String?> addPoint(CollectionPoint point) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(point.toMap());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de l\'ajout du point: $e');
      return null;
    }
  }

  /// Ajoute plusieurs points en batch
  Future<bool> addPointsBatch(List<CollectionPoint> points) async {
    try {
      final batch = _firestore.batch();

      for (var point in points) {
        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, point.toMap());
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Erreur lors de l\'ajout en batch: $e');
      return false;
    }
  }

  // ========== MISE À JOUR (UPDATE) ==========

  /// Met à jour un point existant
  Future<bool> updatePoint(String id, CollectionPoint point) async {
    try {
      await _firestore.collection(_collection).doc(id).update(point.toMap());
      return true;
    } catch (e) {
      print('Erreur lors de la mise à jour du point: $e');
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

  // ========== SUPPRESSION (DELETE) ==========

  /// Supprime un point
  Future<bool> deletePoint(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      print('Erreur lors de la suppression du point: $e');
      return false;
    }
  }

  // ========== MÉTHODES UTILITAIRES ==========

  /// Compte le nombre total de points
  Future<int> getPointsCount() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      return snapshot.size;
    } catch (e) {
      print('Erreur lors du comptage: $e');
      return 0;
    }
  }

  /// Compte les points par type de déchet
  Future<Map<WasteType, int>> countPointsByWasteType() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final points = snapshot.docs
          .map((doc) => CollectionPoint.fromMap(doc.data(), doc.id))
          .toList();

      final counts = <WasteType, int>{};
      for (var type in WasteType.values) {
        counts[type] = points
            .where((point) => point.acceptsWasteType(type))
            .length;
      }

      return counts;
    } catch (e) {
      print('Erreur lors du comptage par type: $e');
      return {};
    }
  }

  /// Vérifie si un point existe
  Future<bool> pointExists(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      return doc.exists;
    } catch (e) {
      print('Erreur lors de la vérification de l\'existence: $e');
      return false;
    }
  }

  // ========== DONNÉES INITIALES (POUR TESTS) ==========

  /// Initialise les points avec des données de base
  Future<bool> initializePointsData() async {
    try {
      // Vérifier si des données existent déjà
      final count = await getPointsCount();
      if (count > 0) {
        print('Des points existent déjà');
        return false;
      }

      // Créer des points de base pour Cotonou
      final points = _createSamplePoints();
      return await addPointsBatch(points);
    } catch (e) {
      print('Erreur lors de l\'initialisation: $e');
      return false;
    }
  }

  /// Crée des points d'exemple pour Cotonou
  List<CollectionPoint> _createSamplePoints() {
    return [
      CollectionPoint(
        id: '',
        name: 'Déchetterie Municipale d\'Akpakpa',
        latitude: 6.3598,
        longitude: 2.4378,
        address: 'Route de Porto-Novo, Akpakpa',
        acceptedWasteTypes: WasteType.values,
        openingHours: 'Lun-Sam: 08:00-18:00, Dim: Fermé',
        phone: '+229 97 00 00 01',
        imageUrl: null,
        description: 'Déchetterie municipale acceptant tous types de déchets',
        isPublic: true,
        rating: 4.2,
      ),
      CollectionPoint(
        id: '',
        name: 'Point de Collecte Recyclable Cadjèhoun',
        latitude: 6.3745,
        longitude: 2.4289,
        address: 'Avenue Steinmetz, Cadjèhoun',
        acceptedWasteTypes: [WasteType.recyclable, WasteType.glass],
        openingHours: 'Lun-Sam: 08:00-18:00',
        phone: '+229 97 00 00 02',
        imageUrl: null,
        description: 'Point de collecte spécialisé dans les recyclables',
        isPublic: true,
        rating: 4.5,
      ),
      CollectionPoint(
        id: '',
        name: 'Centre de Tri de Godomey',
        latitude: 6.3890,
        longitude: 2.3456,
        address: 'Route de Ouidah, Godomey',
        acceptedWasteTypes: WasteType.values,
        openingHours: 'Lun-Sam: 08:00-18:00',
        phone: '+229 97 00 00 03',
        imageUrl: null,
        description: 'Grand centre de tri municipal',
        isPublic: true,
        rating: 4.0,
      ),
      CollectionPoint(
        id: '',
        name: 'Point de Collecte DEEE Fidjrossè',
        latitude: 6.3512,
        longitude: 2.4512,
        address: 'Boulevard de la Marina, Fidjrossè',
        acceptedWasteTypes: [WasteType.electronic, WasteType.dangerous],
        openingHours: 'Lun-Ven: 09:00-17:00',
        phone: '+229 97 00 00 04',
        imageUrl: null,
        description: 'Collecte spécialisée pour appareils électroniques',
        isPublic: true,
        rating: 4.3,
      ),
      CollectionPoint(
        id: '',
        name: 'Recyclerie Communautaire de Vossa',
        latitude: 6.3823,
        longitude: 2.4423,
        address: 'Quartier Vossa',
        acceptedWasteTypes: [
          WasteType.recyclable,
          WasteType.glass,
          WasteType.organic,
        ],
        openingHours: 'Lun-Sam: 07:00-19:00',
        phone: '+229 97 00 00 05',
        imageUrl: null,
        description: 'Initiative communautaire de recyclage',
        isPublic: true,
        rating: 4.7,
      ),
    ];
  }
}
