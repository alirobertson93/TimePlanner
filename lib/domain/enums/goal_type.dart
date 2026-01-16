/// Represents the type of goal being tracked
enum GoalType {
  category, // Time spent on a category
  person, // Time spent with a person
  custom; // Custom goal (future)

  int get value => index;

  static GoalType fromValue(int value) {
    return GoalType.values[value];
  }
}
