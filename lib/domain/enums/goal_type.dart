/// Represents the type of goal being tracked
enum GoalType {
  category, // Time spent on a category
  person, // Time spent with a person
  location, // Time spent at a location (added in Phase 9A)
  event, // Specific recurring event by title (added in Phase 9A)
  custom; // Custom goal (future)

  int get value => index;

  static GoalType fromValue(int value) {
    return GoalType.values[value];
  }
}
