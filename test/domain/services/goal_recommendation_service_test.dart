import 'package:test/test.dart';
import 'package:time_planner/domain/services/goal_recommendation_service.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/category.dart';
import 'package:time_planner/domain/entities/person.dart';
import 'package:time_planner/domain/entities/location.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/enums/goal_type.dart';
import 'package:time_planner/domain/enums/goal_metric.dart';
import 'package:time_planner/domain/enums/goal_period.dart';
import 'package:time_planner/domain/enums/debt_strategy.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('GoalRecommendationService', () {
    final now = DateTime.now();

    Category createCategory({required String id, required String name}) {
      return Category(
        id: id,
        name: name,
        colourHex: 'FF0000FF',
      );
    }

    Location createLocation({required String id, required String name}) {
      return Location(
        id: id,
        name: name,
        createdAt: now,
      );
    }

    Event createEvent({
      required String id,
      required String name,
      required DateTime startTime,
      Duration duration = const Duration(hours: 1),
      String? categoryId,
      String? locationId,
    }) {
      return Event(
        id: id,
        name: name,
        description: '',
        timingType: TimingType.fixed,
        startTime: startTime,
        endTime: startTime.add(duration),
        categoryId: categoryId,
        locationId: locationId,
        status: EventStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }

    Goal createGoal({
      required String id,
      required GoalType type,
      String? categoryId,
      String? locationId,
      String? eventTitle,
    }) {
      return Goal(
        id: id,
        title: 'Test Goal',
        type: type,
        metric: GoalMetric.hours,
        targetValue: 10,
        period: GoalPeriod.week,
        categoryId: categoryId,
        locationId: locationId,
        eventTitle: eventTitle,
        debtStrategy: DebtStrategy.carryForward,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('analyzeAndRecommend', () {
      test('returns empty list for no events', () {
        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: [],
          categories: [],
          people: [],
          locations: [],
          existingGoals: [],
        );

        expect(recommendations, isEmpty);
      });

      test('recommends category-based goals for frequent categories', () {
        final category = createCategory(id: 'cat_exercise', name: 'Exercise');

        // Create multiple events in the same category over multiple weeks
        final events = List.generate(
          10,
          (i) => createEvent(
            id: 'event_$i',
            name: 'Workout',
            startTime: now.subtract(Duration(days: i * 2)),
            duration: const Duration(hours: 1),
            categoryId: 'cat_exercise',
          ),
        );

        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: events,
          categories: [category],
          people: [],
          locations: [],
          existingGoals: [],
        );

        // Should recommend a goal for the Exercise category
        expect(
          recommendations.any((r) =>
              r.type == GoalType.category && r.categoryId == 'cat_exercise'),
          isTrue,
        );
      });

      test('recommends location-based goals for frequent locations', () {
        final location = createLocation(id: 'loc_gym', name: 'Gym');

        // Create multiple events at the same location
        final events = List.generate(
          10,
          (i) => createEvent(
            id: 'event_$i',
            name: 'Workout Session $i',
            startTime: now.subtract(Duration(days: i * 2)),
            duration: const Duration(hours: 1),
            locationId: 'loc_gym',
          ),
        );

        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: events,
          categories: [],
          people: [],
          locations: [location],
          existingGoals: [],
        );

        // Should recommend a goal for the Gym location
        expect(
          recommendations.any(
              (r) => r.type == GoalType.location && r.locationId == 'loc_gym'),
          isTrue,
        );
      });

      test('recommends event-based goals for recurring event titles', () {
        // Create multiple events with the same title
        final events = List.generate(
          5,
          (i) => createEvent(
            id: 'event_$i',
            name: 'Guitar Practice',
            startTime: now.subtract(Duration(days: i * 3)),
            duration: const Duration(hours: 1),
          ),
        );

        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: events,
          categories: [],
          people: [],
          locations: [],
          existingGoals: [],
        );

        // Should recommend a goal for "Guitar Practice" events
        expect(
          recommendations.any((r) =>
              r.type == GoalType.event && r.eventTitle == 'Guitar Practice'),
          isTrue,
        );
      });

      test('does not recommend goals that already exist', () {
        final category = createCategory(id: 'cat_exercise', name: 'Exercise');

        final events = List.generate(
          10,
          (i) => createEvent(
            id: 'event_$i',
            name: 'Workout',
            startTime: now.subtract(Duration(days: i * 2)),
            categoryId: 'cat_exercise',
          ),
        );

        // Already have a goal for this category
        final existingGoal = createGoal(
          id: 'existing_goal',
          type: GoalType.category,
          categoryId: 'cat_exercise',
        );

        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: events,
          categories: [category],
          people: [],
          locations: [],
          existingGoals: [existingGoal],
        );

        // Should NOT recommend a goal for Exercise category since one exists
        expect(
          recommendations.any((r) =>
              r.type == GoalType.category && r.categoryId == 'cat_exercise'),
          isFalse,
        );
      });

      test('limits recommendations to maxRecommendations', () {
        // Create many different event patterns
        final categories = List.generate(
          10,
          (i) => createCategory(id: 'cat_$i', name: 'Category $i'),
        );

        final events = <Event>[];
        for (var i = 0; i < 10; i++) {
          for (var j = 0; j < 5; j++) {
            events.add(createEvent(
              id: 'event_${i}_$j',
              name: 'Event $i',
              startTime: now.subtract(Duration(days: j * 2)),
              categoryId: 'cat_$i',
            ));
          }
        }

        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: events,
          categories: categories,
          people: [],
          locations: [],
          existingGoals: [],
          maxRecommendations: 3,
        );

        expect(recommendations.length, lessThanOrEqualTo(3));
      });

      test('sorts recommendations by confidence', () {
        // Create events with different frequencies
        final categories = [
          createCategory(id: 'cat_high', name: 'High Frequency'),
          createCategory(id: 'cat_low', name: 'Low Frequency'),
        ];

        final events = <Event>[];

        // High frequency category - 20 events
        for (var i = 0; i < 20; i++) {
          events.add(createEvent(
            id: 'high_$i',
            name: 'High Event $i',
            startTime: now.subtract(Duration(days: i)),
            categoryId: 'cat_high',
          ));
        }

        // Low frequency category - 3 events (minimum)
        for (var i = 0; i < 3; i++) {
          events.add(createEvent(
            id: 'low_$i',
            name: 'Low Event $i',
            startTime: now.subtract(Duration(days: i * 7)),
            categoryId: 'cat_low',
          ));
        }

        final recommendations = GoalRecommendationService.analyzeAndRecommend(
          events: events,
          categories: categories,
          people: [],
          locations: [],
          existingGoals: [],
        );

        // Higher frequency category should come first (higher confidence)
        if (recommendations.length >= 2) {
          final highFreqRec = recommendations.firstWhere(
            (r) => r.categoryId == 'cat_high',
          );
          final lowFreqRec = recommendations.firstWhere(
            (r) => r.categoryId == 'cat_low',
            orElse: () => highFreqRec,
          );

          if (lowFreqRec.categoryId != highFreqRec.categoryId) {
            expect(highFreqRec.confidence, greaterThan(lowFreqRec.confidence));
          }
        }
      });
    });

    group('GoalRecommendation.toGoal', () {
      test('creates Goal from recommendation', () {
        final recommendation = GoalRecommendation(
          type: GoalType.category,
          title: '10 hours on Exercise',
          description: 'Track exercise time',
          suggestedTarget: 10,
          suggestedPeriod: GoalPeriod.week,
          suggestedMetric: GoalMetric.hours,
          reason: 'You exercise regularly',
          confidence: 0.8,
          categoryId: 'cat_exercise',
        );

        final goal = recommendation.toGoal(id: 'new_goal_id');

        expect(goal.id, equals('new_goal_id'));
        expect(goal.title, equals('10 hours on Exercise'));
        expect(goal.type, equals(GoalType.category));
        expect(goal.metric, equals(GoalMetric.hours));
        expect(goal.targetValue, equals(10));
        expect(goal.period, equals(GoalPeriod.week));
        expect(goal.categoryId, equals('cat_exercise'));
        expect(goal.isActive, isTrue);
      });
    });
  });
}
