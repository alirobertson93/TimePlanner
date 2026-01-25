import '../enums/scheduling_preference_strength.dart';

/// Represents scheduling constraints for an event
/// 
/// These constraints define when an event can or should be scheduled.
/// Each constraint can be a hard rule (locked) or a preference (weak/strong).
class SchedulingConstraint {
  const SchedulingConstraint({
    this.notBeforeTime,
    this.notAfterTime,
    this.preferredStartTime,
    this.preferredEndTime,
    this.timeConstraintStrength = SchedulingPreferenceStrength.weak,
    this.preferredDays,
    this.dayConstraintStrength = SchedulingPreferenceStrength.weak,
    this.minimumDuration,
    this.maximumDuration,
  });

  /// Event cannot start before this time (e.g., 07:00)
  /// Format: hours * 60 + minutes (e.g., 7:00 AM = 420)
  final int? notBeforeTime;

  /// Event cannot start after this time (e.g., 15:00)
  /// Format: hours * 60 + minutes (e.g., 3:00 PM = 900)
  final int? notAfterTime;

  /// Preferred start time for the event
  /// Format: hours * 60 + minutes
  final int? preferredStartTime;

  /// Preferred end time for the event (must finish by)
  /// Format: hours * 60 + minutes
  final int? preferredEndTime;

  /// How strongly to enforce the time constraints
  final SchedulingPreferenceStrength timeConstraintStrength;

  /// Preferred days of the week (0 = Sunday, 6 = Saturday)
  /// If null, any day is acceptable
  final List<int>? preferredDays;

  /// How strongly to enforce the day constraints
  final SchedulingPreferenceStrength dayConstraintStrength;

  /// Minimum duration in minutes (scheduler cannot shorten below this)
  final int? minimumDuration;

  /// Maximum duration in minutes (scheduler cannot extend beyond this)
  final int? maximumDuration;

  /// Returns true if this constraint has any time restrictions
  bool get hasTimeConstraints =>
      notBeforeTime != null ||
      notAfterTime != null ||
      preferredStartTime != null ||
      preferredEndTime != null;

  /// Returns true if this constraint has day restrictions
  bool get hasDayConstraints => preferredDays != null && preferredDays!.isNotEmpty;

  /// Returns true if this constraint has duration restrictions
  bool get hasDurationConstraints => minimumDuration != null || maximumDuration != null;

  /// Returns true if this constraint has any restrictions
  bool get hasAnyConstraints =>
      hasTimeConstraints || hasDayConstraints || hasDurationConstraints;

  /// Helper to format time in minutes to a readable string (HH:MM)
  static String formatTimeOfDay(int minutesFromMidnight) {
    final hours = minutesFromMidnight ~/ 60;
    final minutes = minutesFromMidnight % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
    return '${displayHours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} $period';
  }

  /// Creates a constraint for "must be before X time"
  factory SchedulingConstraint.mustBeBefore(
    int timeInMinutes, {
    SchedulingPreferenceStrength strength = SchedulingPreferenceStrength.locked,
  }) {
    return SchedulingConstraint(
      notAfterTime: timeInMinutes,
      timeConstraintStrength: strength,
    );
  }

  /// Creates a constraint for "must be after X time"
  factory SchedulingConstraint.mustBeAfter(
    int timeInMinutes, {
    SchedulingPreferenceStrength strength = SchedulingPreferenceStrength.locked,
  }) {
    return SchedulingConstraint(
      notBeforeTime: timeInMinutes,
      timeConstraintStrength: strength,
    );
  }

  /// Creates a constraint for "must be between X and Y time"
  factory SchedulingConstraint.mustBeBetween(
    int notBeforeMinutes,
    int notAfterMinutes, {
    SchedulingPreferenceStrength strength = SchedulingPreferenceStrength.locked,
  }) {
    return SchedulingConstraint(
      notBeforeTime: notBeforeMinutes,
      notAfterTime: notAfterMinutes,
      timeConstraintStrength: strength,
    );
  }

  SchedulingConstraint copyWith({
    int? notBeforeTime,
    bool clearNotBeforeTime = false,
    int? notAfterTime,
    bool clearNotAfterTime = false,
    int? preferredStartTime,
    bool clearPreferredStartTime = false,
    int? preferredEndTime,
    bool clearPreferredEndTime = false,
    SchedulingPreferenceStrength? timeConstraintStrength,
    List<int>? preferredDays,
    bool clearPreferredDays = false,
    SchedulingPreferenceStrength? dayConstraintStrength,
    int? minimumDuration,
    bool clearMinimumDuration = false,
    int? maximumDuration,
    bool clearMaximumDuration = false,
  }) {
    return SchedulingConstraint(
      notBeforeTime: clearNotBeforeTime ? null : (notBeforeTime ?? this.notBeforeTime),
      notAfterTime: clearNotAfterTime ? null : (notAfterTime ?? this.notAfterTime),
      preferredStartTime: clearPreferredStartTime ? null : (preferredStartTime ?? this.preferredStartTime),
      preferredEndTime: clearPreferredEndTime ? null : (preferredEndTime ?? this.preferredEndTime),
      timeConstraintStrength: timeConstraintStrength ?? this.timeConstraintStrength,
      preferredDays: clearPreferredDays ? null : (preferredDays ?? this.preferredDays),
      dayConstraintStrength: dayConstraintStrength ?? this.dayConstraintStrength,
      minimumDuration: clearMinimumDuration ? null : (minimumDuration ?? this.minimumDuration),
      maximumDuration: clearMaximumDuration ? null : (maximumDuration ?? this.maximumDuration),
    );
  }

  /// Converts the constraint to a JSON-serializable map
  Map<String, dynamic> toJson() {
    return {
      if (notBeforeTime != null) 'notBeforeTime': notBeforeTime,
      if (notAfterTime != null) 'notAfterTime': notAfterTime,
      if (preferredStartTime != null) 'preferredStartTime': preferredStartTime,
      if (preferredEndTime != null) 'preferredEndTime': preferredEndTime,
      'timeConstraintStrength': timeConstraintStrength.value,
      if (preferredDays != null) 'preferredDays': preferredDays,
      'dayConstraintStrength': dayConstraintStrength.value,
      if (minimumDuration != null) 'minimumDuration': minimumDuration,
      if (maximumDuration != null) 'maximumDuration': maximumDuration,
    };
  }

  /// Creates a constraint from a JSON map
  factory SchedulingConstraint.fromJson(Map<String, dynamic> json) {
    return SchedulingConstraint(
      notBeforeTime: json['notBeforeTime'] as int?,
      notAfterTime: json['notAfterTime'] as int?,
      preferredStartTime: json['preferredStartTime'] as int?,
      preferredEndTime: json['preferredEndTime'] as int?,
      timeConstraintStrength: json['timeConstraintStrength'] != null
          ? SchedulingPreferenceStrength.fromValue(json['timeConstraintStrength'] as int)
          : SchedulingPreferenceStrength.weak,
      preferredDays: json['preferredDays'] != null
          ? List<int>.from(json['preferredDays'] as List)
          : null,
      dayConstraintStrength: json['dayConstraintStrength'] != null
          ? SchedulingPreferenceStrength.fromValue(json['dayConstraintStrength'] as int)
          : SchedulingPreferenceStrength.weak,
      minimumDuration: json['minimumDuration'] as int?,
      maximumDuration: json['maximumDuration'] as int?,
    );
  }

  /// Returns a human-readable description of the time constraints
  String get timeConstraintDescription {
    if (!hasTimeConstraints) return 'No time constraints';

    final parts = <String>[];
    if (notBeforeTime != null) {
      parts.add('After ${formatTimeOfDay(notBeforeTime!)}');
    }
    if (notAfterTime != null) {
      parts.add('Before ${formatTimeOfDay(notAfterTime!)}');
    }
    if (parts.isEmpty && preferredStartTime != null) {
      parts.add('Preferably at ${formatTimeOfDay(preferredStartTime!)}');
    }
    if (parts.isEmpty && preferredEndTime != null) {
      parts.add('Finish by ${formatTimeOfDay(preferredEndTime!)}');
    }

    final strengthLabel = timeConstraintStrength == SchedulingPreferenceStrength.locked
        ? ' (Required)'
        : timeConstraintStrength == SchedulingPreferenceStrength.strong
            ? ' (Preferred)'
            : '';

    return parts.join(' and ') + strengthLabel;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SchedulingConstraint &&
        other.notBeforeTime == notBeforeTime &&
        other.notAfterTime == notAfterTime &&
        other.preferredStartTime == preferredStartTime &&
        other.preferredEndTime == preferredEndTime &&
        other.timeConstraintStrength == timeConstraintStrength &&
        _listEquals(other.preferredDays, preferredDays) &&
        other.dayConstraintStrength == dayConstraintStrength &&
        other.minimumDuration == minimumDuration &&
        other.maximumDuration == maximumDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      notBeforeTime,
      notAfterTime,
      preferredStartTime,
      preferredEndTime,
      timeConstraintStrength,
      preferredDays != null ? Object.hashAll(preferredDays!) : null,
      dayConstraintStrength,
      minimumDuration,
      maximumDuration,
    );
  }

  @override
  String toString() {
    return 'SchedulingConstraint(notBeforeTime: $notBeforeTime, notAfterTime: $notAfterTime, strength: $timeConstraintStrength)';
  }

  /// Helper to compare lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
