import 'package:ecowaste_cotonou/data/models/event_detail_sheet.dart';
import 'package:ecowaste_cotonou/data/models/calendar_event.dart';
import 'package:ecowaste_cotonou/presentation/providers/calendar_provider.dart';
import 'package:ecowaste_cotonou/presentation/widgets/calendar_widgets/calendar_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      context.read<CalendarProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier de Collecte'),
        actions: [
          // Bouton rafraîchir
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CalendarProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          // Gestion de l'état de chargement
          if (provider.isLoading && provider.events.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Gestion des erreurs
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Calendrier
              CustomCalendarWidget(
                focusedDay: provider.focusedDay,
                selectedDay: provider.selectedDay,
                events: provider.events,
                onDaySelected: (selectedDay, focusedDay) {
                  provider.selectDay(selectedDay);
                  
                  // Afficher les événements du jour
                  final dayEvents = provider.getEventsForDay(selectedDay);
                  if (dayEvents.isNotEmpty) {
                    _showDayEventsSheet(context, selectedDay, dayEvents);
                  }
                },
                onPageChanged: (focusedDay) {
                  provider.setFocusedDay(focusedDay);
                },
              ),

              const Divider(height: 1),

              // Liste des événements du jour sélectionné
              Expanded(
                child: _buildEventsList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construction de la liste des événements
  Widget _buildEventsList(CalendarProvider provider) {
    final events = provider.getEventsForDay(provider.selectedDay);

    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Aucune collecte prévue ce jour',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _parseColor(event.getColor()),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            title: Text(event.title),
            subtitle: event.description != null 
                ? Text(event.description!) 
                : null,
            trailing: Text(
              '${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  /// Afficher le bottom sheet avec les événements du jour
  void _showDayEventsSheet(BuildContext context, DateTime day, List <CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      builder: (context) => EventDetailSheet(
        day: day,
        events: events,
      ),
    );
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}