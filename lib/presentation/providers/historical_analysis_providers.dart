import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/historical_event_service.dart';
import 'repository_providers.dart';

/// Provider for historical event analysis summary
/// Analyzes last 30 days of event data to detect patterns
final historicalAnalysisProvider =
    FutureProvider<HistoricalAnalysisSummary>((ref) async {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final personRepository = ref.watch(personRepositoryProvider);
  final locationRepository = ref.watch(locationRepositoryProvider);

  // Get data for analysis (last 30 days of events)
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  final events = await eventRepository.getEventsInRange(thirtyDaysAgo, now);
  final categories = await categoryRepository.getAll();
  final people = await personRepository.getAll();
  final locations = await locationRepository.getAll();

  return HistoricalEventService.analyze(
    events: events,
    categories: categories,
    people: people,
    locations: locations,
    analysisDays: 30,
  );
});

/// Provider for category pattern suggestions (most time spent categories)
final categorySuggestionsProvider =
    FutureProvider<List<HistoricalActivityPattern>>((ref) async {
  final summary = await ref.watch(historicalAnalysisProvider.future);
  return HistoricalEventService.getSuggestionsForType(
    type: HistoricalPatternType.category,
    summary: summary,
    maxSuggestions: 5,
  );
});

/// Provider for location pattern suggestions (most time at locations)
final locationSuggestionsProvider =
    FutureProvider<List<HistoricalActivityPattern>>((ref) async {
  final summary = await ref.watch(historicalAnalysisProvider.future);
  return HistoricalEventService.getSuggestionsForType(
    type: HistoricalPatternType.location,
    summary: summary,
    maxSuggestions: 5,
  );
});

/// Provider for activity title pattern suggestions (recurring activities)
final activityTitleSuggestionsProvider =
    FutureProvider<List<HistoricalActivityPattern>>((ref) async {
  final summary = await ref.watch(historicalAnalysisProvider.future);
  return HistoricalEventService.getSuggestionsForType(
    type: HistoricalPatternType.activityTitle,
    summary: summary,
    maxSuggestions: 5,
  );
});
