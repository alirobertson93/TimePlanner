import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_wizard_providers.dart';
import '../../../../domain/entities/goal.dart';

/// Step 2: Goals review and selection
class GoalsReviewStep extends ConsumerWidget {
  const GoalsReviewStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(planningWizardProvider);
    final goalsAsync = ref.watch(allGoalsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Your goals for this period',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the goals you want to prioritize during scheduling. The scheduler will try to allocate time to meet these goals.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),

          // Goals list
          goalsAsync.when(
            data: (goals) => _buildGoalsList(context, ref, goals, wizardState),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => _buildErrorState(context, error),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsList(
    BuildContext context,
    WidgetRef ref,
    List<Goal> goals,
    PlanningWizardState wizardState,
  ) {
    if (goals.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Select all / deselect all buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                ref.read(planningWizardProvider.notifier).selectAllGoals(goals);
              },
              child: const Text('Select All'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                ref.read(planningWizardProvider.notifier).deselectAllGoals();
              },
              child: const Text('Deselect All'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Goals cards
        ...goals.map((goal) => _buildGoalCard(
              context,
              ref,
              goal,
              wizardState.selectedGoals.any((g) => g.id == goal.id),
            )),

        const SizedBox(height: 16),

        // Info message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Goals are optional. You can skip this step if you don\'t have any specific time targets.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    WidgetRef ref,
    Goal goal,
    bool isSelected,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          ref.read(planningWizardProvider.notifier).toggleGoal(goal);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox
              Checkbox(
                value: isSelected,
                onChanged: (_) {
                  ref.read(planningWizardProvider.notifier).toggleGoal(goal);
                },
              ),
              const SizedBox(width: 8),

              // Goal icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.flag,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Goal details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGoalDescription(goal),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGoalDescription(Goal goal) {
    final targetStr = '${goal.targetValue} ${_getMetricLabel(goal.metric.value)}';
    final periodStr = _getPeriodLabel(goal.period.value);
    return '$targetStr per $periodStr';
  }

  String _getMetricLabel(int metric) {
    switch (metric) {
      case 0:
        return 'hours';
      case 1:
        return 'events';
      default:
        return 'units';
    }
  }

  String _getPeriodLabel(int period) {
    switch (period) {
      case 0:
        return 'day';
      case 1:
        return 'week';
      case 2:
        return 'month';
      default:
        return 'period';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No goals yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t created any goals. Goals help the scheduler prioritize what\'s important to you.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'You can continue without goals, or create goals later in Settings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load goals',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
