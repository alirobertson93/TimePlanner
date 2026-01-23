import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            title: 'Events Movable by Default',
            subtitle: 'Allow app to reschedule events',
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
            onTap: () {
              // TODO: Show terms of service
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: null,
            onTap: () {
              // TODO: Show privacy policy
            },
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
}
