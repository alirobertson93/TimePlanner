import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/event.dart';
import '../../../providers/event_providers.dart';
import '../../../providers/error_handler_provider.dart';

/// Bottom sheet showing event details
class EventDetailSheet extends ConsumerWidget {
  const EventDetailSheet({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Title
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 24),
                    // Time
                    _buildInfoRow(
                      context,
                      icon: Icons.access_time,
                      label: 'Time',
                      value: _formatTime(),
                    ),
                    const SizedBox(height: 16),
                    // Duration
                    _buildInfoRow(
                      context,
                      icon: Icons.timelapse,
                      label: 'Duration',
                      value: _formatDuration(),
                    ),
                    const SizedBox(height: 16),
                    // Status
                    _buildInfoRow(
                      context,
                      icon: Icons.info_outline,
                      label: 'Status',
                      value: event.status.toString().split('.').last,
                    ),
                    const SizedBox(height: 16),
                    // Type
                    _buildInfoRow(
                      context,
                      icon: Icons.category,
                      label: 'Type',
                      value: event.isFixed ? 'Fixed' : 'Flexible',
                    ),
                    // Recurrence (if applicable)
                    if (event.isRecurring) ...[
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        context,
                        icon: Icons.repeat,
                        label: 'Repeats',
                        value: 'Yes',
                      ),
                    ],
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.description!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.pushReplacement('/event/${event.id}/edit');
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, ref),
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  String _formatTime() {
    if (event.startTime != null && event.endTime != null) {
      final start = DateFormat('h:mm a').format(event.startTime!);
      final end = DateFormat('h:mm a').format(event.endTime!);
      return '$start - $end';
    }
    return 'Flexible';
  }

  String _formatDuration() {
    final duration = event.effectiveDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '$hours hr $minutes min';
    } else if (hours > 0) {
      return '$hours hr';
    } else {
      return '$minutes min';
    }
  }

  /// Shows a confirmation dialog before deleting the event
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          // Delete the event
          await ref.read(deleteEventProvider(event.id).future);
          
          // Close the bottom sheet
          if (context.mounted) {
            Navigator.of(context).pop();
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Event "${event.name}" deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          // Show error message
          if (context.mounted) {
            ref.read(errorHandlerProvider).showErrorSnackBar(
              context,
              e,
              operationContext: 'deleting event',
            );
          }
        }
      }
    });
  }
}
