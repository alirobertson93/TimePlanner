import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/goal.dart';
import '../../scheduler/event_scheduler.dart';
import '../../scheduler/models/schedule_request.dart';
import '../../scheduler/models/schedule_result.dart';
import '../../scheduler/strategies/balanced_strategy.dart';
import '../../scheduler/strategies/front_loaded_strategy.dart';
import '../../scheduler/strategies/max_free_time_strategy.dart';
import '../../scheduler/strategies/least_disruption_strategy.dart';
import '../../scheduler/strategies/scheduling_strategy.dart';
import '../../core/utils/date_utils.dart';
import 'repository_providers.dart';

part 'planning_wizard_providers.g.dart';

/// Enum for available scheduling strategies
enum StrategyType {
  balanced,
  frontLoaded,
  maxFreeTime,
  leastDisruption,
}

/// State class for the planning wizard
class PlanningWizardState {
  const PlanningWizardState({
    this.currentStep = 0,
    this.startDate,
    this.endDate,
    this.selectedGoals = const [],
    this.selectedStrategy = StrategyType.balanced,
    this.isGenerating = false,
    this.scheduleResult,
    this.error,
  });

  /// Current step in the wizard (0-3)
  final int currentStep;

  /// Start date of the planning window
  final DateTime? startDate;

  /// End date of the planning window
  final DateTime? endDate;

  /// Goals selected for this planning session
  final List<Goal> selectedGoals;

  /// Selected scheduling strategy
  final StrategyType selectedStrategy;

  /// Whether a schedule is currently being generated
  final bool isGenerating;

  /// The generated schedule result
  final ScheduleResult? scheduleResult;

  /// Error message if generation failed
  final String? error;

  PlanningWizardState copyWith({
    int? currentStep,
    DateTime? startDate,
    DateTime? endDate,
    List<Goal>? selectedGoals,
    StrategyType? selectedStrategy,
    bool? isGenerating,
    ScheduleResult? scheduleResult,
    String? error,
  }) {
    return PlanningWizardState(
      currentStep: currentStep ?? this.currentStep,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      selectedStrategy: selectedStrategy ?? this.selectedStrategy,
      isGenerating: isGenerating ?? this.isGenerating,
      scheduleResult: scheduleResult ?? this.scheduleResult,
      error: error,
    );
  }

  /// Check if the current step is valid
  bool get isCurrentStepValid {
    switch (currentStep) {
      case 0: // Date range selection
        // Allow same-day planning (startDate == endDate) or longer ranges
        return startDate != null && endDate != null && !endDate!.isBefore(startDate!);
      case 1: // Goals review
        return true; // Goals are optional
      case 2: // Strategy selection
        return true; // Always have a default strategy
      case 3: // Review
        return scheduleResult != null;
      default:
        return false;
    }
  }

  /// Check if can proceed to next step
  bool get canProceed {
    if (currentStep >= 3) return false;
    if (currentStep == 2 && isGenerating) return false;
    return isCurrentStepValid;
  }

  /// Check if can go back
  bool get canGoBack => currentStep > 0 && !isGenerating;

  /// Get the number of days in the planning window
  int get daysInWindow {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }
}

/// Provider for the planning wizard state
@riverpod
class PlanningWizard extends _$PlanningWizard {
  @override
  PlanningWizardState build() {
    return const PlanningWizardState();
  }

  /// Initialize the wizard with default values
  void initialize() {
    final now = DateTime.now();
    // Default to next week (Monday to Sunday)
    final nextMonday = _getNextMonday(now);
    final nextSunday = nextMonday.add(const Duration(days: 6));

    state = PlanningWizardState(
      currentStep: 0,
      startDate: nextMonday,
      endDate: nextSunday,
      selectedGoals: [],
      selectedStrategy: StrategyType.balanced,
    );
  }

  /// Get next Monday from a given date
  DateTime _getNextMonday(DateTime date) {
    final daysUntilMonday = (DateTime.monday - date.weekday + 7) % 7;
    // If today is Monday, get next Monday
    final days = daysUntilMonday == 0 ? 7 : daysUntilMonday;
    return DateTime(date.year, date.month, date.day + days);
  }

  /// Move to the next step
  void nextStep() {
    if (state.canProceed) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Move to the previous step
  void previousStep() {
    if (state.canGoBack) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Update the start date
  void updateStartDate(DateTime date) {
    state = state.copyWith(startDate: date);
    // If end date is before start date, update end date
    if (state.endDate != null && state.endDate!.isBefore(date)) {
      state = state.copyWith(endDate: date.add(const Duration(days: 6)));
    }
  }

  /// Update the end date
  void updateEndDate(DateTime date) {
    state = state.copyWith(endDate: date);
  }

  /// Toggle a goal selection
  void toggleGoal(Goal goal) {
    final currentGoals = List<Goal>.from(state.selectedGoals);
    final index = currentGoals.indexWhere((g) => g.id == goal.id);
    
    if (index >= 0) {
      currentGoals.removeAt(index);
    } else {
      currentGoals.add(goal);
    }
    
    state = state.copyWith(selectedGoals: currentGoals);
  }

  /// Select all goals
  void selectAllGoals(List<Goal> goals) {
    state = state.copyWith(selectedGoals: goals);
  }

  /// Deselect all goals
  void deselectAllGoals() {
    state = state.copyWith(selectedGoals: []);
  }

  /// Update the selected strategy
  void updateStrategy(StrategyType strategy) {
    state = state.copyWith(selectedStrategy: strategy);
  }

  /// Generate the schedule
  Future<void> generateSchedule() async {
    if (state.startDate == null || state.endDate == null) {
      state = state.copyWith(error: 'Please select a date range');
      return;
    }

    state = state.copyWith(isGenerating: true, error: null);

    try {
      // Get events from repository
      final eventRepository = ref.read(eventRepositoryProvider);
      final windowStart = DateTimeUtils.startOfDay(state.startDate!);
      final windowEnd = DateTimeUtils.endOfDay(state.endDate!);
      
      final allEvents = await eventRepository.getEventsInRange(windowStart, windowEnd);

      // Separate fixed and flexible events
      final fixedEvents = allEvents.where((e) => e.isFixed).toList();
      final flexibleEvents = allEvents.where((e) => !e.isFixed).toList();

      // Get the appropriate strategy
      final strategy = _getStrategy(state.selectedStrategy);

      // Create schedule request
      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: fixedEvents,
        flexibleEvents: flexibleEvents,
        goals: state.selectedGoals,
        strategy: strategy,
      );

      // Run scheduler
      final scheduler = EventScheduler();
      final result = scheduler.schedule(request);

      state = state.copyWith(
        isGenerating: false,
        scheduleResult: result,
        currentStep: 3, // Move to review step
      );
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        error: 'Failed to generate schedule: $e',
      );
    }
  }

  /// Get the scheduling strategy instance
  SchedulingStrategy _getStrategy(StrategyType type) {
    switch (type) {
      case StrategyType.balanced:
        return BalancedStrategy();
      case StrategyType.frontLoaded:
        return FrontLoadedStrategy();
      case StrategyType.maxFreeTime:
        return MaxFreeTimeStrategy();
      case StrategyType.leastDisruption:
        return LeastDisruptionStrategy();
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
    } catch (e) {
      state = state.copyWith(error: 'Failed to save schedule: $e');
      return false;
    }
  }

  /// Reset the wizard
  void reset() {
    state = const PlanningWizardState();
    initialize();
  }
}

/// Provider for all active goals
@riverpod
Future<List<Goal>> allGoals(Ref ref) async {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return goalRepository.getAll();
}
