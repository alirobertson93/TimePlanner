import '../enums/activity_status.dart';
import '../enums/timing_type.dart';
import 'scheduling_constraint.dart';

/// Pure domain entity representing an activity in the time planner
/// 
/// An Activity is any item the user wants to track or schedule. It can be:
/// - **Scheduled** - Has a specific date/time, appears on the calendar
/// - **Unscheduled** - No date/time, exists in an "activity bank" for planning
class Activity {
  const Activity({
    required this.id,
    required this.name,
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
    this.status = ActivityStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final TimingType timingType;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String? categoryId;
  final String? locationId;
  /// Reference to the recurrence rule for repeating activities
  final String? recurrenceRuleId;
  /// Groups related activities together (independent of recurrence)
  final String? seriesId;
  /// Scheduling constraints (time restrictions, day preferences, etc.)
  final SchedulingConstraint? schedulingConstraint;
  final bool appCanMove;
  final bool appCanResize;
  final bool isUserLocked;
  final ActivityStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns true if this is a fixed-time activity
  bool get isFixed => timingType == TimingType.fixed;

  /// Returns true if this activity is scheduled (has a start time)
  bool get isScheduled => startTime != null;

  /// Returns true if this activity is unscheduled (no start time - in activity bank)
  bool get isUnscheduled => startTime == null;

  /// Returns true if the app can move this activity during scheduling
  bool get isMovableByApp => appCanMove && !isUserLocked;

  /// Returns true if the app can resize this activity during scheduling
  bool get isResizableByApp => appCanResize && !isUserLocked;

  /// Returns true if this activity is part of a recurring series
  bool get isRecurring => recurrenceRuleId != null;

  /// Returns true if this activity is part of an activity series
  bool get isInSeries => seriesId != null;

  /// Returns true if this activity has scheduling constraints
  bool get hasSchedulingConstraints =>
      schedulingConstraint != null && schedulingConstraint!.hasAnyConstraints;

  /// Calculates the effective duration of the activity
  Duration get effectiveDuration {
    if (duration != null) {
      return duration!;
    }
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    throw StateError('Activity must have either duration or start/end times');
  }

  /// Creates a copy of this activity with the given fields replaced
  Activity copyWith({
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
    ActivityStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
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

    return other is Activity &&
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
    return 'Activity(id: $id, name: $name, timingType: $timingType, status: $status, isRecurring: $isRecurring, isInSeries: $isInSeries, hasConstraints: $hasSchedulingConstraints)';
  }
}
