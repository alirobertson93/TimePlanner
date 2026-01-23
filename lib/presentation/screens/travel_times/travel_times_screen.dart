import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/travel_time_pair.dart';
import '../../../domain/entities/location.dart';
import '../../providers/travel_time_providers.dart';
import '../../providers/location_providers.dart';
import '../../providers/repository_providers.dart';

/// Screen for managing travel times between locations
class TravelTimesScreen extends ConsumerStatefulWidget {
  const TravelTimesScreen({super.key});

  @override
  ConsumerState<TravelTimesScreen> createState() => _TravelTimesScreenState();
}

class _TravelTimesScreenState extends ConsumerState<TravelTimesScreen> {
  @override
  Widget build(BuildContext context) {
    final travelTimesAsync = ref.watch(watchAllTravelTimePairsProvider);
    final locationsAsync = ref.watch(allLocationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Times'),
      ),
      body: travelTimesAsync.when(
        data: (travelTimes) {
          // Group travel times to show unique pairs (avoid showing A→B and B→A separately)
          final uniquePairs = _getUniquePairs(travelTimes);

          if (uniquePairs.isEmpty) {
            return _buildEmptyState(context);
          }

          return locationsAsync.when(
            data: (locations) {
              final locationMap = {for (var loc in locations) loc.id: loc};

              return ListView.builder(
                itemCount: uniquePairs.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final pair = uniquePairs[index];
                  final fromLocation = locationMap[pair.fromLocationId];
                  final toLocation = locationMap[pair.toLocationId];

                  return _TravelTimeCard(
                    travelTimePair: pair,
                    fromLocation: fromLocation,
                    toLocation: toLocation,
                    onEdit: () => _showEditTravelTimeDialog(
                      context,
                      pair,
                      fromLocation,
                      toLocation,
                    ),
                    onDelete: () => _showDeleteConfirmation(
                      context,
                      pair,
                      fromLocation,
                      toLocation,
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTravelTimeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Groups travel times to show unique pairs (not duplicates for bidirectional)
  List<TravelTimePair> _getUniquePairs(List<TravelTimePair> travelTimes) {
    final seen = <String>{};
    final uniquePairs = <TravelTimePair>[];

    for (final pair in travelTimes) {
      // Create a canonical key for the pair (sorted location IDs)
      final ids = [pair.fromLocationId, pair.toLocationId]..sort();
      final key = '${ids[0]}_${ids[1]}';

      if (!seen.contains(key)) {
        seen.add(key);
        uniquePairs.add(pair);
      }
    }

    return uniquePairs;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No travel times set',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add travel times between locations to help\nplan your schedule more accurately',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddTravelTimeDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Travel Time'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTravelTimeDialog(BuildContext context) async {
    final locationsAsync = await ref.read(allLocationsProvider.future);

    if (locationsAsync.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need at least 2 locations to set travel times'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _TravelTimeFormDialog(
        locations: locationsAsync,
        onSave: (fromId, toId, minutes) async {
          final travelTime = TravelTimePair(
            fromLocationId: fromId,
            toLocationId: toId,
            travelTimeMinutes: minutes,
            updatedAt: DateTime.now(),
          );

          await ref.read(travelTimePairRepositoryProvider).saveBidirectional(travelTime);
          ref.invalidate(watchAllTravelTimePairsProvider);
          ref.invalidate(allTravelTimePairsProvider);
        },
      ),
    );
  }

  Future<void> _showEditTravelTimeDialog(
    BuildContext context,
    TravelTimePair pair,
    Location? fromLocation,
    Location? toLocation,
  ) async {
    final locationsAsync = await ref.read(allLocationsProvider.future);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => _TravelTimeFormDialog(
        locations: locationsAsync,
        initialFromLocationId: pair.fromLocationId,
        initialToLocationId: pair.toLocationId,
        initialMinutes: pair.travelTimeMinutes,
        isEditing: true,
        onSave: (fromId, toId, minutes) async {
          // Delete old pair if locations changed
          if (fromId != pair.fromLocationId || toId != pair.toLocationId) {
            await ref.read(travelTimePairRepositoryProvider).deleteBidirectional(
                  pair.fromLocationId,
                  pair.toLocationId,
                );
          }

          final travelTime = TravelTimePair(
            fromLocationId: fromId,
            toLocationId: toId,
            travelTimeMinutes: minutes,
            updatedAt: DateTime.now(),
          );

          await ref.read(travelTimePairRepositoryProvider).saveBidirectional(travelTime);
          ref.invalidate(watchAllTravelTimePairsProvider);
          ref.invalidate(allTravelTimePairsProvider);
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    TravelTimePair pair,
    Location? fromLocation,
    Location? toLocation,
  ) async {
    final fromName = fromLocation?.name ?? 'Unknown';
    final toName = toLocation?.name ?? 'Unknown';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Travel Time?'),
        content: Text(
          'Are you sure you want to delete the travel time between "$fromName" and "$toName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(travelTimePairRepositoryProvider).deleteBidirectional(
              pair.fromLocationId,
              pair.toLocationId,
            );
        ref.invalidate(watchAllTravelTimePairsProvider);
        ref.invalidate(allTravelTimePairsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Travel time deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

/// Card widget for displaying a travel time pair
class _TravelTimeCard extends StatelessWidget {
  const _TravelTimeCard({
    required this.travelTimePair,
    required this.fromLocation,
    required this.toLocation,
    required this.onEdit,
    required this.onDelete,
  });

  final TravelTimePair travelTimePair;
  final Location? fromLocation;
  final Location? toLocation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final fromName = fromLocation?.name ?? 'Unknown';
    final toName = toLocation?.name ?? 'Unknown';
    final minutes = travelTimePair.travelTimeMinutes;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.directions_car,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                fromName,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.swap_horiz,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Expanded(
              child: Text(
                toName,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text(
          _formatDuration(minutes),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hr';
    }
    return '$hours hr $mins min';
  }
}

/// Dialog for adding/editing travel time
class _TravelTimeFormDialog extends StatefulWidget {
  const _TravelTimeFormDialog({
    required this.locations,
    required this.onSave,
    this.initialFromLocationId,
    this.initialToLocationId,
    this.initialMinutes,
    this.isEditing = false,
  });

  final List<Location> locations;
  final String? initialFromLocationId;
  final String? initialToLocationId;
  final int? initialMinutes;
  final bool isEditing;
  final Future<void> Function(String fromId, String toId, int minutes) onSave;

  @override
  State<_TravelTimeFormDialog> createState() => _TravelTimeFormDialogState();
}

class _TravelTimeFormDialogState extends State<_TravelTimeFormDialog> {
  late String? _fromLocationId;
  late String? _toLocationId;
  late TextEditingController _minutesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fromLocationId = widget.initialFromLocationId;
    _toLocationId = widget.initialToLocationId;
    _minutesController = TextEditingController(
      text: widget.initialMinutes?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Travel Time' : 'Add Travel Time'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // From Location
            DropdownButtonFormField<String>(
              value: _fromLocationId,
              decoration: const InputDecoration(
                labelText: 'From Location',
                border: OutlineInputBorder(),
              ),
              items: widget.locations.map((location) {
                return DropdownMenuItem(
                  value: location.id,
                  child: Text(location.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _fromLocationId = value;
                  // Reset toLocationId if it's now the same as fromLocationId
                  if (_toLocationId == value) {
                    _toLocationId = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // To Location
            DropdownButtonFormField<String>(
              value: _toLocationId,
              decoration: const InputDecoration(
                labelText: 'To Location',
                border: OutlineInputBorder(),
              ),
              items: widget.locations
                  .where((loc) => loc.id != _fromLocationId)
                  .map((location) {
                return DropdownMenuItem(
                  value: location.id,
                  child: Text(location.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _toLocationId = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Travel Time
            TextField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: 'Travel Time (minutes)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 30',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),

            // Info text
            Text(
              'This travel time will be stored bidirectionally\n(same time in both directions)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _onSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    // Validate
    if (_fromLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a from location')),
      );
      return;
    }

    if (_toLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a to location')),
      );
      return;
    }

    final minutesText = _minutesController.text.trim();
    if (minutesText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter travel time')),
      );
      return;
    }

    final minutes = int.tryParse(minutesText);
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid travel time')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(_fromLocationId!, _toLocationId!, minutes);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Travel time updated'
                : 'Travel time added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
