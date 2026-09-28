/// Statistiques d'engagement de l'utilisateur
class UserStatistics {
  final int consecutiveDays;          // Jours consécutifs d'utilisation
  final double totalWasteRecycled;    // Total déchets recyclés (kg estimés)
  final double co2Avoided;            // CO₂ évité (kg estimés)
  final int calendarViews;            // Consultations du calendrier
  final int guideSearches;            // Recherches dans le guide
  final int mapViews;                 // Consultations de la carte
  final int points;                   // Points de gamification (Phase 2)
  final List<String> badges;          // Badges obtenus (Phase 2)
  final DateTime lastActive;          // Dernière activité

  UserStatistics({
    this.consecutiveDays = 0,
    this.totalWasteRecycled = 0.0,
    this.co2Avoided = 0.0,
    this.calendarViews = 0,
    this.guideSearches = 0,
    this.mapViews = 0,
    this.points = 0,
    this.badges = const [],
    required this.lastActive,
  });

  //factory initiale

  /// Crée des statistiques initiales pour un nouvel utilisateur
  factory UserStatistics.initial() {
    return UserStatistics(
      consecutiveDays: 1,
      totalWasteRecycled: 0.0,
      co2Avoided: 0.0,
      calendarViews: 0,
      guideSearches: 0,
      mapViews: 0,
      points: 0,
      badges: [],
      lastActive: DateTime.now(),
    );
  }

  //MÉTHODES UTILES

  /// Calcul automatique du CO₂ évité basé sur les déchets recyclés
  /// Formule simplifiée : 1 kg recyclé ≈ 0.27 kg CO₂ évité
  static double calculateCO2Avoided(double wasteKg) {
    return wasteKg * 0.27;
  }

  /// Met à jour les jours consécutifs en fonction de la dernière activité
  UserStatistics updateConsecutiveDays() {
    final now = DateTime.now();
    final lastActiveDate = DateTime(
      lastActive.year,
      lastActive.month,
      lastActive.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    
    final daysDiff = today.difference(lastActiveDate).inDays;
    
    int newConsecutive;
    if (daysDiff == 0) {
      // Même jour, on garde le compteur (au moins 1 : le jour en cours compte)
      newConsecutive = consecutiveDays < 1 ? 1 : consecutiveDays;
    } else if (daysDiff == 1) {
      // Jour suivant, on incrémente
      newConsecutive = consecutiveDays + 1;
    } else {
      // Plus d'un jour, on reset à 1
      newConsecutive = 1;
    }
    
    return copyWith(
      consecutiveDays: newConsecutive,
      lastActive: now,
    );
  }

  /// Incrémente le nombre de consultations du calendrier
  UserStatistics incrementCalendarViews() {
    return copyWith(
      calendarViews: calendarViews + 1,
      lastActive: DateTime.now(),
    ).updateConsecutiveDays();
  }

  /// Incrémente le nombre de recherches dans le guide
  UserStatistics incrementGuideSearches() {
    return copyWith(
      guideSearches: guideSearches + 1,
      lastActive: DateTime.now(),
    ).updateConsecutiveDays();
  }

  /// Incrémente le nombre de consultations de la carte
  UserStatistics incrementMapViews() {
    return copyWith(
      mapViews: mapViews + 1,
      lastActive: DateTime.now(),
    ).updateConsecutiveDays();
  }

  /// Ajoute des déchets recyclés et calcule automatiquement le CO₂ évité
  UserStatistics addRecycledWaste(double kgAmount) {
    final newTotal = totalWasteRecycled + kgAmount;
    final newCO2 = calculateCO2Avoided(newTotal);
    
    return copyWith(
      totalWasteRecycled: newTotal,
      co2Avoided: newCO2,
      lastActive: DateTime.now(),
    ).updateConsecutiveDays();
  }

  /// Ajoute des points (gamification - Phase 2)
  UserStatistics addPoints(int pointsToAdd) {
    return copyWith(
      points: points + pointsToAdd,
      lastActive: DateTime.now(),
    ).updateConsecutiveDays();
  }

  /// Ajoute un badge (gamification - Phase 2)
  UserStatistics addBadge(String badgeId) {
    if (badges.contains(badgeId)) return this;
    
    final newBadges = List<String>.from(badges)..add(badgeId);
    return copyWith(
      badges: newBadges,
      lastActive: DateTime.now(),
    );
  }

  /// Obtient le niveau de l'utilisateur basé sur les points
  String getUserLevel() {
    if (points < 100) return 'Débutant';
    if (points < 500) return 'Éco-Warrior Bronze';
    if (points < 1000) return 'Éco-Warrior Argent';
    if (points < 2500) return 'Éco-Warrior Or';
    return 'Éco-Champion';
  }

  /// Obtient le pourcentage de progression vers le niveau suivant
  double getProgressToNextLevel() {
    if (points < 100) return points / 100;
    if (points < 500) return (points - 100) / 400;
    if (points < 1000) return (points - 500) / 500;
    if (points < 2500) return (points - 1000) / 1500;
    return 1.0; // Niveau max atteint
  }

  /// Obtient le nombre de points nécessaires pour le niveau suivant
  int getPointsToNextLevel() {
    if (points < 100) return 100 - points;
    if (points < 500) return 500 - points;
    if (points < 1000) return 1000 - points;
    if (points < 2500) return 2500 - points;
    return 0; // Niveau max atteint
  }

  /// Vérifie si l'utilisateur est actif (a utilisé l'app dans les 7 derniers jours)
  bool isActive() {
    final daysSinceLastActive = DateTime.now().difference(lastActive).inDays;
    return daysSinceLastActive <= 7;
  }

  /// Obtient un texte motivant basé sur les statistiques
  String getMotivationalText() {
    if (consecutiveDays >= 30) {
      return 'Incroyable ! $consecutiveDays jours consécutifs ! 🔥';
    } else if (consecutiveDays >= 7) {
      return 'Super ! Une semaine complète ! 🎉';
    } else if (consecutiveDays >= 3) {
      return 'Bien joué ! Continuez comme ça ! 💪';
    } else if (totalWasteRecycled > 10) {
      return 'Vous avez déjà recyclé ${totalWasteRecycled.toStringAsFixed(1)} kg ! 🌱';
    } else {
      return 'Continuez à trier pour sauver la planète ! 🌍';
    }
  }

  //SÉRIALISATION FIRESTORE 

  /// Conversion depuis Map (base de données → Dart)
  factory UserStatistics.fromMap(Map<String, dynamic> map) {
    return UserStatistics(
      consecutiveDays: map['consecutiveDays'] ?? 0,
      totalWasteRecycled: (map['totalWasteRecycled'] ?? 0.0).toDouble(),
      co2Avoided: (map['co2Avoided'] ?? 0.0).toDouble(),
      calendarViews: map['calendarViews'] ?? 0,
      guideSearches: map['guideSearches'] ?? 0,
      mapViews: map['mapViews'] ?? 0,
      points: map['points'] ?? 0,
      badges: List<String>.from(map['badges'] ?? []),
      lastActive:
          DateTime.tryParse(map['lastActive'] ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }

  /// Conversion vers Map (Dart → base de données)
  Map<String, dynamic> toMap() {
    return {
      'consecutiveDays': consecutiveDays,
      'totalWasteRecycled': totalWasteRecycled,
      'co2Avoided': co2Avoided,
      'calendarViews': calendarViews,
      'guideSearches': guideSearches,
      'mapViews': mapViews,
      'points': points,
      'badges': badges,
      'lastActive': lastActive.toUtc().toIso8601String(),
    };
  }

  /// CopyWith pour créer une copie modifiée
  UserStatistics copyWith({
    int? consecutiveDays,
    double? totalWasteRecycled,
    double? co2Avoided,
    int? calendarViews,
    int? guideSearches,
    int? mapViews,
    int? points,
    List<String>? badges,
    DateTime? lastActive,
  }) {
    return UserStatistics(
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      totalWasteRecycled: totalWasteRecycled ?? this.totalWasteRecycled,
      co2Avoided: co2Avoided ?? this.co2Avoided,
      calendarViews: calendarViews ?? this.calendarViews,
      guideSearches: guideSearches ?? this.guideSearches,
      mapViews: mapViews ?? this.mapViews,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  String toString() {
    return 'UserStatistics(consecutive: $consecutiveDays days, waste: ${totalWasteRecycled}kg, points: $points)';
  }
}