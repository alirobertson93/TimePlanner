import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/recurrence_end_type.dart';

/// Dialog for creating a custom recurrence rule
class RecurrenceCustomDialog extends StatefulWidget {
  const RecurrenceCustomDialog({super.key});

  @override
  State<RecurrenceCustomDialog> createState() => _RecurrenceCustomDialogState();
}

class _RecurrenceCustomDialogState extends State<RecurrenceCustomDialog> {
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
