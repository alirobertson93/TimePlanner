import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/recurrence_end_type.dart';
import '../providers/repository_providers.dart';
import '../providers/recurrence_providers.dart';

/// A widget for selecting or creating a recurrence rule for an event
class RecurrencePicker extends ConsumerStatefulWidget {
  const RecurrencePicker({
    super.key,
    required this.selectedRecurrenceRuleId,
    required this.onRecurrenceChanged,
  });

  /// Currently selected recurrence rule ID (null if none/no recurrence)
  final String? selectedRecurrenceRuleId;

  /// Callback when the selection changes
  final void Function(String? recurrenceRuleId) onRecurrenceChanged;

  @override
  ConsumerState<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends ConsumerState<RecurrencePicker> {
  @override
  Widget build(BuildContext context) {
    final allRulesAsync = ref.watch(allRecurrenceRulesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Add/Change button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recurrence',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showRecurrencePickerDialog(context),
              icon: const Icon(Icons.repeat, size: 18),
              label: Text(widget.selectedRecurrenceRuleId == null ? 'Add' : 'Change'),
            ),
          ],
        ),

        // Selected recurrence display
        allRulesAsync.when(
          data: (allRules) {
            if (widget.selectedRecurrenceRuleId == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Does not repeat',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              );
            }

            final selectedRule = allRules
                .where((r) => r.id == widget.selectedRecurrenceRuleId)
                .firstOrNull;

            if (selectedRule == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Recurrence rule not found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    _getFrequencyIcon(selectedRule.frequency),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(selectedRule.description),
                subtitle: _buildEndConditionText(context, selectedRule),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => widget.onRecurrenceChanged(null),
                  tooltip: 'Remove recurrence',
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Text(
            'Error loading recurrence rules',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ],
    );
  }

  IconData _getFrequencyIcon(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return Icons.today;
      case RecurrenceFrequency.weekly:
        return Icons.view_week;
      case RecurrenceFrequency.monthly:
        return Icons.calendar_month;
      case RecurrenceFrequency.yearly:
        return Icons.event;
    }
  }

  Widget? _buildEndConditionText(BuildContext context, RecurrenceRule rule) {
    switch (rule.endType) {
      case RecurrenceEndType.never:
        return null;
      case RecurrenceEndType.afterOccurrences:
        if (rule.occurrences != null) {
          return Text(
            'Ends after ${rule.occurrences} occurrences',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return null;
      case RecurrenceEndType.onDate:
        if (rule.endDate != null) {
          return Text(
            'Ends on ${rule.endDate!.year}-${rule.endDate!.month.toString().padLeft(2, '0')}-${rule.endDate!.day.toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }
        return null;
    }
  }

  Future<void> _showRecurrencePickerDialog(BuildContext context) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecurrencePickerBottomSheet(
        selectedId: widget.selectedRecurrenceRuleId,
        onCreateCustom: () => _showCreateRecurrenceDialog(context),
      ),
    );

    // result can be:
    // - null: user dismissed without selection
    // - '': user clicked "Don't Repeat" to remove recurrence
    // - RecurrenceRule: user selected a quick pattern that needs to be saved
    if (result != null) {
      if (result == '') {
        // Empty string means explicitly clear selection
        widget.onRecurrenceChanged(null);
      } else if (result is RecurrenceRule) {
        // Quick pattern selected - save the rule first
        try {
          await ref.read(recurrenceRuleRepositoryProvider).save(result);
          ref.invalidate(allRecurrenceRulesProvider);
          widget.onRecurrenceChanged(result.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving recurrence: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _showCreateRecurrenceDialog(BuildContext context) async {
    final result = await showDialog<RecurrenceRule>(
      context: context,
      builder: (context) => const _CreateRecurrenceDialog(),
    );

    if (result != null) {
      try {
        await ref.read(recurrenceRuleRepositoryProvider).save(result);
        ref.invalidate(allRecurrenceRulesProvider);
        widget.onRecurrenceChanged(result.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

/// Bottom sheet for selecting a recurrence pattern
class _RecurrencePickerBottomSheet extends StatelessWidget {
  const _RecurrencePickerBottomSheet({
    required this.selectedId,
    required this.onCreateCustom,
  });

  final String? selectedId;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    // Quick select patterns
    final quickPatterns = [
      (RecurrenceFrequency.daily, 1, 'Every day'),
      (RecurrenceFrequency.weekly, 1, 'Every week'),
      (RecurrenceFrequency.weekly, 2, 'Every 2 weeks'),
      (RecurrenceFrequency.monthly, 1, 'Every month'),
      (RecurrenceFrequency.yearly, 1, 'Every year'),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repeat',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(null);
                      onCreateCustom();
                    },
                    child: const Text('Custom'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Options list
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  // Don't repeat option
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: selectedId == null
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.block,
                        color: selectedId == null
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      "Doesn't repeat",
                      style: selectedId == null
                          ? const TextStyle(fontWeight: FontWeight.bold)
                          : null,
                    ),
                    trailing: selectedId == null
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(''),
                  ),

                  const Divider(),

                  // Quick select patterns
                  ...quickPatterns.map((pattern) {
                    final (frequency, interval, label) = pattern;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          _getFrequencyIcon(frequency),
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      title: Text(label),
                      onTap: () {
                        // Create the recurrence rule and pass it back
                        final rule = RecurrenceRule(
                          id: const Uuid().v4(),
                          frequency: frequency,
                          interval: interval,
                          endType: RecurrenceEndType.never,
                          createdAt: DateTime.now(),
                        );
                        // Return the rule itself so the parent can save it
                        Navigator.of(context).pop(rule);
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getFrequencyIcon(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return Icons.today;
      case RecurrenceFrequency.weekly:
        return Icons.view_week;
      case RecurrenceFrequency.monthly:
        return Icons.calendar_month;
      case RecurrenceFrequency.yearly:
        return Icons.event;
    }
  }
}

/// Dialog for creating a custom recurrence rule
class _CreateRecurrenceDialog extends StatefulWidget {
  const _CreateRecurrenceDialog();

  @override
  State<_CreateRecurrenceDialog> createState() => _CreateRecurrenceDialogState();
}

class _CreateRecurrenceDialogState extends State<_CreateRecurrenceDialog> {
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  int _interval = 1;
  RecurrenceEndType _endType = RecurrenceEndType.never;
  DateTime? _endDate;
  int _occurrences = 10;
  final List<int> _selectedWeekDays = [];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Recurrence'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Frequency dropdown
            DropdownButtonFormField<RecurrenceFrequency>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceFrequency.values.map((freq) {
                return DropdownMenuItem(
                  value: freq,
                  child: Text(_getFrequencyLabel(freq)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _frequency = value;
                    _selectedWeekDays.clear();
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Interval field
            Row(
              children: [
                const Text('Every'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: DropdownButtonFormField<int>(
                    value: _interval,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    items: List.generate(30, (i) => i + 1).map((n) {
                      return DropdownMenuItem(value: n, child: Text('$n'));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _interval = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(_getIntervalSuffix(_frequency)),
              ],
            ),

            // Week day selection (for weekly)
            if (_frequency == RecurrenceFrequency.weekly) ...[
              const SizedBox(height: 16),
              const Text('On days:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final dayNames = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  final isSelected = _selectedWeekDays.contains(index);
                  return FilterChip(
                    label: Text(dayNames[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeekDays.add(index);
                        } else {
                          _selectedWeekDays.remove(index);
                        }
                      });
                    },
                  );
                }),
              ),
            ],

            const SizedBox(height: 16),

            // End type dropdown
            DropdownButtonFormField<RecurrenceEndType>(
              value: _endType,
              decoration: const InputDecoration(
                labelText: 'Ends',
                border: OutlineInputBorder(),
              ),
              items: RecurrenceEndType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getEndTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _endType = value;
                    if (_endType == RecurrenceEndType.onDate && _endDate == null) {
                      _endDate = DateTime.now().add(const Duration(days: 30));
                    }
                  });
                }
              },
            ),

            // End date picker
            if (_endType == RecurrenceEndType.onDate) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => _endDate = date);
                  }
                },
                child: Text(
                  _endDate != null
                      ? 'End date: ${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                      : 'Select end date',
                ),
              ),
            ],

            // Occurrences picker
            if (_endType == RecurrenceEndType.afterOccurrences) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('After'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: DropdownButtonFormField<int>(
                      value: _occurrences,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      ),
                      items: [5, 10, 15, 20, 25, 30, 50, 100].map((n) {
                        return DropdownMenuItem(value: n, child: Text('$n'));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _occurrences = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('occurrences'),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final rule = RecurrenceRule(
              id: const Uuid().v4(),
              frequency: _frequency,
              interval: _interval,
              byWeekDay: _frequency == RecurrenceFrequency.weekly && _selectedWeekDays.isNotEmpty
                  ? (List<int>.from(_selectedWeekDays)..sort())
                  : null,
              endType: _endType,
              endDate: _endType == RecurrenceEndType.onDate ? _endDate : null,
              occurrences: _endType == RecurrenceEndType.afterOccurrences ? _occurrences : null,
              createdAt: DateTime.now(),
            );
            Navigator.of(context).pop(rule);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  String _getFrequencyLabel(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return 'Daily';
      case RecurrenceFrequency.weekly:
        return 'Weekly';
      case RecurrenceFrequency.monthly:
        return 'Monthly';
      case RecurrenceFrequency.yearly:
        return 'Yearly';
    }
  }

  String _getIntervalSuffix(RecurrenceFrequency frequency) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return _interval == 1 ? 'day' : 'days';
      case RecurrenceFrequency.weekly:
        return _interval == 1 ? 'week' : 'weeks';
      case RecurrenceFrequency.monthly:
        return _interval == 1 ? 'month' : 'months';
      case RecurrenceFrequency.yearly:
        return _interval == 1 ? 'year' : 'years';
    }
  }

  String _getEndTypeLabel(RecurrenceEndType endType) {
    switch (endType) {
      case RecurrenceEndType.never:
        return 'Never';
      case RecurrenceEndType.afterOccurrences:
        return 'After occurrences';
      case RecurrenceEndType.onDate:
        return 'On date';
    }
  }
}
