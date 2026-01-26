import 'package:flutter/material.dart';
import '../../domain/enums/edit_scope.dart';

/// Dialog that prompts the user to select the scope of an edit operation.
/// 
/// This dialog is shown when a user edits an activity that belongs to a
/// series. The user can choose to apply the changes to just this activity,
/// all activities in the series, or (for recurring activities) this and
/// all future activities.
/// 
/// Use [showEditScopeDialog] for the standard use case which returns the
/// selected scope through the dialog's Future.
class EditScopeDialog extends StatefulWidget {
  const EditScopeDialog({
    super.key,
    required this.activityTitle,
    required this.seriesCount,
    required this.isRecurring,
  });

  /// The title of the activity being edited
  final String activityTitle;

  /// The number of activities in the series
  final int seriesCount;

  /// Whether the activity is part of a recurring schedule
  final bool isRecurring;

  @override
  State<EditScopeDialog> createState() => _EditScopeDialogState();
}

class _EditScopeDialogState extends State<EditScopeDialog> {
  EditScope _selectedScope = EditScope.thisOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        widget.activityTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.seriesCount} ${widget.seriesCount == 1 ? 'activity' : 'activities'} in this series',
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
          const SizedBox(height: 16),
          Text(
            'What would you like to edit?',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _buildScopeOption(EditScope.thisOnly),
          _buildScopeOption(EditScope.allInSeries),
          if (widget.isRecurring) _buildScopeOption(EditScope.thisAndFuture),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedScope),
          child: const Text('Continue'),
        ),
      ],
    );
  }

  Widget _buildScopeOption(EditScope scope) {
    return RadioListTile<EditScope>(
      title: Text(scope.label),
      subtitle: Text(
        scope.description,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: scope,
      groupValue: _selectedScope,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedScope = value);
        }
      },
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

/// Shows the edit scope dialog and returns the user's choice.
/// 
/// Returns the selected [EditScope], or `null` if the dialog was dismissed.
Future<EditScope?> showEditScopeDialog(
  BuildContext context, {
  required String activityTitle,
  required int seriesCount,
  required bool isRecurring,
}) {
  return showDialog<EditScope>(
    context: context,
    builder: (context) => EditScopeDialog(
      activityTitle: activityTitle,
      seriesCount: seriesCount,
      isRecurring: isRecurring,
    ),
  );
}
