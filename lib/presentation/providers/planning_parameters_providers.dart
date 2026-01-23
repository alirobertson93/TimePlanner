import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/goal.dart';
import '../../scheduler/strategies/scheduling_strategy.dart';
import '../../scheduler/strategies/balanced_strategy.dart';
import '../../scheduler/strategies/front_loaded_strategy.dart';
import '../../scheduler/strategies/max_free_time_strategy.dart';
import '../../scheduler/strategies/least_disruption_strategy.dart';

part 'planning_parameters_providers.g.dart';

/// Enum for available scheduling strategies
enum StrategyType {
  balanced,
  frontLoaded,
  maxFreeTime,
  leastDisruption,
}

/// State class for planning parameters (date range and goals)
class PlanningParametersState {
  const PlanningParametersState({
    this.startDate,
    this.endDate,
    this.selectedGoals = const [],
  });

  /// Start date of the planning window
  final DateTime? startDate;

  /// End date of the planning window
  final DateTime? endDate;

  /// Goals selected for this planning session
  final List<Goal> selectedGoals;

  PlanningParametersState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<Goal>? selectedGoals,
  }) {
    return PlanningParametersState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedGoals: selectedGoals ?? this.selectedGoals,
    );
  }

  /// Check if the date range is valid
  bool get isDateRangeValid {
    return startDate != null && endDate != null && !endDate!.isBefore(startDate!);
  }

  /// Get the number of days in the planning window
  int get daysInWindow {
    if (startDate == null || endDate == null) return 0;
    return endDate!.difference(startDate!).inDays + 1;
  }
}

/// Provider for planning parameters (date range and goals selection)
@riverpod
class PlanningParameters extends _$PlanningParameters {
  @override
  PlanningParametersState build() {
    return const PlanningParametersState();
  }

  /// Initialize with default values (next week)
  void initialize() {
    final now = DateTime.now();
    final nextMonday = _getNextMonday(now);
    final nextSunday = nextMonday.add(const Duration(days: 6));

    state = PlanningParametersState(
      startDate: nextMonday,
      endDate: nextSunday,
      selectedGoals: [],
    );
  }

  /// Get next Monday from a given date
  DateTime _getNextMonday(DateTime date) {
    final daysUntilMonday = (DateTime.monday - date.weekday + 7) % 7;
    final days = daysUntilMonday == 0 ? 7 : daysUntilMonday;
    return DateTime(date.year, date.month, date.day + days);
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

  /// Reset to initial state
  void reset() {
    state = const PlanningParametersState();
    initialize();
  }
}

/// Provider for scheduling strategy selection (standalone)
@riverpod
class SchedulingStrategySelection extends _$SchedulingStrategySelection {
  @override
  StrategyType build() {
    return StrategyType.balanced;
  }

  /// Update the selected strategy
  void updateStrategy(StrategyType strategy) {
    state = strategy;
  }

  /// Get the scheduling strategy instance
  SchedulingStrategy getStrategyInstance() {
    switch (state) {
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

  /// Reset to default strategy
  void reset() {
    state = StrategyType.balanced;
  }
}
