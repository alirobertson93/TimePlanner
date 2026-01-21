import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/person.dart';
import 'repository_providers.dart';

part 'person_providers.g.dart';

/// Provider for all people
@riverpod
Future<List<Person>> allPeople(AllPeopleRef ref) async {
  final repository = ref.watch(personRepositoryProvider);
  return repository.getAll();
}

/// Provider for watching all people (reactive)
@riverpod
Stream<List<Person>> watchAllPeople(WatchAllPeopleRef ref) {
  final repository = ref.watch(personRepositoryProvider);
  return repository.watchAll();
}

/// Provider for getting people associated with an event
@riverpod
Future<List<Person>> peopleForEvent(
  PeopleForEventRef ref,
  String eventId,
) async {
  final repository = ref.watch(eventPeopleRepositoryProvider);
  return repository.getPeopleForEvent(eventId);
}

/// Provider for watching people associated with an event (reactive)
@riverpod
Stream<List<Person>> watchPeopleForEvent(
  WatchPeopleForEventRef ref,
  String eventId,
) {
  final repository = ref.watch(eventPeopleRepositoryProvider);
  return repository.watchPeopleForEvent(eventId);
}

/// Provider for searching people by name
@riverpod
Future<List<Person>> searchPeople(
  SearchPeopleRef ref,
  String query,
) async {
  if (query.isEmpty) {
    return ref.watch(allPeopleProvider.future);
  }
  final repository = ref.watch(personRepositoryProvider);
  return repository.searchByName(query);
}

/// Provider for a single person by ID
@riverpod
Future<Person?> personById(PersonByIdRef ref, String id) async {
  final repository = ref.watch(personRepositoryProvider);
  return repository.getById(id);
}
