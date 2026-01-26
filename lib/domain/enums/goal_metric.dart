/// Represents the metric used to measure goal progress
enum GoalMetric {
  hours, // Track hours spent
  activities, // Track number of activities
  completions; // Track completion percentage

  int get value => index;

  static GoalMetric fromValue(int value) {
    return GoalMetric.values[value];
  }
}
