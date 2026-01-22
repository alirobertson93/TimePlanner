/// Status of a notification
enum NotificationStatus {
  /// Notification is pending delivery
  pending,

  /// Notification has been delivered to the user
  delivered,

  /// Notification has been read by the user
  read,

  /// Notification was dismissed by the user
  dismissed,

  /// Notification was cancelled (e.g., event deleted before reminder)
  cancelled,
}
