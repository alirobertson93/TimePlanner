import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/event.dart';
import '../../../domain/entities/goal.dart';
import '../../../domain/entities/location.dart';
import '../../../domain/entities/person.dart';
import '../../../domain/entities/recurrence_rule.dart';
import '../../../domain/enums/debt_strategy.dart';
import '../../../domain/enums/event_status.dart';
import '../../../domain/enums/goal_metric.dart';
import '../../../domain/enums/goal_period.dart';
import '../../../domain/enums/goal_type.dart';
import '../../../domain/enums/recurrence_end_type.dart';
import '../../../domain/enums/recurrence_frequency.dart';
import '../../../domain/enums/timing_type.dart';
import '../../providers/onboarding_providers.dart';
import '../../providers/repository_providers.dart';

/// Enhanced onboarding wizard that guides users through setting up their
/// recurring schedule, people, goals, and places.
class EnhancedOnboardingScreen extends ConsumerStatefulWidget {
  const EnhancedOnboardingScreen({super.key});

  @override
  ConsumerState<EnhancedOnboardingScreen> createState() =>
      _EnhancedOnboardingScreenState();
}

class _EnhancedOnboardingScreenState
    extends ConsumerState<EnhancedOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Data collected during onboarding
  final List<_RecurringEventData> _recurringEvents = [];
  final List<_PersonWithGoalData> _peopleWithGoals = [];
  final List<_ActivityGoalData> _activityGoals = [];
  final List<_LocationWithGoalData> _locationsWithGoals = [];

  static const int _totalPages = 6;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    _completeOnboarding(skipDataCreation: true);
  }

  Future<void> _completeOnboarding({bool skipDataCreation = false}) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (!skipDataCreation) {
        await _saveAllOnboardingData();
      }

      final service = ref.read(onboardingServiceProvider);
      await service.completeOnboarding();

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context); // Close loading dialog
      }

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing setup: $e')),
        );
        context.go('/');
      }
    }
  }

  Future<void> _saveAllOnboardingData() async {
    const uuid = Uuid();
    final now = DateTime.now();

    // Save recurring events
    final eventRepo = ref.read(eventRepositoryProvider);
    final recurrenceRepo = ref.read(recurrenceRuleRepositoryProvider);

    for (final eventData in _recurringEvents) {
      // Create recurrence rule
      final recurrenceRule = RecurrenceRule(
        id: uuid.v4(),
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        byWeekDay: eventData.selectedDays,
        endType: RecurrenceEndType.never,
        createdAt: now,
      );
      await recurrenceRepo.save(recurrenceRule);

      // Create event
      final event = Event(
        id: uuid.v4(),
        name: eventData.name,
        description: eventData.description,
        timingType: TimingType.fixed,
        startTime: _combineDateAndTime(now, eventData.startHour, eventData.startMinute),
        endTime: _combineDateAndTime(now, eventData.endHour, eventData.endMinute),
        duration: Duration(
          hours: eventData.endHour - eventData.startHour,
          minutes: eventData.endMinute - eventData.startMinute,
        ),
        recurrenceRuleId: recurrenceRule.id,
        appCanMove: false,
        appCanResize: false,
        isUserLocked: true,
        status: EventStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
      await eventRepo.save(event);
    }

    // Save people and their goals
    final personRepo = ref.read(personRepositoryProvider);
    final goalRepo = ref.read(goalRepositoryProvider);

    for (final personData in _peopleWithGoals) {
      // Create person
      final person = Person(
        id: uuid.v4(),
        name: personData.name,
        email: personData.email,
        phone: personData.phone,
        createdAt: now,
      );
      await personRepo.save(person);

      // Create goal for this person if specified
      if (personData.targetHours > 0) {
        final goal = Goal(
          id: uuid.v4(),
          title: 'Time with ${personData.name}',
          type: GoalType.person,
          metric: GoalMetric.hours,
          targetValue: personData.targetHours,
          period: personData.period,
          personId: person.id,
          debtStrategy: DebtStrategy.carryForward,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await goalRepo.save(goal);
      }
    }

    // Save activity goals
    for (final activityData in _activityGoals) {
      final goal = Goal(
        id: uuid.v4(),
        title: activityData.name,
        type: GoalType.custom,
        metric: GoalMetric.hours,
        targetValue: activityData.targetHours,
        period: activityData.period,
        debtStrategy: DebtStrategy.carryForward,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      await goalRepo.save(goal);
    }

    // Save locations and their goals
    final locationRepo = ref.read(locationRepositoryProvider);

    for (final locationData in _locationsWithGoals) {
      // Create location
      final location = Location(
        id: uuid.v4(),
        name: locationData.name,
        address: locationData.address,
        createdAt: now,
      );
      await locationRepo.save(location);

      // Create goal for this location if specified
      // Note: Location goals would need to be implemented via custom goals
      // or by extending the Goal type. For now, we create a custom goal.
      if (locationData.targetHours > 0) {
        final goal = Goal(
          id: uuid.v4(),
          title: 'Time at ${locationData.name}',
          type: GoalType.custom,
          metric: GoalMetric.hours,
          targetValue: locationData.targetHours,
          period: locationData.period,
          debtStrategy: DebtStrategy.carryForward,
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );
        await goalRepo.save(goal);
      }
    }
  }

  DateTime _combineDateAndTime(DateTime date, int hour, int minute) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Semantics(
                button: true,
                label: 'Skip onboarding and go to app',
                child: TextButton(
                  onPressed: _skipOnboarding,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _totalPages,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomePage(theme),
                  _buildRecurringEventsPage(theme),
                  _buildPeopleGoalsPage(theme),
                  _buildActivityGoalsPage(theme),
                  _buildLocationsPage(theme),
                  _buildSummaryPage(theme),
                ],
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextPage,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                      ),
                      child: Text(
                        _currentPage == _totalPages - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule,
              size: 64,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Welcome to TimePlanner',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Let's set up your recurring weekly schedule. This will help the app understand your commitments and plan your time more effectively.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  "In the next few steps, you'll add:",
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _buildSetupItem(Icons.repeat, 'Recurring events (work, gym, etc.)'),
                _buildSetupItem(Icons.people, 'People you want to spend time with'),
                _buildSetupItem(Icons.flag, 'Activity goals (exercise, reading, etc.)'),
                _buildSetupItem(Icons.location_on, 'Your main locations'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildRecurringEventsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.repeat, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Recurring Fixed Events',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add events that happen at the same time each week, like work shifts, classes, or regular appointments.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // List of added recurring events
          if (_recurringEvents.isNotEmpty) ...[
            ..._recurringEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.event_repeat),
                  title: Text(event.name),
                  subtitle: Text(
                    '${_formatTime(event.startHour, event.startMinute)} - ${_formatTime(event.endHour, event.endMinute)} • ${_formatDays(event.selectedDays)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _recurringEvents.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Add new recurring event button
          OutlinedButton.icon(
            onPressed: () => _showAddRecurringEventDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Recurring Event'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          if (_recurringEvents.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                'No recurring events added yet.\nYou can skip this step or add them later.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPeopleGoalsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'People & Time Goals',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add important people in your life and set goals for how much time you want to spend with them.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // List of added people
          if (_peopleWithGoals.isNotEmpty) ...[
            ..._peopleWithGoals.asMap().entries.map((entry) {
              final index = entry.key;
              final person = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(person.name[0].toUpperCase()),
                  ),
                  title: Text(person.name),
                  subtitle: person.targetHours > 0
                      ? Text(
                          '${person.targetHours} hours ${person.period == GoalPeriod.week ? "per week" : "per month"}',
                        )
                      : const Text('No time goal set'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _peopleWithGoals.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: () => _showAddPersonDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Person'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          if (_peopleWithGoals.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Text(
                'No people added yet.\nAdd family, friends, or colleagues to track time with them.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityGoalsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Activity Goals',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Set goals for activities you want to make time for each week or month, like exercise, reading, hobbies, or learning.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // List of added activity goals
          if (_activityGoals.isNotEmpty) ...[
            ..._activityGoals.asMap().entries.map((entry) {
              final index = entry.key;
              final goal = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.track_changes),
                  title: Text(goal.name),
                  subtitle: Text(
                    '${goal.targetHours} hours ${goal.period == GoalPeriod.week ? "per week" : "per month"}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _activityGoals.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: () => _showAddActivityGoalDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Add Activity Goal'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          if (_activityGoals.isEmpty) ...[
            const SizedBox(height: 24),
            _buildSuggestedGoals(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedGoals(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested Activities',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildSuggestionChip('Exercise', 3),
            _buildSuggestionChip('Reading', 2),
            _buildSuggestionChip('Learning', 2),
            _buildSuggestionChip('Meditation', 1),
            _buildSuggestionChip('Hobbies', 3),
            _buildSuggestionChip('Side Project', 5),
          ],
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String name, int suggestedHours) {
    return ActionChip(
      avatar: const Icon(Icons.add, size: 18),
      label: Text(name),
      onPressed: () {
        setState(() {
          _activityGoals.add(_ActivityGoalData(
            name: name,
            targetHours: suggestedHours,
            period: GoalPeriod.week,
          ));
        });
      },
    );
  }

  Widget _buildLocationsPage(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your Places',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add your main locations. You can also set goals for time spent at specific places.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // List of added locations
          if (_locationsWithGoals.isNotEmpty) ...[
            ..._locationsWithGoals.asMap().entries.map((entry) {
              final index = entry.key;
              final location = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.place),
                  title: Text(location.name),
                  subtitle: location.targetHours > 0
                      ? Text(
                          '${location.targetHours} hours ${location.period == GoalPeriod.week ? "per week" : "per month"}',
                        )
                      : Text(location.address ?? 'No address'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      setState(() {
                        _locationsWithGoals.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          OutlinedButton.icon(
            onPressed: () => _showAddLocationDialog(),
            icon: const Icon(Icons.add_location),
            label: const Text('Add Location'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),

          if (_locationsWithGoals.isEmpty) ...[
            const SizedBox(height: 24),
            _buildSuggestedLocations(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestedLocations(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Add',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildLocationChip('Home', Icons.home),
            _buildLocationChip('Office', Icons.business),
            _buildLocationChip('Gym', Icons.fitness_center),
            _buildLocationChip('Coffee Shop', Icons.local_cafe),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationChip(String name, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(name),
      onPressed: () {
        setState(() {
          _locationsWithGoals.add(_LocationWithGoalData(
            name: name,
            address: null,
            targetHours: 0,
            period: GoalPeriod.week,
          ));
        });
      },
    );
  }

  Widget _buildSummaryPage(ThemeData theme) {
    final totalItems = _recurringEvents.length +
        _peopleWithGoals.length +
        _activityGoals.length +
        _locationsWithGoals.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 56,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "You're All Set!",
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            totalItems > 0
                ? "Here's a summary of what you've set up:"
                : "You can always add these later in the app settings.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          if (totalItems > 0) ...[
            _buildSummarySection(
              theme,
              'Recurring Events',
              Icons.repeat,
              _recurringEvents.length,
            ),
            _buildSummarySection(
              theme,
              'People Added',
              Icons.people,
              _peopleWithGoals.length,
            ),
            _buildSummarySection(
              theme,
              'Activity Goals',
              Icons.flag,
              _activityGoals.length,
            ),
            _buildSummarySection(
              theme,
              'Locations',
              Icons.location_on,
              _locationsWithGoals.length,
            ),
          ],

          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Use the Planning Wizard to automatically schedule your flexible events around your fixed commitments.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(
    ThemeData theme,
    String title,
    IconData icon,
    int count,
  ) {
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog methods
  Future<void> _showAddRecurringEventDialog() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int startHour = 9;
    int startMinute = 0;
    int endHour = 17;
    int endMinute = 0;
    List<int> selectedDays = [1, 2, 3, 4, 5]; // Mon-Fri by default

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Recurring Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name *',
                    hintText: 'e.g., Work, Gym, Class',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Time'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: startHour, minute: startMinute),
                          );
                          if (time != null) {
                            setDialogState(() {
                              startHour = time.hour;
                              startMinute = time.minute;
                            });
                          }
                        },
                        child: Text(_formatTime(startHour, startMinute)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('to'),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(hour: endHour, minute: endMinute),
                          );
                          if (time != null) {
                            setDialogState(() {
                              endHour = time.hour;
                              endMinute = time.minute;
                            });
                          }
                        },
                        child: Text(_formatTime(endHour, endMinute)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Repeat on'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    _buildDayChip('S', 0, selectedDays, setDialogState),
                    _buildDayChip('M', 1, selectedDays, setDialogState),
                    _buildDayChip('T', 2, selectedDays, setDialogState),
                    _buildDayChip('W', 3, selectedDays, setDialogState),
                    _buildDayChip('T', 4, selectedDays, setDialogState),
                    _buildDayChip('F', 5, selectedDays, setDialogState),
                    _buildDayChip('S', 6, selectedDays, setDialogState),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an event name')),
                  );
                  return;
                }
                if (selectedDays.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one day')),
                  );
                  return;
                }
                setState(() {
                  _recurringEvents.add(_RecurringEventData(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    startHour: startHour,
                    startMinute: startMinute,
                    endHour: endHour,
                    endMinute: endMinute,
                    selectedDays: selectedDays,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayChip(
    String label,
    int day,
    List<int> selectedDays,
    void Function(void Function()) setDialogState,
  ) {
    final isSelected = selectedDays.contains(day);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setDialogState(() {
          if (selected) {
            selectedDays.add(day);
          } else {
            selectedDays.remove(day);
          }
        });
      },
    );
  }

  Future<void> _showAddPersonDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    int targetHours = 0;
    GoalPeriod period = GoalPeriod.week;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Person'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Mom, Partner, Friend',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                const Text('Time Goal (optional)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: targetHours,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(21, (i) => i).map((hours) {
                          return DropdownMenuItem(
                            value: hours,
                            child: Text(hours == 0 ? 'No goal' : '$hours'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            targetHours = value ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<GoalPeriod>(
                        value: period,
                        decoration: const InputDecoration(
                          labelText: 'Period',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GoalPeriod.week,
                            child: Text('Per week'),
                          ),
                          DropdownMenuItem(
                            value: GoalPeriod.month,
                            child: Text('Per month'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            period = value ?? GoalPeriod.week;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a name')),
                  );
                  return;
                }
                setState(() {
                  _peopleWithGoals.add(_PersonWithGoalData(
                    name: nameController.text.trim(),
                    email: emailController.text.trim().isEmpty
                        ? null
                        : emailController.text.trim(),
                    phone: phoneController.text.trim().isEmpty
                        ? null
                        : phoneController.text.trim(),
                    targetHours: targetHours,
                    period: period,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddActivityGoalDialog() async {
    final nameController = TextEditingController();
    int targetHours = 3;
    GoalPeriod period = GoalPeriod.week;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Activity Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Activity Name *',
                    hintText: 'e.g., Exercise, Reading, Learning',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                const Text('Time Goal'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: targetHours,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(20, (i) => i + 1).map((hours) {
                          return DropdownMenuItem(
                            value: hours,
                            child: Text('$hours'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            targetHours = value ?? 3;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<GoalPeriod>(
                        value: period,
                        decoration: const InputDecoration(
                          labelText: 'Period',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GoalPeriod.week,
                            child: Text('Per week'),
                          ),
                          DropdownMenuItem(
                            value: GoalPeriod.month,
                            child: Text('Per month'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            period = value ?? GoalPeriod.week;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an activity name')),
                  );
                  return;
                }
                setState(() {
                  _activityGoals.add(_ActivityGoalData(
                    name: nameController.text.trim(),
                    targetHours: targetHours,
                    period: period,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddLocationDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    int targetHours = 0;
    GoalPeriod period = GoalPeriod.week;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Location'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name *',
                    hintText: 'e.g., Home, Office, Gym',
                  ),
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address (optional)',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                const Text('Time Goal (optional)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: targetHours,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        items: List.generate(41, (i) => i).map((hours) {
                          return DropdownMenuItem(
                            value: hours,
                            child: Text(hours == 0 ? 'No goal' : '$hours'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            targetHours = value ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<GoalPeriod>(
                        value: period,
                        decoration: const InputDecoration(
                          labelText: 'Period',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: GoalPeriod.week,
                            child: Text('Per week'),
                          ),
                          DropdownMenuItem(
                            value: GoalPeriod.month,
                            child: Text('Per month'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            period = value ?? GoalPeriod.week;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a location name')),
                  );
                  return;
                }
                setState(() {
                  _locationsWithGoals.add(_LocationWithGoalData(
                    name: nameController.text.trim(),
                    address: addressController.text.trim().isEmpty
                        ? null
                        : addressController.text.trim(),
                    targetHours: targetHours,
                    period: period,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _formatTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  String _formatDays(List<int> days) {
    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (days.length == 7) return 'Every day';
    if (days.length == 5 && !days.contains(0) && !days.contains(6)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(0) && days.contains(6)) {
      return 'Weekends';
    }
    return days.map((d) => dayNames[d]).join(', ');
  }
}

// Data classes for collecting onboarding information

class _RecurringEventData {
  _RecurringEventData({
    required this.name,
    this.description,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.selectedDays,
  });

  final String name;
  final String? description;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<int> selectedDays;
}

class _PersonWithGoalData {
  _PersonWithGoalData({
    required this.name,
    this.email,
    this.phone,
    required this.targetHours,
    required this.period,
  });

  final String name;
  final String? email;
  final String? phone;
  final int targetHours;
  final GoalPeriod period;
}

class _ActivityGoalData {
  _ActivityGoalData({
    required this.name,
    required this.targetHours,
    required this.period,
  });

  final String name;
  final int targetHours;
  final GoalPeriod period;
}

class _LocationWithGoalData {
  _LocationWithGoalData({
    required this.name,
    this.address,
    required this.targetHours,
    required this.period,
  });

  final String name;
  final String? address;
  final int targetHours;
  final GoalPeriod period;
}
