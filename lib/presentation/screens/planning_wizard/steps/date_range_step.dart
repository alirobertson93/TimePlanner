import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../providers/planning_wizard_providers.dart';

/// Step 1: Date range selection for the planning window
class DateRangeStep extends ConsumerWidget {
  const DateRangeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(planningWizardProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Plan your week',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the date range you want to plan for. The scheduler will arrange your flexible activities within this period.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Quick selection buttons
          _buildQuickSelections(context, ref, wizardState),
          const SizedBox(height: 32),

          // Start date picker
          _buildDatePicker(
            context: context,
            label: 'Start Date',
            date: wizardState.startDate,
            onDateSelected: (date) {
              ref.read(planningWizardProvider.notifier).updateStartDate(date);
            },
          ),
          const SizedBox(height: 24),

          // End date picker
          _buildDatePicker(
            context: context,
            label: 'End Date',
            date: wizardState.endDate,
            firstDate: wizardState.startDate,
            onDateSelected: (date) {
              ref.read(planningWizardProvider.notifier).updateEndDate(date);
            },
          ),
          const SizedBox(height: 32),

          // Summary
          if (wizardState.startDate != null && wizardState.endDate != null)
            _buildSummary(context, wizardState),

          // Error message
          if (wizardState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      wizardState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickSelections(
      BuildContext context, WidgetRef ref, PlanningWizardState state) {
    final now = DateTime.now();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickSelectChip(
              context: context,
              ref: ref,
              label: 'This Week',
              isSelected: _isThisWeek(state),
              onTap: () {
                final monday = _getStartOfWeek(now);
                final sunday = monday.add(const Duration(days: 6));
                ref.read(planningWizardProvider.notifier).updateStartDate(monday);
                ref.read(planningWizardProvider.notifier).updateEndDate(sunday);
              },
            ),
            _buildQuickSelectChip(
              context: context,
              ref: ref,
              label: 'Next Week',
              isSelected: _isNextWeek(state),
              onTap: () {
                final nextMonday = _getStartOfWeek(now.add(const Duration(days: 7)));
                final nextSunday = nextMonday.add(const Duration(days: 6));
                ref.read(planningWizardProvider.notifier).updateStartDate(nextMonday);
                ref.read(planningWizardProvider.notifier).updateEndDate(nextSunday);
              },
            ),
            _buildQuickSelectChip(
              context: context,
              ref: ref,
              label: 'Next 7 Days',
              isSelected: _isNext7Days(state),
              onTap: () {
                final today = DateTime(now.year, now.month, now.day);
                final endDate = today.add(const Duration(days: 6));
                ref.read(planningWizardProvider.notifier).updateStartDate(today);
                ref.read(planningWizardProvider.notifier).updateEndDate(endDate);
              },
            ),
            _buildQuickSelectChip(
              context: context,
              ref: ref,
              label: 'Next 14 Days',
              isSelected: _isNext14Days(state),
              onTap: () {
                final today = DateTime(now.year, now.month, now.day);
                final endDate = today.add(const Duration(days: 13));
                ref.read(planningWizardProvider.notifier).updateStartDate(today);
                ref.read(planningWizardProvider.notifier).updateEndDate(endDate);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickSelectChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }

  DateTime _getStartOfWeek(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  bool _isThisWeek(PlanningWizardState state) {
    if (state.startDate == null || state.endDate == null) return false;
    final now = DateTime.now();
    final monday = _getStartOfWeek(now);
    final sunday = monday.add(const Duration(days: 6));
    return _isSameDay(state.startDate!, monday) && _isSameDay(state.endDate!, sunday);
  }

  bool _isNextWeek(PlanningWizardState state) {
    if (state.startDate == null || state.endDate == null) return false;
    final now = DateTime.now();
    final nextMonday = _getStartOfWeek(now.add(const Duration(days: 7)));
    final nextSunday = nextMonday.add(const Duration(days: 6));
    return _isSameDay(state.startDate!, nextMonday) && _isSameDay(state.endDate!, nextSunday);
  }

  bool _isNext7Days(PlanningWizardState state) {
    if (state.startDate == null || state.endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(const Duration(days: 6));
    return _isSameDay(state.startDate!, today) && _isSameDay(state.endDate!, endDate);
  }

  bool _isNext14Days(PlanningWizardState state) {
    if (state.startDate == null || state.endDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = today.add(const Duration(days: 13));
    return _isSameDay(state.startDate!, today) && _isSameDay(state.endDate!, endDate);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime? date,
    DateTime? firstDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    final dateFormat = DateFormat.yMMMMd();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: firstDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (selectedDate != null) {
              onDateSelected(selectedDate);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date) : 'Select date',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: date != null
                              ? null
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context, PlanningWizardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Planning window: ${state.daysInWindow} days',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
