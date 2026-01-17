import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../providers/event_providers.dart';
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
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).setDate(
                    selectedDate.subtract(const Duration(days: 7)),
                  );
            },
            tooltip: 'Previous week',
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).today();
            },
            tooltip: 'This week',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              ref.read(selectedDateProvider.notifier).setDate(
                    selectedDate.add(const Duration(days: 7)),
                  );
            },
            tooltip: 'Next week',
          ),
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            onPressed: () {
              context.go('/day');
            },
            tooltip: 'Day view',
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
