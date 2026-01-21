import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/goal.dart';
import '../../domain/enums/goal_type.dart';
import '../../domain/enums/goal_metric.dart';
import '../../domain/enums/goal_period.dart';
import '../../domain/enums/debt_strategy.dart';
import 'repository_providers.dart';

part 'goal_form_providers.g.dart';

/// State class for the goal form
class GoalFormState {
  const GoalFormState({
    this.id,
    this.title = '',
    this.type = GoalType.category,
    this.metric = GoalMetric.hours,
    this.targetValue = 10,
    this.period = GoalPeriod.week,
    this.categoryId,
    this.debtStrategy = DebtStrategy.ignore,
    this.isActive = true,
    this.isEditMode = false,
    this.isSaving = false,
    this.error,
  });

  final String? id;
  final String title;
  final GoalType type;
  final GoalMetric metric;
  final int targetValue;
  final GoalPeriod period;
  final String? categoryId;
  final DebtStrategy debtStrategy;
  final bool isActive;
  final bool isEditMode;
  final bool isSaving;
  final String? error;

  GoalFormState copyWith({
    String? id,
    String? title,
    GoalType? type,
    GoalMetric? metric,
    int? targetValue,
    GoalPeriod? period,
    String? categoryId,
    bool clearCategoryId = false,
    DebtStrategy? debtStrategy,
    bool? isActive,
    bool? isEditMode,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return GoalFormState(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      metric: metric ?? this.metric,
      targetValue: targetValue ?? this.targetValue,
      period: period ?? this.period,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      debtStrategy: debtStrategy ?? this.debtStrategy,
      isActive: isActive ?? this.isActive,
      isEditMode: isEditMode ?? this.isEditMode,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Validates the form and returns error message if invalid
  String? validate() {
    if (title.trim().isEmpty) {
      return 'Title is required';
    }

    if (targetValue <= 0) {
      return 'Target value must be greater than 0';
    }

    if (type == GoalType.category && categoryId == null) {
      return 'Please select a category for this goal';
    }

    return null;
  }

  /// Checks if the form is valid
  bool get isValid => validate() == null;

  /// Get display text for metric
  String get metricDisplayText {
    switch (metric) {
      case GoalMetric.hours:
        return 'hours';
      case GoalMetric.events:
        return 'events';
      case GoalMetric.completions:
        return 'completions';
    }
  }

  /// Get display text for period
  String get periodDisplayText {
    switch (period) {
      case GoalPeriod.week:
        return 'per week';
      case GoalPeriod.month:
        return 'per month';
      case GoalPeriod.quarter:
        return 'per quarter';
      case GoalPeriod.year:
        return 'per year';
    }
  }
}

/// Provider for the goal form state
@riverpod
class GoalForm extends _$GoalForm {
  @override
  GoalFormState build() {
    return const GoalFormState();
  }

  /// Initialize form for creating a new goal
  void initializeForNew() {
    state = const GoalFormState(
      type: GoalType.category,
      metric: GoalMetric.hours,
      targetValue: 10,
      period: GoalPeriod.week,
      debtStrategy: DebtStrategy.ignore,
      isActive: true,
      isEditMode: false,
    );
  }

  /// Initialize form for editing an existing goal
  Future<void> initializeForEdit(String goalId) async {
    final repository = ref.read(goalRepositoryProvider);
    final goal = await repository.getById(goalId);

    if (goal == null) {
      state = state.copyWith(error: 'Goal not found');
      return;
    }

    state = GoalFormState(
      id: goal.id,
      title: goal.title,
      type: goal.type,
      metric: goal.metric,
      targetValue: goal.targetValue,
      period: goal.period,
      categoryId: goal.categoryId,
      debtStrategy: goal.debtStrategy,
      isActive: goal.isActive,
      isEditMode: true,
    );
  }

  /// Update form fields
  void updateTitle(String title) {
    state = state.copyWith(title: title, clearError: true);
  }

  void updateType(GoalType type) {
    state = state.copyWith(type: type, clearError: true);
    // Clear category if switching away from category type
    if (type != GoalType.category) {
      state = state.copyWith(clearCategoryId: true);
    }
  }

  void updateMetric(GoalMetric metric) {
    state = state.copyWith(metric: metric, clearError: true);
  }

  void updateTargetValue(int targetValue) {
    state = state.copyWith(targetValue: targetValue, clearError: true);
  }

  void updatePeriod(GoalPeriod period) {
    state = state.copyWith(period: period, clearError: true);
  }

  void updateCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryId: true, clearError: true);
    } else {
      state = state.copyWith(categoryId: categoryId, clearError: true);
    }
  }

  void updateDebtStrategy(DebtStrategy debtStrategy) {
    state = state.copyWith(debtStrategy: debtStrategy, clearError: true);
  }

  void updateIsActive(bool isActive) {
    state = state.copyWith(isActive: isActive, clearError: true);
  }

  /// Save the goal
  Future<bool> save() async {
    final validationError = state.validate();
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repository = ref.read(goalRepositoryProvider);
      final now = DateTime.now();
      final uuid = const Uuid();

      // Get createdAt timestamp
      DateTime createdAt = now;
      if (state.isEditMode && state.id != null) {
        final existingGoal = await repository.getById(state.id!);
        if (existingGoal != null) {
          createdAt = existingGoal.createdAt;
        }
      }

      final goal = Goal(
        id: state.id ?? uuid.v4(),
        title: state.title.trim(),
        type: state.type,
        metric: state.metric,
        targetValue: state.targetValue,
        period: state.period,
        categoryId: state.type == GoalType.category ? state.categoryId : null,
        debtStrategy: state.debtStrategy,
        isActive: state.isActive,
        createdAt: createdAt,
        updatedAt: now,
      );

      await repository.save(goal);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to save goal: $e',
      );
      return false;
    }
  }

  /// Delete the goal
  Future<bool> delete() async {
    if (state.id == null) {
      state = state.copyWith(error: 'Cannot delete a goal that has not been saved');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repository = ref.read(goalRepositoryProvider);
      await repository.delete(state.id!);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Failed to delete goal: $e',
      );
      return false;
    }
  }
}
