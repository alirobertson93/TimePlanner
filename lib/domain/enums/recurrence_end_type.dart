/// Defines when a recurring event stops repeating
enum RecurrenceEndType {
  /// Event repeats indefinitely
  never,

  /// Event stops after a specific number of occurrences
  afterOccurrences,

  /// Event stops on a specific date
  onDate,
}
