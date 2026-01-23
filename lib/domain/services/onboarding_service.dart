import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing onboarding state and first-time user experience.
class OnboardingService {
  OnboardingService(this._prefs);

  final SharedPreferences _prefs;

  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _onboardingVersionKey = 'onboarding_version';
  static const String _sampleDataInstalledKey = 'sample_data_installed';
  static const String _tutorialSeenKey = 'tutorial_seen';

  /// Current onboarding version. Increment to re-show onboarding after major updates.
  static const int currentOnboardingVersion = 1;

  /// Check if onboarding has been completed
  bool get isOnboardingComplete {
    final version = _prefs.getInt(_onboardingVersionKey) ?? 0;
    final completed = _prefs.getBool(_onboardingCompleteKey) ?? false;
    return completed && version >= currentOnboardingVersion;
  }

  /// Check if this is a fresh install (never seen onboarding)
  bool get isFreshInstall {
    return !_prefs.containsKey(_onboardingCompleteKey);
  }

  /// Check if sample data has been installed
  bool get hasSampleDataInstalled {
    return _prefs.getBool(_sampleDataInstalledKey) ?? false;
  }

  /// Check if a specific tutorial has been seen
  bool hasTutorialBeenSeen(String tutorialKey) {
    return _prefs.getBool('${_tutorialSeenKey}_$tutorialKey') ?? false;
  }

  /// Mark onboarding as complete
  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingCompleteKey, true);
    await _prefs.setInt(_onboardingVersionKey, currentOnboardingVersion);
  }

  /// Mark sample data as installed
  Future<void> markSampleDataInstalled() async {
    await _prefs.setBool(_sampleDataInstalledKey, true);
  }

  /// Mark a specific tutorial as seen
  Future<void> markTutorialSeen(String tutorialKey) async {
    await _prefs.setBool('${_tutorialSeenKey}_$tutorialKey', true);
  }

  /// Reset onboarding state (for testing or re-onboarding)
  Future<void> resetOnboarding() async {
    await _prefs.remove(_onboardingCompleteKey);
    await _prefs.remove(_onboardingVersionKey);
  }

  /// Reset sample data flag (for testing)
  Future<void> resetSampleData() async {
    await _prefs.remove(_sampleDataInstalledKey);
  }
}

/// Keys for specific tutorials/feature guides
class TutorialKeys {
  static const String dayView = 'day_view';
  static const String weekView = 'week_view';
  static const String eventCreation = 'event_creation';
  static const String goalTracking = 'goal_tracking';
  static const String planningWizard = 'planning_wizard';
  static const String notifications = 'notifications';
}
