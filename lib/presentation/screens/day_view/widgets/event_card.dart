import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/event.dart';
import '../../../../domain/entities/category.dart';
import '../../../providers/category_providers.dart';

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
    // Fetch category to get color
    final categoryAsync = event.categoryId != null
        ? ref.watch(categoryByIdProvider(event.categoryId!))
        : const AsyncValue<Category?>.data(null);

    return categoryAsync.when(
      data: (category) => _buildCard(context, category),
      loading: () => _buildCard(context, null),
      error: (_, __) => _buildCard(context, null),
    );
  }

  /// Build semantic label for screen readers
  String _buildSemanticLabel(Category? category) {
    final buffer = StringBuffer();
    buffer.write(event.name);

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

    if (event.isRecurring) {
      buffer.write(', recurring event');
    }

    if (event.description != null && event.description!.isNotEmpty) {
      buffer.write(', ${event.description}');
    }

    buffer.write('. Tap to view details.');
    return buffer.toString();
  }

  Widget _buildCard(BuildContext context, Category? category) {
    return Semantics(
      button: true,
      label: _buildSemanticLabel(category),
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
                        event.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
