import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/schedule_repository.dart';
import '../../data/services/notification_service.dart';

/// Maintient les rappels de collecte en phase avec le profil connecté :
/// replanifie quand le quartier ou les réglages de notifications changent,
/// annule tout à la déconnexion.
class ReminderScheduler {
  ReminderScheduler({
    NotificationService? notifications,
    ScheduleRepository? repository,
  }) : _notifications = notifications ?? NotificationService.instance,
       _repository = repository ?? ScheduleRepository();

  final NotificationService _notifications;
  final ScheduleRepository _repository;

  /// Nombre de collectes à venir couvertes (2 rappels max par collecte)
  static const int _upcomingCount = 30;

  String? _lastKey;
  bool _permissionAsked = false;

  /// Appelé à chaque changement de [AuthProvider] (via ProxyProvider)
  void onProfileChanged(UserProfile? profile) {
    if (!NotificationService.isSupported) return;

    // Seuls le quartier et les réglages influencent les rappels
    final key = profile == null
        ? null
        : '${profile.id}|${profile.district}|'
              '${jsonEncode(profile.notificationSettings.toMap())}';
    if (key == _lastKey) return;
    _lastKey = key;

    // Hors du build en cours (appelé depuis un ProxyProvider)
    Future.microtask(() => _reschedule(profile));
  }

  Future<void> _reschedule(UserProfile? profile) async {
    try {
      if (profile == null) {
        await _notifications.cancelAll();
        return;
      }

      final settings = profile.notificationSettings;
      if (settings.isCompletelyDisabled) {
        await _notifications.cancelAll();
        return;
      }

      if (!_permissionAsked) {
        _permissionAsked = true;
        await _notifications.requestPermission();
      }

      final upcoming = await _repository.getUpcomingSchedules(
        district: profile.district,
        limit: _upcomingCount,
      );
      final count = await _notifications.scheduleReminders(upcoming, settings);
      debugPrint('Rappels planifiés : $count (${profile.district})');
    } catch (e) {
      debugPrint('Erreur de planification des rappels : $e');
    }
  }
}
