/// Represents the strength of a scheduling preference/constraint
enum SchedulingPreferenceStrength {
  /// A weak preference - scheduler may ignore if needed
  weak,
  /// A strong preference - scheduler should try to respect
  strong,
  /// A locked preference - scheduler must respect (hard constraint)
  locked;

  int get value => index;

  static SchedulingPreferenceStrength fromValue(int value) {
    return SchedulingPreferenceStrength.values[value];
  }

  /// Returns a human-readable label for this preference strength
  String get label {
    switch (this) {
      case SchedulingPreferenceStrength.weak:
        return 'Weak Preference';
      case SchedulingPreferenceStrength.strong:
        return 'Strong Preference';
      case SchedulingPreferenceStrength.locked:
        return 'Locked';
    }
  }
}
