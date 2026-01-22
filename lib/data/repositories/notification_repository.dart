import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/entities/notification.dart' as domain;
import '../../domain/enums/notification_type.dart';
import '../../domain/enums/notification_status.dart';

/// Repository for managing notifications
class NotificationRepository {
  final AppDatabase _db;

  NotificationRepository(this._db);

  /// Get all notifications
  Future<List<domain.Notification>> getAll() async {
    final rows = await _db.select(_db.notifications).get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get a notification by ID
  Future<domain.Notification?> getById(String id) async {
    final query = _db.select(_db.notifications)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  /// Get pending notifications that should be delivered
  Future<List<domain.Notification>> getPendingToDeliver() async {
    final now = DateTime.now();
    final query = _db.select(_db.notifications)
      ..where((t) => t.status.equals(NotificationStatus.pending.index))
      ..where((t) => t.scheduledAt.isSmallerOrEqualValue(now));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get notifications by status
  Future<List<domain.Notification>> getByStatus(NotificationStatus status) async {
    final query = _db.select(_db.notifications)
      ..where((t) => t.status.equals(status.index));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get notifications by type
  Future<List<domain.Notification>> getByType(NotificationType type) async {
    final query = _db.select(_db.notifications)
      ..where((t) => t.type.equals(type.index));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get notifications for a specific event
  Future<List<domain.Notification>> getByEventId(String eventId) async {
    final query = _db.select(_db.notifications)
      ..where((t) => t.eventId.equals(eventId));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get notifications for a specific goal
  Future<List<domain.Notification>> getByGoalId(String goalId) async {
    final query = _db.select(_db.notifications)
      ..where((t) => t.goalId.equals(goalId));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get unread notifications
  Future<List<domain.Notification>> getUnread() async {
    final query = _db.select(_db.notifications)
      ..where((t) => t.status.equals(NotificationStatus.delivered.index));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Save (insert or update) a notification
  Future<void> save(domain.Notification notification) async {
    final companion = _mapToDbModel(notification);
    await _db.into(_db.notifications).insertOnConflictUpdate(companion);
  }

  /// Delete a notification by ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.notifications)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all notifications
  Future<void> deleteAll() async {
    await _db.delete(_db.notifications).go();
  }

  /// Delete all notifications for an event
  Future<void> deleteByEventId(String eventId) async {
    await (_db.delete(_db.notifications)..where((t) => t.eventId.equals(eventId))).go();
  }

  /// Delete all notifications for a goal
  Future<void> deleteByGoalId(String goalId) async {
    await (_db.delete(_db.notifications)..where((t) => t.goalId.equals(goalId))).go();
  }

  /// Mark a notification as delivered
  Future<void> markDelivered(String id) async {
    await (_db.update(_db.notifications)..where((t) => t.id.equals(id)))
        .write(NotificationsCompanion(
          status: Value(NotificationStatus.delivered),
          deliveredAt: Value(DateTime.now()),
        ));
  }

  /// Mark a notification as read
  Future<void> markRead(String id) async {
    await (_db.update(_db.notifications)..where((t) => t.id.equals(id)))
        .write(NotificationsCompanion(
          status: Value(NotificationStatus.read),
          readAt: Value(DateTime.now()),
        ));
  }

  /// Mark all unread notifications as read
  Future<void> markAllRead() async {
    await (_db.update(_db.notifications)
          ..where((t) => t.status.equals(NotificationStatus.delivered.index)))
        .write(NotificationsCompanion(
          status: Value(NotificationStatus.read),
          readAt: Value(DateTime.now()),
        ));
  }

  /// Cancel pending notifications for an event (e.g., when event is deleted)
  Future<void> cancelPendingForEvent(String eventId) async {
    await (_db.update(_db.notifications)
          ..where((t) => t.eventId.equals(eventId))
          ..where((t) => t.status.equals(NotificationStatus.pending.index)))
        .write(const NotificationsCompanion(
          status: Value(NotificationStatus.cancelled),
        ));
  }

  /// Watch all notifications (reactive stream)
  Stream<List<domain.Notification>> watchAll() {
    return _db.select(_db.notifications).watch().map(
          (rows) => rows.map(_mapToEntity).toList(),
        );
  }

  /// Watch unread notification count
  Stream<int> watchUnreadCount() {
    final query = _db.select(_db.notifications)
      ..where((t) => t.status.equals(NotificationStatus.delivered.index));
    return query.watch().map((rows) => rows.length);
  }

  /// Map database row to domain entity
  domain.Notification _mapToEntity(Notification dbNotification) {
    return domain.Notification(
      id: dbNotification.id,
      type: dbNotification.type,
      title: dbNotification.title,
      body: dbNotification.body,
      eventId: dbNotification.eventId,
      goalId: dbNotification.goalId,
      scheduledAt: dbNotification.scheduledAt,
      deliveredAt: dbNotification.deliveredAt,
      readAt: dbNotification.readAt,
      status: dbNotification.status,
      createdAt: dbNotification.createdAt,
    );
  }

  /// Map domain entity to database model
  NotificationsCompanion _mapToDbModel(domain.Notification notification) {
    return NotificationsCompanion(
      id: Value(notification.id),
      type: Value(notification.type),
      title: Value(notification.title),
      body: Value(notification.body),
      eventId: Value(notification.eventId),
      goalId: Value(notification.goalId),
      scheduledAt: Value(notification.scheduledAt),
      deliveredAt: Value(notification.deliveredAt),
      readAt: Value(notification.readAt),
      status: Value(notification.status),
      createdAt: Value(notification.createdAt),
    );
  }
}
