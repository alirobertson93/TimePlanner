import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/timing_type.dart';
import '../../domain/enums/event_status.dart';
import 'repository_providers.dart';
import 'error_handler_provider.dart';

part 'event_form_providers.g.dart';

/// State class for the event form
class EventFormState {
  const EventFormState({
    this.id,
    this.title = '',
    this.description = '',
    this.categoryId,
    this.locationId,
    this.recurrenceRuleId,
    this.timingType = TimingType.fixed,
    this.startDate,
    this.startTime,
    this.endDate,
    this.endTime,
    this.durationHours = 1,
    this.durationMinutes = 0,
    this.selectedPeopleIds = const [],
    this.isEditMode = false,
    this.isSaving = false,
    this.error,
  });

  final String? id;
  final String title;
  final String description;
  final String? categoryId;
  final String? locationId;
  final String? recurrenceRuleId;
  final TimingType timingType;
  final DateTime? startDate;
  final TimeOfDay? startTime;
  final DateTime? endDate;
  final TimeOfDay? endTime;
  final int durationHours;
  final int durationMinutes;
  final List<String> selectedPeopleIds;
  final bool isEditMode;
  final bool isSaving;
  final String? error;

  EventFormState copyWith({
    String? id,
    String? title,
    String? description,
    String? categoryId,
    String? locationId,
    String? recurrenceRuleId,
    TimingType? timingType,
    DateTime? startDate,
    TimeOfDay? startTime,
    DateTime? endDate,
    TimeOfDay? endTime,
    int? durationHours,
    int? durationMinutes,
    List<String>? selectedPeopleIds,
    bool? isEditMode,
    bool? isSaving,
    String? error,
  }) {
    return EventFormState(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      locationId: locationId ?? this.locationId,
      recurrenceRuleId: recurrenceRuleId ?? this.recurrenceRuleId,
      timingType: timingType ?? this.timingType,
      startDate: startDate ?? this.startDate,
      startTime: startTime ?? this.startTime,
      endDate: endDate ?? this.endDate,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      selectedPeopleIds: selectedPeopleIds ?? this.selectedPeopleIds,
      isEditMode: isEditMode ?? this.isEditMode,
      isSaving: isSaving ?? this.isSaving,
      error: error ?? this.error,
    );
  }

  /// Validates the form and returns error message if invalid
  String? validate() {
    if (title.trim().isEmpty) {
      return 'Title is required';
    }

    if (timingType == TimingType.fixed) {
      if (startDate == null || startTime == null || endDate == null || endTime == null) {
        return 'Start and end date/time are required for fixed events';
      }

      final start = DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        startTime!.hour,
        startTime!.minute,
      );

      final end = DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        endTime!.hour,
        endTime!.minute,
      );

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        return 'End time must be after start time';
      }
    } else {
      // Flexible event
      if (durationHours == 0 && durationMinutes == 0) {
        return 'Duration must be greater than 0';
      }
    }

    return null;
  }

  /// Checks if the form is valid
  bool get isValid => validate() == null;
}

/// Time of day helper class since we can't import flutter/material in providers.
/// This keeps the provider pure Dart and testable without Flutter dependencies,
/// maintaining separation of concerns in our clean architecture.
class TimeOfDay {
  const TimeOfDay({required this.hour, required this.minute});

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeOfDay &&
          runtimeType == other.runtimeType &&
          hour == other.hour &&
          minute == other.minute;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

/// Provider for the event form state
@riverpod
class EventForm extends _$EventForm {
  @override
  EventFormState build() {
    return const EventFormState();
  }

  /// Initialize form for creating a new event
  void initializeForNew({DateTime? initialDate}) {
    final now = initialDate ?? DateTime.now();
    final currentHour = now.hour;
    final nextHour = (currentHour + 1) % 24;

    state = EventFormState(
      startDate: now,
      startTime: TimeOfDay(hour: currentHour, minute: 0),
      endDate: now,
      endTime: TimeOfDay(hour: nextHour, minute: 0),
      timingType: TimingType.fixed,
      isEditMode: false,
    );
  }

  /// Initialize form for editing an existing event
  Future<void> initializeForEdit(String eventId) async {
    final repository = ref.read(eventRepositoryProvider);
    final eventPeopleRepository = ref.read(eventPeopleRepositoryProvider);
    final event = await repository.getById(eventId);

    if (event == null) {
      state = state.copyWith(error: 'Event not found');
      return;
    }

    // Load associated people
    final associatedPeople = await eventPeopleRepository.getPeopleForEvent(eventId);
    final peopleIds = associatedPeople.map((p) => p.id).toList();

    state = EventFormState(
      id: event.id,
      title: event.name,
      description: event.description ?? '',
      categoryId: event.categoryId,
      locationId: event.locationId,
      recurrenceRuleId: event.recurrenceRuleId,
      timingType: event.timingType,
      startDate: event.startTime,
      startTime: event.startTime != null
          ? TimeOfDay(hour: event.startTime!.hour, minute: event.startTime!.minute)
          : null,
      endDate: event.endTime,
      endTime: event.endTime != null
          ? TimeOfDay(hour: event.endTime!.hour, minute: event.endTime!.minute)
          : null,
      durationHours: event.duration?.inHours ?? 1,
      durationMinutes: event.duration?.inMinutes.remainder(60) ?? 0,
      selectedPeopleIds: peopleIds,
      isEditMode: true,
    );
  }

  /// Update form fields
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateCategory(String? categoryId) {
    state = state.copyWith(categoryId: categoryId);
  }

  void updateTimingType(TimingType type) {
    state = state.copyWith(timingType: type);
  }

  void updateStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
  }

  void updateStartTime(TimeOfDay time) {
    state = state.copyWith(startTime: time);
  }

  void updateEndDate(DateTime date) {
    state = state.copyWith(endDate: date);
  }

  void updateEndTime(TimeOfDay time) {
    state = state.copyWith(endTime: time);
  }

  void updateDurationHours(int hours) {
    state = state.copyWith(durationHours: hours);
  }

  void updateDurationMinutes(int minutes) {
    state = state.copyWith(durationMinutes: minutes);
  }

  void updateSelectedPeople(List<String> peopleIds) {
    state = state.copyWith(selectedPeopleIds: peopleIds);
  }

  void updateLocation(String? locationId) {
    state = state.copyWith(locationId: locationId);
  }

  void updateRecurrence(String? recurrenceRuleId) {
    state = state.copyWith(recurrenceRuleId: recurrenceRuleId);
  }

  /// Save the event
  Future<bool> save() async {
    final validationError = state.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return false;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final repository = ref.read(eventRepositoryProvider);
      final eventPeopleRepository = ref.read(eventPeopleRepositoryProvider);
      final now = DateTime.now();
      final uuid = const Uuid();

      // Get createdAt timestamp
      DateTime createdAt = now;
      if (state.isEditMode && state.id != null) {
        final existingEvent = await repository.getById(state.id!);
        if (existingEvent != null) {
          createdAt = existingEvent.createdAt;
        }
      }

      final eventId = state.id ?? uuid.v4();
      final event = Event(
        id: eventId,
        name: state.title.trim(),
        description: state.description.trim().isEmpty ? null : state.description.trim(),
        timingType: state.timingType,
        startTime: state.timingType == TimingType.fixed && state.startDate != null && state.startTime != null
            ? DateTime(
                state.startDate!.year,
                state.startDate!.month,
                state.startDate!.day,
                state.startTime!.hour,
                state.startTime!.minute,
              )
            : null,
        endTime: state.timingType == TimingType.fixed && state.endDate != null && state.endTime != null
            ? DateTime(
                state.endDate!.year,
                state.endDate!.month,
                state.endDate!.day,
                state.endTime!.hour,
                state.endTime!.minute,
              )
            : null,
        duration: state.timingType == TimingType.flexible
            ? Duration(hours: state.durationHours, minutes: state.durationMinutes)
            : null,
        categoryId: state.categoryId,
        locationId: state.locationId,
        recurrenceRuleId: state.recurrenceRuleId,
        status: EventStatus.pending,
        createdAt: createdAt,
        updatedAt: now,
      );

      await repository.save(event);

      // Save people associations
      try {
        await eventPeopleRepository.setPeopleForEvent(
          eventId: eventId,
          personIds: state.selectedPeopleIds,
        );
      } catch (peopleError, stackTrace) {
        // If people save fails, we still consider the event saved but log the error
        final errorHandler = ref.read(errorHandlerProvider);
        final message = errorHandler.handleError(
          peopleError,
          stackTrace: stackTrace,
          operationContext: 'saving event people associations',
          fallbackMessage: 'Event saved but failed to save people associations',
        );
        state = state.copyWith(
          isSaving: false,
          error: message,
        );
        return true; // Event was saved, just people associations failed
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e, stackTrace) {
      final errorHandler = ref.read(errorHandlerProvider);
      final message = errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        operationContext: 'saving event',
      );
      state = state.copyWith(
        isSaving: false,
        error: message,
      );
      return false;
    }
  }
}
