import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/event_form_providers.dart';
import '../../providers/repository_providers.dart';
import '../../../domain/enums/timing_type.dart';

/// Screen for creating or editing events
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({
    super.key,
    this.eventId,
    this.initialDate,
  });

  final String? eventId;
  final DateTime? initialDate;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
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

    final formNotifier = ref.read(eventFormProvider.notifier);
    if (widget.eventId != null) {
      await formNotifier.initializeForEdit(widget.eventId!);
    } else {
      formNotifier.initializeForNew(initialDate: widget.initialDate);
    }

    final state = ref.read(eventFormProvider);
    _titleController.text = state.title;
    _descriptionController.text = state.description;

    _isInitialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(eventFormProvider);
    final formNotifier = ref.read(eventFormProvider.notifier);
    final categoriesAsync = ref.watch(categoryRepositoryProvider).getAll();

    return Scaffold(
      appBar: AppBar(
        title: Text(formState.isEditMode ? 'Edit Event' : 'New Event'),
        actions: [
          TextButton(
            onPressed: formState.isSaving || !formState.isValid
                ? null
                : () async {
                    final success = await formNotifier.save();
                    if (success && context.mounted) {
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
              labelText: 'Title *',
              border: OutlineInputBorder(),
              hintText: 'Enter event title',
            ),
            onChanged: formNotifier.updateTitle,
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              hintText: 'Enter event description',
            ),
            maxLines: 4,
            onChanged: formNotifier.updateDescription,
          ),
          const SizedBox(height: 16),

          // Category dropdown
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
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No category'),
                  ),
                  ...categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(int.parse('0xFF${category.colourHex}')),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(category.name),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: formNotifier.updateCategory,
              );
            },
          ),

          const SizedBox(height: 32),

          // Timing Section
          Text(
            'Timing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // Event Type segmented button
          Text(
            'Event Type',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<TimingType>(
            segments: const [
              ButtonSegment<TimingType>(
                value: TimingType.fixed,
                label: Text('Fixed Time'),
                icon: Icon(Icons.schedule),
              ),
              ButtonSegment<TimingType>(
                value: TimingType.flexible,
                label: Text('Flexible'),
                icon: Icon(Icons.timelapse),
              ),
            ],
            selected: {formState.timingType},
            onSelectionChanged: (Set<TimingType> selected) {
              formNotifier.updateTimingType(selected.first);
            },
          ),
          const SizedBox(height: 24),

          // Fixed Time fields
          if (formState.timingType == TimingType.fixed) ...[
            Text(
              'Start',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: formState.startDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        formNotifier.updateStartDate(date);
                      }
                    },
                    child: Text(
                      formState.startDate != null
                          ? DateFormat.yMMMd().format(formState.startDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: formState.startTime != null
                            ? material.TimeOfDay(
                                hour: formState.startTime!.hour,
                                minute: formState.startTime!.minute,
                              )
                            : material.TimeOfDay.now(),
                      );
                      if (time != null) {
                        formNotifier.updateStartTime(
                          TimeOfDay(hour: time.hour, minute: time.minute),
                        );
                      }
                    },
                    child: Text(
                      formState.startTime != null
                          ? '${formState.startTime!.hour.toString().padLeft(2, '0')}:${formState.startTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select Time',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'End',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: formState.endDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        formNotifier.updateEndDate(date);
                      }
                    },
                    child: Text(
                      formState.endDate != null
                          ? DateFormat.yMMMd().format(formState.endDate!)
                          : 'Select Date',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: formState.endTime != null
                            ? material.TimeOfDay(
                                hour: formState.endTime!.hour,
                                minute: formState.endTime!.minute,
                              )
                            : material.TimeOfDay.now(),
                      );
                      if (time != null) {
                        formNotifier.updateEndTime(
                          TimeOfDay(hour: time.hour, minute: time.minute),
                        );
                      }
                    },
                    child: Text(
                      formState.endTime != null
                          ? '${formState.endTime!.hour.toString().padLeft(2, '0')}:${formState.endTime!.minute.toString().padLeft(2, '0')}'
                          : 'Select Time',
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Flexible fields
          if (formState.timingType == TimingType.flexible) ...[
            Text(
              'Duration',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: formState.durationHours,
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(24, (index) {
                      return DropdownMenuItem(
                        value: index,
                        child: Text('$index hr'),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        formNotifier.updateDurationHours(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: formState.durationMinutes,
                    decoration: const InputDecoration(
                      labelText: 'Minutes',
                      border: OutlineInputBorder(),
                    ),
                    items: [0, 15, 30, 45].map((minutes) {
                      return DropdownMenuItem(
                        value: minutes,
                        child: Text('$minutes min'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        formNotifier.updateDurationMinutes(value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
