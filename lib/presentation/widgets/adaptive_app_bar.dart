import 'package:flutter/material.dart';

/// Represents an action item that can appear in the app bar or overflow menu
class AdaptiveAppBarAction {
  const AdaptiveAppBarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.priority = AdaptiveActionPriority.normal,
    this.badge,
  });

  /// The icon to display
  final Widget icon;

  /// The label for the tooltip and overflow menu
  final String label;

  /// Callback when the action is triggered
  final VoidCallback onPressed;

  /// Priority level for determining which actions stay visible
  final AdaptiveActionPriority priority;

  /// Optional badge widget (e.g., notification count)
  final Widget? badge;
}

/// Priority levels for app bar actions
/// Higher priority actions are more likely to remain visible on narrow screens
enum AdaptiveActionPriority {
  /// Navigation actions (prev/next) - always visible
  navigation,

  /// Core actions (plan week, view toggle) - visible if space allows
  core,

  /// Normal priority - may move to overflow
  normal,

  /// Low priority - first to move to overflow
  low,
}

/// A widget that builds an adaptive list of app bar actions
/// that collapses into an overflow menu on narrow screens.
class AdaptiveAppBarActions extends StatelessWidget {
  const AdaptiveAppBarActions({
    super.key,
    required this.actions,
    this.overflowIcon = const Icon(Icons.more_vert),
    this.overflowTooltip = 'More options',
  });

  /// List of actions to display
  final List<AdaptiveAppBarAction> actions;

  /// Icon for the overflow menu button
  final Widget overflowIcon;

  /// Tooltip for the overflow menu button
  final String overflowTooltip;

  /// Estimated width for each icon button
  static const double _iconButtonWidth = 48.0;

  /// Minimum width threshold before we start collapsing
  /// This accounts for the app bar title and some padding
  static const double _minAppBarContentWidth = 200.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many actions can fit
        // The constraints.maxWidth may be infinite (unconstrained),
        // so we use MediaQuery as a fallback
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Reserve space for title and leading widget
        final availableWidth = screenWidth - _minAppBarContentWidth;
        
        // Calculate how many icon buttons can fit
        final maxVisibleActions = (availableWidth / _iconButtonWidth).floor();
        
        // Sort actions by priority (navigation > core > normal > low)
        final sortedActions = List<AdaptiveAppBarAction>.from(actions)
          ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
        
        // Determine which actions to show and which to overflow
        // If all actions fit, show them all
        if (maxVisibleActions >= sortedActions.length) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: sortedActions.map((action) => _buildIconButton(action)).toList(),
          );
        }
        
        // Otherwise, show priority actions and put the rest in overflow
        // Reserve one slot for the overflow button
        final visibleCount = maxVisibleActions - 1;
        
        // Ensure we show at least the overflow button
        if (visibleCount < 0) {
          return _buildOverflowButton(context, sortedActions);
        }
        
        final visibleActions = sortedActions.take(visibleCount).toList();
        final overflowActions = sortedActions.skip(visibleCount).toList();
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...visibleActions.map((action) => _buildIconButton(action)),
            if (overflowActions.isNotEmpty)
              _buildOverflowButton(context, overflowActions),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(AdaptiveAppBarAction action) {
    Widget button = IconButton(
      icon: action.icon,
      onPressed: action.onPressed,
      tooltip: action.label,
    );
    
    // Wrap with badge if provided
    if (action.badge != null) {
      button = IconButton(
        icon: action.badge!,
        onPressed: action.onPressed,
        tooltip: action.label,
      );
    }
    
    return button;
  }

  Widget _buildOverflowButton(BuildContext context, List<AdaptiveAppBarAction> overflowActions) {
    return PopupMenuButton<int>(
      icon: overflowIcon,
      tooltip: overflowTooltip,
      onSelected: (index) {
        overflowActions[index].onPressed();
      },
      itemBuilder: (context) {
        return overflowActions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          return PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 24,
                  ),
                  child: action.icon,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(action.label)),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
