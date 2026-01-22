/// Types of notifications in the TimePlanner app
enum NotificationType {
  /// Reminder before an event starts
  eventReminder,

  /// Alert when schedule changes occur
  scheduleChange,

  /// Notification about goal progress
  goalProgress,

  /// Warning about scheduling conflicts
  conflictWarning,

  /// Alert when a goal is at risk of not being met
  goalAtRisk,

  /// Notification when a goal is completed
  goalCompleted,
}
