// lib/data/models/recycling_tip.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de contenu pour un conseil de recyclage
enum TipType {
  article,   // Article textuel
  video,     // Vidéo
  quiz,      // Quiz interactif
  infographic // Infographie
}

/// Catégorie de conseil
enum TipCategory {
  reduction,   // Réduction des déchets
  reuse,       // Réutilisation
  recycling,   // Recyclage
  composting,  // Compostage
  upcycling,   // Upcycling créatif
  general      // Général
}

/// Extension pour obtenir les informations visuelles
extension TipTypeExtension on TipType {
  /// Nom lisible en français
  String get displayName {
    switch (this) {
      case TipType.article:
        return 'Article';
      case TipType.video:
        return 'Vidéo';
      case TipType.quiz:
        return 'Quiz';
      case TipType.infographic:
        return 'Infographie';
    }
  }

  /// Icône associée
  String get iconName {
    switch (this) {
      case TipType.article:
        return 'article';
      case TipType.video:
        return 'play-circle';
      case TipType.quiz:
        return 'help-circle';
      case TipType.infographic:
        return 'image';
    }
  }
}

extension TipCategoryExtension on TipCategory {
  /// Nom lisible en français
  String get displayName {
    switch (this) {
      case TipCategory.reduction:
        return 'Réduction';
      case TipCategory.reuse:
        return 'Réutilisation';
      case TipCategory.recycling:
        return 'Recyclage';
      case TipCategory.composting:
        return 'Compostage';
      case TipCategory.upcycling:
        return 'Upcycling';
      case TipCategory.general:
        return 'Général';
    }
  }

  /// Couleur associée
  String get color {
    switch (this) {
      case TipCategory.reduction:
        return '#EF5350';
      case TipCategory.reuse:
        return '#42A5F5';
      case TipCategory.recycling:
        return '#66BB6A';
      case TipCategory.composting:
        return '#8BC34A';
      case TipCategory.upcycling:
        return '#AB47BC';
      case TipCategory.general:
        return '#4A9B7F';
    }
  }
}

/// Représente un conseil ou une astuce de recyclage
class RecyclingTip {
  final String id;
  final String title;                // Titre du conseil
  final String description;          // Description courte (pour la liste)
  final String content;              // Contenu complet (HTML ou Markdown)
  final TipType type;                // Type de contenu
  final TipCategory category;        // Catégorie
  final String? imageUrl;            // Image de couverture
  final String? videoUrl;            // URL vidéo (si type = video)
  final int readingTimeMinutes;      // Durée de lecture estimée
  final List<String> tags;           // Tags pour la recherche
  final DateTime publishedAt;        // Date de publication
  final int viewCount;               // Nombre de vues
  final int likeCount;               // Nombre de likes
  final String author;               // Auteur du conseil
  final bool isFeatured;             // Mis en avant sur la page d'accueil

  RecyclingTip({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.type,
    required this.category,
    this.imageUrl,
    this.videoUrl,
    required this.readingTimeMinutes,
    required this.tags,
    required this.publishedAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.author = 'EcoWaste Cotonou',
    this.isFeatured = false,
  });

  // ========== MÉTHODES UTILES ==========

  /// Vérifie si le conseil est récent (moins de 7 jours)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(publishedAt).inDays;
    return difference <= 7;
  }

  /// Vérifie si c'est une vidéo
  bool get isVideo => type == TipType.video && videoUrl != null;

  /// Vérifie si c'est un quiz
  bool get isQuiz => type == TipType.quiz;

  /// Obtient un extrait du contenu (150 caractères)
  String getExcerpt() {
    if (description.length <= 150) return description;
    return '${description.substring(0, 147)}...';
  }

  /// Obtient le texte de durée de lecture
  String get readingTimeText {
    if (type == TipType.video) {
      return '$readingTimeMinutes min';
    } else {
      return '$readingTimeMinutes min de lecture';
    }
  }

  /// Vérifie si le conseil correspond à une recherche
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;

    final lowerQuery = query.toLowerCase().trim();

    // Recherche dans le titre
    if (title.toLowerCase().contains(lowerQuery)) return true;

    // Recherche dans la description
    if (description.toLowerCase().contains(lowerQuery)) return true;

    // Recherche dans les tags
    for (var tag in tags) {
      if (tag.toLowerCase().contains(lowerQuery)) return true;
    }

    // Recherche dans la catégorie
    if (category.displayName.toLowerCase().contains(lowerQuery)) return true;

    return false;
  }

  /// Vérifie si le conseil appartient à une catégorie
  bool belongsToCategory(TipCategory cat) {
    return category == cat;
  }

  /// Formate la date de publication
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else {
      final months = [
        'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
        'juil', 'août', 'sep', 'oct', 'nov', 'déc'
      ];
      return '${publishedAt.day} ${months[publishedAt.month - 1]} ${publishedAt.year}';
    }
  }

  /// Incrémente le nombre de vues
  RecyclingTip incrementViewCount() {
    return copyWith(viewCount: viewCount + 1);
  }

  /// Incrémente le nombre de likes
  RecyclingTip incrementLikeCount() {
    return copyWith(likeCount: likeCount + 1);
  }

  // ========== SÉRIALISATION FIRESTORE ==========

  /// Conversion depuis Map (Firestore → Dart)
  factory RecyclingTip.fromMap(Map<String, dynamic> map, String id) {
    return RecyclingTip(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      content: map['content'] ?? '',
      type: TipType.values.firstWhere(
        (e) => e.toString() == 'TipType.${map['type']}',
        orElse: () => TipType.article,
      ),
      category: TipCategory.values.firstWhere(
        (e) => e.toString() == 'TipCategory.${map['category']}',
        orElse: () => TipCategory.general,
      ),
      imageUrl: map['imageUrl'],
      videoUrl: map['videoUrl'],
      readingTimeMinutes: map['readingTimeMinutes'] ?? 5,
      tags: List<String>.from(map['tags'] ?? []),
      publishedAt: (map['publishedAt'] as Timestamp).toDate(),
      viewCount: map['viewCount'] ?? 0,
      likeCount: map['likeCount'] ?? 0,
      author: map['author'] ?? 'EcoWaste Cotonou',
      isFeatured: map['isFeatured'] ?? false,
    );
  }

  /// Conversion vers Map (Dart → Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'content': content,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'readingTimeMinutes': readingTimeMinutes,
      'tags': tags,
      'publishedAt': Timestamp.fromDate(publishedAt),
      'viewCount': viewCount,
      'likeCount': likeCount,
      'author': author,
      'isFeatured': isFeatured,
    };
  }

  /// CopyWith pour créer une copie modifiée
  RecyclingTip copyWith({
    String? id,
    String? title,
    String? description,
    String? content,
    TipType? type,
    TipCategory? category,
    String? imageUrl,
    String? videoUrl,
    int? readingTimeMinutes,
    List<String>? tags,
    DateTime? publishedAt,
    int? viewCount,
    int? likeCount,
    String? author,
    bool? isFeatured,
  }) {
    return RecyclingTip(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      content: content ?? this.content,
      type: type ?? this.type,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      tags: tags ?? this.tags,
      publishedAt: publishedAt ?? this.publishedAt,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      author: author ?? this.author,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  String toString() {
    return 'RecyclingTip(id: $id, title: $title, type: ${type.displayName}, category: ${category.displayName})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecyclingTip && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modèle pour un quiz (sous-type de RecyclingTip)
class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  /// Vérifie si une réponse est correcte
  bool isCorrectAnswer(int selectedIndex) {
    return selectedIndex == correctAnswerIndex;
  }

  /// Obtient la bonne réponse
  String get correctAnswer => options[correctAnswerIndex];

  // Sérialisation
  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      question: map['question'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }
}

/// Modèle pour un quiz complet
class RecyclingQuiz {
  final String tipId;
  final List<QuizQuestion> questions;
  final int passingScore; // Score minimum pour réussir (en %)

  RecyclingQuiz({
    required this.tipId,
    required this.questions,
    this.passingScore = 60,
  });

  /// Calcule le score (pourcentage)
  int calculateScore(List<int> userAnswers) {
    if (questions.isEmpty) return 0;

    int correctCount = 0;
    for (int i = 0; i < questions.length && i < userAnswers.length; i++) {
      if (questions[i].isCorrectAnswer(userAnswers[i])) {
        correctCount++;
      }
    }

    return ((correctCount / questions.length) * 100).round();
  }

  /// Vérifie si l'utilisateur a réussi
  bool hasPassed(List<int> userAnswers) {
    return calculateScore(userAnswers) >= passingScore;
  }

  /// Obtient un message selon le score
  String getScoreMessage(int score) {
    if (score >= 90) return 'Excellent ! Vous êtes un pro du tri ! 🌟';
    if (score >= 70) return 'Très bien ! Vous maîtrisez le recyclage ! 👏';
    if (score >= 60) return 'Bien ! Continuez vos efforts ! 💪';
    return 'Pas mal, mais vous pouvez progresser ! 📚';
  }

  // Sérialisation
  factory RecyclingQuiz.fromMap(Map<String, dynamic> map, String tipId) {
    return RecyclingQuiz(
      tipId: tipId,
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList() ?? [],
      passingScore: map['passingScore'] ?? 60,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questions': questions.map((q) => q.toMap()).toList(),
      'passingScore': passingScore,
    };
  }
}