import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/event_providers.dart';
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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).previousDay();
            },
            tooltip: 'Previous day',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).today();
            },
            tooltip: 'Today',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).nextDay();
            },
            tooltip: 'Next day',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              context.push('/locations');
            },
            tooltip: 'Locations',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              context.push('/people');
            },
            tooltip: 'People',
          ),
          IconButton(
            icon: const Icon(Icons.track_changes),
            onPressed: () {
              context.push('/goals');
            },
            tooltip: 'Goals',
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              context.push('/plan');
            },
            tooltip: 'Plan week',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () {
              context.go('/week');
            },
            tooltip: 'Week view',
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
                'Error loading events',
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
}
