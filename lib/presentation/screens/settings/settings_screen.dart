import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen for managing user preferences and settings
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            subtitle: '15 minutes',
            onTap: () => _showTimeSlotDurationDialog(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.work_outline,
            title: 'Work Hours',
            subtitle: '9:00 AM - 5:00 PM',
            onTap: () => _showWorkHoursDialog(context),
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.calendar_today,
            title: 'First Day of Week',
            subtitle: 'Monday',
            onTap: () => _showFirstDayOfWeekDialog(context),
          ),

          const Divider(),

          // Default Event Settings Section
          _buildSectionHeader(context, 'Default Event Settings'),
          _buildSettingsTile(
            context: context,
            icon: Icons.timer,
            title: 'Default Event Duration',
            subtitle: '1 hour',
            onTap: () => _showDefaultDurationDialog(context),
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.open_with,
            title: 'Events Movable by Default',
            subtitle: 'Allow app to reschedule events',
            value: true,
            onChanged: (value) {
              // TODO: Save preference
            },
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.aspect_ratio,
            title: 'Events Resizable by Default',
            subtitle: 'Allow app to adjust event duration',
            value: true,
            onChanged: (value) {
              // TODO: Save preference
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
            value: true,
            onChanged: (value) {
              // TODO: Save preference
            },
          ),
          _buildSettingsTile(
            context: context,
            icon: Icons.access_time,
            title: 'Default Reminder Time',
            subtitle: '15 minutes before',
            onTap: () => _showReminderTimeDialog(context),
          ),
          _buildSwitchTile(
            context: context,
            icon: Icons.warning_amber,
            title: 'Goal Progress Alerts',
            subtitle: 'Notify when goals are at risk',
            value: true,
            onChanged: (value) {
              // TODO: Save preference
            },
          ),

          const Divider(),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingsTile(
            context: context,
            icon: Icons.palette,
            title: 'Theme',
            subtitle: 'System default',
            onTap: () => _showThemeDialog(context),
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
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
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
    return SwitchListTile(
      secondary: Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  void _showTimeSlotDurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Time Slot Duration'),
        children: [
          _buildRadioOption(context, '5 minutes', false),
          _buildRadioOption(context, '10 minutes', false),
          _buildRadioOption(context, '15 minutes', true),
          _buildRadioOption(context, '30 minutes', false),
          _buildRadioOption(context, '1 hour', false),
        ],
      ),
    );
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

  void _showFirstDayOfWeekDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('First Day of Week'),
        children: [
          _buildRadioOption(context, 'Sunday', false),
          _buildRadioOption(context, 'Monday', true),
          _buildRadioOption(context, 'Saturday', false),
        ],
      ),
    );
  }

  void _showDefaultDurationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Event Duration'),
        children: [
          _buildRadioOption(context, '15 minutes', false),
          _buildRadioOption(context, '30 minutes', false),
          _buildRadioOption(context, '1 hour', true),
          _buildRadioOption(context, '2 hours', false),
        ],
      ),
    );
  }

  void _showReminderTimeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Reminder Time'),
        children: [
          _buildRadioOption(context, 'At time of event', false),
          _buildRadioOption(context, '5 minutes before', false),
          _buildRadioOption(context, '15 minutes before', true),
          _buildRadioOption(context, '30 minutes before', false),
          _buildRadioOption(context, '1 hour before', false),
          _buildRadioOption(context, '1 day before', false),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          _buildRadioOption(context, 'System default', true),
          _buildRadioOption(context, 'Light', false),
          _buildRadioOption(context, 'Dark', false),
        ],
      ),
    );
  }

  Widget _buildRadioOption(BuildContext context, String label, bool selected) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.of(context).pop();
        // TODO: Save the selection
      },
      child: Row(
        children: [
          Radio<bool>(
            value: true,
            groupValue: selected,
            onChanged: (_) {
              Navigator.of(context).pop();
              // TODO: Save the selection
            },
          ),
          Text(label),
        ],
      ),
    );
  }
}
