import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/onboarding_providers.dart';

/// Onboarding wizard screen that guides first-time users through the app
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      title: 'Welcome to TimePlanner',
      description:
          'Your intelligent time planning assistant that helps you organize your schedule and achieve your goals.',
      icon: Icons.schedule,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Smart Scheduling',
      description:
          'Create events with fixed times or let the app find the perfect slot for flexible tasks.',
      icon: Icons.auto_fix_high,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Track Your Goals',
      description:
          'Set weekly or monthly goals for activities like exercise, reading, or learning. We\'ll help you stay on track.',
      icon: Icons.flag,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Plan Ahead',
      description:
          'Use the Planning Wizard to automatically schedule your flexible events across the week.',
      icon: Icons.auto_awesome,
      color: Colors.purple,
    ),
    OnboardingPage(
      title: 'Stay Notified',
      description:
          'Get reminders for upcoming events and alerts when goals need attention.',
      icon: Icons.notifications_active,
      color: Colors.red,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showSampleDataDialog();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding({bool installSampleData = false}) async {
    try {
      final service = ref.read(onboardingServiceProvider);

      if (installSampleData) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        try {
          final sampleService = ref.read(sampleDataServiceProvider);
          await sampleService.generateAllSampleData();
          await service.markSampleDataInstalled();
        } finally {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      }

      await service.completeOnboarding();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      // If onboarding service isn't available, just navigate
      if (mounted) {
        context.go('/');
      }
    }
  }

  void _showSampleDataDialog() {
    final shouldOffer = ref.read(shouldOfferSampleDataProvider);

    if (!shouldOffer) {
      _completeOnboarding();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Sample Data?'),
        content: const Text(
          'Would you like to start with some sample events and goals to help you explore the app? You can delete them anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOnboarding(installSampleData: false);
            },
            child: const Text('No Thanks'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOnboarding(installSampleData: true);
            },
            child: const Text('Add Samples'),
          ),
        ],
      ),
    );
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
              child: TextButton(
                onPressed: _skipOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pages.length - 1
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

  Widget _buildPage(OnboardingPage page) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: page.color,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Data class for onboarding page content
class OnboardingPage {
  const OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}
