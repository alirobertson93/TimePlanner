import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/planning_wizard_providers.dart';
import '../../../../scheduler/models/scheduled_event.dart';

/// Step 4: Review the generated schedule
class PlanReviewStep extends ConsumerWidget {
  const PlanReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(planningWizardProvider);
    final result = wizardState.scheduleResult;

    if (result == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating schedule...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          _buildHeader(context, result),
          const SizedBox(height: 24),

          // Summary cards
          _buildSummaryCards(context, result),
          const SizedBox(height: 24),

          // Scheduled events by day
          if (result.scheduledEvents.isNotEmpty) ...[
            Text(
              'Scheduled Events',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildScheduledEventsList(context, result.scheduledEvents, wizardState),
          ],

          // Unscheduled events
          if (result.unscheduledEvents.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildUnscheduledSection(context, result),
          ],

          // Conflicts
          if (result.conflicts.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildConflictsSection(context, result),
          ],

          // Error message
          if (wizardState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wizardState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic result) {
    final isSuccess = result.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSuccess
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSuccess
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.warning,
              color: isSuccess
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onError,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSuccess
                      ? 'Your schedule is ready!'
                      : 'Schedule generated with issues',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSuccess
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Strategy: ${_capitalizeFirst(result.strategyUsed)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, dynamic result) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context: context,
            title: 'Scheduled',
            value: result.scheduledEvents.length.toString(),
            icon: Icons.event_available,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context: context,
            title: 'Unscheduled',
            value: result.unscheduledEvents.length.toString(),
            icon: Icons.event_busy,
            color: result.unscheduledEvents.isEmpty
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            context: context,
            title: 'Conflicts',
            value: result.conflicts.length.toString(),
            icon: Icons.warning_amber,
            color: result.conflicts.isEmpty
                ? Theme.of(context).colorScheme.outline
                : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledEventsList(
    BuildContext context,
    List<ScheduledEvent> events,
    PlanningWizardState wizardState,
  ) {
    // Group events by day
    final eventsByDay = <DateTime, List<ScheduledEvent>>{};
    for (final event in events) {
      final day = DateTime(
        event.scheduledStart.year,
        event.scheduledStart.month,
        event.scheduledStart.day,
      );
      eventsByDay.putIfAbsent(day, () => []).add(event);
    }

    // Sort days
    final sortedDays = eventsByDay.keys.toList()..sort();

    return Column(
      children: sortedDays.map((day) {
        final dayEvents = eventsByDay[day]!;
        dayEvents.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
        
        return _buildDaySection(context, day, dayEvents);
      }).toList(),
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime day,
    List<ScheduledEvent> events,
  ) {
    final dateFormat = DateFormat.EEEE_MMMMd();
    final timeFormat = DateFormat.jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(day),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Text(
                '${events.length} events',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...events.map((event) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(
                  event.event.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                subtitle: Text(
                  '${timeFormat.format(event.scheduledStart)} - ${timeFormat.format(event.scheduledEnd)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                trailing: event.event.isFixed
                    ? const Icon(Icons.lock, size: 16)
                    : null,
              ),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildUnscheduledSection(BuildContext context, dynamic result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.event_busy,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              'Unscheduled Events (${result.unscheduledEvents.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following events couldn\'t be scheduled due to time constraints:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              ...result.unscheduledEvents.map((event) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8),
                        const SizedBox(width: 8),
                        Text(event.name),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConflictsSection(BuildContext context, dynamic result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(
              'Conflicts (${result.conflicts.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'The following conflicts were detected:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              ...result.conflicts.map((conflict) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            conflict.description,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  /// Capitalize the first letter of a string
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
