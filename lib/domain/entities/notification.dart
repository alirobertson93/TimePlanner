import '../enums/notification_type.dart';
import '../enums/notification_status.dart';

/// Pure domain entity representing a notification in the time planner
class Notification {
  const Notification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.eventId,
    this.goalId,
    required this.scheduledAt,
    this.deliveredAt,
    this.readAt,
    this.status = NotificationStatus.pending,
    required this.createdAt,
  });

  /// Unique identifier for the notification
  final String id;

  /// Type of notification (reminder, alert, etc.)
  final NotificationType type;

  /// Title of the notification
  final String title;

  /// Optional body/description of the notification
  final String? body;

  /// Optional reference to the related event
  final String? eventId;

  /// Optional reference to the related goal
  final String? goalId;

  /// When the notification should be delivered
  final DateTime scheduledAt;

  /// When the notification was actually delivered
  final DateTime? deliveredAt;

  /// When the notification was read
  final DateTime? readAt;

  /// Current status of the notification
  final NotificationStatus status;

  /// When this notification was created
  final DateTime createdAt;

  /// Returns true if the notification has been delivered
  bool get isDelivered => status == NotificationStatus.delivered || 
                           status == NotificationStatus.read;

  /// Returns true if the notification has been read
  bool get isRead => status == NotificationStatus.read;

  /// Returns true if the notification is still pending
  bool get isPending => status == NotificationStatus.pending;

  /// Returns true if this is an event-related notification
  bool get isEventNotification => eventId != null;

  /// Returns true if this is a goal-related notification
  bool get isGoalNotification => goalId != null;

  /// Creates a copy of this notification with the given fields replaced
  Notification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? eventId,
    String? goalId,
    DateTime? scheduledAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    NotificationStatus? status,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      eventId: eventId ?? this.eventId,
      goalId: goalId ?? this.goalId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Mark the notification as delivered
  Notification markDelivered() {
    return copyWith(
      status: NotificationStatus.delivered,
      deliveredAt: DateTime.now(),
    );
  }

  /// Mark the notification as read
  Notification markRead() {
    return copyWith(
      status: NotificationStatus.read,
      readAt: DateTime.now(),
    );
  }

  /// Mark the notification as dismissed
  Notification markDismissed() {
    return copyWith(status: NotificationStatus.dismissed);
  }

  /// Mark the notification as cancelled
  Notification markCancelled() {
    return copyWith(status: NotificationStatus.cancelled);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Notification &&
        other.id == id &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        other.eventId == eventId &&
        other.goalId == goalId &&
        other.scheduledAt == scheduledAt &&
        other.deliveredAt == deliveredAt &&
        other.readAt == readAt &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      type,
      title,
      body,
      eventId,
      goalId,
      scheduledAt,
      deliveredAt,
      readAt,
      status,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Notification(id: $id, type: $type, title: $title, status: $status, scheduledAt: $scheduledAt)';
  }
}
