import 'waste_type.dart';

/// Représente un événement de collecte de déchets
class CollectionSchedule {
  final String id;
  final String district;           // Quartier (Akpakpa, Cadjèhoun, etc.)
  final WasteType wasteType;       // Type de déchet collecté
  final DateTime collectionDate;   // Date de la collecte
  final String collectionTime;     // Horaire (ex: "06:00 - 10:00")
  final String instructions;       // Conseils de préparation
  final bool isRecurring;          // Collecte récurrente ?
  final String? recurrencePattern; // Pattern si récurrente (ex: "weekly")

  CollectionSchedule({
    required this.id,
    required this.district,
    required this.wasteType,
    required this.collectionDate,
    required this.collectionTime,
    required this.instructions,
    this.isRecurring = false,
    this.recurrencePattern,
  });

  //MÉTHODES UTILES

  /// Vérifie si la collecte est aujourd'hui
  bool isToday() {
    final now = DateTime.now();
    return collectionDate.year == now.year &&
           collectionDate.month == now.month &&
           collectionDate.day == now.day;
  }

  /// Vérifie si la collecte est demain
  bool isTomorrow() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return collectionDate.year == tomorrow.year &&
           collectionDate.month == tomorrow.month &&
           collectionDate.day == tomorrow.day;
  }

  /// Vérifie si la collecte est dans le passé
  bool isPast() {
    final now = DateTime.now();
    return collectionDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  /// Temps restant avant la collecte
  Duration timeUntilCollection() {
    return collectionDate.difference(DateTime.now());
  }

  /// Nombre de jours avant la collecte
  int daysUntilCollection() {
    final now = DateTime.now();
    final difference = collectionDate.difference(
      DateTime(now.year, now.month, now.day)
    );
    return difference.inDays;
  }

  /// Texte humanisé du compte à rebours
  String getCountdownText() {
    final days = daysUntilCollection();
    
    if (days < 0) return 'Collecte passée';
    if (days == 0) return 'Aujourd\'hui';
    if (days == 1) return 'Demain';
    if (days < 7) return 'Dans $days jours';
    if (days < 30) return 'Dans ${(days / 7).floor()} semaines';
    return 'Dans ${(days / 30).floor()} mois';
  }

  /// Formatte la date en français (ex: "Lundi 22 janvier")
  String getFormattedDate() {
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    
    final weekday = weekdays[collectionDate.weekday - 1];
    final day = collectionDate.day;
    final month = months[collectionDate.month - 1];
    
    return '$weekday $day $month';
  }

  //SÉRIALISATION FIRESTORE

  /// Conversion depuis une ligne Supabase (table collection_schedules)
  factory CollectionSchedule.fromMap(Map<String, dynamic> map) {
    return CollectionSchedule(
      id: map['id'] as String,
      district: map['district'] ?? '',
      wasteType: WasteType.values.asNameMap()[map['waste_type']] ??
          WasteType.general,
      // Colonne `date` : "2026-09-28" → minuit heure locale
      collectionDate: DateTime.parse(map['collection_date'] as String),
      collectionTime: map['collection_time'] ?? '',
      instructions: map['instructions'] ?? '',
      isRecurring: map['is_recurring'] ?? false,
      recurrencePattern: map['recurrence_pattern'],
    );
  }

  /// Conversion vers une ligne Supabase
  Map<String, dynamic> toMap() {
    return {
      'district': district,
      'waste_type': wasteType.name,
      'collection_date': collectionDate.toIso8601String().substring(0, 10),
      'collection_time': collectionTime,
      'instructions': instructions,
      'is_recurring': isRecurring,
      'recurrence_pattern': recurrencePattern,
    };
  }

  /// CopyWith pour créer une copie modifiée
  CollectionSchedule copyWith({
    String? id,
    String? district,
    WasteType? wasteType,
    DateTime? collectionDate,
    String? collectionTime,
    String? instructions,
    bool? isRecurring,
    String? recurrencePattern,
  }) {
    return CollectionSchedule(
      id: id ?? this.id,
      district: district ?? this.district,
      wasteType: wasteType ?? this.wasteType,
      collectionDate: collectionDate ?? this.collectionDate,
      collectionTime: collectionTime ?? this.collectionTime,
      instructions: instructions ?? this.instructions,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
    );
  }

//OVERRIDES
  @override
  String toString() {
    return 'CollectionSchedule(id: $id, district: $district, wasteType: $wasteType, date: $collectionDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CollectionSchedule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}