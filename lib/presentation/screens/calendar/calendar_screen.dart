import 'package:ecowaste_cotonou/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/collection_schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../widgets/calendar_widgets/calendar_widget.dart';
import '../../widgets/waste_visuals.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Consumer<ScheduleProvider>(
          builder: (context, provider, _) =>
              Text('Collectes · ${provider.currentDistrict}'),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ScheduleProvider>().refresh(),
          ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, child) {
          if (provider.errorMessage != null) {
            return _buildError(provider);
          }

          return Column(
            children: [
              CustomCalendarWidget(
                focusedDay: provider.selectedDay,
                selectedDay: provider.selectedDay,
                eventLoader: provider.getSchedulesForDate,
                onDaySelected: (selectedDay, focusedDay) {
                  provider.selectDay(selectedDay);
                },
                onPageChanged: (focusedDay) {
                  provider.selectDay(focusedDay);
                  provider.setMonth(focusedDay);
                },
              ),

              if (provider.isLoading) const LinearProgressIndicator(minHeight: 2),

              const Divider(height: 1),

              // Collectes du jour sélectionné
              Expanded(child: _buildEventsList(provider)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildError(ScheduleProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: provider.refresh,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Liste des collectes du jour sélectionné
  Widget _buildEventsList(ScheduleProvider provider) {
    final schedules = provider.getSchedulesForDate(provider.selectedDay);

    if (schedules.isEmpty) {
      return const Center(
        child: Text(
          'Aucune collecte prévue ce jour',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      itemCount: schedules.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => _buildScheduleCard(schedules[index]),
    );
  }

  Widget _buildScheduleCard(CollectionSchedule schedule) {
    final color = schedule.wasteType.uiColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color,
            child: Icon(schedule.wasteType.icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.wasteType.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedule.collectionTime,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                if (schedule.instructions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    schedule.instructions,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
