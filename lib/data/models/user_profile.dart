import 'user_statistics.dart';
import 'notification_settings.dart';

/// Représente le profil complet d'un utilisateur
class UserProfile {
  final String id;                    // ID utilisateur (Supabase Auth)
  final String? name;                 // Nom complet (optionnel)
  final String? email;                // Email
  final String? phone;                // Téléphone (optionnel)
  final String? photoUrl;             // URL photo de profil (optionnel)
  final String district;              // Quartier de résidence
  final DateTime createdAt;           // Date de création du compte
  final DateTime updatedAt;           // Date de dernière mise à jour
  final UserStatistics statistics;    // Statistiques utilisateur
  final NotificationSettings notificationSettings; // Paramètres notifications

  UserProfile({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    required this.district,
    required this.createdAt,
    required this.updatedAt,
    required this.statistics,
    required this.notificationSettings,
  });

  //factory initiale

  /// Crée un profil initial pour un nouvel utilisateur
  factory UserProfile.initial({
    required String id,
    String? email,
    String? name,
    String district = 'Akpakpa',
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      name: name,
      email: email,
      phone: null,
      photoUrl: null,
      district: district,
      createdAt: now,
      updatedAt: now,
      statistics: UserStatistics.initial(),
      notificationSettings: NotificationSettings.defaultSettings(),
    );
  }

  // MÉTHODES UTILES

  /// Obtient les initiales pour l'avatar (si pas de photo)
  String getInitials() {
    if (name == null || name!.isEmpty) return '?';
    
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      // Prend la première lettre du prénom et du nom
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts[0].isNotEmpty) {
      // Prend juste la première lettre du nom
      return parts[0][0].toUpperCase();
    } else {
      return '?';
    }
  }

  /// Obtient le prénom (premier mot du nom)
  String? getFirstName() {
    if (name == null || name!.isEmpty) return null;
    return name!.trim().split(' ').first;
  }

  /// Vérifie si le profil est complet (toutes les infos renseignées)
  bool get isComplete {
    return name != null &&
           name!.isNotEmpty &&
           email != null &&
           email!.isNotEmpty &&
           district.isNotEmpty;
  }

  /// Vérifie si l'utilisateur a une photo de profil
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Vérifie si l'utilisateur est un nouveau membre (< 7 jours)
  bool get isNewUser {
    final daysSinceCreation = DateTime.now().difference(createdAt).inDays;
    return daysSinceCreation < 7;
  }

  /// Obtient le nombre de jours depuis l'inscription
  int get daysSinceRegistration {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Obtient un message de bienvenue personnalisé
  String getWelcomeMessage() {
    final firstName = getFirstName();
    final greeting = firstName != null ? 'Bonjour, $firstName' : 'Bonjour';
    
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return '$greeting ☀️';
    } else if (hour < 18) {
      return '$greeting 🌤️';
    } else {
      return '$greeting 🌙';
    }
  }

  /// Vérifie si le profil nécessite une mise à jour (> 30 jours)
  bool get needsUpdate {
    final daysSinceUpdate = DateTime.now().difference(updatedAt).inDays;
    return daysSinceUpdate > 30;
  }

  /// Liste des quartiers disponibles à Cotonou
  static List<String> get availableDistricts => [
        'Akpakpa',
        'Cadjèhoun',
        'Fidjrossè',
        'Godomey',
        'Agla',
        'Vossa',
        'Gbégamey',
        'Houéyiho',
        'Jonquet',
        'Enagnon',
        'Saint-Michel',
        'Zongo',
      ];

  /// Valide le format de l'email
  bool get hasValidEmail {
    if (email == null) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email!);
  }

  /// Valide le format du téléphone (Bénin)
  bool get hasValidPhone {
    if (phone == null) return false;
    // Format Bénin : +229 XX XX XX XX ou 01 XX XX XX XX
    final phoneRegex = RegExp(r'^(\+229|00229|0)?[0-9]{8,10}$');
    return phoneRegex.hasMatch(phone!.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Formatte le numéro de téléphone pour l'affichage
  String? get formattedPhone {
    if (phone == null) return null;
    final cleaned = phone!.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length >= 8) {
      // Format: XX XX XX XX
      return '${cleaned.substring(0, 2)} ${cleaned.substring(2, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6)}';
    }
    return phone;
  }

  //SÉRIALISATION SUPABASE (table profiles)

  /// Conversion depuis une ligne Supabase
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    final createdAt =
        DateTime.tryParse(map['created_at'] ?? '')?.toLocal() ?? DateTime.now();
    return UserProfile(
      id: map['id'] as String,
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      photoUrl: map['photo_url'],
      district: map['district'] ?? 'Akpakpa',
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(map['updated_at'] ?? '')?.toLocal() ?? createdAt,
      statistics: UserStatistics.fromMap(
        Map<String, dynamic>.from(map['statistics'] ?? const {}),
      ),
      notificationSettings: NotificationSettings.fromMap(
        Map<String, dynamic>.from(map['notification_settings'] ?? const {}),
      ),
    );
  }

  /// Champs modifiables par l'utilisateur. `id`, `email` et les dates sont
  /// gérés par la base (trigger d'inscription et `updated_at` automatique).
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'photo_url': photoUrl,
      'district': district,
      'statistics': statistics.toMap(),
      'notification_settings': notificationSettings.toMap(),
    };
  }

  /// CopyWith pour créer une copie modifiée
  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
    String? district,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStatistics? statistics,
    NotificationSettings? notificationSettings,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      district: district ?? this.district,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Auto-update timestamp
      statistics: statistics ?? this.statistics,
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  /// CopyWith pour mettre à jour seulement les infos de base
  UserProfile updateBasicInfo({
    String? name,
    String? phone,
    String? photoUrl,
    String? district,
  }) {
    return copyWith(
      name: name,
      phone: phone,
      photoUrl: photoUrl,
      district: district,
      updatedAt: DateTime.now(),
    );
  }

  /// CopyWith pour mettre à jour seulement les statistiques
  UserProfile updateStatistics(UserStatistics newStatistics) {
    return copyWith(
      statistics: newStatistics,
      updatedAt: DateTime.now(),
    );
  }

  /// CopyWith pour mettre à jour seulement les paramètres de notification
  UserProfile updateNotificationSettings(NotificationSettings newSettings) {
    return copyWith(
      notificationSettings: newSettings,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, name: $name, district: $district, complete: $isComplete)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}