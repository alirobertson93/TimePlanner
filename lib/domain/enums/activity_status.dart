/// Represents the current status of an activity
enum ActivityStatus {
  /// Activity is planned but not yet started
  pending(0),
  
  /// Activity is currently in progress
  inProgress(1),
  
  /// Activity has been completed
  completed(2),
  
  /// Activity was cancelled
  cancelled(3);

  const ActivityStatus(this.value);
  
  final int value;
  
  static ActivityStatus fromValue(int value) {
    return ActivityStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ActivityStatus.pending,
    );
  }
}
