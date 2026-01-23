import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/notification_service.dart';
import '../../domain/services/notification_scheduler_service.dart';
import 'repository_providers.dart';

/// Provider for the system notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Provider for the notification scheduler service
/// This bridges the notification repository with the system notification service
final notificationSchedulerServiceProvider =
    Provider<NotificationSchedulerService>((ref) {
  final notificationRepository = ref.watch(notificationRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);

  return NotificationSchedulerService(
    notificationRepository: notificationRepository,
    notificationService: notificationService,
  );
});
