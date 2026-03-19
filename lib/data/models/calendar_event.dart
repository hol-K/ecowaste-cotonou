import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un événement de collecte dans le calendrier
class CalendarEvent {
  final String id;
  final DateTime date;
  final String wasteType; // 'organic', 'plastic', 'paper', 'glass', etc.
  final String title;
  final String? description;
  final String? location;

  CalendarEvent({
    required this.id,
    required this.date,
    required this.wasteType,
    required this.title,
    this.description,
    this.location,
  });

  /// Convertir depuis Firestore
  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      wasteType: data['wasteType'] ?? 'general',
      title: data['title'] ?? 'Collecte',
      description: data['description'],
      location: data['location'],
    );
  }

  /// Convertir vers Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'wasteType': wasteType,
      'title': title,
      'description': description,
      'location': location,
    };
  }

  /// Couleur associée au type de déchet
  static Map<String, String> getWasteColors() {
    return {
      'organic': '#4CAF50',    // Vert
      'plastic': '#FFC107',    // Jaune
      'paper': '#2196F3',      // Bleu
      'glass': '#9C27B0',      // Violet
      'metal': '#FF5722',      // Orange
      'general': '#757575',    // Gris
    };
  }

  /// Obtenir la couleur hexadécimale du type de déchet
  String getColor() {
    return getWasteColors()[wasteType] ?? '#757575';
  }

  /// Copier avec modifications
  CalendarEvent copyWith({
    String? id,
    DateTime? date,
    String? wasteType,
    String? title,
    String? description,
    String? location,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      date: date ?? this.date,
      wasteType: wasteType ?? this.wasteType,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
    );
  }
}