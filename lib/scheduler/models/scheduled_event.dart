import 'package:time_planner/domain/entities/event.dart';

/// An event that has been scheduled with specific start/end times
class ScheduledEvent {
  const ScheduledEvent({
    required this.event,
    required this.scheduledStart,
    required this.scheduledEnd,
  });

  /// The original event
  final Event event;

  /// When this event is scheduled to start
  final DateTime scheduledStart;

  /// When this event is scheduled to end
  final DateTime scheduledEnd;

  /// Get the duration of the scheduled event
  Duration get duration => scheduledEnd.difference(scheduledStart);

  @override
  String toString() {
    return 'ScheduledEvent(${event.name ?? 'Untitled'}, $scheduledStart - $scheduledEnd)';
  }
}
