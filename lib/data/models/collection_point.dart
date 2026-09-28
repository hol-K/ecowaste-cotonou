import 'dart:math' show sin, cos, sqrt, asin;
import 'waste_type.dart';

/// Représente un point de collecte géolocalisé
class CollectionPoint {
  final String id;
  final String name;                      // Nom du point
  final double latitude;                  // Latitude GPS
  final double longitude;                 // Longitude GPS
  final String address;                   // Adresse complète
  final List<WasteType> acceptedWasteTypes; // Types de déchets acceptés
  final String openingHours;              // Horaires d'ouverture
  final String? phone;                    // Numéro de téléphone (optionnel)
  final String? imageUrl;                 // Photo du lieu (optionnel)
  final String? description;              // Description (optionnel)
  final bool isPublic;                    // Public ou privé
  final double? rating;                   // Note (0-5, optionnel)

  CollectionPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.acceptedWasteTypes,
    required this.openingHours,
    this.phone,
    this.imageUrl,
    this.description,
    this.isPublic = true,
    this.rating,
  });

  //MÉTHODES UTILES

  /// Calcule la distance depuis une position utilisateur (en km)
  /// Utilise la formule de Haversine
  double distanceFrom(double userLat, double userLon) {
    const double earthRadius = 6371; // Rayon de la Terre en km
    
    final dLat = _toRadians(latitude - userLat);
    final dLon = _toRadians(longitude - userLon);
    
    final a = 
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(userLat)) * cos(_toRadians(latitude)) *
      sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  /// Convertit les degrés en radians
  double _toRadians(double degree) {
    return degree * (3.141592653589793 / 180);
  }

  /// Texte de distance humanisé (ex: "1,2 km" ou "450 m")
  String getDistanceText(double userLat, double userLon) {
    final distance = distanceFrom(userLat, userLon);
    
    if (distance < 1) {
      return '${(distance * 1000).round()} m';
    } else {
      return '${distance.toStringAsFixed(1)} km';
    }
  }

  /// Vérifie si un type de déchet spécifique est accepté
  bool acceptsWasteType(WasteType type) {
    return acceptedWasteTypes.contains(type);
  }

  /// Vérifie si tous les types de déchets sont acceptés
  bool acceptsAllWasteTypes() {
    return acceptedWasteTypes.length == WasteType.values.length;
  }

  /// Obtient la liste des noms de types acceptés
  List<String> getAcceptedWasteTypeNames() {
    return acceptedWasteTypes.map((type) => type.displayName).toList();
  }

  /// URL pour lancer Google Maps avec itinéraire
  String getNavigationUrl() {
    return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
  }

  /// URL pour appeler le numéro de téléphone
  String? getPhoneUrl() {
    if (phone == null) return null;
    return 'tel:${phone!.replaceAll(RegExp(r'[^0-9+]'), '')}';
  }

  /// Vérifie si le point a une note
  bool get hasRating => rating != null && rating! > 0;

  /// Obtient le texte de la note (ex: "4.5 / 5")
  String get ratingText {
    if (!hasRating) return 'Non noté';
    return '${rating!.toStringAsFixed(1)} / 5';
  }

  //SÉRIALISATION SUPABASE (table collection_points)

  /// Conversion depuis une ligne Supabase
  factory CollectionPoint.fromMap(Map<String, dynamic> map) {
    final types = WasteType.values.asNameMap();
    return CollectionPoint(
      id: map['id'] as String,
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] ?? '',
      acceptedWasteTypes: [
        for (final name in (map['accepted_waste_types'] as List? ?? const []))
          if (types[name] != null) types[name]!,
      ],
      openingHours: map['opening_hours'] ?? '',
      phone: map['phone'],
      imageUrl: map['image_url'],
      description: map['description'],
      isPublic: map['is_public'] ?? true,
      // numeric Postgres : peut arriver en num ou en String selon le client
      rating: switch (map['rating']) {
        num value => value.toDouble(),
        String value => double.tryParse(value),
        _ => null,
      },
    );
  }

  /// Conversion vers une ligne Supabase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'accepted_waste_types': acceptedWasteTypes.map((e) => e.name).toList(),
      'opening_hours': openingHours,
      'phone': phone,
      'image_url': imageUrl,
      'description': description,
      'is_public': isPublic,
      'rating': rating,
    };
  }

  /// CopyWith pour créer une copie modifiée
  CollectionPoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? address,
    List<WasteType>? acceptedWasteTypes,
    String? openingHours,
    String? phone,
    String? imageUrl,
    String? description,
    bool? isPublic,
    double? rating,
  }) {
    return CollectionPoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      acceptedWasteTypes: acceptedWasteTypes ?? this.acceptedWasteTypes,
      openingHours: openingHours ?? this.openingHours,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      rating: rating ?? this.rating,
    );
  }

  @override
  String toString() {
    return 'CollectionPoint(id: $id, name: $name, location: ($latitude, $longitude))';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionPoint && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}