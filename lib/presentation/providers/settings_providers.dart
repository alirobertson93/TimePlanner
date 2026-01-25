import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keys for SharedPreferences storage
class SettingsKeys {
  static const String timeSlotDuration = 'time_slot_duration';
  static const String workHoursStart = 'work_hours_start';
  static const String workHoursEnd = 'work_hours_end';
  static const String firstDayOfWeek = 'first_day_of_week';
  static const String defaultEventDuration = 'default_event_duration';
  static const String eventsMovableByDefault = 'events_movable_by_default';
  static const String eventsResizableByDefault = 'events_resizable_by_default';
  static const String eventRemindersEnabled = 'event_reminders_enabled';
  static const String defaultReminderMinutes = 'default_reminder_minutes';
  static const String goalAlertsEnabled = 'goal_alerts_enabled';
  static const String themeMode = 'theme_mode';
  static const String wizardAutoSuggest = 'wizard_auto_suggest';
  // Goal settings (Phase 9D)
  static const String defaultGoalPeriod = 'default_goal_period';
  static const String defaultGoalMetric = 'default_goal_metric';
  static const String showGoalWarnings = 'show_goal_warnings';
  static const String enableGoalRecommendations = 'enable_goal_recommendations';
}

/// Default values for settings
class SettingsDefaults {
  static const int timeSlotDuration = 15;
  static const int workHoursStart = 9; // 9 AM
  static const int workHoursEnd = 17; // 5 PM
  static const int firstDayOfWeek = 1; // Monday (1 = Monday, 7 = Sunday)
  static const int defaultEventDuration = 60; // 1 hour in minutes
  static const bool eventsMovableByDefault = true;
  static const bool eventsResizableByDefault = true;
  static const bool eventRemindersEnabled = true;
  static const int defaultReminderMinutes = 15;
  static const bool goalAlertsEnabled = true;
  static const String themeMode = 'system'; // 'system', 'light', 'dark'
  static const bool wizardAutoSuggest = false; // When true, auto-take first suggestion in Plan Week wizard
  // Goal settings (Phase 9D)
  static const int defaultGoalPeriod = 0; // week=0, month=1, quarter=2, year=3
  static const int defaultGoalMetric = 0; // hours=0, events=1, completions=2
  static const bool showGoalWarnings = true; // Show warnings for unachievable goals
  static const bool enableGoalRecommendations = true; // Enable goal recommendations
}

/// Application settings state
class AppSettings {
  final int timeSlotDuration;
  final int workHoursStart;
  final int workHoursEnd;
  final int firstDayOfWeek;
  final int defaultEventDuration;
  final bool eventsMovableByDefault;
  final bool eventsResizableByDefault;
  final bool eventRemindersEnabled;
  final int defaultReminderMinutes;
  final bool goalAlertsEnabled;
  final String themeMode;
  final bool wizardAutoSuggest;
  // Goal settings (Phase 9D)
  final int defaultGoalPeriod;
  final int defaultGoalMetric;
  final bool showGoalWarnings;
  final bool enableGoalRecommendations;

  const AppSettings({
    this.timeSlotDuration = SettingsDefaults.timeSlotDuration,
    this.workHoursStart = SettingsDefaults.workHoursStart,
    this.workHoursEnd = SettingsDefaults.workHoursEnd,
    this.firstDayOfWeek = SettingsDefaults.firstDayOfWeek,
    this.defaultEventDuration = SettingsDefaults.defaultEventDuration,
    this.eventsMovableByDefault = SettingsDefaults.eventsMovableByDefault,
    this.eventsResizableByDefault = SettingsDefaults.eventsResizableByDefault,
    this.eventRemindersEnabled = SettingsDefaults.eventRemindersEnabled,
    this.defaultReminderMinutes = SettingsDefaults.defaultReminderMinutes,
    this.goalAlertsEnabled = SettingsDefaults.goalAlertsEnabled,
    this.themeMode = SettingsDefaults.themeMode,
    this.wizardAutoSuggest = SettingsDefaults.wizardAutoSuggest,
    this.defaultGoalPeriod = SettingsDefaults.defaultGoalPeriod,
    this.defaultGoalMetric = SettingsDefaults.defaultGoalMetric,
    this.showGoalWarnings = SettingsDefaults.showGoalWarnings,
    this.enableGoalRecommendations = SettingsDefaults.enableGoalRecommendations,
  });

  AppSettings copyWith({
    int? timeSlotDuration,
    int? workHoursStart,
    int? workHoursEnd,
    int? firstDayOfWeek,
    int? defaultEventDuration,
    bool? eventsMovableByDefault,
    bool? eventsResizableByDefault,
    bool? eventRemindersEnabled,
    int? defaultReminderMinutes,
    bool? goalAlertsEnabled,
    String? themeMode,
    bool? wizardAutoSuggest,
    int? defaultGoalPeriod,
    int? defaultGoalMetric,
    bool? showGoalWarnings,
    bool? enableGoalRecommendations,
  }) {
    return AppSettings(
      timeSlotDuration: timeSlotDuration ?? this.timeSlotDuration,
      workHoursStart: workHoursStart ?? this.workHoursStart,
      workHoursEnd: workHoursEnd ?? this.workHoursEnd,
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
      defaultEventDuration: defaultEventDuration ?? this.defaultEventDuration,
      eventsMovableByDefault: eventsMovableByDefault ?? this.eventsMovableByDefault,
      eventsResizableByDefault: eventsResizableByDefault ?? this.eventsResizableByDefault,
      eventRemindersEnabled: eventRemindersEnabled ?? this.eventRemindersEnabled,
      defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
      goalAlertsEnabled: goalAlertsEnabled ?? this.goalAlertsEnabled,
      themeMode: themeMode ?? this.themeMode,
      wizardAutoSuggest: wizardAutoSuggest ?? this.wizardAutoSuggest,
      defaultGoalPeriod: defaultGoalPeriod ?? this.defaultGoalPeriod,
      defaultGoalMetric: defaultGoalMetric ?? this.defaultGoalMetric,
      showGoalWarnings: showGoalWarnings ?? this.showGoalWarnings,
      enableGoalRecommendations: enableGoalRecommendations ?? this.enableGoalRecommendations,
    );
  }

  /// Helper to get first day of week as a formatted string
  String get firstDayOfWeekLabel {
    switch (firstDayOfWeek) {
      case 7:
        return 'Sunday';
      case 6:
        return 'Saturday';
      default:
        return 'Monday';
    }
  }

  /// Helper to get time slot duration as a formatted string
  String get timeSlotDurationLabel {
    if (timeSlotDuration >= 60) {
      return '${timeSlotDuration ~/ 60} hour${timeSlotDuration >= 120 ? 's' : ''}';
    }
    return '$timeSlotDuration minutes';
  }

  /// Helper to get default event duration as a formatted string
  String get defaultEventDurationLabel {
    if (defaultEventDuration >= 60) {
      final hours = defaultEventDuration ~/ 60;
      final minutes = defaultEventDuration % 60;
      if (minutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      }
      return '$hours:${minutes.toString().padLeft(2, '0')} hours';
    }
    return '$defaultEventDuration minutes';
  }

  /// Helper to get default reminder time as a formatted string
  String get defaultReminderLabel {
    if (defaultReminderMinutes == 0) {
      return 'At time of event';
    } else if (defaultReminderMinutes >= 60 * 24) {
      return '1 day before';
    } else if (defaultReminderMinutes >= 60) {
      return '${defaultReminderMinutes ~/ 60} hour${defaultReminderMinutes >= 120 ? 's' : ''} before';
    }
    return '$defaultReminderMinutes minutes before';
  }

  /// Helper to get theme mode as a formatted string
  String get themeModeLabel {
    switch (themeMode) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      default:
        return 'System default';
    }
  }

  /// Helper to get work hours as a formatted string
  String get workHoursLabel {
    String formatHour(int hour) {
      if (hour == 0) return '12:00 AM';
      if (hour == 12) return '12:00 PM';
      if (hour < 12) return '$hour:00 AM';
      return '${hour - 12}:00 PM';
    }
    return '${formatHour(workHoursStart)} - ${formatHour(workHoursEnd)}';
  }

  /// Helper to get default goal period as a formatted string
  String get defaultGoalPeriodLabel {
    switch (defaultGoalPeriod) {
      case 0:
        return 'Weekly';
      case 1:
        return 'Monthly';
      case 2:
        return 'Quarterly';
      case 3:
        return 'Yearly';
      default:
        return 'Weekly';
    }
  }

  /// Helper to get default goal metric as a formatted string
  String get defaultGoalMetricLabel {
    switch (defaultGoalMetric) {
      case 0:
        return 'Hours';
      case 1:
        return 'Events';
      case 2:
        return 'Completions';
      default:
        return 'Hours';
    }
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Notifier for managing app settings with persistence
class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences? _prefs;

  SettingsNotifier(this._prefs) : super(const AppSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    if (_prefs == null) return;

    state = AppSettings(
      timeSlotDuration: _prefs!.getInt(SettingsKeys.timeSlotDuration) ?? SettingsDefaults.timeSlotDuration,
      workHoursStart: _prefs!.getInt(SettingsKeys.workHoursStart) ?? SettingsDefaults.workHoursStart,
      workHoursEnd: _prefs!.getInt(SettingsKeys.workHoursEnd) ?? SettingsDefaults.workHoursEnd,
      firstDayOfWeek: _prefs!.getInt(SettingsKeys.firstDayOfWeek) ?? SettingsDefaults.firstDayOfWeek,
      defaultEventDuration: _prefs!.getInt(SettingsKeys.defaultEventDuration) ?? SettingsDefaults.defaultEventDuration,
      eventsMovableByDefault: _prefs!.getBool(SettingsKeys.eventsMovableByDefault) ?? SettingsDefaults.eventsMovableByDefault,
      eventsResizableByDefault: _prefs!.getBool(SettingsKeys.eventsResizableByDefault) ?? SettingsDefaults.eventsResizableByDefault,
      eventRemindersEnabled: _prefs!.getBool(SettingsKeys.eventRemindersEnabled) ?? SettingsDefaults.eventRemindersEnabled,
      defaultReminderMinutes: _prefs!.getInt(SettingsKeys.defaultReminderMinutes) ?? SettingsDefaults.defaultReminderMinutes,
      goalAlertsEnabled: _prefs!.getBool(SettingsKeys.goalAlertsEnabled) ?? SettingsDefaults.goalAlertsEnabled,
      themeMode: _prefs!.getString(SettingsKeys.themeMode) ?? SettingsDefaults.themeMode,
      wizardAutoSuggest: _prefs!.getBool(SettingsKeys.wizardAutoSuggest) ?? SettingsDefaults.wizardAutoSuggest,
      // Goal settings (Phase 9D)
      defaultGoalPeriod: _prefs!.getInt(SettingsKeys.defaultGoalPeriod) ?? SettingsDefaults.defaultGoalPeriod,
      defaultGoalMetric: _prefs!.getInt(SettingsKeys.defaultGoalMetric) ?? SettingsDefaults.defaultGoalMetric,
      showGoalWarnings: _prefs!.getBool(SettingsKeys.showGoalWarnings) ?? SettingsDefaults.showGoalWarnings,
      enableGoalRecommendations: _prefs!.getBool(SettingsKeys.enableGoalRecommendations) ?? SettingsDefaults.enableGoalRecommendations,
    );
  }

  Future<void> setTimeSlotDuration(int minutes) async {
    state = state.copyWith(timeSlotDuration: minutes);
    await _prefs?.setInt(SettingsKeys.timeSlotDuration, minutes);
  }

  Future<void> setWorkHours(int start, int end) async {
    state = state.copyWith(workHoursStart: start, workHoursEnd: end);
    await _prefs?.setInt(SettingsKeys.workHoursStart, start);
    await _prefs?.setInt(SettingsKeys.workHoursEnd, end);
  }

  Future<void> setFirstDayOfWeek(int day) async {
    state = state.copyWith(firstDayOfWeek: day);
    await _prefs?.setInt(SettingsKeys.firstDayOfWeek, day);
  }

  Future<void> setDefaultEventDuration(int minutes) async {
    state = state.copyWith(defaultEventDuration: minutes);
    await _prefs?.setInt(SettingsKeys.defaultEventDuration, minutes);
  }

  Future<void> setEventsMovableByDefault(bool value) async {
    state = state.copyWith(eventsMovableByDefault: value);
    await _prefs?.setBool(SettingsKeys.eventsMovableByDefault, value);
  }

  Future<void> setEventsResizableByDefault(bool value) async {
    state = state.copyWith(eventsResizableByDefault: value);
    await _prefs?.setBool(SettingsKeys.eventsResizableByDefault, value);
  }

  Future<void> setEventRemindersEnabled(bool value) async {
    state = state.copyWith(eventRemindersEnabled: value);
    await _prefs?.setBool(SettingsKeys.eventRemindersEnabled, value);
  }

  Future<void> setDefaultReminderMinutes(int minutes) async {
    state = state.copyWith(defaultReminderMinutes: minutes);
    await _prefs?.setInt(SettingsKeys.defaultReminderMinutes, minutes);
  }

  Future<void> setGoalAlertsEnabled(bool value) async {
    state = state.copyWith(goalAlertsEnabled: value);
    await _prefs?.setBool(SettingsKeys.goalAlertsEnabled, value);
  }

  Future<void> setThemeMode(String mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs?.setString(SettingsKeys.themeMode, mode);
  }

  Future<void> setWizardAutoSuggest(bool value) async {
    state = state.copyWith(wizardAutoSuggest: value);
    await _prefs?.setBool(SettingsKeys.wizardAutoSuggest, value);
  }

  // Goal settings setters (Phase 9D)
  Future<void> setDefaultGoalPeriod(int period) async {
    state = state.copyWith(defaultGoalPeriod: period);
    await _prefs?.setInt(SettingsKeys.defaultGoalPeriod, period);
  }

  Future<void> setDefaultGoalMetric(int metric) async {
    state = state.copyWith(defaultGoalMetric: metric);
    await _prefs?.setInt(SettingsKeys.defaultGoalMetric, metric);
  }

  Future<void> setShowGoalWarnings(bool value) async {
    state = state.copyWith(showGoalWarnings: value);
    await _prefs?.setBool(SettingsKeys.showGoalWarnings, value);
  }

  Future<void> setEnableGoalRecommendations(bool value) async {
    state = state.copyWith(enableGoalRecommendations: value);
    await _prefs?.setBool(SettingsKeys.enableGoalRecommendations, value);
  }
}

/// Provider for app settings with persistence
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final prefs = prefsAsync.valueOrNull;
  return SettingsNotifier(prefs);
});
