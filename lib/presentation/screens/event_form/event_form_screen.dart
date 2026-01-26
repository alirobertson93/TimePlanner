import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../providers/event_form_providers.dart' as form_providers;
import '../../providers/repository_providers.dart';
import '../../providers/error_handler_provider.dart';
import '../../providers/series_providers.dart';
import '../../widgets/people_picker.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/recurrence_picker.dart';
import '../../widgets/travel_time_prompt.dart';
import '../../widgets/series_prompt_dialog.dart';
import '../../widgets/edit_scope_dialog.dart';
import '../../../domain/enums/timing_type.dart';
import '../../../domain/enums/scheduling_preference_strength.dart';
import '../../../domain/enums/edit_scope.dart';
import '../../../domain/entities/scheduling_constraint.dart';

// Type aliases for clarity
typedef FlutterTimeOfDay = TimeOfDay;

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

    final formNotifier = ref.read(form_providers.eventFormProvider.notifier);
    if (widget.eventId != null) {
      await formNotifier.initializeForEdit(widget.eventId!);
    } else {
      formNotifier.initializeForNew(initialDate: widget.initialDate);
    }

    final state = ref.read(form_providers.eventFormProvider);
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
    final formState = ref.watch(form_providers.eventFormProvider);
    final formNotifier = ref.read(form_providers.eventFormProvider.notifier);
    final categoriesAsync = ref.watch(categoryRepositoryProvider).getAll();

    return Scaffold(
      appBar: AppBar(
        title: Text(formState.isEditMode ? 'Edit Activity' : 'New Activity'),
        actions: [
          Semantics(
            button: true,
            label: formState.isSaving
                ? 'Saving activity'
                : (formState.isEditMode
                    ? 'Save changes to activity'
                    : 'Save new activity'),
            enabled: !formState.isSaving && formState.isValid,
            child: TextButton(
              onPressed: formState.isSaving || !formState.isValid
                  ? null
                  : () => _saveWithSeriesIntegration(
                        context,
                        ref,
                        formState,
                        formNotifier,
                      ),
              child: formState.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
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
          Semantics(
            textField: true,
            label: 'Activity title, required field',
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
                hintText: 'Enter activity title',
              ),
              onChanged: formNotifier.updateTitle,
            ),
          ),
          const SizedBox(height: 16),

          // Description field
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              hintText: 'Enter activity description',
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
                              color: _parseColor(category.colourHex),
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

          // Activity Type segmented button
          Semantics(
            label: 'Activity type selection',
            child: Text(
              'Activity Type',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            container: true,
            label:
                'Select activity type: ${formState.timingType == TimingType.fixed ? "Fixed time selected" : "Flexible selected"}',
            child: SegmentedButton<TimingType>(
              segments: const [
                ButtonSegment<TimingType>(
                  value: TimingType.fixed,
                  label: Text('Fixed Time'),
                  icon: Icon(Icons.schedule, semanticLabel: 'Fixed time activity'),
                ),
                ButtonSegment<TimingType>(
                  value: TimingType.flexible,
                  label: Text('Flexible'),
                  icon: Icon(Icons.timelapse, semanticLabel: 'Flexible activity'),
                ),
              ],
              selected: {formState.timingType},
              onSelectionChanged: (Set<TimingType> selected) {
                formNotifier.updateTimingType(selected.first);
              },
            ),
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
                            ? FlutterTimeOfDay(
                                hour: formState.startTime!.hour,
                                minute: formState.startTime!.minute,
                              )
                            : FlutterTimeOfDay.now(),
                      );
                      if (time != null) {
                        formNotifier.updateStartTime(
                          form_providers.TimeOfDay(
                              hour: time.hour, minute: time.minute),
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
                            ? FlutterTimeOfDay(
                                hour: formState.endTime!.hour,
                                minute: formState.endTime!.minute,
                              )
                            : FlutterTimeOfDay.now(),
                      );
                      if (time != null) {
                        formNotifier.updateEndTime(
                          form_providers.TimeOfDay(
                              hour: time.hour, minute: time.minute),
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

          const SizedBox(height: 32),

          // People Section
          Text(
            'People',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // People Picker
          PeoplePicker(
            selectedPeopleIds: formState.selectedPeopleIds,
            onPeopleChanged: formNotifier.updateSelectedPeople,
          ),

          const SizedBox(height: 32),

          // Location Section
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // Location Picker
          LocationPicker(
            selectedLocationId: formState.locationId,
            onLocationChanged: formNotifier.updateLocation,
          ),

          const SizedBox(height: 32),

          // Recurrence Section
          Text(
            'Recurrence',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Divider(height: 16),
          const SizedBox(height: 16),

          // Recurrence Picker
          RecurrencePicker(
            selectedRecurrenceRuleId: formState.recurrenceRuleId,
            onRecurrenceChanged: formNotifier.updateRecurrence,
          ),

          const SizedBox(height: 32),

          // Scheduling Options Section (collapsible)
          _buildSchedulingOptionsSection(context, formState, formNotifier),
        ],
      ),
    );
  }

  /// Builds the Scheduling Options section with constraint toggles
  Widget _buildSchedulingOptionsSection(
    BuildContext context,
    form_providers.EventFormState formState,
    dynamic formNotifier,
  ) {
    return ExpansionTile(
      initiallyExpanded: false,
      tilePadding: EdgeInsets.zero,
      title: Text(
        'Scheduling Options',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        'Advanced settings for the scheduler',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
      ),
      leading: Icon(
        Icons.tune,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Divider(height: 16),
        const SizedBox(height: 8),
        if (formState.timingType == TimingType.fixed) ...[
          // Fixed event: Allow app to suggest changes
          SwitchListTile(
            value: formState.appCanMove,
            onChanged: (value) => formNotifier.updateAppCanMove(value),
            title: const Text('Allow app to suggest changes'),
            subtitle: const Text(
              'Let the scheduler suggest moving this if there are conflicts',
            ),
            secondary: const Icon(Icons.swap_horiz),
            contentPadding: EdgeInsets.zero,
          ),
        ] else ...[
          // Flexible activity: Lock this time toggle
          // Only show if the event is being edited AND has a scheduled time.
          // New flexible events don't have times yet (scheduler places them),
          // so there's nothing to lock. Existing events that have been scheduled
          // can be locked to prevent the scheduler from moving them.
          if (formState.isEditMode && formState.hasScheduledTime) ...[
            SwitchListTile(
              value: formState.isUserLocked,
              onChanged: (value) => formNotifier.updateIsUserLocked(value),
              title: const Text('Lock this time'),
              subtitle: const Text(
                'Keep this event at its scheduled time',
              ),
              secondary: Icon(
                formState.isUserLocked ? Icons.lock : Icons.lock_open,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
          ],
          // Flexible activity: Allow duration changes
          SwitchListTile(
            value: formState.appCanResize,
            onChanged: (value) => formNotifier.updateAppCanResize(value),
            title: const Text('Allow duration changes'),
            subtitle: const Text(
              'Let the scheduler shorten this if needed',
            ),
            secondary: const Icon(Icons.expand),
            contentPadding: EdgeInsets.zero,
          ),
        ],
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        // Time Constraints Section (for flexible events)
        if (formState.timingType == TimingType.flexible)
          _buildTimeConstraintsSection(context, formState, formNotifier),
        const SizedBox(height: 16),
      ],
    );
  }

  /// Builds the time constraints section for flexible events
  Widget _buildTimeConstraintsSection(
    BuildContext context,
    form_providers.EventFormState formState,
    dynamic formNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle for time constraints
        SwitchListTile(
          value: formState.hasTimeConstraint,
          onChanged: (value) => formNotifier.updateHasTimeConstraint(value),
          title: const Text('Time Restrictions'),
          subtitle: const Text(
            'Restrict when this event can be scheduled',
          ),
          secondary: const Icon(Icons.access_time),
          contentPadding: EdgeInsets.zero,
        ),
        
        if (formState.hasTimeConstraint) ...[
          const SizedBox(height: 16),
          // Not Before Time picker
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not Before',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _minutesToTimeOfDay(
                            formState.notBeforeTime,
                            defaultHour: 7,
                          ),
                        );
                        if (time != null) {
                          formNotifier.updateNotBeforeTime(time.hour * 60 + time.minute);
                        }
                      },
                      child: Text(
                        formState.notBeforeTime != null
                            ? SchedulingConstraint.formatTimeOfDay(formState.notBeforeTime!)
                            : 'Set time',
                      ),
                    ),
                    if (formState.notBeforeTime != null)
                      TextButton(
                        onPressed: () => formNotifier.updateNotBeforeTime(null),
                        child: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not After',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _minutesToTimeOfDay(
                            formState.notAfterTime,
                            defaultHour: 15,
                          ),
                        );
                        if (time != null) {
                          formNotifier.updateNotAfterTime(time.hour * 60 + time.minute);
                        }
                      },
                      child: Text(
                        formState.notAfterTime != null
                            ? SchedulingConstraint.formatTimeOfDay(formState.notAfterTime!)
                            : 'Set time',
                      ),
                    ),
                    if (formState.notAfterTime != null)
                      TextButton(
                        onPressed: () => formNotifier.updateNotAfterTime(null),
                        child: const Text('Clear', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Preference Strength dropdown
          DropdownButtonFormField<SchedulingPreferenceStrength>(
            value: formState.timeConstraintStrength,
            decoration: const InputDecoration(
              labelText: 'Constraint Strength',
              border: OutlineInputBorder(),
              helperText: 'How strictly should the scheduler follow this rule?',
            ),
            items: SchedulingPreferenceStrength.values.map((strength) {
              return DropdownMenuItem<SchedulingPreferenceStrength>(
                value: strength,
                child: Row(
                  children: [
                    Icon(
                      strength == SchedulingPreferenceStrength.locked
                          ? Icons.lock
                          : strength == SchedulingPreferenceStrength.strong
                              ? Icons.priority_high
                              : Icons.low_priority,
                      size: 20,
                      color: strength == SchedulingPreferenceStrength.locked
                          ? Colors.red
                          : strength == SchedulingPreferenceStrength.strong
                              ? Colors.orange
                              : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(strength.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                formNotifier.updateTimeConstraintStrength(value);
              }
            },
          ),
          const SizedBox(height: 8),
          // Explanation card
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
                    formState.timeConstraintStrength == SchedulingPreferenceStrength.locked
                        ? 'Locked: Scheduler MUST respect this constraint.'
                        : formState.timeConstraintStrength == SchedulingPreferenceStrength.strong
                            ? 'Strong: Scheduler will try hard to respect this.'
                            : 'Weak: Scheduler may ignore if needed for other priorities.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Converts minutes from midnight to FlutterTimeOfDay
  /// If minutesFromMidnight is null, returns default time
  FlutterTimeOfDay _minutesToTimeOfDay(int? minutesFromMidnight, {int defaultHour = 9}) {
    if (minutesFromMidnight != null) {
      return FlutterTimeOfDay(
        hour: minutesFromMidnight ~/ 60,
        minute: minutesFromMidnight % 60,
      );
    }
    return FlutterTimeOfDay(hour: defaultHour, minute: 0);
  }

  /// Safely parse color hex string to Color
  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) {
      return Colors.grey; // Default color
    }

    try {
      // Remove any non-hex characters
      final cleanHex = hexString.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
      if (cleanHex.length == 6) {
        return Color(int.parse('0xFF$cleanHex'));
      }
    } catch (e) {
      // Return default color on parse error
    }
    return Colors.grey;
  }

  /// Handles the save operation with series integration.
  /// 
  /// For new activities:
  /// - Checks for matching series and prompts user to join or stay standalone
  /// - If user chooses to join, sets the seriesId before saving
  /// 
  /// For existing activities in a series:
  /// - Prompts user to select edit scope (this only, all in series, this and future)
  /// - Applies the edit according to the selected scope
  Future<void> _saveWithSeriesIntegration(
    BuildContext context,
    WidgetRef ref,
    form_providers.EventFormState formState,
    form_providers.EventForm formNotifier,
  ) async {
    final seriesMatchingService = ref.read(seriesMatchingServiceProvider);
    final seriesEditService = ref.read(seriesEditServiceProvider);

    // Generate ID for new activities
    final activityId = formState.id ?? const Uuid().v4();

    // For editing existing activities that are in a series, show edit scope dialog
    if (formState.isEditMode && formState.isInSeries) {
      // Get the series count
      final seriesCount = await seriesMatchingService.getSeriesCount(formState.seriesId!);
      
      if (seriesCount > 1 && context.mounted) {
        final scope = await showEditScopeDialog(
          context,
          activityTitle: formState.title.isNotEmpty 
              ? formState.title 
              : 'Activity',
          seriesCount: seriesCount,
          isRecurring: formState.isRecurring,
        );

        if (scope == null) {
          // User cancelled
          return;
        }

        if (scope == EditScope.thisOnly) {
          // Just save this activity normally
          final success = await formNotifier.save();
          if (success && context.mounted) {
            await _handlePostSave(context, ref, formState);
          }
        } else {
          // Apply edits to multiple activities
          final activity = formState.buildActivity(activityId: formState.id!);
          final updates = <String, dynamic>{
            'name': formState.title.trim().isEmpty ? null : formState.title.trim(),
            'description': formState.description.trim().isEmpty ? null : formState.description.trim(),
            'categoryId': formState.categoryId,
            'locationId': formState.locationId,
          };

          // First save this activity
          final success = await formNotifier.save();
          if (!success) return;

          // Then apply to other activities in series based on scope
          await seriesEditService.updateWithScope(
            activity: activity,
            updates: updates,
            scope: scope,
          );

          if (context.mounted) {
            await _handlePostSave(context, ref, formState);
          }
        }
        return;
      }
    }

    // For new activities (not editing), check for matching series
    if (!formState.isEditMode) {
      final activity = formState.buildActivity(activityId: activityId);
      final matchingSeries = await seriesMatchingService.findMatchingSeries(activity);

      if (matchingSeries.isNotEmpty && context.mounted) {
        // Show series prompt dialog with the best match
        final addToSeries = await showSeriesPromptDialog(
          context,
          matchingSeries: matchingSeries.first,
        );

        if (addToSeries == true) {
          // User chose to add to series
          formNotifier.updateSeriesId(matchingSeries.first.id);
        }
        // If addToSeries is false or null, continue without series
      }
    }

    // Save the activity
    final success = await formNotifier.save();
    if (success && context.mounted) {
      await _handlePostSave(context, ref, formState);
    }
  }

  /// Handles post-save operations (travel time check, navigation)
  Future<void> _handlePostSave(
    BuildContext context,
    WidgetRef ref,
    form_providers.EventFormState formState,
  ) async {
    // Check for missing travel times if the event has a location
    if (formState.locationId != null) {
      await _checkAndPromptForTravelTimes(
        context,
        ref,
        formState.locationId!,
        formState.startDate,
      );
    }
    if (context.mounted) {
      context.pop();
    }
  }

  /// Checks for adjacent events with different locations and prompts for travel time if needed
  Future<void> _checkAndPromptForTravelTimes(
    BuildContext context,
    WidgetRef ref,
    String currentLocationId,
    DateTime? eventDate,
  ) async {
    if (eventDate == null) return;

    try {
      final eventRepo = ref.read(eventRepositoryProvider);
      final travelTimeRepo = ref.read(travelTimePairRepositoryProvider);

      // Get events for the same day (end of day is last microsecond of the day)
      final startOfDay =
          DateTime(eventDate.year, eventDate.month, eventDate.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      final dayEvents = await eventRepo.getEventsInRange(startOfDay, endOfDay);

      // Filter events with locations and sort by time
      final eventsWithLocations = dayEvents
          .where((e) => e.locationId != null && e.startTime != null)
          .toList()
        ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

      if (eventsWithLocations.length < 2) return;

      // Check for adjacent events with different locations
      final checkedPairs = <String>{};
      for (int i = 0; i < eventsWithLocations.length - 1; i++) {
        final currentEvent = eventsWithLocations[i];
        final nextEvent = eventsWithLocations[i + 1];

        // Skip if same location
        if (currentEvent.locationId == nextEvent.locationId) continue;

        // Create canonical key to avoid duplicate checks
        final ids = [currentEvent.locationId!, nextEvent.locationId!]..sort();
        final pairKey = '${ids[0]}_${ids[1]}';

        if (checkedPairs.contains(pairKey)) continue;
        checkedPairs.add(pairKey);

        // Check if travel time exists
        final existingTravelTime =
            await travelTimeRepo.getByLocationPairBidirectional(
          currentEvent.locationId!,
          nextEvent.locationId!,
        );

        if (existingTravelTime == null && context.mounted) {
          // Prompt user for travel time
          await TravelTimePromptDialog.show(
            context: context,
            fromLocationId: currentEvent.locationId!,
            toLocationId: nextEvent.locationId!,
          );
        }
      }
    } catch (e) {
      // Don't block the save operation if travel time check fails
      ref.read(errorHandlerProvider).handleWarning(
        e,
        context: 'checking travel times',
      );
    }
  }
}
