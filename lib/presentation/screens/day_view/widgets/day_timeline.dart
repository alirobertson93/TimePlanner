import 'package:flutter/material.dart';
import '../../../../domain/entities/event.dart';
import 'time_marker.dart';
import 'event_card.dart';
import 'current_time_indicator.dart';

/// Widget displaying a scrollable 24-hour timeline with events
class DayTimeline extends StatelessWidget {
  const DayTimeline({
    super.key,
    required this.date,
    required this.events,
    required this.onEventTap,
  });

  final DateTime date;
  final List<Event> events;
  final void Function(Event) onEventTap;

  static const double hourHeight = 60.0;
  static const double timeMarkerWidth = 60.0;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);

    return Stack(
      children: [
        // Timeline with hour markers and events
        SingleChildScrollView(
          child: SizedBox(
            height: 24 * hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hour markers column
                SizedBox(
                  width: timeMarkerWidth,
                  child: Column(
                    children: List.generate(
                      24,
                      (hour) => TimeMarker(
                        hour: hour,
                        height: hourHeight,
                      ),
                    ),
                  ),
                ),
                // Events column
                Expanded(
                  child: Stack(
                    children: [
                      // Hour divider lines
                      ...List.generate(24, (hour) {
                        return Positioned(
                          top: hour * hourHeight,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                        );
                      }),
                      // Events
                      ...events.where((e) => e.isFixed).map((event) {
                        return Positioned(
                          top: _getTopPosition(event.startTime!),
                          left: 8,
                          right: 8,
                          height: _getEventHeight(event),
                          child: EventCard(
                            event: event,
                            onTap: () => onEventTap(event),
                          ),
                        );
                      }),
                      // Current time indicator (only for today)
                      if (isToday)
                        const CurrentTimeIndicator(
                          hourHeight: hourHeight,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double _getTopPosition(DateTime startTime) {
    final hour = startTime.hour;
    final minute = startTime.minute;
    return hour * hourHeight + (minute / 60.0) * hourHeight;
  }

  double _getEventHeight(Event event) {
    if (event.startTime != null && event.endTime != null) {
      final duration = event.endTime!.difference(event.startTime!);
      return (duration.inMinutes / 60.0) * hourHeight;
    }
    return hourHeight; // Default to 1 hour if duration not available
  }
}
