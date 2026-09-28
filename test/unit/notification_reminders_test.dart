import 'package:ecowaste_cotonou/data/models/collection_schedule.dart';
import 'package:ecowaste_cotonou/data/models/notification_settings.dart';
import 'package:ecowaste_cotonou/data/models/waste_type.dart';
import 'package:ecowaste_cotonou/data/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late tz.Location benin;

  setUpAll(() {
    tz_data.initializeTimeZones();
    benin = tz.getLocation('Africa/Porto-Novo');
  });

  CollectionSchedule schedule(DateTime date, WasteType type) =>
      CollectionSchedule(
        id: '${date.day}-${type.name}',
        district: 'Akpakpa',
        wasteType: type,
        collectionDate: date,
        collectionTime: '06:00 - 10:00',
        instructions: 'Fermez bien les sacs.',
      );

  test('rappel la veille et le jour même, triés, aux heures choisies', () {
    final now = tz.TZDateTime(benin, 2026, 9, 28, 12); // lundi midi
    final reminders = NotificationService.buildReminders(
      [schedule(DateTime(2026, 10, 1), WasteType.general)],
      NotificationSettings(), // veille 18:00, jour J 06:00
      now: now,
    );

    expect(reminders.map((r) => r.at), [
      tz.TZDateTime(benin, 2026, 9, 30, 18),
      tz.TZDateTime(benin, 2026, 10, 1, 6),
    ]);
    expect(reminders.first.title, 'Collecte demain : Ordures ménagères');
    expect(reminders.first.body, contains('Akpakpa · 06:00 - 10:00'));
  });

  test('la veille d\'un 1er du mois tombe le dernier jour du mois précédent', () {
    final reminders = NotificationService.buildReminders(
      [schedule(DateTime(2026, 11, 1), WasteType.glass)],
      NotificationSettings(dayOfEnabled: false),
      now: tz.TZDateTime(benin, 2026, 10, 1),
    );
    expect(reminders.single.at, tz.TZDateTime(benin, 2026, 10, 31, 18));
  });

  test('ignore les rappels passés et les types désactivés', () {
    final settings = NotificationSettings().toggleWasteType(
      WasteType.recyclable,
    );
    final reminders = NotificationService.buildReminders(
      [
        schedule(DateTime(2026, 9, 28), WasteType.general), // aujourd'hui
        schedule(DateTime(2026, 9, 29), WasteType.recyclable), // désactivé
      ],
      settings,
      now: tz.TZDateTime(benin, 2026, 9, 28, 12),
    );
    // Veille (27 à 18h) et jour J (28 à 6h) déjà passés ; recyclables coupés
    expect(reminders, isEmpty);
  });

  test('aucun rappel si les notifications sont désactivées', () {
    final reminders = NotificationService.buildReminders(
      [schedule(DateTime(2026, 10, 1), WasteType.general)],
      NotificationSettings.disabled(),
      now: tz.TZDateTime(benin, 2026, 9, 28),
    );
    expect(reminders, isEmpty);
  });
}
