/// Represents the time period for a goal
enum GoalPeriod {
  week,
  month,
  quarter,
  year;

  int get value => index;

  static GoalPeriod fromValue(int value) {
    return GoalPeriod.values[value];
  }
}
