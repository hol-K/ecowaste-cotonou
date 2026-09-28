import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../data/models/collection_schedule.dart';
import '../waste_visuals.dart';

class CustomCalendarWidget extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final List<CollectionSchedule> Function(DateTime day) eventLoader;
  final void Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final void Function(DateTime focusedDay) onPageChanged;

  const CustomCalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.eventLoader,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar<CollectionSchedule>(
      locale: 'fr_FR',
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: focusedDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      eventLoader: eventLoader,

      // Callbacks
      onDaySelected: onDaySelected,
      onPageChanged: onPageChanged,

      // Styles
      calendarStyle: CalendarStyle(
        defaultTextStyle: const TextStyle(color: Colors.white),
        weekendTextStyle: const TextStyle(color: Color(0xFFB8C5C0)),
        outsideTextStyle: const TextStyle(color: Color(0xFF5A6B64)),
        todayDecoration: BoxDecoration(
          color: const Color(0xFF4A9B7F).withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: const BoxDecoration(
          color: Color(0xFF4A9B7F),
          shape: BoxShape.circle,
        ),
        markersMaxCount: 3,
      ),

      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(color: Color(0xFFB8C5C0)),
        weekendStyle: TextStyle(color: Color(0xFFB8C5C0)),
      ),

      // En-tête
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
      ),

      // Marqueurs colorés selon le type de déchet
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox();

          return Positioned(
            bottom: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: events.take(3).map((schedule) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: schedule.wasteType.uiColor,
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
