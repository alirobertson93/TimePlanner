import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/notification.dart' as domain;
import '../../../domain/enums/notification_type.dart';
import '../../../domain/enums/notification_status.dart';
import '../../providers/notification_providers.dart';
import '../../providers/repository_providers.dart';

/// Screen for viewing and managing notifications
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  /// Helper method to refresh notification providers
  void _refreshNotifications(WidgetRef ref) {
    ref.invalidate(watchAllNotificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(watchAllNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await _markAllAsRead(ref);
              } else if (value == 'clear_all') {
                await _showClearAllDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildNotificationsList(context, ref, notifications);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading notifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 72,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<domain.Notification> notifications,
  ) {
    // Group notifications by date
    final groupedNotifications = _groupNotificationsByDate(notifications);
    final sortedDates = groupedNotifications.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateNotifications = groupedNotifications[date]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDateHeader(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...dateNotifications.map(
              (notification) => _buildNotificationTile(context, ref, notification),
            ),
          ],
        );
      },
    );
  }

  Map<DateTime, List<domain.Notification>> _groupNotificationsByDate(
    List<domain.Notification> notifications,
  ) {
    final grouped = <DateTime, List<domain.Notification>>{};
    for (final notification in notifications) {
      final dateKey = DateTime(
        notification.scheduledAt.year,
        notification.scheduledAt.month,
        notification.scheduledAt.day,
      );
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }
    // Sort notifications within each group by time (newest first)
    for (final list in grouped.values) {
      list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    }
    return grouped;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    domain.Notification notification,
  ) {
    final isUnread = notification.status == NotificationStatus.delivered ||
                     notification.status == NotificationStatus.pending;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref.read(notificationRepositoryProvider).delete(notification.id);
        _refreshNotifications(ref);
      },
      child: ListTile(
        leading: _buildNotificationIcon(notification),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body != null && notification.body!.isNotEmpty) ...[
              Text(
                notification.body!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat.jm().format(notification.scheduledAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(context, ref, notification),
      ),
    );
  }

  Widget _buildNotificationIcon(domain.Notification notification) {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.eventReminder:
        icon = Icons.alarm;
        color = Colors.blue;
        break;
      case NotificationType.scheduleChange:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case NotificationType.goalProgress:
        icon = Icons.trending_up;
        color = Colors.green;
        break;
      case NotificationType.conflictWarning:
        icon = Icons.warning;
        color = Colors.amber;
        break;
      case NotificationType.goalAtRisk:
        icon = Icons.error;
        color = Colors.red;
        break;
      case NotificationType.goalCompleted:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    domain.Notification notification,
  ) async {
    // Mark as read if not already
    if (notification.status == NotificationStatus.delivered ||
        notification.status == NotificationStatus.pending) {
      await ref.read(notificationRepositoryProvider).markRead(notification.id);
      _refreshNotifications(ref);
    }

    // Navigate based on notification type
    if (notification.eventId != null) {
      // Navigate to event detail/edit
      if (context.mounted) {
        context.push('/event/${notification.eventId}/edit');
      }
    } else if (notification.goalId != null) {
      // Navigate to goal
      if (context.mounted) {
        context.push('/goal/${notification.goalId}/edit');
      }
    }
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    _refreshNotifications(ref);
  }

  Future<void> _showClearAllDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will permanently delete all your notifications. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notificationRepositoryProvider).deleteAll();
      _refreshNotifications(ref);
    }
  }
}
