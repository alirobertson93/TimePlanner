import 'package:uuid/uuid.dart';

import '../entities/event.dart';
import '../entities/goal.dart';
import '../entities/person.dart';
import '../entities/location.dart';
import '../enums/timing_type.dart';
import '../enums/event_status.dart';
import '../enums/goal_type.dart';
import '../enums/goal_metric.dart';
import '../enums/goal_period.dart';
import '../enums/debt_strategy.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/person_repository.dart';
import '../../data/repositories/location_repository.dart';

/// Service for generating sample data to help users understand the app
class SampleDataService {
  SampleDataService({
    required this.eventRepository,
    required this.goalRepository,
    required this.personRepository,
    required this.locationRepository,
  });

  final IEventRepository eventRepository;
  final IGoalRepository goalRepository;
  final PersonRepository personRepository;
  final LocationRepository locationRepository;

  static const _uuid = Uuid();

  /// Generate all sample data
  Future<void> generateAllSampleData() async {
    await _generateLocations();
    await _generatePeople();
    await _generateGoals();
    await _generateEvents();
  }

  /// Generate sample locations
  Future<List<Location>> _generateLocations() async {
    final now = DateTime.now();
    final locations = [
      Location(
        id: _uuid.v4(),
        name: 'Home',
        address: '123 Main Street',
        createdAt: now,
      ),
      Location(
        id: _uuid.v4(),
        name: 'Office',
        address: '456 Business Ave',
        createdAt: now,
      ),
      Location(
        id: _uuid.v4(),
        name: 'Gym',
        address: '789 Fitness Blvd',
        createdAt: now,
      ),
      Location(
        id: _uuid.v4(),
        name: 'Coffee Shop',
        address: '321 Brew Lane',
        createdAt: now,
      ),
    ];

    for (final location in locations) {
      await locationRepository.save(location);
    }

    return locations;
  }

  /// Generate sample people
  Future<List<Person>> _generatePeople() async {
    final now = DateTime.now();
    final people = [
      Person(
        id: _uuid.v4(),
        name: 'Alex Johnson',
        email: 'alex@example.com',
        phone: '+1 555-0123',
        notes: 'Project collaborator',
        createdAt: now,
      ),
      Person(
        id: _uuid.v4(),
        name: 'Sam Williams',
        email: 'sam@example.com',
        notes: 'Gym buddy',
        createdAt: now,
      ),
      Person(
        id: _uuid.v4(),
        name: 'Jordan Lee',
        email: 'jordan@example.com',
        notes: 'Study group',
        createdAt: now,
      ),
    ];

    for (final person in people) {
      await personRepository.save(person);
    }

    return people;
  }

  /// Generate sample goals
  Future<List<Goal>> _generateGoals() async {
    final now = DateTime.now();
    final goals = [
      Goal(
        id: _uuid.v4(),
        title: 'Exercise',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 3, // 3 hours per week
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.carryForward,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Goal(
        id: _uuid.v4(),
        title: 'Reading',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 2, // 2 hours per week
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.carryForward,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      Goal(
        id: _uuid.v4(),
        title: 'Learning Spanish',
        type: GoalType.category,
        metric: GoalMetric.events,
        targetValue: 5, // 5 sessions per week
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.ignore,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final goal in goals) {
      await goalRepository.save(goal);
    }

    return goals;
  }

  /// Generate sample events
  Future<void> _generateEvents() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Create events for the next few days
    final events = <Event>[];

    // Today's events
    events.add(Event(
      id: _uuid.v4(),
      name: 'Morning Standup',
      description: 'Daily team sync meeting',
      timingType: TimingType.fixed,
      startTime: today.add(const Duration(hours: 9)),
      endTime: today.add(const Duration(hours: 9, minutes: 30)),
      duration: const Duration(minutes: 30),
      status: EventStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));

    events.add(Event(
      id: _uuid.v4(),
      name: 'Gym Session',
      description: 'Cardio and strength training',
      timingType: TimingType.flexible,
      startTime: today.add(const Duration(hours: 17)),
      endTime: today.add(const Duration(hours: 18)),
      duration: const Duration(minutes: 60),
      status: EventStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));

    // Tomorrow's events
    final tomorrow = today.add(const Duration(days: 1));
    
    events.add(Event(
      id: _uuid.v4(),
      name: 'Project Review',
      description: 'Weekly project status review',
      timingType: TimingType.fixed,
      startTime: tomorrow.add(const Duration(hours: 10)),
      endTime: tomorrow.add(const Duration(hours: 11)),
      duration: const Duration(minutes: 60),
      status: EventStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));

    events.add(Event(
      id: _uuid.v4(),
      name: 'Reading Time',
      description: 'Read current book',
      timingType: TimingType.flexible,
      startTime: tomorrow.add(const Duration(hours: 19)),
      endTime: tomorrow.add(const Duration(hours: 20)),
      duration: const Duration(minutes: 60),
      status: EventStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));

    // Day after tomorrow
    final dayAfter = today.add(const Duration(days: 2));

    events.add(Event(
      id: _uuid.v4(),
      name: 'Spanish Practice',
      description: 'Language learning session',
      timingType: TimingType.flexible,
      startTime: dayAfter.add(const Duration(hours: 18)),
      endTime: dayAfter.add(const Duration(hours: 18, minutes: 30)),
      duration: const Duration(minutes: 30),
      status: EventStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));

    events.add(Event(
      id: _uuid.v4(),
      name: 'Coffee with Alex',
      description: 'Catch up and discuss project ideas',
      timingType: TimingType.fixed,
      startTime: dayAfter.add(const Duration(hours: 15)),
      endTime: dayAfter.add(const Duration(hours: 16)),
      duration: const Duration(minutes: 60),
      status: EventStatus.pending,
      createdAt: now,
      updatedAt: now,
    ));

    for (final event in events) {
      await eventRepository.save(event);
    }
  }

  /// Clear all sample data (for testing or reset)
  Future<void> clearAllData() async {
    // Get all events and delete them
    final events = await eventRepository.getAll();
    for (final event in events) {
      await eventRepository.delete(event.id);
    }

    // Get all goals and delete them
    final goals = await goalRepository.getAll();
    for (final goal in goals) {
      await goalRepository.delete(goal.id);
    }

    // Get all people and delete them
    final people = await personRepository.getAll();
    for (final person in people) {
      await personRepository.delete(person.id);
    }

    // Get all locations and delete them
    final locations = await locationRepository.getAll();
    for (final location in locations) {
      await locationRepository.delete(location.id);
    }
  }
}
