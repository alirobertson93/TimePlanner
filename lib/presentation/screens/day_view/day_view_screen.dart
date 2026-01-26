import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
import '../../providers/notification_providers.dart';
import '../../widgets/adaptive_app_bar.dart';
import 'widgets/day_timeline.dart';
import 'widgets/event_detail_sheet.dart';

/// Day view screen showing a 24-hour timeline
class DayViewScreen extends ConsumerWidget {
  const DayViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final eventsAsync = ref.watch(eventsForDateProvider(selectedDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMMd().format(selectedDate)),
        actions: [
          AdaptiveAppBarActions(
            actions: _buildAppBarActions(context, ref),
          ),
        ],
      ),
      body: eventsAsync.when(
        data: (events) => DayTimeline(
          date: selectedDate,
          events: events,
          onEventTap: (event) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => EventDetailSheet(event: event),
            );
          },
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
      floatingActionButton: Semantics(
        button: true,
        label: 'Create new activity',
        child: FloatingActionButton(
          onPressed: () {
            context.push('/event/new', extra: selectedDate);
          },
          tooltip: 'Create new activity',
          child: const Icon(Icons.add, semanticLabel: 'Add activity'),
        ),
      ),
    );
  }

  List<AdaptiveAppBarAction> _buildAppBarActions(BuildContext context, WidgetRef ref) {
    final unreadCountAsync = ref.watch(unreadCountProvider);
    
    return [
      // Navigation actions (highest priority - always visible)
      AdaptiveAppBarAction(
        icon: const Icon(Icons.chevron_left),
        label: 'Previous day',
        onPressed: () {
          ref.read(selectedDateProvider.notifier).previousDay();
        },
        priority: AdaptiveActionPriority.navigation,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.today),
        label: 'Today',
        onPressed: () {
          ref.read(selectedDateProvider.notifier).today();
        },
        priority: AdaptiveActionPriority.navigation,
      ),
      AdaptiveAppBarAction(
        icon: const Icon(Icons.chevron_right),
        label: 'Next day',
        onPressed: () {
          ref.read(selectedDateProvider.notifier).nextDay();
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
        icon: const Icon(Icons.calendar_view_week),
        label: 'Week view',
        onPressed: () {
          context.go('/week');
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
