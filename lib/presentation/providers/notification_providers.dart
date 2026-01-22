import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification.dart';
import '../../domain/enums/notification_type.dart';
import '../../domain/enums/notification_status.dart';
import 'repository_providers.dart';

/// Provider for all notifications
final allNotificationsProvider = FutureProvider<List<Notification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getAll();
});

/// Provider for unread notifications
final unreadNotificationsProvider = FutureProvider<List<Notification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getUnread();
});

/// Provider for pending notifications ready to deliver
final pendingNotificationsProvider = FutureProvider<List<Notification>>((ref) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getPendingToDeliver();
});

/// Provider for notifications by event ID
final notificationsByEventProvider = FutureProvider.family<List<Notification>, String>((ref, eventId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getByEventId(eventId);
});

/// Provider for notifications by goal ID
final notificationsByGoalProvider = FutureProvider.family<List<Notification>, String>((ref, goalId) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getByGoalId(goalId);
});

/// Provider for notification by ID
final notificationByIdProvider = FutureProvider.family<Notification?, String>((ref, id) async {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.getById(id);
});

/// Stream provider for watching all notifications
final watchAllNotificationsProvider = StreamProvider<List<Notification>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchAll();
});

/// Stream provider for watching unread count
final unreadCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return repository.watchUnreadCount();
});
