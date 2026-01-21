import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/goal_providers.dart';
import '../../providers/category_providers.dart';
import '../../../core/utils/color_utils.dart';
import '../../../domain/enums/goal_period.dart';

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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    // Group goals by period
    final weeklyGoals = goals.where((g) => g.goal.period == GoalPeriod.week).toList();
    final monthlyGoals = goals.where((g) => g.goal.period == GoalPeriod.month).toList();
    final quarterlyGoals = goals.where((g) => g.goal.period == GoalPeriod.quarter).toList();
    final yearlyGoals = goals.where((g) => g.goal.period == GoalPeriod.year).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(goalsWithProgressProvider);
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
          const SizedBox(height: 24),
          
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
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
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

  Widget _buildGoalCard(BuildContext context, WidgetRef ref, GoalProgress goalProgress) {
    final categoryAsync = goalProgress.goal.categoryId != null
        ? ref.watch(categoryByIdProvider(goalProgress.goal.categoryId!))
        : null;

    // Get category color
    Color categoryColor = ColorUtils.defaultCategoryColor;
    String? categoryName;
    
    if (categoryAsync != null) {
      categoryAsync.when(
        data: (category) {
          if (category != null) {
            categoryName = category.name;
            categoryColor = ColorUtils.parseHexColor(category.colourHex);
          }
        },
        loading: () {},
        error: (_, __) {},
      );
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

    return Card(
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
                      color: categoryColor,
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
                            const Icon(Icons.track_changes, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                goalProgress.goal.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (categoryName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            categoryName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
