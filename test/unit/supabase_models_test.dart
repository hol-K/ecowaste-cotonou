import 'package:ecowaste_cotonou/data/models/collection_point.dart';
import 'package:ecowaste_cotonou/data/models/collection_schedule.dart';
import 'package:ecowaste_cotonou/data/models/user_profile.dart';
import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Conversions depuis des lignes au format exact renvoyé par Supabase.
void main() {
  group('CollectionSchedule', () {
    test('lit une colonne date comme minuit heure locale', () {
      final schedule = CollectionSchedule.fromMap({
        'id': 'a',
        'district': 'Akpakpa',
        'waste_type': 'recyclable',
        'collection_date': '2026-09-29',
        'collection_time': '06:00 - 10:00',
        'instructions': 'Triez',
        'is_recurring': true,
        'recurrence_pattern': 'weekly',
      });

      expect(schedule.wasteType, WasteType.recyclable);
      expect(schedule.collectionDate, DateTime(2026, 9, 29));
      expect(schedule.toMap()['collection_date'], '2026-09-29');
    });
  });

  group('CollectionPoint', () {
    final row = {
      'id': 'p',
      'name': 'Déchetterie',
      'latitude': 6.3667,
      'longitude': 2,
      'address': 'Akpakpa',
      'accepted_waste_types': ['glass', 'inconnu', 'electronic'],
      'opening_hours': 'Lun-Sam',
      'phone': null,
      'image_url': null,
      'description': null,
      'is_public': true,
      'rating': '4.5',
    };

    test('ignore les types inconnus et convertit les nombres', () {
      final point = CollectionPoint.fromMap(row);
      expect(point.acceptedWasteTypes, [WasteType.glass, WasteType.electronic]);
      expect(point.longitude, 2.0);
      expect(point.rating, 4.5);
    });
  });

  group('UserProfile', () {
    test('un profil tout neuf (jsonb vides) se lit sans erreur', () {
      final profile = UserProfile.fromMap({
        'id': 'u',
        'name': 'Awa Dossou',
        'email': 'awa@example.com',
        'phone': null,
        'photo_url': null,
        'district': 'Fidjrossè',
        'statistics': <String, dynamic>{},
        'notification_settings': <String, dynamic>{},
        'created_at': '2026-09-28T10:00:00.000Z',
        'updated_at': '2026-09-28T10:00:00.000Z',
      });

      expect(profile.district, 'Fidjrossè');
      expect(profile.getInitials(), 'AD');
      expect(profile.notificationSettings.enabled, isTrue);
      // Premier jour : le compteur démarre à 1, pas à 0
      expect(profile.statistics.updateConsecutiveDays().consecutiveDays, 1);
    });

    test('toMap n\'envoie que les champs modifiables', () {
      final profile = UserProfile.initial(id: 'u', name: 'Awa');
      final map = profile.toMap();
      expect(map.containsKey('id'), isFalse);
      expect(map.containsKey('email'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['statistics'], isA<Map<String, dynamic>>());
    });
  });
}
