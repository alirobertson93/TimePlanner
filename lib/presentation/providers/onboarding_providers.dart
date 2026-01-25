import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/onboarding_service.dart';
import '../../domain/services/sample_data_service.dart';
import 'repository_providers.dart';

/// Provider for SharedPreferences (async initialization)
final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for the onboarding service
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) {
    throw Exception('SharedPreferences not initialized');
  }
  return OnboardingService(prefs);
});

/// Provider to check if onboarding is needed
final needsOnboardingProvider = Provider<bool>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) {
      final service = OnboardingService(prefs);
      return !service.isOnboardingComplete;
    },
    loading: () => true, // Assume onboarding needed until confirmed complete
    error: (_, __) => false,
  );
});

/// Provider to check if sample data should be offered
final shouldOfferSampleDataProvider = Provider<bool>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return prefsAsync.when(
    data: (prefs) {
      final service = OnboardingService(prefs);
      return service.isFreshInstall && !service.hasSampleDataInstalled;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for the sample data service
final sampleDataServiceProvider = Provider<SampleDataService>((ref) {
  return SampleDataService(
    eventRepository: ref.watch(eventRepositoryProvider),
    goalRepository: ref.watch(goalRepositoryProvider),
    personRepository: ref.watch(personRepositoryProvider),
    locationRepository: ref.watch(locationRepositoryProvider),
  );
});
