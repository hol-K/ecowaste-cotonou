import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/collection_schedule.dart';
import '../models/notification_settings.dart';

/// Rappels locaux de collecte (la veille et le jour même).
///
/// Les notifications sont planifiées sur le téléphone : aucun serveur n'est
/// nécessaire, elles fonctionnent hors connexion une fois planifiées.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// iOS limite à 64 notifications en attente par application
  static const int _maxPending = 60;

  /// Les rappels ne concernent que les téléphones
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (!isSupported || _initialized) return;

    tz_data.initializeTimeZones();
    // Heure du Bénin (UTC+1, sans heure d'été), quel que soit le réglage du téléphone
    tz.setLocalLocation(tz.getLocation('Africa/Porto-Novo'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // La permission est demandée plus tard, quand les rappels sont activés
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  /// Demande l'autorisation d'afficher des notifications (Android 13+, iOS)
  Future<bool> requestPermission() async {
    if (!_initialized) return false;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  /// Supprime tous les rappels planifiés
  Future<void> cancelAll() async {
    if (_initialized) await _plugin.cancelAll();
  }

  /// Remplace les rappels planifiés par ceux des [schedules] à venir.
  /// Renvoie le nombre de notifications planifiées.
  Future<int> scheduleReminders(
    List<CollectionSchedule> schedules,
    NotificationSettings settings,
  ) async {
    if (!_initialized) return 0;
    await _plugin.cancelAll();
    if (settings.isCompletelyDisabled) return 0;

    final reminders = buildReminders(
      schedules,
      settings,
      now: tz.TZDateTime.now(tz.local),
    ).take(_maxPending);

    final details = _details(settings);
    var id = 0;
    for (final reminder in reminders) {
      await _plugin.zonedSchedule(
        id++,
        reminder.title,
        reminder.body,
        reminder.at,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    return id;
  }

  /// Calcule les rappels à planifier (fonction pure, testable sans plugin)
  @visibleForTesting
  static List<CollectionReminder> buildReminders(
    List<CollectionSchedule> schedules,
    NotificationSettings settings, {
    required tz.TZDateTime now,
  }) {
    if (settings.isCompletelyDisabled) return const [];

    final dayBefore = settings.dayBeforeTimeComponents;
    final dayOf = settings.dayOfTimeComponents;
    final reminders = <CollectionReminder>[];

    for (final schedule in schedules) {
      if (!settings.isEnabledForType(schedule.wasteType)) continue;
      final date = schedule.collectionDate;
      final type = schedule.wasteType.displayName;
      final details = [
        schedule.district,
        if (schedule.collectionTime.isNotEmpty) schedule.collectionTime,
      ].join(' · ');

      if (settings.dayBeforeEnabled) {
        reminders.add(
          CollectionReminder(
            at: tz.TZDateTime(
              now.location,
              date.year,
              date.month,
              date.day - 1,
              dayBefore[0],
              dayBefore[1],
            ),
            title: 'Collecte demain : $type',
            body: schedule.instructions.isNotEmpty
                ? '$details — ${schedule.instructions}'
                : details,
          ),
        );
      }
      if (settings.dayOfEnabled) {
        reminders.add(
          CollectionReminder(
            at: tz.TZDateTime(
              now.location,
              date.year,
              date.month,
              date.day,
              dayOf[0],
              dayOf[1],
            ),
            title: 'Collecte aujourd\'hui : $type',
            body: details,
          ),
        );
      }
    }

    return reminders.where((r) => r.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
  }

  /// Son et vibration sont figés à la création d'un canal Android :
  /// un canal par combinaison permet de respecter les préférences.
  NotificationDetails _details(NotificationSettings settings) {
    final sound = settings.soundEnabled;
    final vibration = settings.vibrationEnabled;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'collectes_${sound ? 1 : 0}${vibration ? 1 : 0}',
        'Rappels de collecte',
        channelDescription: 'Rappels la veille et le jour des collectes',
        importance: Importance.high,
        priority: Priority.high,
        playSound: sound,
        enableVibration: vibration,
      ),
      iOS: DarwinNotificationDetails(presentSound: sound),
    );
  }
}

/// Un rappel calculé, prêt à être planifié
class CollectionReminder {
  const CollectionReminder({
    required this.at,
    required this.title,
    required this.body,
  });

  final tz.TZDateTime at;
  final String title;
  final String body;
}
