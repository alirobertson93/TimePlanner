import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/event_providers.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/adaptive_app_bar.dart';
import 'widgets/week_header.dart';
import 'widgets/week_timeline.dart';

/// Week view screen showing a 7-day timeline
class WeekViewScreen extends ConsumerWidget {
  const WeekViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final weekStart = DateTimeUtils.startOfWeek(selectedDate);
    final eventsAsync = ref.watch(eventsForWeekProvider(weekStart));

    final weekLabel = 'Week of ${DateFormat.MMMd().format(weekStart)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(weekLabel),
        actions: [
          AdaptiveAppBarActions(
            actions: _buildAppBarActions(context, ref, selectedDate),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => Column(
          children: [
            WeekHeader(
              weekStart: weekStart,
              selectedDate: selectedDate,
              onDayTap: (date) {
                ref.read(selectedDateProvider.notifier).setDate(date);
                context.go('/day');
              },
            ),
            Expanded(
              child: WeekTimeline(
                weekStart: weekStart,
                events: events,
                onEventTap: (event) {
                  // Navigate to day view for the event's day
                  if (event.startTime != null) {
                    ref.read(selectedDateProvider.notifier).setDate(event.startTime!);
                  }
                  context.go('/day');
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading activities',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/event/new', extra: selectedDate);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<AdaptiveAppBarAction> _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    DateTime selectedDate,
  ) {
    final unreadCountAsync = ref.watch(unreadCountProvider);
    
    return [
      // Navigation actions (highest priority - always visible)
      AdaptiveAppBarAction(
        icon: const Icon(Icons.chevron_left),
        label: 'Previous week',
        onPressed: () {
          ref.read(selectedDateProvider.notifier).setDate(
                selectedDate.subtract(const Duration(days: 7)),
              );
        },
        priority: AdaptiveActionPriority.navigation,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.today),
        label: 'This week',
        onPressed: () {
          ref.read(selectedDateProvider.notifier).today();
        },
        priority: AdaptiveActionPriority.navigation,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.chevron_right),
        label: 'Next week',
        onPressed: () {
          ref.read(selectedDateProvider.notifier).setDate(
                selectedDate.add(const Duration(days: 7)),
              );
        },
        priority: AdaptiveActionPriority.navigation,
      ),
      
      // Core actions (high priority)
      AdaptiveAppBarAction(
        icon: const Icon(Icons.auto_awesome),
        label: 'Plan week',
        onPressed: () {
          context.push('/plan');
        },
        priority: AdaptiveActionPriority.core,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.calendar_view_day),
        label: 'Day view',
        onPressed: () {
          context.go('/day');
        },
        priority: AdaptiveActionPriority.core,
      ),
      
      // Normal priority actions
      AdaptiveAppBarAction(
        icon: const Icon(Icons.track_changes),
        label: 'Goals',
        onPressed: () {
          context.push('/goals');
        },
        priority: AdaptiveActionPriority.normal,
      ),
      
      // Low priority actions (first to go into overflow)
      AdaptiveAppBarAction(
        icon: const Icon(Icons.people),
        label: 'People',
        onPressed: () {
          context.push('/people');
        },
        priority: AdaptiveActionPriority.low,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.location_on),
        label: 'Locations',
        onPressed: () {
          context.push('/locations');
        },
        priority: AdaptiveActionPriority.low,
      ),
      AdaptiveAppBarAction(
        icon: unreadCountAsync.when(
          data: (count) => Badge(
            isLabelVisible: count > 0,
            label: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(fontSize: 10),
            ),
            child: const Icon(Icons.notifications),
          ),
          loading: () => const Icon(Icons.notifications),
          error: (_, __) => const Icon(Icons.notifications),
        ),
        label: unreadCountAsync.when(
          data: (count) => count > 0 ? 'Notifications ($count unread)' : 'Notifications',
          loading: () => 'Notifications',
          error: (_, __) => 'Notifications',
        ),
        onPressed: () {
          context.push('/notifications');
        },
        priority: AdaptiveActionPriority.low,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.settings),
        label: 'Settings',
        onPressed: () {
          context.push('/settings');
        },
        priority: AdaptiveActionPriority.low,
      ),
    ];
  }
}
