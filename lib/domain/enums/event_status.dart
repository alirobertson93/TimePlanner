/// Represents the current status of an event
enum EventStatus {
  /// Event is planned but not yet started
  pending(0),
  
  /// Event is currently in progress
  inProgress(1),
  
  /// Event has been completed
  completed(2),
  
  /// Event was cancelled
  cancelled(3);

  const EventStatus(this.value);
  
  final int value;
  
  static EventStatus fromValue(int value) {
    return EventStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EventStatus.pending,
    );
  }
}
