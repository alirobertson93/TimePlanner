import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../scheduler/event_scheduler.dart';
import '../../scheduler/models/schedule_request.dart';
import '../../scheduler/models/schedule_result.dart';
import '../../core/utils/date_utils.dart';
import 'repository_providers.dart';
import 'planning_parameters_providers.dart';
import 'error_handler_provider.dart';

part 'schedule_generation_providers.g.dart';

/// State class for schedule generation
class ScheduleGenerationState {
  const ScheduleGenerationState({
    this.isGenerating = false,
    this.scheduleResult,
    this.error,
  });

  /// Whether a schedule is currently being generated
  final bool isGenerating;

  /// The generated schedule result
  final ScheduleResult? scheduleResult;

  /// Error message if generation failed
  final String? error;

  ScheduleGenerationState copyWith({
    bool? isGenerating,
    ScheduleResult? scheduleResult,
    String? error,
  }) {
    return ScheduleGenerationState(
      isGenerating: isGenerating ?? this.isGenerating,
      scheduleResult: scheduleResult ?? this.scheduleResult,
      error: error,
    );
  }

  /// Check if schedule generation was successful
  bool get hasResult => scheduleResult != null;
}

/// Provider for schedule generation (async computation)
@riverpod
class ScheduleGeneration extends _$ScheduleGeneration {
  @override
  ScheduleGenerationState build() {
    return const ScheduleGenerationState();
  }

  /// Generate the schedule using current parameters and strategy
  Future<void> generateSchedule() async {
    final params = ref.read(planningParametersProvider);
    final strategyNotifier = ref.read(schedulingStrategySelectionProvider.notifier);
    
    if (params.startDate == null || params.endDate == null) {
      state = state.copyWith(error: 'Please select a date range');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    try {
      // Get events from repository
      final eventRepository = ref.read(eventRepositoryProvider);
      final windowStart = DateTimeUtils.startOfDay(params.startDate!);
      final windowEnd = DateTimeUtils.endOfDay(params.endDate!);
      
      final allEvents = await eventRepository.getEventsInRange(windowStart, windowEnd);

      // Separate fixed and flexible events
      final fixedEvents = allEvents.where((e) => e.isFixed).toList();
      final flexibleEvents = allEvents.where((e) => !e.isFixed).toList();

      // Get the appropriate strategy
      final strategy = strategyNotifier.getStrategyInstance();

      // Create schedule request
      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: fixedEvents,
        flexibleEvents: flexibleEvents,
        goals: params.selectedGoals,
        strategy: strategy,
      );

      // Run scheduler
      final scheduler = EventScheduler();
      final result = scheduler.schedule(request);

      state = state.copyWith(
        isGenerating: false,
        scheduleResult: result,
      );
    } catch (e, stackTrace) {
      final errorHandler = ref.read(errorHandlerProvider);
      final message = errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        operationContext: 'generating schedule',
      );
      state = state.copyWith(
        isGenerating: false,
        error: message,
      );
    }
  }

  /// Accept the generated schedule (save scheduled events)
  Future<bool> acceptSchedule() async {
    if (state.scheduleResult == null) return false;

    try {
      final eventRepository = ref.read(eventRepositoryProvider);
      
      // Update events with their scheduled times
      for (final scheduledEvent in state.scheduleResult!.scheduledEvents) {
        final event = scheduledEvent.event;
        
        // Only update flexible events that got scheduled times
        if (!event.isFixed) {
          final updatedEvent = event.copyWith(
            startTime: scheduledEvent.scheduledStart,
            endTime: scheduledEvent.scheduledEnd,
          );
          await eventRepository.save(updatedEvent);
        }
      }

      return true;
    } catch (e, stackTrace) {
      final errorHandler = ref.read(errorHandlerProvider);
      final message = errorHandler.handleError(
        e,
        stackTrace: stackTrace,
        operationContext: 'saving schedule',
      );
      state = state.copyWith(error: message);
      return false;
    }
  }

  /// Reset the generation state
  void reset() {
    state = const ScheduleGenerationState();
  }

  /// Clear any error
  void clearError() {
    state = state.copyWith(error: null);
  }
}
