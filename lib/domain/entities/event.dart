import '../enums/event_status.dart';
import '../enums/activity_status.dart';
import '../enums/timing_type.dart';
import 'scheduling_constraint.dart';
import 'activity.dart';

/// Pure domain entity representing an event in the time planner
/// 
/// @deprecated Use Activity instead. This class will be removed in a future version.
/// Event is now an alias for backward compatibility.
class Event {
  const Event({
    required this.id,
    this.name,
    this.description,
    required this.timingType,
    this.startTime,
    this.endTime,
    this.duration,
    this.categoryId,
    this.locationId,
    this.recurrenceRuleId,
    this.seriesId,
    this.schedulingConstraint,
    this.appCanMove = true,
    this.appCanResize = true,
    this.isUserLocked = false,
    this.status = EventStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  /// The name/title of the event. Can be null if the event has
  /// associated people, locations, or categories.
  final String? name;
  final String? description;
  final TimingType timingType;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String? categoryId;
  final String? locationId;
  /// Reference to the recurrence rule for repeating events
  final String? recurrenceRuleId;
  /// Groups related activities together (independent of recurrence)
  final String? seriesId;
  /// Scheduling constraints (time restrictions, day preferences, etc.)
  final SchedulingConstraint? schedulingConstraint;
  final bool appCanMove;
  final bool appCanResize;
  final bool isUserLocked;
  final EventStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns true if the event has a non-empty name
  bool get hasName => name != null && name!.isNotEmpty;

  /// Returns true if this is a fixed-time event
  bool get isFixed => timingType == TimingType.fixed;

  /// Returns true if the app can move this event during scheduling
  bool get isMovableByApp => appCanMove && !isUserLocked;

  /// Returns true if the app can resize this event during scheduling
  bool get isResizableByApp => appCanResize && !isUserLocked;

  /// Returns true if this event is part of a recurring series
  bool get isRecurring => recurrenceRuleId != null;

  /// Returns true if this event is part of an activity series
  bool get isInSeries => seriesId != null;

  /// Returns true if this event has scheduling constraints
  bool get hasSchedulingConstraints =>
      schedulingConstraint != null && schedulingConstraint!.hasAnyConstraints;

  /// Calculates the effective duration of the event
  Duration get effectiveDuration {
    if (duration != null) {
      return duration!;
    }
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    throw StateError('Event must have either duration or start/end times');
  }

  /// Convert this Event to an Activity
  Activity toActivity() {
    return Activity(
      id: id,
      name: name,
      description: description,
      timingType: timingType,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      categoryId: categoryId,
      locationId: locationId,
      recurrenceRuleId: recurrenceRuleId,
      seriesId: seriesId,
      schedulingConstraint: schedulingConstraint,
      appCanMove: appCanMove,
      appCanResize: appCanResize,
      isUserLocked: isUserLocked,
      status: ActivityStatus.fromValue(status.value),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create an Event from an Activity
  factory Event.fromActivity(Activity activity) {
    return Event(
      id: activity.id,
      name: activity.name,
      description: activity.description,
      timingType: activity.timingType,
      startTime: activity.startTime,
      endTime: activity.endTime,
      duration: activity.duration,
      categoryId: activity.categoryId,
      locationId: activity.locationId,
      recurrenceRuleId: activity.recurrenceRuleId,
      seriesId: activity.seriesId,
      schedulingConstraint: activity.schedulingConstraint,
      appCanMove: activity.appCanMove,
      appCanResize: activity.appCanResize,
      isUserLocked: activity.isUserLocked,
      status: EventStatus.fromValue(activity.status.value),
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
    );
  }

  /// Creates a copy of this event with the given fields replaced
  Event copyWith({
    String? id,
    String? name,
    String? description,
    TimingType? timingType,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? categoryId,
    String? locationId,
    String? recurrenceRuleId,
    String? seriesId,
    SchedulingConstraint? schedulingConstraint,
    bool clearSchedulingConstraint = false,
    bool? appCanMove,
    bool? appCanResize,
    bool? isUserLocked,
    EventStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      timingType: timingType ?? this.timingType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      categoryId: categoryId ?? this.categoryId,
      locationId: locationId ?? this.locationId,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
      seriesId: seriesId ?? this.seriesId,
      schedulingConstraint: clearSchedulingConstraint
          ? null
          : (schedulingConstraint ?? this.schedulingConstraint),
      appCanMove: appCanMove ?? this.appCanMove,
      appCanResize: appCanResize ?? this.appCanResize,
      isUserLocked: isUserLocked ?? this.isUserLocked,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Event &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.timingType == timingType &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.duration == duration &&
        other.categoryId == categoryId &&
        other.locationId == locationId &&
        other.recurrenceRuleId == recurrenceRuleId &&
        other.seriesId == seriesId &&
        other.schedulingConstraint == schedulingConstraint &&
        other.appCanMove == appCanMove &&
        other.appCanResize == appCanResize &&
        other.isUserLocked == isUserLocked &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      timingType,
      startTime,
      endTime,
      duration,
      categoryId,
      locationId,
      recurrenceRuleId,
      seriesId,
      schedulingConstraint,
      appCanMove,
      appCanResize,
      isUserLocked,
      status,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, name: $name, timingType: $timingType, status: $status, isRecurring: $isRecurring, hasConstraints: $hasSchedulingConstraints)';
  }
}
