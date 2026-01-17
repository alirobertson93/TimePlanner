import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/planning_wizard_providers.dart';

/// Step 3: Strategy selection for scheduling
class StrategySelectionStep extends ConsumerWidget {
  const StrategySelectionStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(planningWizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'How should we schedule your week?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a scheduling strategy that matches your preferences. Each strategy optimizes your schedule differently.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Strategy cards
          _buildStrategyCard(
            context: context,
            ref: ref,
            strategy: StrategyType.balanced,
            isSelected: wizardState.selectedStrategy == StrategyType.balanced,
            title: 'Balanced',
            description: 'Evenly distribute work throughout the week. Best for maintaining a consistent routine.',
            icon: Icons.balance,
            isRecommended: true,
          ),
          const SizedBox(height: 16),

          _buildStrategyCard(
            context: context,
            ref: ref,
            strategy: StrategyType.frontLoaded,
            isSelected: wizardState.selectedStrategy == StrategyType.frontLoaded,
            title: 'Front-Loaded',
            description: 'Schedule important tasks early in the week. Best for getting ahead and having flexibility later.',
            icon: Icons.trending_down,
          ),
          const SizedBox(height: 16),

          _buildStrategyCard(
            context: context,
            ref: ref,
            strategy: StrategyType.maxFreeTime,
            isSelected: wizardState.selectedStrategy == StrategyType.maxFreeTime,
            title: 'Max Free Time',
            description: 'Create large uninterrupted blocks of free time. Best for deep work or personal projects.',
            icon: Icons.free_breakfast,
          ),
          const SizedBox(height: 16),

          _buildStrategyCard(
            context: context,
            ref: ref,
            strategy: StrategyType.leastDisruption,
            isSelected: wizardState.selectedStrategy == StrategyType.leastDisruption,
            title: 'Least Disruption',
            description: 'Minimize changes to your existing schedule. Best when rescheduling events.',
            icon: Icons.sync_disabled,
          ),
          const SizedBox(height: 32),

          // Error message
          if (wizardState.error != null)
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

          // Info card about generating schedule
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap "Generate Schedule" to see how your events will be arranged. You can review and adjust before accepting.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard({
    required BuildContext context,
    required WidgetRef ref,
    required StrategyType strategy,
    required bool isSelected,
    required String title,
    required String description,
    required IconData icon,
    bool isRecommended = false,
  }) {
    return Card(
      elevation: isSelected ? 4 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          ref.read(planningWizardProvider.notifier).updateStrategy(strategy);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radio button
              Radio<StrategyType>(
                value: strategy,
                groupValue: ref.watch(planningWizardProvider).selectedStrategy,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(planningWizardProvider.notifier).updateStrategy(value);
                  }
                },
              ),
              const SizedBox(width: 12),

              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),

              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Recommended',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

}
