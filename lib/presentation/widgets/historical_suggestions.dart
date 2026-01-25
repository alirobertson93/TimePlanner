import 'package:flutter/material.dart';
import '../../domain/services/historical_event_service.dart';

/// Widget that displays historical activity suggestions as selectable chips
/// Used in Goal Form to show smart suggestions based on past event data
class HistoricalSuggestionsCard extends StatelessWidget {
  const HistoricalSuggestionsCard({
    super.key,
    required this.title,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.selectedId,
    this.isLoading = false,
    this.emptyMessage,
  });

  /// Card title (e.g., "Based on your activity")
  final String title;

  /// List of suggestions to display
  final List<HistoricalActivityPattern> suggestions;

  /// Callback when a suggestion is selected
  final Function(HistoricalActivityPattern) onSuggestionSelected;

  /// Currently selected suggestion ID (for highlighting)
  final String? selectedId;

  /// Whether suggestions are loading
  final bool isLoading;

  /// Message to show when no suggestions available
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Analyzing your activity...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (suggestions.isEmpty) {
      if (emptyMessage == null) {
        return const SizedBox.shrink();
      }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  emptyMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions.map((suggestion) {
                final isSelected = suggestion.id == selectedId;
                return _SuggestionChip(
                  suggestion: suggestion,
                  isSelected: isSelected,
                  onTap: () => onSuggestionSelected(suggestion),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual suggestion chip with activity details
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.isSelected,
    required this.onTap,
  });

  final HistoricalActivityPattern suggestion;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final weeklyHours = suggestion.weeklyHours;
    final hoursText = weeklyHours >= 1
        ? '${weeklyHours.toStringAsFixed(1)}h/wk'
        : '${(weeklyHours * 60).round()}m/wk';

    return ActionChip(
      avatar: isSelected
          ? Icon(
              Icons.check_circle,
              size: 18,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            )
          : _getIconForType(context, suggestion.patternType),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(suggestion.name),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              hoursText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
            ),
          ),
        ],
      ),
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      onPressed: onTap,
    );
  }

  Widget _getIconForType(BuildContext context, HistoricalPatternType type) {
    IconData iconData;
    switch (type) {
      case HistoricalPatternType.category:
        iconData = Icons.category;
        break;
      case HistoricalPatternType.person:
        iconData = Icons.person;
        break;
      case HistoricalPatternType.location:
        iconData = Icons.location_on;
        break;
      case HistoricalPatternType.eventTitle:
        iconData = Icons.event;
        break;
    }
    return Icon(
      iconData,
      size: 18,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}

/// Simplified inline suggestion list for specific fields
class InlineSuggestionList extends StatelessWidget {
  const InlineSuggestionList({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
    this.selectedId,
    this.isLoading = false,
  });

  final List<HistoricalActivityPattern> suggestions;
  final Function(HistoricalActivityPattern) onSuggestionSelected;
  final String? selectedId;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Loading suggestions...',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Based on your activity:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: suggestions.take(3).map((suggestion) {
            final isSelected = suggestion.id == selectedId;
            return ActionChip(
              visualDensity: VisualDensity.compact,
              label: Text(
                '${suggestion.name} (${suggestion.weeklyHours.toStringAsFixed(1)}h/wk)',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              onPressed: () => onSuggestionSelected(suggestion),
            );
          }).toList(),
        ),
      ],
    );
  }
}
