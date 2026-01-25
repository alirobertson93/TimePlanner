import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/repositories/event_repository.dart';
import '../../data/repositories/goal_repository.dart';
import '../../data/repositories/person_repository.dart';
import '../../data/repositories/event_people_repository.dart';
import '../../data/repositories/location_repository.dart';
import '../../data/repositories/recurrence_rule_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/travel_time_pair_repository.dart';
import 'database_provider.dart';

/// Provider for the event repository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(databaseProvider));
});

/// Provider for the category repository
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(databaseProvider));
});

/// Provider for the goal repository
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(databaseProvider));
});

/// Provider for the person repository
final personRepositoryProvider = Provider<PersonRepository>((ref) {
  return PersonRepository(ref.watch(databaseProvider));
});

/// Provider for the event-people repository
final eventPeopleRepositoryProvider = Provider<EventPeopleRepository>((ref) {
  return EventPeopleRepository(ref.watch(databaseProvider));
});

/// Provider for the location repository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(databaseProvider));
});

/// Provider for the recurrence rule repository
final recurrenceRuleRepositoryProvider = Provider<RecurrenceRuleRepository>((ref) {
  return RecurrenceRuleRepository(ref.watch(databaseProvider));
});

/// Provider for the notification repository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(databaseProvider));
});

/// Provider for the travel time pair repository
final travelTimePairRepositoryProvider = Provider<TravelTimePairRepository>((ref) {
  return TravelTimePairRepository(ref.watch(databaseProvider));
});
