import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/onboarding_providers.dart';
import '../../providers/settings_providers.dart';

/// Screen for managing user preferences and settings
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/day'),
        ),
      ),
      body: ListView(
        children: [
          // Schedule Settings Section
          _buildSectionHeader(context, 'Schedule'),
          _buildSettingsTile(
            context: context,
            icon: Icons.schedule,
            title: 'Time Slot Duration',
            subtitle: settings.timeSlotDurationLabel,
            onTap: () => _showTimeSlotDurationDialog(
                context, ref, settings.timeSlotDuration),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.work_outline,
            title: 'Work Hours',
            subtitle: settings.workHoursLabel,
            onTap: () => _showWorkHoursDialog(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.calendar_today,
            title: 'First Day of Week',
            subtitle: settings.firstDayOfWeekLabel,
            onTap: () => _showFirstDayOfWeekDialog(
                context, ref, settings.firstDayOfWeek),
          ),

          const Divider(),

          // Default Event Settings Section
          _buildSectionHeader(context, 'Default Event Settings'),
          _buildSettingsTile(
            context: context,
            icon: Icons.timer,
            title: 'Default Event Duration',
            subtitle: settings.defaultEventDurationLabel,
            onTap: () => _showDefaultDurationDialog(
                context, ref, settings.defaultEventDuration),
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.open_with,
            title: 'Activities Movable by Default',
            subtitle: 'Allow app to reschedule activities',
            value: settings.eventsMovableByDefault,
            onChanged: (value) {
              settingsNotifier.setEventsMovableByDefault(value);
            },
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.aspect_ratio,
            title: 'Events Resizable by Default',
            subtitle: 'Allow app to adjust event duration',
            value: settings.eventsResizableByDefault,
            onChanged: (value) {
              settingsNotifier.setEventsResizableByDefault(value);
            },
          ),

          const Divider(),

          // Notification Settings Section
          _buildSectionHeader(context, 'Notifications'),
          _buildSwitchTile(
            context: context,
            icon: Icons.notifications,
            title: 'Event Reminders',
            subtitle: 'Get notified before events',
            value: settings.eventRemindersEnabled,
            onChanged: (value) {
              settingsNotifier.setEventRemindersEnabled(value);
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.access_time,
            title: 'Default Reminder Time',
            subtitle: settings.defaultReminderLabel,
            onTap: () => _showReminderTimeDialog(
                context, ref, settings.defaultReminderMinutes),
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.warning_amber,
            title: 'Goal Progress Alerts',
            subtitle: 'Notify when goals are at risk',
            value: settings.goalAlertsEnabled,
            onChanged: (value) {
              settingsNotifier.setGoalAlertsEnabled(value);
            },
          ),

          const Divider(),

          // Planning Wizard Section
          _buildSectionHeader(context, 'Planning Wizard'),
          _buildSwitchTile(
            context: context,
            icon: Icons.auto_awesome,
            title: 'Auto-Select Suggestions',
            subtitle: 'Automatically use the first suggested event for goals',
            value: settings.wizardAutoSuggest,
            onChanged: (value) {
              settingsNotifier.setWizardAutoSuggest(value);
            },
          ),

          const Divider(),

          // Goals Section (Phase 9D)
          _buildSectionHeader(context, 'Goals'),
          _buildSettingsTile(
            context: context,
            icon: Icons.calendar_view_week,
            title: 'Default Goal Period',
            subtitle: settings.defaultGoalPeriodLabel,
            onTap: () => _showDefaultGoalPeriodDialog(
                context, ref, settings.defaultGoalPeriod),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.straighten,
            title: 'Default Goal Metric',
            subtitle: settings.defaultGoalMetricLabel,
            onTap: () => _showDefaultGoalMetricDialog(
                context, ref, settings.defaultGoalMetric),
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.warning_amber,
            title: 'Show Goal Warnings',
            subtitle: 'Alert when goals may be unachievable',
            value: settings.showGoalWarnings,
            onChanged: (value) {
              settingsNotifier.setShowGoalWarnings(value);
            },
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.lightbulb_outline,
            title: 'Goal Recommendations',
            subtitle: 'Suggest goals based on your activity patterns',
            value: settings.enableGoalRecommendations,
            onChanged: (value) {
              settingsNotifier.setEnableGoalRecommendations(value);
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsTile(
            context: context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: settings.themeModeLabel,
            onTap: () => _showThemeDialog(context, ref, settings.themeMode),
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingsTile(
            context: context,
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.description,
            title: 'Terms of Service',
            subtitle: null,
            onTap: () => _showTermsOfServiceDialog(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: null,
            onTap: () => _showPrivacyPolicyDialog(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.play_circle_outline,
            title: 'Replay Onboarding',
            subtitle: 'See the welcome wizard again',
            onTap: () => _showReplayOnboardingDialog(context, ref),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: subtitle != null ? '$title, current value: $subtitle' : title,
      child: ListTile(
        leading: Icon(icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: ''),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.chevron_right, semanticLabel: ''),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Semantics(
      toggled: value,
      label: subtitle != null ? '$title, $subtitle' : title,
      child: SwitchListTile(
        secondary: Icon(icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: ''),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showTimeSlotDurationDialog(
      BuildContext context, WidgetRef ref, int currentValue) async {
    final options = [
      (5, '5 minutes'),
      (10, '10 minutes'),
      (15, '15 minutes'),
      (30, '30 minutes'),
      (60, '1 hour'),
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Time Slot Duration'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setTimeSlotDuration(result);
    }
  }

  void _showWorkHoursDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Work Hours'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Configure work hours in a future update.'),
            SizedBox(height: 16),
            Text('Current: 9:00 AM - 5:00 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFirstDayOfWeekDialog(
      BuildContext context, WidgetRef ref, int currentValue) async {
    final options = [
      (7, 'Sunday'),
      (1, 'Monday'),
      (6, 'Saturday'),
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('First Day of Week'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setFirstDayOfWeek(result);
    }
  }

  void _showDefaultDurationDialog(
      BuildContext context, WidgetRef ref, int currentValue) async {
    final options = [
      (15, '15 minutes'),
      (30, '30 minutes'),
      (60, '1 hour'),
      (120, '2 hours'),
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Event Duration'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setDefaultEventDuration(result);
    }
  }

  void _showReminderTimeDialog(
      BuildContext context, WidgetRef ref, int currentValue) async {
    final options = [
      (0, 'At time of event'),
      (5, '5 minutes before'),
      (15, '15 minutes before'),
      (30, '30 minutes before'),
      (60, '1 hour before'),
      (1440, '1 day before'),
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Reminder Time'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setDefaultReminderMinutes(result);
    }
  }

  void _showThemeDialog(
      BuildContext context, WidgetRef ref, String currentValue) async {
    final options = [
      ('system', 'System default'),
      ('light', 'Light'),
      ('dark', 'Dark'),
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setThemeMode(result);
    }
  }

  void _showDefaultGoalPeriodDialog(
      BuildContext context, WidgetRef ref, int currentValue) async {
    final options = [
      (0, 'Weekly'),
      (1, 'Monthly'),
      (2, 'Quarterly'),
      (3, 'Yearly'),
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Goal Period'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setDefaultGoalPeriod(result);
    }
  }

  void _showDefaultGoalMetricDialog(
      BuildContext context, WidgetRef ref, int currentValue) async {
    final options = [
      (0, 'Hours'),
      (1, 'Events'),
      (2, 'Completions'),
    ];

    final result = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Goal Metric'),
        children: options.map((option) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(option.$1),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: option.$1 == currentValue
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.radio_button_unchecked,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
                const SizedBox(width: 12),
                Text(option.$2),
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (result != null) {
      ref.read(settingsProvider.notifier).setDefaultGoalMetric(result);
    }
  }

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Terms of Service'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: 2026-01-24',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                _buildLegalSection(context, 'Agreement to Terms',
                    'By downloading, installing, or using TimePlanner ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, do not use the App.'),
                _buildLegalSection(context, 'Description of Service',
                    'TimePlanner is a smart time planning application that helps you:\n• Manage events and appointments\n• Set and track personal and professional goals\n• Generate optimized schedules using intelligent algorithms\n• Organize contacts and locations associated with your activities'),
                _buildLegalSection(context, 'Use License',
                    'We grant you a limited, non-exclusive, non-transferable, revocable license to download, install, and use the App on your personal device(s) for personal, non-commercial purposes.\n\nYou may NOT:\n• Copy, modify, or distribute the App\n• Reverse engineer, decompile, or disassemble the App\n• Use the App for any illegal purpose'),
                _buildLegalSection(context, 'User Content and Data',
                    'You retain all rights to the data you enter into the App. This data is stored locally on your device. You are solely responsible for maintaining backups of your data.'),
                _buildLegalSection(context, 'Disclaimer of Warranties',
                    'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.'),
                _buildLegalSection(context, 'Limitation of Liability',
                    'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APP.'),
                _buildLegalSection(context, 'Contact',
                    'For questions about these Terms, please contact us at:\nEmail: legal@timeplanner.app'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Privacy Policy'),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: 2026-01-24',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                _buildLegalSection(context, 'Introduction',
                    'Welcome to TimePlanner. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.\n\nPlease read this Privacy Policy carefully. By using the App, you agree to the collection and use of information in accordance with this policy.'),
                _buildLegalSection(context, 'Information Stored Locally',
                    'TimePlanner is designed with a privacy-first, offline-first architecture. All your data is stored locally on your device:\n• Events and Calendar Data\n• Categories\n• Goals\n• People\n• Locations\n• Preferences\n\nThis data never leaves your device unless you explicitly export it.'),
                _buildLegalSection(context, 'Information We Do NOT Collect',
                    '• We do NOT collect personal identification information\n• We do NOT track your location\n• We do NOT collect analytics\n• We do NOT sell or share your data\n• We do NOT use advertising or ad tracking'),
                _buildLegalSection(context, 'Data Storage and Security',
                    'All data is stored in a SQLite database on your device. This data is protected by your device\'s security (passcode, biometrics), not accessible to other apps, and not transmitted over the internet.'),
                _buildLegalSection(context, 'Your Data Rights',
                    'Since all data is stored locally, you have complete control:\n• View all your data within the App\n• Edit or update any data\n• Delete individual items\n• Uninstalling the App removes all data'),
                _buildLegalSection(context, 'Contact',
                    'If you have questions about this Privacy Policy, please contact us at:\nEmail: privacy@timeplanner.app'),
                const SizedBox(height: 16),
                _buildSummaryTable(context),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showReplayOnboardingDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replay Onboarding?'),
        content: const Text(
            'This will show the welcome wizard again. Your data will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(onboardingServiceProvider);
              await service.resetOnboarding();
              // Invalidate the shared preferences provider to force refresh of onboarding state
              ref.invalidate(sharedPreferencesProvider);
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
            child: const Text('Show Wizard'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(
      BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTable(BuildContext context) {
    final rows = [
      ('Data Storage', '100% local on your device'),
      ('Data Transmission', 'None - offline-first'),
      ('Analytics', 'None'),
      ('Advertising', 'None'),
      ('Third-party Sharing', 'None'),
      ('User Control', 'Complete - you own your data'),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Category',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'How We Handle It',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ),
          ...rows.map((row) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
