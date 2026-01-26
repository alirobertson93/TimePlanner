import '../entities/event.dart';
import '../entities/category.dart';
import '../entities/person.dart';
import '../entities/location.dart';

/// Represents a historical activity pattern detected from past events
class HistoricalActivityPattern {
  const HistoricalActivityPattern({
    required this.id,
    required this.name,
    required this.patternType,
    required this.totalMinutes,
    required this.eventCount,
    required this.averageMinutesPerWeek,
    required this.averageMinutesPerEvent,
    required this.firstSeen,
    required this.lastSeen,
    this.categoryId,
    this.personId,
    this.locationId,
    this.activityTitle,
  });

  /// Unique identifier (categoryId, personId, locationId, or normalized title)
  final String id;

  /// Display name for the pattern
  final String name;

  /// Type of pattern detected
  final HistoricalPatternType patternType;

  /// Total time spent in minutes
  final int totalMinutes;

  /// Number of events matching this pattern
  final int eventCount;

  /// Average minutes per week
  final double averageMinutesPerWeek;

  /// Average minutes per event
  final double averageMinutesPerEvent;

  /// First time this pattern was seen
  final DateTime firstSeen;

  /// Last time this pattern was seen
  final DateTime lastSeen;

  // Type-specific identifiers

  /// Category ID (for category patterns)
  final String? categoryId;

  /// Person ID (for person patterns)
  final String? personId;

  /// Location ID (for location patterns)
  final String? locationId;

  /// Activity title (for event title patterns)
  final String? eventTitle;

  /// Get time in hours with one decimal
  double get totalHours => totalMinutes / 60.0;

  /// Get weekly hours with one decimal
  double get weeklyHours => averageMinutesPerWeek / 60.0;

  /// Confidence score based on data quantity and recency
  double get confidence {
    // Base confidence on event count (more events = more confident)
    final eventFactor = (eventCount / 10.0).clamp(0.0, 1.0);

    // Recency factor (recent events are more relevant)
    final daysSinceLastEvent = DateTime.now().difference(lastSeen).inDays.abs();
    final recencyFactor = (1.0 - daysSinceLastEvent / 60.0).clamp(0.0, 1.0);

    // Regularity factor (data spread over time)
    final dataSpanDays = lastSeen.difference(firstSeen).inDays.abs();
    final regularityFactor =
        dataSpanDays > 7 ? (dataSpanDays / 30.0).clamp(0.0, 1.0) : 0.3;

    // Weighted average
    return (eventFactor * 0.4 + recencyFactor * 0.35 + regularityFactor * 0.25)
        .clamp(0.0, 1.0);
  }

  @override
  String toString() {
    return 'HistoricalActivityPattern(name: $name, type: $patternType, hours: ${totalHours.toStringAsFixed(1)}, events: $eventCount)';
  }
}

/// Types of patterns that can be detected
enum HistoricalPatternType {
  /// Pattern based on category
  category,

  /// Pattern based on person association
  person,

  /// Pattern based on location
  location,

  /// Pattern based on recurring event title
  activityTitle,
}

/// Summary of historical data analysis
class HistoricalAnalysisSummary {
  const HistoricalAnalysisSummary({
    required this.analysisStartDate,
    required this.analysisEndDate,
    required this.totalEvents,
    required this.totalMinutes,
    required this.categoryPatterns,
    required this.personPatterns,
    required this.locationPatterns,
    required this.eventTitlePatterns,
  });

  /// Start of analysis period
  final DateTime analysisStartDate;

  /// End of analysis period
  final DateTime analysisEndDate;

  /// Total events analyzed
  final int totalEvents;

  /// Total time in minutes
  final int totalMinutes;

  /// Category-based patterns
  final List<HistoricalActivityPattern> categoryPatterns;

  /// Person-based patterns
  final List<HistoricalActivityPattern> personPatterns;

  /// Location-based patterns
  final List<HistoricalActivityPattern> locationPatterns;

  /// Activity title patterns
  final List<HistoricalActivityPattern> eventTitlePatterns;

  /// All patterns combined, sorted by confidence
  List<HistoricalActivityPattern> get allPatterns {
    final all = <HistoricalActivityPattern>[
      ...categoryPatterns,
      ...personPatterns,
      ...locationPatterns,
      ...eventTitlePatterns,
    ];
    all.sort((a, b) => b.confidence.compareTo(a.confidence));
    return all;
  }

  /// Duration of analysis in days
  int get analysisDays => analysisEndDate.difference(analysisStartDate).inDays;

  /// Duration of analysis in weeks
  double get analysisWeeks => analysisDays / 7.0;

  /// Total hours analyzed
  double get totalHours => totalMinutes / 60.0;
}

/// Service for analyzing historical event data and detecting patterns
class HistoricalEventService {
  /// Minimum events to consider a pattern significant
  static const int minEventsForPattern = 2;

  /// Default analysis period in days
  static const int defaultAnalysisDays = 30;

  /// Analyze events and generate historical patterns
  static HistoricalAnalysisSummary analyze({
    required List<Event> events,
    required List<Category> categories,
    required List<Person> people,
    required List<Location> locations,
    List<String>? excludeEventIds,
    int? analysisDays,
  }) {
    final now = DateTime.now();
    final days = analysisDays ?? defaultAnalysisDays;
    final analysisStart = now.subtract(Duration(days: days));

    // Filter events by date range
    final relevantEvents = events.where((e) {
      final eventDate = e.startTime ?? e.createdAt;
      return eventDate.isAfter(analysisStart) &&
          (excludeEventIds == null || !excludeEventIds.contains(e.id));
    }).toList();

    // Calculate total time
    var totalMinutes = 0;
    for (final event in relevantEvents) {
      totalMinutes += _getEventMinutes(event);
    }

    // Analyze each pattern type
    final categoryPatterns = _analyzeCategoryPatterns(
      events: relevantEvents,
      categories: categories,
    );

    final personPatterns = _analyzePersonPatterns(
      events: relevantEvents,
      people: people,
    );

    final locationPatterns = _analyzeLocationPatterns(
      events: relevantEvents,
      locations: locations,
    );

    final eventTitlePatterns = _analyzeEventTitlePatterns(
      events: relevantEvents,
    );

    return HistoricalAnalysisSummary(
      analysisStartDate: analysisStart,
      analysisEndDate: now,
      totalEvents: relevantEvents.length,
      totalMinutes: totalMinutes,
      categoryPatterns: categoryPatterns,
      personPatterns: personPatterns,
      locationPatterns: locationPatterns,
      eventTitlePatterns: eventTitlePatterns,
    );
  }

  /// Get suggestions for a specific goal type
  static List<HistoricalActivityPattern> getSuggestionsForType({
    required HistoricalPatternType type,
    required HistoricalAnalysisSummary summary,
    int maxSuggestions = 5,
  }) {
    List<HistoricalActivityPattern> patterns;

    switch (type) {
      case HistoricalPatternType.category:
        patterns = summary.categoryPatterns;
        break;
      case HistoricalPatternType.person:
        patterns = summary.personPatterns;
        break;
      case HistoricalPatternType.location:
        patterns = summary.locationPatterns;
        break;
      case HistoricalPatternType.activityTitle:
        patterns = summary.eventTitlePatterns;
        break;
    }

    // Sort by weekly hours (most time spent first)
    final sorted = List<HistoricalActivityPattern>.from(patterns);
    sorted.sort((a, b) => b.weeklyHours.compareTo(a.weeklyHours));

    return sorted.take(maxSuggestions).toList();
  }

  /// Analyze category-based patterns
  static List<HistoricalActivityPattern> _analyzeCategoryPatterns({
    required List<Event> events,
    required List<Category> categories,
  }) {
    final stats = <String, _PatternStats>{};

    for (final event in events) {
      if (event.categoryId == null) continue;

      final s = stats.putIfAbsent(
        event.categoryId!,
        () => _PatternStats(id: event.categoryId!),
      );
      s.addEvent(event);
    }

    final patterns = <HistoricalActivityPattern>[];
    final weeksInPeriod = _weeksInEvents(events);

    for (final entry in stats.entries) {
      if (entry.value.eventCount < minEventsForPattern) continue;

      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: entry.key,
          name: 'Unknown',
          colourHex: 'FF000000',
        ),
      );

      patterns.add(HistoricalActivityPattern(
        id: entry.key,
        name: category.name,
        patternType: HistoricalPatternType.category,
        totalMinutes: entry.value.totalMinutes,
        eventCount: entry.value.eventCount,
        averageMinutesPerWeek: entry.value.totalMinutes / weeksInPeriod,
        averageMinutesPerEvent:
            entry.value.totalMinutes / entry.value.eventCount,
        firstSeen: entry.value.firstSeen!,
        lastSeen: entry.value.lastSeen!,
        categoryId: entry.key,
      ));
    }

    patterns.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return patterns;
  }

  /// Analyze person-based patterns
  static List<HistoricalActivityPattern> _analyzePersonPatterns({
    required List<Event> events,
    required List<Person> people,
  }) {
    // Note: Person associations are stored in EventPeople junction table
    // For now, return empty list - would need EventPeople data
    // This is a limitation we can document and address in future
    return [];
  }

  /// Analyze location-based patterns
  static List<HistoricalActivityPattern> _analyzeLocationPatterns({
    required List<Event> events,
    required List<Location> locations,
  }) {
    final stats = <String, _PatternStats>{};

    for (final event in events) {
      if (event.locationId == null) continue;

      final s = stats.putIfAbsent(
        event.locationId!,
        () => _PatternStats(id: event.locationId!),
      );
      s.addEvent(event);
    }

    final patterns = <HistoricalActivityPattern>[];
    final weeksInPeriod = _weeksInEvents(events);

    for (final entry in stats.entries) {
      if (entry.value.eventCount < minEventsForPattern) continue;

      final location = locations.firstWhere(
        (l) => l.id == entry.key,
        orElse: () => Location(
          id: entry.key,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      patterns.add(HistoricalActivityPattern(
        id: entry.key,
        name: location.name,
        patternType: HistoricalPatternType.location,
        totalMinutes: entry.value.totalMinutes,
        eventCount: entry.value.eventCount,
        averageMinutesPerWeek: entry.value.totalMinutes / weeksInPeriod,
        averageMinutesPerEvent:
            entry.value.totalMinutes / entry.value.eventCount,
        firstSeen: entry.value.firstSeen!,
        lastSeen: entry.value.lastSeen!,
        locationId: entry.key,
      ));
    }

    patterns.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return patterns;
  }

  /// Analyze event title patterns (recurring activities)
  static List<HistoricalActivityPattern> _analyzeEventTitlePatterns({
    required List<Event> events,
  }) {
    final stats = <String, _PatternStats>{};

    for (final event in events) {
      final normalizedTitle = event.name.toLowerCase().trim();
      if (normalizedTitle.isEmpty) continue;

      final s = stats.putIfAbsent(
        normalizedTitle,
        () => _PatternStats(id: normalizedTitle, originalTitle: event.name),
      );
      s.addEvent(event);
    }

    final patterns = <HistoricalActivityPattern>[];
    final weeksInPeriod = _weeksInEvents(events);

    for (final entry in stats.entries) {
      if (entry.value.eventCount < minEventsForPattern) continue;

      // Use first seen title as canonical name
      patterns.add(HistoricalActivityPattern(
        id: entry.key,
        name: entry.value.originalTitle ?? entry.key,
        patternType: HistoricalPatternType.activityTitle,
        totalMinutes: entry.value.totalMinutes,
        eventCount: entry.value.eventCount,
        averageMinutesPerWeek: entry.value.totalMinutes / weeksInPeriod,
        averageMinutesPerEvent:
            entry.value.totalMinutes / entry.value.eventCount,
        firstSeen: entry.value.firstSeen!,
        lastSeen: entry.value.lastSeen!,
        activityTitle: entry.value.originalTitle ?? entry.key,
      ));
    }

    patterns.sort((a, b) => b.totalMinutes.compareTo(a.totalMinutes));
    return patterns;
  }

  /// Helper to get event duration in minutes
  static int _getEventMinutes(Event event) {
    if (event.startTime != null && event.endTime != null) {
      return event.endTime!.difference(event.startTime!).inMinutes;
    } else if (event.duration != null) {
      return event.duration!.inMinutes;
    }
    return 0;
  }

  /// Calculate approximate weeks in the event data
  static double _weeksInEvents(List<Event> events) {
    if (events.isEmpty) return 1;

    DateTime? earliest;
    DateTime? latest;

    for (final event in events) {
      final eventDate = event.startTime ?? event.createdAt;
      if (earliest == null || eventDate.isBefore(earliest)) {
        earliest = eventDate;
      }
      if (latest == null || eventDate.isAfter(latest)) {
        latest = eventDate;
      }
    }

    if (earliest == null || latest == null) return 1;

    final days = latest.difference(earliest).inDays;
    final weeks = days / 7.0;
    return weeks < 1 ? 1 : weeks;
  }
}

/// Internal class for tracking pattern statistics
class _PatternStats {
  _PatternStats({required this.id, this.originalTitle});

  final String id;
  final String? originalTitle;
  int eventCount = 0;
  int totalMinutes = 0;
  DateTime? firstSeen;
  DateTime? lastSeen;

  void addEvent(Event event) {
    eventCount++;

    // Add duration
    if (event.startTime != null && event.endTime != null) {
      totalMinutes += event.endTime!.difference(event.startTime!).inMinutes;
    } else if (event.duration != null) {
      totalMinutes += event.duration!.inMinutes;
    }

    // Track first/last seen
    final eventDate = event.startTime ?? event.createdAt;
    if (firstSeen == null || eventDate.isBefore(firstSeen!)) {
      firstSeen = eventDate;
    }
    if (lastSeen == null || eventDate.isAfter(lastSeen!)) {
      lastSeen = eventDate;
    }
  }
}
