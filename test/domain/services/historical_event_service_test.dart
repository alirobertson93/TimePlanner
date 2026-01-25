import 'package:flutter_test/flutter_test.dart';
import 'package:time_planner/domain/services/historical_event_service.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/category.dart';
import 'package:time_planner/domain/entities/location.dart';
import 'package:time_planner/domain/entities/person.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('HistoricalEventService', () {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    group('analyze', () {
      test('returns empty patterns for empty events list', () {
        final summary = HistoricalEventService.analyze(
          events: [],
          categories: [],
          people: [],
          locations: [],
        );

        expect(summary.totalEvents, 0);
        expect(summary.totalMinutes, 0);
        expect(summary.categoryPatterns, isEmpty);
        expect(summary.locationPatterns, isEmpty);
        expect(summary.eventTitlePatterns, isEmpty);
      });

      test('calculates total time correctly', () {
        final events = [
          _createEvent(
            name: 'Meeting',
            startTime: now.subtract(const Duration(hours: 2)),
            endTime: now,
          ),
          _createEvent(
            name: 'Work',
            startTime: now.subtract(const Duration(hours: 5)),
            endTime: now.subtract(const Duration(hours: 2)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: [],
          people: [],
          locations: [],
        );

        expect(summary.totalEvents, 2);
        expect(summary.totalMinutes, 5 * 60); // 5 hours
        expect(summary.totalHours, closeTo(5.0, 0.1));
      });

      test('excludes events outside analysis period', () {
        final events = [
          _createEvent(
            name: 'Recent Event',
            startTime: now.subtract(const Duration(days: 1)),
            endTime: now
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 1)),
          ),
          _createEvent(
            name: 'Old Event',
            startTime: now.subtract(const Duration(days: 60)),
            endTime: now
                .subtract(const Duration(days: 60))
                .add(const Duration(hours: 1)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: [],
          people: [],
          locations: [],
          analysisDays: 30,
        );

        expect(summary.totalEvents, 1);
        expect(summary.eventTitlePatterns.length,
            0); // Not enough for pattern (need 2)
      });
    });

    group('category patterns', () {
      test('detects category patterns with sufficient events', () {
        final categoryId = 'cat-1';
        final categories = [
          Category(
            id: categoryId,
            name: 'Work',
            colourHex: 'FF0000FF',
          ),
        ];

        final events = [
          _createEvent(
            name: 'Task 1',
            categoryId: categoryId,
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 2)),
          ),
          _createEvent(
            name: 'Task 2',
            categoryId: categoryId,
            startTime: now.subtract(const Duration(days: 3)),
            endTime: now
                .subtract(const Duration(days: 3))
                .add(const Duration(hours: 3)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: categories,
          people: [],
          locations: [],
        );

        expect(summary.categoryPatterns, hasLength(1));
        final pattern = summary.categoryPatterns.first;
        expect(pattern.name, 'Work');
        expect(pattern.categoryId, categoryId);
        expect(pattern.eventCount, 2);
        expect(pattern.totalHours, closeTo(5.0, 0.1));
      });

      test('ignores categories with insufficient events', () {
        final categoryId = 'cat-1';
        final categories = [
          Category(
            id: categoryId,
            name: 'Rare',
            colourHex: 'FF0000FF',
          ),
        ];

        final events = [
          _createEvent(
            name: 'Only Once',
            categoryId: categoryId,
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 1)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: categories,
          people: [],
          locations: [],
        );

        expect(summary.categoryPatterns, isEmpty);
      });
    });

    group('location patterns', () {
      test('detects location patterns', () {
        final locationId = 'loc-1';
        final locations = [
          Location(
            id: locationId,
            name: 'Office',
            createdAt: now,
          ),
        ];

        final events = [
          _createEvent(
            name: 'Meeting 1',
            locationId: locationId,
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 2)),
          ),
          _createEvent(
            name: 'Meeting 2',
            locationId: locationId,
            startTime: now.subtract(const Duration(days: 2)),
            endTime: now
                .subtract(const Duration(days: 2))
                .add(const Duration(hours: 3)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: [],
          people: [],
          locations: locations,
        );

        expect(summary.locationPatterns, hasLength(1));
        final pattern = summary.locationPatterns.first;
        expect(pattern.name, 'Office');
        expect(pattern.locationId, locationId);
        expect(pattern.eventCount, 2);
      });
    });

    group('event title patterns', () {
      test('detects recurring event titles', () {
        final events = [
          _createEvent(
            name: 'Daily Standup',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(minutes: 30)),
          ),
          _createEvent(
            name: 'Daily Standup',
            startTime: now.subtract(const Duration(days: 5)),
            endTime: now
                .subtract(const Duration(days: 5))
                .add(const Duration(minutes: 30)),
          ),
          _createEvent(
            name: 'Daily Standup',
            startTime: now.subtract(const Duration(days: 3)),
            endTime: now
                .subtract(const Duration(days: 3))
                .add(const Duration(minutes: 30)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: [],
          people: [],
          locations: [],
        );

        expect(summary.eventTitlePatterns, hasLength(1));
        final pattern = summary.eventTitlePatterns.first;
        expect(pattern.name, 'Daily Standup');
        expect(pattern.eventTitle, 'Daily Standup');
        expect(pattern.eventCount, 3);
      });

      test('normalizes event titles for matching (case-insensitive)', () {
        final events = [
          _createEvent(
            name: 'MEETING',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 1)),
          ),
          _createEvent(
            name: 'Meeting',
            startTime: now.subtract(const Duration(days: 3)),
            endTime: now
                .subtract(const Duration(days: 3))
                .add(const Duration(hours: 1)),
          ),
          _createEvent(
            name: 'meeting',
            startTime: now.subtract(const Duration(days: 1)),
            endTime: now
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 1)),
          ),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: [],
          people: [],
          locations: [],
        );

        // Should be grouped as one pattern
        expect(summary.eventTitlePatterns, hasLength(1));
        expect(summary.eventTitlePatterns.first.eventCount, 3);
      });
    });

    group('getSuggestionsForType', () {
      test('returns suggestions sorted by weekly hours', () {
        final events = [
          // High frequency category
          _createEvent(
            name: 'Cat A Event 1',
            categoryId: 'cat-a',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 5)),
          ),
          _createEvent(
            name: 'Cat A Event 2',
            categoryId: 'cat-a',
            startTime: now.subtract(const Duration(days: 3)),
            endTime: now
                .subtract(const Duration(days: 3))
                .add(const Duration(hours: 5)),
          ),
          // Low frequency category
          _createEvent(
            name: 'Cat B Event 1',
            categoryId: 'cat-b',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 1)),
          ),
          _createEvent(
            name: 'Cat B Event 2',
            categoryId: 'cat-b',
            startTime: now.subtract(const Duration(days: 2)),
            endTime: now
                .subtract(const Duration(days: 2))
                .add(const Duration(hours: 1)),
          ),
        ];

        final categories = [
          Category(id: 'cat-a', name: 'High Hours', colourHex: 'FF0000'),
          Category(id: 'cat-b', name: 'Low Hours', colourHex: '0000FF'),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: categories,
          people: [],
          locations: [],
        );

        final suggestions = HistoricalEventService.getSuggestionsForType(
          type: HistoricalPatternType.category,
          summary: summary,
          maxSuggestions: 5,
        );

        expect(suggestions, hasLength(2));
        expect(suggestions.first.name, 'High Hours');
        expect(suggestions.last.name, 'Low Hours');
      });

      test('limits number of suggestions', () {
        final events = <Event>[];
        final categories = <Category>[];

        // Create 10 categories with events
        for (var i = 0; i < 10; i++) {
          final catId = 'cat-$i';
          categories.add(Category(
            id: catId,
            name: 'Category $i',
            colourHex: 'FF0000',
          ));

          // Add 2 events per category
          events.add(_createEvent(
            name: 'Event ${i}a',
            categoryId: catId,
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(Duration(hours: i + 1)),
          ));
          events.add(_createEvent(
            name: 'Event ${i}b',
            categoryId: catId,
            startTime: now.subtract(const Duration(days: 3)),
            endTime: now
                .subtract(const Duration(days: 3))
                .add(Duration(hours: i + 1)),
          ));
        }

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: categories,
          people: [],
          locations: [],
        );

        final suggestions = HistoricalEventService.getSuggestionsForType(
          type: HistoricalPatternType.category,
          summary: summary,
          maxSuggestions: 3,
        );

        expect(suggestions, hasLength(3));
      });
    });

    group('HistoricalActivityPattern', () {
      test('calculates weekly hours correctly', () {
        final pattern = HistoricalActivityPattern(
          id: 'test',
          name: 'Test',
          patternType: HistoricalPatternType.category,
          totalMinutes: 600, // 10 hours
          eventCount: 5,
          averageMinutesPerWeek: 300, // 5 hours per week
          averageMinutesPerEvent: 120,
          firstSeen: twoWeeksAgo,
          lastSeen: now,
          categoryId: 'cat-1',
        );

        expect(pattern.totalHours, closeTo(10.0, 0.1));
        expect(pattern.weeklyHours, closeTo(5.0, 0.1));
      });

      test('confidence is higher for more events and recent activity', () {
        final recentHighActivity = HistoricalActivityPattern(
          id: 'high',
          name: 'High Activity',
          patternType: HistoricalPatternType.category,
          totalMinutes: 1200,
          eventCount: 15,
          averageMinutesPerWeek: 400,
          averageMinutesPerEvent: 80,
          firstSeen: twoWeeksAgo,
          lastSeen: now,
          categoryId: 'cat-1',
        );

        final oldLowActivity = HistoricalActivityPattern(
          id: 'low',
          name: 'Low Activity',
          patternType: HistoricalPatternType.category,
          totalMinutes: 120,
          eventCount: 2,
          averageMinutesPerWeek: 60,
          averageMinutesPerEvent: 60,
          firstSeen: now.subtract(const Duration(days: 60)),
          lastSeen: now.subtract(const Duration(days: 45)),
          categoryId: 'cat-2',
        );

        expect(recentHighActivity.confidence,
            greaterThan(oldLowActivity.confidence));
      });
    });

    group('HistoricalAnalysisSummary', () {
      test('allPatterns combines and sorts by confidence', () {
        final events = [
          // Category events
          _createEvent(
            name: 'Cat Event 1',
            categoryId: 'cat-1',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 2)),
          ),
          _createEvent(
            name: 'Cat Event 2',
            categoryId: 'cat-1',
            startTime: now.subtract(const Duration(days: 1)),
            endTime: now
                .subtract(const Duration(days: 1))
                .add(const Duration(hours: 2)),
          ),
          // Location events
          _createEvent(
            name: 'Loc Event 1',
            locationId: 'loc-1',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(hours: 1)),
          ),
          _createEvent(
            name: 'Loc Event 2',
            locationId: 'loc-1',
            startTime: now.subtract(const Duration(days: 2)),
            endTime: now
                .subtract(const Duration(days: 2))
                .add(const Duration(hours: 1)),
          ),
          // Title events
          _createEvent(
            name: 'Standup',
            startTime: oneWeekAgo,
            endTime: oneWeekAgo.add(const Duration(minutes: 30)),
          ),
          _createEvent(
            name: 'Standup',
            startTime: now.subtract(const Duration(days: 1)),
            endTime: now
                .subtract(const Duration(days: 1))
                .add(const Duration(minutes: 30)),
          ),
        ];

        final categories = [
          Category(id: 'cat-1', name: 'Work', colourHex: 'FF0000'),
        ];
        final locations = [
          Location(id: 'loc-1', name: 'Office', createdAt: now),
        ];

        final summary = HistoricalEventService.analyze(
          events: events,
          categories: categories,
          people: [],
          locations: locations,
        );

        // Should have patterns from multiple types
        expect(summary.allPatterns.length, greaterThanOrEqualTo(2));

        // Should be sorted by confidence (descending)
        final confidences =
            summary.allPatterns.map((p) => p.confidence).toList();
        for (var i = 0; i < confidences.length - 1; i++) {
          expect(confidences[i], greaterThanOrEqualTo(confidences[i + 1]));
        }
      });
    });
  });
}

/// Helper to create test events
Event _createEvent({
  required String name,
  String? categoryId,
  String? locationId,
  DateTime? startTime,
  DateTime? endTime,
  Duration? duration,
}) {
  return Event(
    id: 'event-${DateTime.now().microsecondsSinceEpoch}',
    name: name,
    categoryId: categoryId,
    locationId: locationId,
    timingType: TimingType.fixed,
    status: EventStatus.pending,
    startTime: startTime ?? DateTime.now(),
    endTime: endTime ?? DateTime.now().add(const Duration(hours: 1)),
    duration: duration,
    appCanMove: false,
    appCanResize: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
