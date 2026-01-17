import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/day_view/day_view_screen.dart';
import '../presentation/screens/event_form/event_form_screen.dart';

/// Application router configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/day',
        name: 'day_view',
        builder: (context, state) => const DayViewScreen(),
      ),
      GoRoute(
        path: '/event/new',
        name: 'event_new',
        builder: (context, state) {
          final initialDate = state.extra as DateTime?;
          return EventFormScreen(initialDate: initialDate);
        },
      ),
      GoRoute(
        path: '/event/:id/edit',
        name: 'event_edit',
        builder: (context, state) {
          final eventId = state.pathParameters['id'];
          return EventFormScreen(eventId: eventId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
