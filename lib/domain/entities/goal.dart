import '../enums/goal_type.dart';
import '../enums/goal_metric.dart';
import '../enums/goal_period.dart';
import '../enums/debt_strategy.dart';

/// Pure domain entity representing a user-defined goal
class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.type,
    required this.metric,
    required this.targetValue,
    required this.period,
    this.categoryId,
    this.personId,
    required this.debtStrategy,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final GoalType type;
  final GoalMetric metric;
  final int targetValue;
  final GoalPeriod period;
  final String? categoryId;
  /// Related person ID (for relationship goals - tracking time with specific people)
  final String? personId;
  final DebtStrategy debtStrategy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Creates a copy of this goal with the given fields replaced
  Goal copyWith({
    String? id,
    String? title,
    GoalType? type,
    GoalMetric? metric,
    int? targetValue,
    GoalPeriod? period,
    String? categoryId,
    String? personId,
    DebtStrategy? debtStrategy,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      metric: metric ?? this.metric,
      targetValue: targetValue ?? this.targetValue,
      period: period ?? this.period,
      categoryId: categoryId ?? this.categoryId,
      personId: personId ?? this.personId,
      debtStrategy: debtStrategy ?? this.debtStrategy,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Goal &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.metric == metric &&
        other.targetValue == targetValue &&
        other.period == period &&
        other.categoryId == categoryId &&
        other.personId == personId &&
        other.debtStrategy == debtStrategy &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      type,
      metric,
      targetValue,
      period,
      categoryId,
      personId,
      debtStrategy,
      isActive,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Goal(id: $id, title: $title, type: $type, targetValue: $targetValue, period: $period, personId: $personId)';
  }
}
