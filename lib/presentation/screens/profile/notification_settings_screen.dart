import 'package:ecowaste_cotonou/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../data/models/waste_type.dart';

/// Écran des paramètres de notifications
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isLoading = false;

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final profile = authProvider.userProfile;

    if (profile != null) {
      await authProvider.updateProfile(profile);

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final profile = authProvider.userProfile;
          if (profile == null) {
            return const Center(
              child: Text(
                'Profil non disponible',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final settings = profile.notificationSettings;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Activation globale
                _buildSection(
                  title: 'Notifications',
                  children: [
                    SwitchListTile(
                      value: settings.enabled,
                      onChanged: (value) {
                        final newSettings = settings.copyWith(enabled: value);
                        final newProfile = profile.updateNotificationSettings(newSettings);
                        authProvider.updateProfile(newProfile);
                      },
                      title: const Text(
                        'Activer les notifications',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        settings.enabled
                            ? 'Les notifications sont activées'
                            : 'Activez pour recevoir des rappels',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      activeThumbColor: AppColors.accent,
                    ),
                  ],
                ),

                if (settings.enabled) ...[
                  const SizedBox(height: 16),

                  // Horaires
                  _buildSection(
                    title: 'Horaires des rappels',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.access_time, color: AppColors.accent),
                        title: const Text(
                          'Rappel la veille',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          settings.formatTimeForDisplay(settings.reminderDayBeforeTime),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Switch(
                          value: settings.dayBeforeEnabled,
                          onChanged: (value) {
                            final newSettings = settings.copyWith(dayBeforeEnabled: value);
                            final newProfile = profile.updateNotificationSettings(newSettings);
                            authProvider.updateProfile(newProfile);
                          },
                          activeThumbColor: AppColors.accent,
                        ),
                        onTap: () => _selectTime(
                          context,
                          settings.reminderDayBeforeTime,
                          (time) {
                            final newSettings = settings.copyWith(reminderDayBeforeTime: time);
                            final newProfile = profile.updateNotificationSettings(newSettings);
                            authProvider.updateProfile(newProfile);
                          },
                        ),
                      ),
                      const Divider(color: AppColors.outline, height: 1),
                      ListTile(
                        leading: const Icon(Icons.access_time, color: AppColors.accent),
                        title: const Text(
                          'Rappel le jour de collecte',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          settings.formatTimeForDisplay(settings.reminderDayOfTime),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        trailing: Switch(
                          value: settings.dayOfEnabled,
                          onChanged: (value) {
                            final newSettings = settings.copyWith(dayOfEnabled: value);
                            final newProfile = profile.updateNotificationSettings(newSettings);
                            authProvider.updateProfile(newProfile);
                          },
                          activeThumbColor: AppColors.accent,
                        ),
                        onTap: () => _selectTime(
                          context,
                          settings.reminderDayOfTime,
                          (time) {
                            final newSettings = settings.copyWith(reminderDayOfTime: time);
                            final newProfile = profile.updateNotificationSettings(newSettings);
                            authProvider.updateProfile(newProfile);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Types de déchets
                  _buildSection(
                    title: 'Notifications par type',
                    subtitle: 'Choisissez les types de déchets pour lesquels recevoir des rappels',
                    children: WasteType.values.map((type) {
                      return SwitchListTile(
                        value: settings.isEnabledForType(type),
                        onChanged: (value) {
                          final newSettings = settings.toggleWasteType(type);
                          final newProfile = profile.updateNotificationSettings(newSettings);
                          authProvider.updateProfile(newProfile);
                        },
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(int.parse(type.color.replaceAll('#', '0xFF'))),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              type.displayName,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        activeThumbColor: AppColors.accent,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Préférences
                  _buildSection(
                    title: 'Préférences',
                    children: [
                      SwitchListTile(
                        value: settings.soundEnabled,
                        onChanged: (value) {
                          final newSettings = settings.copyWith(soundEnabled: value);
                          final newProfile = profile.updateNotificationSettings(newSettings);
                          authProvider.updateProfile(newProfile);
                        },
                        title: const Text(
                          'Son',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Émettre un son lors des notifications',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        secondary: const Icon(Icons.volume_up, color: AppColors.accent),
                        activeThumbColor: AppColors.accent,
                      ),
                      const Divider(color: AppColors.outline, height: 1),
                      SwitchListTile(
                        value: settings.vibrationEnabled,
                        onChanged: (value) {
                          final newSettings = settings.copyWith(vibrationEnabled: value);
                          final newProfile = profile.updateNotificationSettings(newSettings);
                          authProvider.updateProfile(newProfile);
                        },
                        title: const Text(
                          'Vibration',
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: const Text(
                          'Faire vibrer le téléphone',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        secondary: const Icon(Icons.vibration, color: AppColors.accent),
                        activeThumbColor: AppColors.accent,
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 32),

                // Bouton sauvegarder
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    String currentTime,
    Function(String) onTimeSelected,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onTimeSelected(formattedTime);
    }
  }
}