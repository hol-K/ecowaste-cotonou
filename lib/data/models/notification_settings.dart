import 'waste_type.dart';

/// Paramètres de notifications de l'utilisateur
class NotificationSettings {
  final bool enabled;                     // Notifications activées globalement
  final String reminderDayBeforeTime;     // Heure rappel la veille (HH:mm)
  final String reminderDayOfTime;         // Heure rappel le jour J (HH:mm)
  final bool dayBeforeEnabled;            // Rappel veille activé
  final bool dayOfEnabled;                // Rappel jour J activé
  final Map<WasteType, bool> typeEnabled; // Activation par type de déchet
  final bool soundEnabled;                // Son activé
  final bool vibrationEnabled;            // Vibration activée

  NotificationSettings({
    this.enabled = true,
    this.reminderDayBeforeTime = '18:00',
    this.reminderDayOfTime = '06:00',
    this.dayBeforeEnabled = true,
    this.dayOfEnabled = true,
    Map<WasteType, bool>? typeEnabled,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
  }) : typeEnabled = typeEnabled ?? {
          WasteType.general: true,
          WasteType.recyclable: true,
          WasteType.glass: true,
          WasteType.organic: true,
          WasteType.dangerous: true,
          WasteType.electronic: true,
        };

  //factory initiale

  /// Paramètres par défaut pour un nouvel utilisateur
  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      enabled: true,
      reminderDayBeforeTime: '18:00',
      reminderDayOfTime: '06:00',
      dayBeforeEnabled: true,
      dayOfEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }

  /// Paramètres avec notifications désactivées
  factory NotificationSettings.disabled() {
    return NotificationSettings(
      enabled: false,
      dayBeforeEnabled: false,
      dayOfEnabled: false,
      soundEnabled: false,
      vibrationEnabled: false,
    );
  }

  //MÉTHODES UTILES

  /// Vérifie si les notifications sont activées pour un type spécifique
  bool isEnabledForType(WasteType type) {
    if (!enabled) return false;
    return typeEnabled[type] ?? false;
  }

  /// Vérifie si les notifications sont complètement désactivées
  bool get isCompletelyDisabled {
    return !enabled || (!dayBeforeEnabled && !dayOfEnabled);
  }

  /// Vérifie si au moins un type de déchet a les notifications activées
  bool get hasAtLeastOneTypeEnabled {
    if (!enabled) return false;
    return typeEnabled.values.any((isEnabled) => isEnabled);
  }

  /// Obtient le nombre de types de déchets avec notifications activées
  int get enabledTypesCount {
    if (!enabled) return 0;
    return typeEnabled.values.where((isEnabled) => isEnabled).length;
  }

  /// Obtient la liste des types de déchets avec notifications activées
  List<WasteType> get enabledWasteTypes {
    if (!enabled) return [];
    return typeEnabled.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Parse l'heure au format TimeOfDay (pour Flutter)
  /// Retourne [hour, minute]
  List<int> parseTime(String time) {
    final parts = time.split(':');
    return [
      int.parse(parts[0]),
      int.parse(parts[1]),
    ];
  }

  /// Obtient l'heure du rappel la veille
  List<int> get dayBeforeTimeComponents => parseTime(reminderDayBeforeTime);

  /// Obtient l'heure du rappel le jour J
  List<int> get dayOfTimeComponents => parseTime(reminderDayOfTime);

  /// Formate l'heure pour l'affichage (ex: "18:00" → "18h00")
  String formatTimeForDisplay(String time) {
    final parts = parseTime(time);
    return '${parts[0]}h${parts[1].toString().padLeft(2, '0')}';
  }

  /// Active/désactive un type de déchet spécifique
  NotificationSettings toggleWasteType(WasteType type) {
    final newTypeEnabled = Map<WasteType, bool>.from(typeEnabled);
    newTypeEnabled[type] = !(typeEnabled[type] ?? false);
    return copyWith(typeEnabled: newTypeEnabled);
  }

  /// Active tous les types de déchets
  NotificationSettings enableAllWasteTypes() {
    final newTypeEnabled = Map<WasteType, bool>.from(typeEnabled);
    for (var type in WasteType.values) {
      newTypeEnabled[type] = true;
    }
    return copyWith(typeEnabled: newTypeEnabled);
  }

  /// Désactive tous les types de déchets
  NotificationSettings disableAllWasteTypes() {
    final newTypeEnabled = Map<WasteType, bool>.from(typeEnabled);
    for (var type in WasteType.values) {
      newTypeEnabled[type] = false;
    }
    return copyWith(typeEnabled: newTypeEnabled);
  }

  /// Obtient un résumé textuel des paramètres
  String getSummary() {
    if (!enabled) return 'Notifications désactivées';
    
    final enabledCount = enabledTypesCount;
    String summary = 'Notifications activées pour ';
    
    if (enabledCount == 0) {
      summary += 'aucun type de déchet';
    } else if (enabledCount == WasteType.values.length) {
      summary += 'tous les types de déchets';
    } else {
      summary += '$enabledCount type${enabledCount > 1 ? 's' : ''} de déchet${enabledCount > 1 ? 's' : ''}';
    }
    
    return summary;
  }

  //SÉRIALISATION FIRESTORE

  /// Conversion depuis Map (base de données → Dart)
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] ?? true,
      reminderDayBeforeTime: map['reminderDayBeforeTime'] ?? '18:00',
      reminderDayOfTime: map['reminderDayOfTime'] ?? '06:00',
      dayBeforeEnabled: map['dayBeforeEnabled'] ?? true,
      dayOfEnabled: map['dayOfEnabled'] ?? true,
      typeEnabled: map['typeEnabled'] != null
          ? (map['typeEnabled'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(
                WasteType.values.firstWhere(
                  (e) => e.toString() == 'WasteType.$key',
                  orElse: () => WasteType.general,
                ),
                value as bool,
              ),
            )
          : null,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
    );
  }

  /// Conversion vers Map (Dart → base de données)
  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'reminderDayBeforeTime': reminderDayBeforeTime,
      'reminderDayOfTime': reminderDayOfTime,
      'dayBeforeEnabled': dayBeforeEnabled,
      'dayOfEnabled': dayOfEnabled,
      'typeEnabled': typeEnabled.map(
        (key, value) => MapEntry(key.toString().split('.').last, value),
      ),
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  /// CopyWith pour créer une copie modifiée
  NotificationSettings copyWith({
    bool? enabled,
    String? reminderDayBeforeTime,
    String? reminderDayOfTime,
    bool? dayBeforeEnabled,
    bool? dayOfEnabled,
    Map<WasteType, bool>? typeEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      reminderDayBeforeTime: reminderDayBeforeTime ?? this.reminderDayBeforeTime,
      reminderDayOfTime: reminderDayOfTime ?? this.reminderDayOfTime,
      dayBeforeEnabled: dayBeforeEnabled ?? this.dayBeforeEnabled,
      dayOfEnabled: dayOfEnabled ?? this.dayOfEnabled,
      typeEnabled: typeEnabled ?? this.typeEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  @override
  String toString() {
    return 'NotificationSettings(enabled: $enabled, types: $enabledTypesCount/${WasteType.values.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings &&
        other.enabled == enabled &&
        other.reminderDayBeforeTime == reminderDayBeforeTime &&
        other.reminderDayOfTime == reminderDayOfTime;
  }

  @override
  int get hashCode {
    return enabled.hashCode ^
        reminderDayBeforeTime.hashCode ^
        reminderDayOfTime.hashCode;
  }
}