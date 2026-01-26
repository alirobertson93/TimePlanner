import '../entities/activity.dart';
import '../entities/event.dart';
import '../enums/edit_scope.dart';
import '../../data/repositories/event_repository.dart';

/// Service for editing activities in a series.
/// 
/// When a user edits an activity that belongs to a series, this service
/// can apply the changes to multiple activities based on the selected
/// edit scope.
class SeriesEditService {
  const SeriesEditService(this._eventRepository);

  final IEventRepository _eventRepository;

  /// Update activities in a series with new values.
  /// 
  /// [activity] - The activity being edited
  /// [updates] - Map of property names to new values
  /// [scope] - Which activities to update
  /// 
  /// Returns the number of activities updated.
  Future<int> updateWithScope({
    required Activity activity,
    required Map<String, dynamic> updates,
    required EditScope scope,
  }) async {
    switch (scope) {
      case EditScope.thisOnly:
        // Only update this activity
        final updated = _applyUpdates(activity, updates);
        await _eventRepository.save(Event.fromActivity(updated));
        return 1;

      case EditScope.allInSeries:
        // Update all activities in the series
        if (activity.seriesId == null) {
          // Not in a series, just update this activity
          final updated = _applyUpdates(activity, updates);
          await _eventRepository.save(Event.fromActivity(updated));
          return 1;
        }
        return await _updateSeries(activity.seriesId!, updates);

      case EditScope.thisAndFuture:
        // Update this and all future activities
        if (activity.seriesId == null) {
          // Not in a series, just update this activity
          final updated = _applyUpdates(activity, updates);
          await _eventRepository.save(Event.fromActivity(updated));
          return 1;
        }
        return await _updateSeriesFromDate(
          activity.seriesId!,
          activity.startTime ?? DateTime.now(),
          updates,
        );
    }
  }

  /// Update all activities in a series.
  Future<int> _updateSeries(
    String seriesId,
    Map<String, dynamic> updates,
  ) async {
    final events = await _eventRepository.getBySeriesId(seriesId);
    int count = 0;

    for (final event in events) {
      final activity = event.toActivity();
      final updated = _applyUpdates(activity, updates);
      await _eventRepository.save(Event.fromActivity(updated));
      count++;
    }

    return count;
  }

  /// Update activities in a series starting from a specific date.
  Future<int> _updateSeriesFromDate(
    String seriesId,
    DateTime fromDate,
    Map<String, dynamic> updates,
  ) async {
    final events = await _eventRepository.getBySeriesId(seriesId);
    int count = 0;

    for (final event in events) {
      // Only update if the event starts on or after the given date
      if (event.startTime != null && !event.startTime!.isBefore(fromDate)) {
        final activity = event.toActivity();
        final updated = _applyUpdates(activity, updates);
        await _eventRepository.save(Event.fromActivity(updated));
        count++;
      }
    }

    return count;
  }

  /// Apply updates to an activity.
  Activity _applyUpdates(Activity activity, Map<String, dynamic> updates) {
    return activity.copyWith(
      name: updates['name'] as String? ?? activity.name,
      description: updates['description'] as String? ?? activity.description,
      categoryId: updates['categoryId'] as String? ?? activity.categoryId,
      locationId: updates['locationId'] as String? ?? activity.locationId,
      duration: updates['duration'] as Duration? ?? activity.duration,
      updatedAt: DateTime.now(),
    );
  }

  /// Detect which properties vary across activities in a series.
  /// 
  /// Returns a map where keys are property names and values are lists
  /// of the different values found for that property.
  Future<Map<String, List<dynamic>>> detectVariance(String seriesId) async {
    final events = await _eventRepository.getBySeriesId(seriesId);
    final variance = <String, Set<dynamic>>{};

    for (final event in events) {
      _addToVariance(variance, 'name', event.name);
      _addToVariance(variance, 'description', event.description);
      _addToVariance(variance, 'categoryId', event.categoryId);
      _addToVariance(variance, 'locationId', event.locationId);
      _addToVariance(variance, 'duration', event.duration?.inMinutes);
    }

    // Return only properties that have multiple different values
    return Map.fromEntries(
      variance.entries
          .where((e) => e.value.length > 1)
          .map((e) => MapEntry(e.key, e.value.toList())),
    );
  }

  void _addToVariance(
    Map<String, Set<dynamic>> variance,
    String key,
    dynamic value,
  ) {
    variance.putIfAbsent(key, () => {}).add(value);
  }

  /// Add an activity to an existing series.
  /// 
  /// Sets the seriesId on the activity and saves it.
  Future<void> addToSeries(Activity activity, String seriesId) async {
    final updated = activity.copyWith(seriesId: seriesId);
    await _eventRepository.save(Event.fromActivity(updated));
  }

  /// Remove an activity from its series.
  /// 
  /// Clears the seriesId and saves the activity.
  Future<void> removeFromSeries(Activity activity) async {
    // Use copyWith with explicit null handling through a new activity
    final updated = Activity(
      id: activity.id,
      name: activity.name,
      description: activity.description,
      timingType: activity.timingType,
      startTime: activity.startTime,
      endTime: activity.endTime,
      duration: activity.duration,
      categoryId: activity.categoryId,
      locationId: activity.locationId,
      recurrenceRuleId: activity.recurrenceRuleId,
      seriesId: null, // Explicitly set to null to remove from series
      schedulingConstraint: activity.schedulingConstraint,
      appCanMove: activity.appCanMove,
      appCanResize: activity.appCanResize,
      isUserLocked: activity.isUserLocked,
      status: activity.status,
      createdAt: activity.createdAt,
      updatedAt: DateTime.now(),
    );
    await _eventRepository.save(Event.fromActivity(updated));
  }
}
