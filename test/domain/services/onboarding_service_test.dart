import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test/test.dart';
import 'package:time_planner/domain/services/onboarding_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('OnboardingService', () {
    late MockSharedPreferences mockPrefs;
    late OnboardingService service;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      service = OnboardingService(mockPrefs);
    });

    group('isOnboardingComplete', () {
      test('returns false when both keys are missing', () {
        when(() => mockPrefs.getInt('onboarding_version')).thenReturn(null);
        when(() => mockPrefs.getBool('onboarding_complete')).thenReturn(null);

        expect(service.isOnboardingComplete, false);
      });

      test('returns false when completed but version is lower', () {
        when(() => mockPrefs.getInt('onboarding_version')).thenReturn(0);
        when(() => mockPrefs.getBool('onboarding_complete')).thenReturn(true);

        expect(service.isOnboardingComplete, false);
      });

      test('returns true when completed and version matches', () {
        when(() => mockPrefs.getInt('onboarding_version'))
            .thenReturn(OnboardingService.currentOnboardingVersion);
        when(() => mockPrefs.getBool('onboarding_complete')).thenReturn(true);

        expect(service.isOnboardingComplete, true);
      });

      test('returns false when version matches but not completed', () {
        when(() => mockPrefs.getInt('onboarding_version'))
            .thenReturn(OnboardingService.currentOnboardingVersion);
        when(() => mockPrefs.getBool('onboarding_complete')).thenReturn(false);

        expect(service.isOnboardingComplete, false);
      });
    });

    group('isFreshInstall', () {
      test('returns true when onboarding_complete key is missing', () {
        when(() => mockPrefs.containsKey('onboarding_complete'))
            .thenReturn(false);

        expect(service.isFreshInstall, true);
      });

      test('returns false when onboarding_complete key exists', () {
        when(() => mockPrefs.containsKey('onboarding_complete'))
            .thenReturn(true);

        expect(service.isFreshInstall, false);
      });
    });

    group('completeOnboarding', () {
      test('sets completion flag and version', () async {
        when(() => mockPrefs.setBool('onboarding_complete', true))
            .thenAnswer((_) async => true);
        when(() => mockPrefs.setInt('onboarding_version',
                OnboardingService.currentOnboardingVersion))
            .thenAnswer((_) async => true);

        await service.completeOnboarding();

        verify(() => mockPrefs.setBool('onboarding_complete', true)).called(1);
        verify(() => mockPrefs.setInt('onboarding_version',
            OnboardingService.currentOnboardingVersion)).called(1);
      });
    });

    group('resetOnboarding', () {
      test('removes completion flag and version', () async {
        when(() => mockPrefs.remove('onboarding_complete'))
            .thenAnswer((_) async => true);
        when(() => mockPrefs.remove('onboarding_version'))
            .thenAnswer((_) async => true);

        await service.resetOnboarding();

        verify(() => mockPrefs.remove('onboarding_complete')).called(1);
        verify(() => mockPrefs.remove('onboarding_version')).called(1);
      });
    });
  });
}
