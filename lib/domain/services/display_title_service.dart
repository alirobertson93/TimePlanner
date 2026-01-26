import '../entities/activity.dart';
import '../entities/category.dart';
import '../entities/location.dart';
import '../entities/person.dart';

/// Service for computing display titles for activities.
/// 
/// Activities can have optional titles. When no title is provided, the
/// display title is computed from associated entities (person, location,
/// category) using a priority order:
/// 
/// 1. Activity name (if present and non-empty)
/// 2. Person names (joined by commas if multiple)
/// 3. Location name
/// 4. Category name
/// 5. "Untitled Activity" (fallback)
class DisplayTitleService {
  const DisplayTitleService();

  /// Computes the display title for an activity.
  /// 
  /// [activity] - The activity to compute the title for
  /// [people] - People associated with the activity (from junction table)
  /// [location] - The location entity (if activity has locationId)
  /// [category] - The category entity (if activity has categoryId)
  /// 
  /// Returns a user-friendly display title.
  String getDisplayTitle(
    Activity activity, {
    List<Person>? people,
    Location? location,
    Category? category,
  }) {
    // Priority 1: Activity name
    if (activity.hasName) {
      return activity.name!;
    }

    // Build title from associated entities
    final parts = <String>[];

    // Priority 2: Person names
    if (people != null && people.isNotEmpty) {
      parts.add(people.map((p) => p.name).join(', '));
    }

    // Priority 3: Location name
    if (location != null) {
      parts.add(location.name);
    }

    // Priority 4: Category name
    if (category != null) {
      parts.add(category.name);
    }

    // Return joined parts or fallback
    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }

    // Fallback for invalid activities (should not happen in normal usage)
    return 'Untitled Activity';
  }

  /// Computes a short display title for compact UI elements.
  /// 
  /// Uses the same logic as [getDisplayTitle] but truncates long titles
  /// and only uses the first person name if multiple people are present.
  String getShortDisplayTitle(
    Activity activity, {
    List<Person>? people,
    Location? location,
    Category? category,
    int maxLength = 30,
  }) {
    // Priority 1: Activity name (truncated)
    if (activity.hasName) {
      return _truncate(activity.name!, maxLength);
    }

    // Priority 2: First person name only
    if (people != null && people.isNotEmpty) {
      return _truncate(people.first.name, maxLength);
    }

    // Priority 3: Location name
    if (location != null) {
      return _truncate(location.name, maxLength);
    }

    // Priority 4: Category name
    if (category != null) {
      return _truncate(category.name, maxLength);
    }

    // Fallback
    return 'Untitled';
  }

  /// Truncates a string to the specified maximum length with ellipsis.
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 1)}…';
  }
}
