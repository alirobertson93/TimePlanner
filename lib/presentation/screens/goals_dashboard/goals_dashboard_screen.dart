import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/goal_providers.dart';
import '../../providers/goal_analysis_providers.dart';
import '../../providers/category_providers.dart';
import '../../providers/person_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/settings_providers.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../domain/services/goal_warning_service.dart';
import '../../../domain/services/goal_recommendation_service.dart';

/// Goals Dashboard screen showing goal progress
class GoalsDashboardScreen extends ConsumerWidget {
  const GoalsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsWithProgressProvider);
    final summaryAsync = ref.watch(goalsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/day'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/goal/new'),
            tooltip: 'Add Goal',
          ),
        ],
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildGoalsList(context, ref, goals, summaryAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Goals Set',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create goals to track your time allocation and stay on target.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.push('/goal/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Goal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Goals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsList(
    BuildContext context,
    WidgetRef ref,
    List<GoalProgress> goals,
    AsyncValue<GoalsSummary> summaryAsync,
  ) {
    final settings = ref.watch(settingsProvider);
    final warningsAsync = ref.watch(goalWarningsSummaryProvider);
    final recommendationsAsync = ref.watch(goalRecommendationsProvider);

    // Group goals by period
    final weeklyGoals =
        goals.where((g) => g.goal.period == GoalPeriod.week).toList();
    final monthlyGoals =
        goals.where((g) => g.goal.period == GoalPeriod.month).toList();
    final quarterlyGoals =
        goals.where((g) => g.goal.period == GoalPeriod.quarter).toList();
    final yearlyGoals =
        goals.where((g) => g.goal.period == GoalPeriod.year).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(goalsWithProgressProvider);
        ref.invalidate(goalWarningsProvider);
        ref.invalidate(goalRecommendationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Summary Card
          summaryAsync.when(
            data: (summary) => _buildSummaryCard(context, summary),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),

          // Warnings Card (if enabled and has warnings)
          if (settings.showGoalWarnings)
            warningsAsync.when(
              data: (summary) => summary.hasWarnings
                  ? _buildWarningsCard(context, ref, summary)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          // Recommendations Card (if enabled and has recommendations)
          if (settings.enableGoalRecommendations)
            recommendationsAsync.when(
              data: (recommendations) => recommendations.isNotEmpty
                  ? _buildRecommendationsCard(context, ref, recommendations)
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

          const SizedBox(height: 8),

          // Weekly Goals
          if (weeklyGoals.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Week'),
            const SizedBox(height: 12),
            ...weeklyGoals.map((goal) => _buildGoalCard(context, ref, goal)),
            const SizedBox(height: 24),
          ],

          // Monthly Goals
          if (monthlyGoals.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Month'),
            const SizedBox(height: 12),
            ...monthlyGoals.map((goal) => _buildGoalCard(context, ref, goal)),
            const SizedBox(height: 24),
          ],

          // Quarterly Goals
          if (quarterlyGoals.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Quarter'),
            const SizedBox(height: 12),
            ...quarterlyGoals.map((goal) => _buildGoalCard(context, ref, goal)),
            const SizedBox(height: 24),
          ],

          // Yearly Goals
          if (yearlyGoals.isNotEmpty) ...[
            _buildSectionHeader(context, 'This Year'),
            const SizedBox(height: 12),
            ...yearlyGoals.map((goal) => _buildGoalCard(context, ref, goal)),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, GoalsSummary summary) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Goal Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  context,
                  '${summary.onTrack}',
                  'On Track',
                  Colors.green,
                  Icons.check_circle_outline,
                ),
                _buildSummaryItem(
                  context,
                  '${summary.atRisk}',
                  'At Risk',
                  Colors.orange,
                  Icons.warning_amber_outlined,
                ),
                _buildSummaryItem(
                  context,
                  '${summary.behind}',
                  'Behind',
                  Colors.red,
                  Icons.cancel_outlined,
                ),
              ],
            ),
            if (summary.totalGoals > 0) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: summary.onTrackPercent / 100,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.onTrackPercent.toStringAsFixed(0)}% of goals on track',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Semantics(
      label: '$value goals $label',
      child: Column(
        children: [
          Icon(icon, color: color, size: 28, semanticLabel: ''),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildWarningsCard(
      BuildContext context, WidgetRef ref, GoalWarningsSummary summary) {
    return Card(
      elevation: 2,
      color: summary.hasCritical
          ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.8)
          : Colors.orange.withOpacity(0.2),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showWarningsDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                summary.hasCritical ? Icons.error : Icons.warning_amber,
                color:
                    summary.hasCritical ? Colors.red : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.hasCritical
                          ? 'Critical Goal Warnings'
                          : 'Goal Warnings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${summary.total} warning${summary.total > 1 ? 's' : ''} - tap to view',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showWarningsDialog(BuildContext context, WidgetRef ref) async {
    final warnings = await ref.read(goalWarningsProvider.future);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Goal Warnings')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: warnings.isEmpty
              ? const Text('No warnings at this time.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: warnings.length,
                  itemBuilder: (context, index) {
                    final warning = warnings[index];
                    return ListTile(
                      leading: Icon(
                        warning.severity == GoalWarningSeverity.critical
                            ? Icons.error
                            : warning.severity == GoalWarningSeverity.warning
                                ? Icons.warning_amber
                                : Icons.info_outline,
                        color:
                            warning.severity == GoalWarningSeverity.critical
                                ? Colors.red
                                : warning.severity ==
                                        GoalWarningSeverity.warning
                                    ? Colors.orange
                                    : Colors.blue,
                      ),
                      title: Text(warning.goalTitle),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(warning.message),
                          if (warning.suggestedAction != null)
                            Text(
                              '💡 ${warning.suggestedAction}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                        ],
                      ),
                      isThreeLine: warning.suggestedAction != null,
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, WidgetRef ref,
      List<GoalRecommendation> recommendations) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _showRecommendationsDialog(context, ref, recommendations),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Recommendations',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${recommendations.length} suggestion${recommendations.length > 1 ? 's' : ''} based on your activity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  void _showRecommendationsDialog(BuildContext context, WidgetRef ref,
      List<GoalRecommendation> recommendations) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Goal Recommendations')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recommendations.length,
            itemBuilder: (context, index) {
              final rec = recommendations[index];
              final confidencePercent = (rec.confidence * 100).round();
              return Card(
                child: ListTile(
                  leading: Icon(
                    rec.type == GoalType.category
                        ? Icons.category
                        : rec.type == GoalType.location
                            ? Icons.location_on
                            : rec.type == GoalType.person
                                ? Icons.person
                                : Icons.event,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(rec.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.reason),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.analytics,
                              size: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Confidence: $confidencePercent%',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Create this goal',
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to goal form with pre-filled data
                      // For now, just navigate to new goal form
                      context.push('/goal/new');
                    },
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(
      BuildContext context, WidgetRef ref, GoalProgress goalProgress) {
    final categoryAsync = goalProgress.goal.categoryId != null
        ? ref.watch(categoryByIdProvider(goalProgress.goal.categoryId!))
        : null;
    final personAsync = goalProgress.goal.personId != null
        ? ref.watch(personByIdProvider(goalProgress.goal.personId!))
        : null;
    final locationAsync = goalProgress.goal.locationId != null
        ? ref.watch(locationByIdProvider(goalProgress.goal.locationId!))
        : null;

    // Get display info based on goal type
    Color indicatorColor = ColorUtils.defaultCategoryColor;
    String? targetName;
    IconData targetIcon = Icons.track_changes;

    // For category goals
    if (goalProgress.goal.type == GoalType.category && categoryAsync != null) {
      categoryAsync.when(
        data: (category) {
          if (category != null) {
            targetName = category.name;
            indicatorColor = ColorUtils.parseHexColor(category.colourHex);
            targetIcon = Icons.category;
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }

    // For relationship goals
    if (goalProgress.goal.type == GoalType.person && personAsync != null) {
      personAsync.when(
        data: (person) {
          if (person != null) {
            targetName = person.name;
            indicatorColor = Theme.of(context).colorScheme.secondary;
            targetIcon = Icons.person;
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }

    // For location goals
    if (goalProgress.goal.type == GoalType.location && locationAsync != null) {
      locationAsync.when(
        data: (location) {
          if (location != null) {
            targetName = location.name;
            indicatorColor = Theme.of(context).colorScheme.tertiary;
            targetIcon = Icons.location_on;
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    }

    // For event goals
    if (goalProgress.goal.type == GoalType.event &&
        goalProgress.goal.eventTitle != null) {
      targetName = goalProgress.goal.eventTitle;
      indicatorColor = Theme.of(context).colorScheme.primary;
      targetIcon = Icons.event;
    }

    // Get status color
    Color statusColor;
    switch (goalProgress.status) {
      case GoalProgressStatus.onTrack:
        statusColor = Colors.green;
        break;
      case GoalProgressStatus.atRisk:
        statusColor = Colors.orange;
        break;
      case GoalProgressStatus.behind:
        statusColor = Colors.red;
        break;
    }

    // Build semantic label for screen readers
    String semanticLabel = goalProgress.goal.title;
    if (targetName != null) {
      semanticLabel += ', for $targetName';
    }
    semanticLabel += ', ${goalProgress.statusText}';
    semanticLabel += ', ${goalProgress.progressPercentText} complete';
    semanticLabel += '. Tap to edit.';

    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () => context.push('/goal/${goalProgress.goal.id}/edit'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: indicatorColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(targetIcon, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  goalProgress.goal.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          if (targetName != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (goalProgress.goal.type ==
                                    GoalType.person) ...[
                                  Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: indicatorColor,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                if (goalProgress.goal.type ==
                                    GoalType.location) ...[
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: indicatorColor,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                if (goalProgress.goal.type ==
                                    GoalType.event) ...[
                                  Icon(
                                    Icons.event_outlined,
                                    size: 14,
                                    color: indicatorColor,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  targetName!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: indicatorColor,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            goalProgress.statusIcon,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            goalProgress.statusText,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      goalProgress.progressText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      goalProgress.progressPercentText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goalProgress.progressPercent,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
