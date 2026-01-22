import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/enums/recurrence_frequency.dart';
import 'repository_providers.dart';

/// Provider for all recurrence rules
final allRecurrenceRulesProvider = FutureProvider<List<RecurrenceRule>>((ref) async {
  final repository = ref.watch(recurrenceRuleRepositoryProvider);
  return repository.getAll();
});

/// Provider for watching all recurrence rules (reactive)
final watchAllRecurrenceRulesProvider = StreamProvider<List<RecurrenceRule>>((ref) {
  final repository = ref.watch(recurrenceRuleRepositoryProvider);
  return repository.watchAll();
});

/// Provider for getting a recurrence rule by ID
final recurrenceRuleByIdProvider = FutureProvider.family<RecurrenceRule?, String>((ref, id) async {
  final repository = ref.watch(recurrenceRuleRepositoryProvider);
  return repository.getById(id);
});

/// Provider for getting recurrence rules by frequency
final recurrenceRulesByFrequencyProvider = FutureProvider.family<List<RecurrenceRule>, RecurrenceFrequency>((ref, frequency) async {
  final repository = ref.watch(recurrenceRuleRepositoryProvider);
  return repository.getByFrequency(frequency);
});
