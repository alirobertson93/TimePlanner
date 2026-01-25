import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/entities/category.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../providers/category_providers.dart';

/// Timeline widget showing a 7-day grid with events
class WeekTimeline extends ConsumerWidget {
  const WeekTimeline({
    super.key,
    required this.weekStart,
    required this.events,
    required this.onEventTap,
  });

  final DateTime weekStart;
  final List<Event> events;
  final void Function(Event) onEventTap;

  // Display hours from 8 AM to 8 PM (working hours)
  static const int startHour = 8;
  static const int endHour = 20;
  static const double hourHeight = 50.0;
  static const double timeMarkerWidth = 40.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final totalHours = endHour - startHour;

    return SingleChildScrollView(
      child: SizedBox(
        height: totalHours * hourHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time markers column
            SizedBox(
              width: timeMarkerWidth,
              child: Column(
                children: List.generate(
                  totalHours,
                  (index) => _TimeMarker(
                    hour: startHour + index,
                    height: hourHeight,
                  ),
                ),
              ),
            ),
            // Days columns
            Expanded(
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final date = weekStart.add(Duration(days: dayIndex));
                  final dayEvents = _getEventsForDay(date);

                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.dividerColor,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Hour grid lines
                          ...List.generate(totalHours, (hourIndex) {
                            return Positioned(
                              top: hourIndex * hourHeight,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 1,
                                color: theme.dividerColor.withOpacity(0.5),
                              ),
                            );
                          }),
                          // Events for this day
                          ...dayEvents.where((e) => e.isFixed).map((event) {
                            return _WeekEventBlock(
                              event: event,
                              startHour: startHour,
                              hourHeight: hourHeight,
                              onTap: () => onEventTap(event),
                            );
                          }),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Event> _getEventsForDay(DateTime date) {
    return events.where((event) {
      if (event.startTime == null) return false;
      return DateTimeUtils.isSameDay(event.startTime!, date);
    }).toList();
  }
}

/// Time marker showing the hour
class _TimeMarker extends StatelessWidget {
  const _TimeMarker({
    required this.hour,
    required this.height,
  });

  final int hour;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hourString = hour == 0
        ? '12 AM'
        : hour < 12
            ? '$hour AM'
            : hour == 12
                ? '12 PM'
                : '${hour - 12} PM';

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(right: 4, top: 0),
        child: Align(
          alignment: Alignment.topRight,
          child: Text(
            hourString,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

/// Event block displayed in the week view
class _WeekEventBlock extends ConsumerWidget {
  const _WeekEventBlock({
    required this.event,
    required this.startHour,
    required this.hourHeight,
    required this.onTap,
  });

  final Event event;
  final int startHour;
  final double hourHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryAsync = event.categoryId != null
        ? ref.watch(categoryByIdProvider(event.categoryId!))
        : const AsyncValue<Category?>.data(null);

    final top = _getTopPosition();
    final height = _getEventHeight();

    // Don't render events outside the visible time range
    if (top < 0 && top + height <= 0) return const SizedBox.shrink();
    if (top >= (WeekTimeline.endHour - startHour) * hourHeight) {
      return const SizedBox.shrink();
    }

    return categoryAsync.when(
      data: (category) => _buildBlock(context, category, top, height),
      loading: () => _buildBlock(context, null, top, height),
      error: (_, __) => _buildBlock(context, null, top, height),
    );
  }

  Widget _buildBlock(BuildContext context, Category? category, double top, double height) {
    final adjustedTop = top.clamp(0.0, double.infinity);
    final adjustedHeight = height.clamp(8.0, double.infinity);

    return Positioned(
      top: adjustedTop,
      left: 1,
      right: 1,
      height: adjustedHeight,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _getColor(category),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (event.hasSchedulingConstraints)
                const Icon(
                  Icons.schedule,
                  size: 10,
                  color: Colors.white70,
                ),
              if (event.isUserLocked)
                const Icon(
                  Icons.lock,
                  size: 10,
                  color: Colors.white70,
                ),
              if (event.isRecurring)
                const Icon(
                  Icons.repeat,
                  size: 10,
                  color: Colors.white70,
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _getTopPosition() {
    if (event.startTime == null) return 0;
    final eventHour = event.startTime!.hour;
    final eventMinute = event.startTime!.minute;
    return (eventHour - startHour) * hourHeight +
        (eventMinute / 60.0) * hourHeight;
  }

  double _getEventHeight() {
    if (event.startTime != null && event.endTime != null) {
      final duration = event.endTime!.difference(event.startTime!);
      return (duration.inMinutes / 60.0) * hourHeight;
    }
    return hourHeight; // Default to 1 hour if duration not available
  }

  Color _getColor(Category? category) {
    if (category != null && category.colourHex.isNotEmpty) {
      try {
        final hexColor = category.colourHex.replaceAll('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        return Colors.blue;
      }
    }
    return Colors.blue;
  }
}
