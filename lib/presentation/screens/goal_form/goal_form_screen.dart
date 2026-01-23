import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/goal_form_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/goal_providers.dart';
import '../../providers/person_providers.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../domain/enums/goal_metric.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/debt_strategy.dart';
import '../../../core/utils/color_utils.dart';

/// Screen for creating or editing goals
class GoalFormScreen extends ConsumerStatefulWidget {
  const GoalFormScreen({
    super.key,
    this.goalId,
  });

  final String? goalId;

  @override
  ConsumerState<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends ConsumerState<GoalFormScreen> {
  final _titleController = TextEditingController();
  final _targetValueController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeForm();
    });
  }

  Future<void> _initializeForm() async {
    if (_isInitialized) return;

    final formNotifier = ref.read(goalFormProvider.notifier);
    if (widget.goalId != null) {
      await formNotifier.initializeForEdit(widget.goalId!);
    } else {
      formNotifier.initializeForNew();
    }

    final state = ref.read(goalFormProvider);
    _titleController.text = state.title;
    _targetValueController.text = state.targetValue.toString();

    _isInitialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(goalFormProvider);
    final formNotifier = ref.read(goalFormProvider.notifier);
    final categoriesAsync = ref.watch(categoryRepositoryProvider).getAll();
    final peopleAsync = ref.watch(allPeopleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(formState.isEditMode ? 'Edit Goal' : 'New Goal'),
        actions: [
          if (formState.isEditMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: formState.isSaving
                  ? null
                  : () => _showDeleteConfirmation(context, formNotifier),
              tooltip: 'Delete Goal',
            ),
          TextButton(
            onPressed: formState.isSaving || !formState.isValid
                ? null
                : () async {
                    final success = await formNotifier.save();
                    if (success && context.mounted) {
                      // Invalidate goals provider to refresh the list
                      ref.invalidate(goalsWithProgressProvider);
                      context.pop();
                    }
                  },
            child: formState.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Error message
          if (formState.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formState.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),

          // Basic Information Section
          Text(
            'Basic Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // Title field
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Goal Title *',
              border: OutlineInputBorder(),
              hintText: 'e.g., Deep Work Time',
            ),
            onChanged: formNotifier.updateTitle,
          ),
          const SizedBox(height: 24),

          // Target Section
          Text(
            'Target',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // Target value and metric row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target value field
              Expanded(
                child: TextField(
                  controller: _targetValueController,
                  decoration: const InputDecoration(
                    labelText: 'Target Value *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 10',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final intValue = int.tryParse(value) ?? 0;
                    formNotifier.updateTargetValue(intValue);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Metric dropdown
              Expanded(
                child: DropdownButtonFormField<GoalMetric>(
                  value: formState.metric,
                  decoration: const InputDecoration(
                    labelText: 'Metric',
                    border: OutlineInputBorder(),
                  ),
                  items: GoalMetric.values.map((metric) {
                    return DropdownMenuItem<GoalMetric>(
                      value: metric,
                      child: Text(_getMetricDisplayName(metric)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      formNotifier.updateMetric(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Period dropdown
          DropdownButtonFormField<GoalPeriod>(
            value: formState.period,
            decoration: const InputDecoration(
              labelText: 'Period',
              border: OutlineInputBorder(),
            ),
            items: GoalPeriod.values.map((period) {
              return DropdownMenuItem<GoalPeriod>(
                value: period,
                child: Text(_getPeriodDisplayName(period)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                formNotifier.updatePeriod(value);
              }
            },
          ),
          const SizedBox(height: 8),

          // Goal summary text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.track_changes,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Track ${formState.targetValue} ${formState.metricDisplayText} ${formState.periodDisplayText}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Goal Target Section
          Text(
            'Goal Target',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // Goal type selector
          Text(
            'Track time spent:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          
          SegmentedButton<GoalType>(
            segments: const [
              ButtonSegment<GoalType>(
                value: GoalType.category,
                label: Text('By Category'),
                icon: Icon(Icons.category),
              ),
              ButtonSegment<GoalType>(
                value: GoalType.person,
                label: Text('With Person'),
                icon: Icon(Icons.person),
              ),
            ],
            selected: {formState.type},
            onSelectionChanged: (Set<GoalType> selected) {
              formNotifier.updateType(selected.first);
            },
          ),
          const SizedBox(height: 16),

          // Category dropdown (shown when type is category)
          if (formState.type == GoalType.category)
            FutureBuilder<List<dynamic>>(
              future: categoriesAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final categories = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: formState.categoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: ColorUtils.parseHexColor(category.colourHex),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: formNotifier.updateCategory,
                );
              },
            ),

          // Person dropdown (shown when type is person/relationship)
          if (formState.type == GoalType.person)
            peopleAsync.when(
              data: (people) {
                if (people.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No people added yet. Add people in the People screen first.',
                            style: TextStyle(color: Colors.orange.shade700),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return DropdownButtonFormField<String>(
                  value: formState.personId,
                  decoration: const InputDecoration(
                    labelText: 'Person *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: people.map((person) {
                    return DropdownMenuItem<String>(
                      value: person.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              person.name.trim().isNotEmpty ? person.name.trim()[0].toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(person.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: formNotifier.updatePerson,
                );
              },
              loading: () => const SizedBox(
                height: 56,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error loading people: $error',
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Advanced Options Section (collapsed by default)
          ExpansionTile(
            title: Text(
              'Advanced Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            initiallyExpanded: false,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Debt Strategy dropdown
                    DropdownButtonFormField<DebtStrategy>(
                      value: formState.debtStrategy,
                      decoration: const InputDecoration(
                        labelText: 'Shortfall Strategy',
                        border: OutlineInputBorder(),
                        helperText: 'What happens if you don\'t meet this goal?',
                        helperMaxLines: 2,
                      ),
                      items: DebtStrategy.values.map((strategy) {
                        return DropdownMenuItem<DebtStrategy>(
                          value: strategy,
                          child: Text(_getDebtStrategyDisplayName(strategy)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          formNotifier.updateDebtStrategy(value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Active toggle
                    SwitchListTile(
                      title: const Text('Goal is Active'),
                      subtitle: const Text('Inactive goals are not tracked'),
                      value: formState.isActive,
                      onChanged: formNotifier.updateIsActive,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMetricDisplayName(GoalMetric metric) {
    switch (metric) {
      case GoalMetric.hours:
        return 'Hours';
      case GoalMetric.events:
        return 'Events';
      case GoalMetric.completions:
        return 'Completions';
    }
  }

  String _getPeriodDisplayName(GoalPeriod period) {
    switch (period) {
      case GoalPeriod.week:
        return 'Per Week';
      case GoalPeriod.month:
        return 'Per Month';
      case GoalPeriod.quarter:
        return 'Per Quarter';
      case GoalPeriod.year:
        return 'Per Year';
    }
  }

  String _getDebtStrategyDisplayName(DebtStrategy strategy) {
    switch (strategy) {
      case DebtStrategy.ignore:
        return 'Start Fresh (Ignore)';
      case DebtStrategy.carryForward:
        return 'Carry Forward';
      case DebtStrategy.distributeEvenly:
        return 'Distribute Evenly';
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    GoalForm formNotifier,
  ) async {
    final formState = ref.read(goalFormProvider);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
          'Are you sure you want to delete "${formState.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await formNotifier.delete();
      if (success && context.mounted) {
        ref.invalidate(goalsWithProgressProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Goal "${formState.title}" deleted')),
        );
      }
    }
  }
}
