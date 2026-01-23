import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/planning_wizard_providers.dart';
import 'steps/date_range_step.dart';
import 'steps/goals_review_step.dart';
import 'steps/strategy_selection_step.dart';
import 'steps/plan_review_step.dart';

/// Main planning wizard screen with 4-step flow
class PlanningWizardScreen extends ConsumerStatefulWidget {
  const PlanningWizardScreen({super.key});

  @override
  ConsumerState<PlanningWizardScreen> createState() =>
      _PlanningWizardScreenState();
}

class _PlanningWizardScreenState extends ConsumerState<PlanningWizardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize wizard on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(planningWizardProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(planningWizardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle(wizardState.currentStep)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showCancelConfirmation(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildStepIndicator(wizardState.currentStep),

          // Step content
          Expanded(
            child: _buildStepContent(wizardState.currentStep),
          ),

          // Navigation buttons
          _buildNavigationButtons(context, wizardState),
        ],
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Select Date Range';
      case 1:
        return 'Review Goals';
      case 2:
        return 'Choose Strategy';
      case 3:
        return 'Review Schedule';
      default:
        return 'Planning Wizard';
    }
  }

  Widget _buildStepIndicator(int currentStep) {
    return Semantics(
      label: 'Step ${currentStep + 1} of 4: ${_getStepTitle(currentStep)}',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i <= currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
              _buildStepCircle(i, currentStep),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle(int step, int currentStep) {
    final isCompleted = step < currentStep;
    final isCurrent = step == currentStep;
    final theme = Theme.of(context);
    final stepTitle = _getStepTitle(step);

    return Semantics(
      label: isCompleted
          ? 'Step ${step + 1}: $stepTitle, completed'
          : isCurrent
              ? 'Step ${step + 1}: $stepTitle, current step'
              : 'Step ${step + 1}: $stepTitle',
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted || isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          border: isCurrent
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: isCompleted
              ? Icon(
                  Icons.check,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                  semanticLabel: 'Completed',
                )
              : Text(
                  '${step + 1}',
                  style: TextStyle(
                    color: isCurrent
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return const DateRangeStep();
      case 1:
        return const GoalsReviewStep();
      case 2:
        return const StrategySelectionStep();
      case 3:
        return const PlanReviewStep();
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  Widget _buildNavigationButtons(
      BuildContext context, PlanningWizardState wizardState) {
    final isLastStep = wizardState.currentStep == 3;
    final isGeneratingStep = wizardState.currentStep == 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Back button
            if (wizardState.canGoBack)
              Expanded(
                child: Semantics(
                  button: true,
                  label: 'Go back to previous step',
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(planningWizardProvider.notifier).previousStep();
                    },
                    child: const Text('Back'),
                  ),
                ),
              )
            else
              const Spacer(),

            const SizedBox(width: 16),

            // Next/Generate/Accept button
            Expanded(
              child: Semantics(
                button: true,
                label: wizardState.isGenerating
                    ? 'Generating schedule, please wait'
                    : isGeneratingStep
                        ? 'Generate schedule'
                        : isLastStep
                            ? 'Accept and save schedule'
                            : 'Continue to next step',
                child: FilledButton(
                  onPressed: wizardState.isGenerating
                      ? null
                      : () async {
                          if (isGeneratingStep) {
                            await ref
                                .read(planningWizardProvider.notifier)
                                .generateSchedule();
                          } else if (isLastStep) {
                            final success = await ref
                                .read(planningWizardProvider.notifier)
                                .acceptSchedule();
                            if (success && context.mounted) {
                              _showSuccessAndNavigate(context);
                            }
                          } else if (wizardState.canProceed) {
                            ref
                                .read(planningWizardProvider.notifier)
                                .nextStep();
                          }
                        },
                  child: wizardState.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isGeneratingStep
                              ? 'Generate Schedule'
                              : isLastStep
                                  ? 'Accept Schedule'
                                  : 'Next',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Planning?'),
        content: const Text(
          'Are you sure you want to cancel? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/day');
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSuccessAndNavigate(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule saved successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/week');
  }
}
