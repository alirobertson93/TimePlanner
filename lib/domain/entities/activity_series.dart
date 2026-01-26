import 'activity.dart';

/// Represents a group of related activities that share common properties.
/// 
/// A series groups activities together using a `seriesId` field, independent
/// of recurrence. This allows users to edit multiple related activities at once.
class ActivitySeries {
  const ActivitySeries({
    required this.id,
    required this.activities,
    required this.displayTitle,
    required this.count,
  });

  /// The unique identifier for this series (usually the first activity's seriesId or id)
  final String id;

  /// The activities in this series
  final List<Activity> activities;

  /// The display title for the series (derived from the first activity)
  final String displayTitle;

  /// The number of activities in this series
  final int count;

  /// Creates a copy of this series with the given fields replaced
  ActivitySeries copyWith({
    String? id,
    List<Activity>? activities,
    String? displayTitle,
    int? count,
  }) {
    return ActivitySeries(
      id: id ?? this.id,
      activities: activities ?? this.activities,
      displayTitle: displayTitle ?? this.displayTitle,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ActivitySeries) return false;
    
    return other.id == id &&
        other.displayTitle == displayTitle &&
        other.count == count;
  }

  @override
  int get hashCode => Object.hash(id, displayTitle, count);

  @override
  String toString() {
    return 'ActivitySeries(id: $id, displayTitle: $displayTitle, count: $count)';
  }
}
