import 'package:drift/drift.dart';
import '../../../domain/enums/notification_type.dart';
import '../../../domain/enums/notification_status.dart';

/// Notifications table definition
/// Stores scheduled and delivered notifications for events, goals, etc.
@TableIndex(name: 'idx_notifications_scheduled', columns: {#scheduledAt})
@TableIndex(name: 'idx_notifications_status', columns: {#status})
@TableIndex(name: 'idx_notifications_event', columns: {#eventId})
class Notifications extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Type of notification (event reminder, schedule change, etc.)
  IntColumn get type => intEnum<NotificationType>()();

  /// Title of the notification
  TextColumn get title => text()();

  /// Optional body/description
  TextColumn get body => text().nullable()();

  /// Reference to related event (optional)
  TextColumn get eventId => text().nullable()();

  /// Reference to related goal (optional)
  TextColumn get goalId => text().nullable()();

  /// When the notification should be delivered
  DateTimeColumn get scheduledAt => dateTime()();

  /// When the notification was actually delivered
  DateTimeColumn get deliveredAt => dateTime().nullable()();

  /// When the notification was read
  DateTimeColumn get readAt => dateTime().nullable()();

  /// Current status of the notification
  IntColumn get status =>
      intEnum<NotificationStatus>().withDefault(const Constant(0))();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
