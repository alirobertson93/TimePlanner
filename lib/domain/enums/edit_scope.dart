/// Defines the scope of an edit operation on an activity that is part of a series.
/// 
/// When a user edits an activity that belongs to a series, they can choose
/// to apply the changes to just the current activity, all activities in the
/// series, or (for recurring activities) this activity and all future ones.
enum EditScope {
  /// Edit only this specific activity instance
  thisOnly,

  /// Edit all activities in the series
  allInSeries,

  /// Edit this activity and all future activities (only for recurring activities)
  thisAndFuture;

  /// Returns a human-readable label for this scope
  String get label {
    switch (this) {
      case EditScope.thisOnly:
        return 'This activity only';
      case EditScope.allInSeries:
        return 'All activities in this series';
      case EditScope.thisAndFuture:
        return 'This and all future activities';
    }
  }

  /// Returns a human-readable description for this scope
  String get description {
    switch (this) {
      case EditScope.thisOnly:
        return 'Changes will only apply to this activity';
      case EditScope.allInSeries:
        return 'Changes will apply to all activities in the series';
      case EditScope.thisAndFuture:
        return 'Changes will apply to this and all future occurrences';
    }
  }
}
