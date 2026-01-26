import '../entities/activity.dart';
import '../entities/activity_series.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/event_people_repository.dart';

/// Service for finding existing series that match a given activity.
/// 
/// When a user creates or saves an activity, this service can identify
/// similar existing activities that could be grouped into a series.
/// 
/// ## Matching Rules
/// 
/// Activities are considered a match (should be in same series) if:
/// 1. They have the same title (case-insensitive), OR
/// 2. They share 2+ matching properties (person, location, category)
class SeriesMatchingService {
  const SeriesMatchingService(
    this._eventRepository,
    this._eventPeopleRepository,
  );

  final IEventRepository _eventRepository;
  final IEventPeopleRepository _eventPeopleRepository;

  /// Find existing series that match the given activity.
  /// 
  /// Returns a list of potential series matches, ordered by relevance.
  /// Each match contains the activities that could be grouped with the
  /// given activity.
  Future<List<ActivitySeries>> findMatchingSeries(Activity activity) async {
    final allEvents = await _eventRepository.getAll();
    final matchesBySeriesId = <String, List<Activity>>{};

    for (final existing in allEvents) {
      // Skip the activity itself
      if (existing.id == activity.id) continue;

      // Convert Event to Activity for comparison
      final existingActivity = existing.toActivity();

      if (await _isMatch(activity, existingActivity)) {
        // Use existing seriesId or the activity's own ID as the grouping key
        final seriesId = existingActivity.seriesId ?? existingActivity.id;
        matchesBySeriesId.putIfAbsent(seriesId, () => []).add(existingActivity);
      }
    }

    return matchesBySeriesId.entries.map((entry) {
      final activities = entry.value;
      return ActivitySeries(
        id: entry.key,
        activities: activities,
        displayTitle: _getDisplayTitle(activities.first),
        count: activities.length,
      );
    }).toList()
      // Sort by count (most matches first)
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Check if two activities match and should be in the same series.
  Future<bool> _isMatch(Activity a, Activity b) async {
    // Rule 1: Same title (case-insensitive)
    if (a.name != null &&
        b.name != null &&
        a.name!.toLowerCase() == b.name!.toLowerCase()) {
      return true;
    }

    // Rule 2: 2+ matching properties
    int matchCount = 0;

    // Check category match
    if (a.categoryId != null && a.categoryId == b.categoryId) {
      matchCount++;
    }

    // Check location match
    if (a.locationId != null && a.locationId == b.locationId) {
      matchCount++;
    }

    // Check person match (requires junction table lookup)
    final aPeople = await _eventPeopleRepository.getPeopleForEvent(a.id);
    final bPeople = await _eventPeopleRepository.getPeopleForEvent(b.id);
    final aPersonIds = aPeople.map((p) => p.id).toSet();
    final bPersonIds = bPeople.map((p) => p.id).toSet();

    if (aPersonIds.intersection(bPersonIds).isNotEmpty) {
      matchCount++;
    }

    return matchCount >= 2;
  }

  /// Get a display title for an activity (simple fallback).
  String _getDisplayTitle(Activity activity) {
    if (activity.name != null && activity.name!.isNotEmpty) {
      return activity.name!;
    }
    return 'Related Activities';
  }

  /// Check if an activity has any potential series matches.
  /// 
  /// This is a quick check that can be used to decide whether to
  /// show the series prompt UI.
  Future<bool> hasMatchingSeries(Activity activity) async {
    final matches = await findMatchingSeries(activity);
    return matches.isNotEmpty;
  }

  /// Get the count of activities in a series.
  Future<int> getSeriesCount(String seriesId) async {
    return await _eventRepository.countInSeries(seriesId);
  }
}
