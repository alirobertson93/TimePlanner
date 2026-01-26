import 'package:flutter/material.dart';
import '../../domain/entities/activity_series.dart';

/// Dialog that prompts the user to add an activity to an existing series.
/// 
/// This dialog is shown when a user creates or edits an activity that
/// matches an existing series. The user can choose to add the activity
/// to the series or keep it as a standalone activity.
class SeriesPromptDialog extends StatelessWidget {
  const SeriesPromptDialog({
    super.key,
    required this.matchingSeries,
    required this.onAddToSeries,
    required this.onKeepStandalone,
  });

  /// The matching series that the activity could be added to
  final ActivitySeries matchingSeries;

  /// Callback when user chooses to add the activity to the series
  final VoidCallback onAddToSeries;

  /// Callback when user chooses to keep the activity as standalone
  final VoidCallback onKeepStandalone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Similar Activity Found'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This looks similar to an existing activity:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        matchingSeries.displayTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${matchingSeries.count} previous ${matchingSeries.count == 1 ? 'time' : 'times'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildOption(
            context,
            icon: Icons.link,
            title: 'Add to this series',
            subtitle:
                'Changes to shared properties will apply to all activities in the series',
            onTap: () {
              Navigator.pop(context);
              onAddToSeries();
            },
          ),
          const SizedBox(height: 8),
          _buildOption(
            context,
            icon: Icons.link_off,
            title: 'Keep as standalone',
            subtitle: "This activity won't be linked to any others",
            onTap: () {
              Navigator.pop(context);
              onKeepStandalone();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.5),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the series prompt dialog and returns the user's choice.
/// 
/// Returns `true` if the user chose to add to series, `false` if they
/// chose to keep standalone, or `null` if the dialog was dismissed.
Future<bool?> showSeriesPromptDialog(
  BuildContext context, {
  required ActivitySeries matchingSeries,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => SeriesPromptDialog(
      matchingSeries: matchingSeries,
      onAddToSeries: () {
        Navigator.pop(context, true);
      },
      onKeepStandalone: () {
        Navigator.pop(context, false);
      },
    ),
  );
}
