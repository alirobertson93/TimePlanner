import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/entities/category.dart';
import '../../../../domain/entities/person.dart';
import '../../../../domain/entities/location.dart';
import '../../../providers/category_providers.dart';
import '../../../providers/location_providers.dart';
import '../../../providers/person_providers.dart';
import '../../../providers/display_title_providers.dart';

/// Card widget displaying an event in the timeline
class EventCard extends ConsumerWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch category to get color and name
    final categoryAsync = event.categoryId != null
        ? ref.watch(categoryByIdProvider(event.categoryId!))
        : const AsyncValue<Category?>.data(null);

    // Fetch location for display title
    final locationAsync = event.locationId != null
        ? ref.watch(locationByIdProvider(event.locationId!))
        : const AsyncValue<Location?>.data(null);

    // Fetch people for display title
    final peopleAsync = ref.watch(peopleForEventProvider(event.id));

    return categoryAsync.when(
      data: (category) => locationAsync.when(
        data: (location) => peopleAsync.when(
          data: (people) => _buildCard(context, ref, category, location, people),
          loading: () => _buildCard(context, ref, category, location, null),
          error: (_, __) => _buildCard(context, ref, category, location, null),
        ),
        loading: () => _buildCard(context, ref, category, null, null),
        error: (_, __) => _buildCard(context, ref, category, null, null),
      ),
      loading: () => _buildCard(context, ref, null, null, null),
      error: (_, __) => _buildCard(context, ref, null, null, null),
    );
  }

  /// Get the display title for the event
  String _getDisplayTitle(WidgetRef ref, Category? category, Location? location, List<Person>? people) {
    final service = ref.read(displayTitleServiceProvider);
    
    // Convert Event to Activity for displayTitle computation
    final activity = event.toActivity();
    
    return service.getDisplayTitle(
      activity,
      people: people,
      location: location,
      category: category,
    );
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel(WidgetRef ref, Category? category, Location? location, List<Person>? people) {
    final displayTitle = _getDisplayTitle(ref, category, location, people);
    final buffer = StringBuffer();
    buffer.write(displayTitle);

    if (event.startTime != null) {
      final timeFormat = DateFormat.jm();
      buffer.write(', at ${timeFormat.format(event.startTime!)}');
      if (event.endTime != null) {
        buffer.write(' to ${timeFormat.format(event.endTime!)}');
      }
    }

    if (category != null) {
      buffer.write(', category: ${category.name}');
    }

    if (event.isUserLocked) {
      buffer.write(', locked activity');
    }

    if (event.isRecurring) {
      buffer.write(', recurring activity');
    }

    if (event.hasSchedulingConstraints) {
      buffer.write(', has time constraints');
    }

    if (event.description != null && event.description!.isNotEmpty) {
      buffer.write(', ${event.description}');
    }

    buffer.write('. Tap to view details.');
    return buffer.toString();
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, Category? category, Location? location, List<Person>? people) {
    final displayTitle = _getDisplayTitle(ref, category, location, people);
    
    return Semantics(
      button: true,
      label: _buildSemanticLabel(ref, category, location, people),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          color: _getCardColor(category),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (event.hasSchedulingConstraints) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.white70,
                        semanticLabel: 'Time constraints',
                      ),
                    ],
                    if (event.isUserLocked) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.white70,
                        semanticLabel: 'Locked',
                      ),
                    ],
                    if (event.isRecurring) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.repeat,
                        size: 14,
                        color: Colors.white70,
                        semanticLabel: 'Recurring',
                      ),
                    ],
                  ],
                ),
                if (event.description != null &&
                    event.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCardColor(Category? category) {
    if (category != null && category.colourHex.isNotEmpty) {
      try {
        // Parse hex color (format: #RRGGBB)
        final hexColor = category.colourHex.replaceAll('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        // If parsing fails, fall back to default
        return Colors.blue;
      }
    }
    // Default color when no category or parsing fails
    return Colors.blue;
  }
}
