import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/location.dart';
import '../../domain/entities/travel_time_pair.dart';
import '../providers/repository_providers.dart';
import '../providers/travel_time_providers.dart';

/// Dialog to prompt user for travel time between two locations
class TravelTimePromptDialog extends ConsumerStatefulWidget {
  const TravelTimePromptDialog({
    super.key,
    required this.fromLocationId,
    required this.toLocationId,
  });

  final String fromLocationId;
  final String toLocationId;

  /// Shows the travel time prompt dialog and returns true if travel time was saved
  static Future<bool> show({
    required BuildContext context,
    required String fromLocationId,
    required String toLocationId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TravelTimePromptDialog(
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
      ),
    );
    return result ?? false;
  }

  @override
  ConsumerState<TravelTimePromptDialog> createState() => _TravelTimePromptDialogState();
}

class _TravelTimePromptDialogState extends ConsumerState<TravelTimePromptDialog> {
  final _minutesController = TextEditingController();
  bool _isSaving = false;
  Location? _fromLocation;
  Location? _toLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final locationRepo = ref.read(locationRepositoryProvider);
    final from = await locationRepo.getById(widget.fromLocationId);
    final to = await locationRepo.getById(widget.toLocationId);
    
    if (mounted) {
      setState(() {
        _fromLocation = from;
        _toLocation = to;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        content: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final fromName = _fromLocation?.name ?? 'Unknown';
    final toName = _toLocation?.name ?? 'Unknown';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.directions_car),
          SizedBox(width: 8),
          Text('Travel Time Needed'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have events at different locations. How long does it take to travel between them?',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            
            // Location pair display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fromName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          toName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Travel time input
            TextField(
              controller: _minutesController,
              decoration: const InputDecoration(
                labelText: 'Travel time (minutes)',
                border: OutlineInputBorder(),
                hintText: 'e.g., 30',
                prefixIcon: Icon(Icons.timer),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            
            Text(
              'This will be remembered for future scheduling.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveTravelTime,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveTravelTime() async {
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
      final travelTime = TravelTimePair(
        fromLocationId: widget.fromLocationId,
        toLocationId: widget.toLocationId,
        travelTimeMinutes: minutes,
        updatedAt: DateTime.now(),
      );

      await ref.read(travelTimePairRepositoryProvider).saveBidirectional(travelTime);
      ref.invalidate(watchAllTravelTimePairsProvider);
      ref.invalidate(allTravelTimePairsProvider);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Travel time saved')),
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

/// Service to check for missing travel times between events
class TravelTimeChecker {
  TravelTimeChecker(this._ref);
  
  final WidgetRef _ref;

  /// Checks if travel time exists between two locations (bidirectional)
  Future<bool> hasTravelTime(String locationId1, String locationId2) async {
    final repo = _ref.read(travelTimePairRepositoryProvider);
    final pair = await repo.getByLocationPairBidirectional(locationId1, locationId2);
    return pair != null;
  }

  /// Finds consecutive events with different locations that don't have travel time set
  /// Returns list of (fromLocationId, toLocationId) pairs
  Future<List<(String, String)>> findMissingTravelTimes(
    List<({String? locationId, DateTime start, DateTime end})> sortedEvents,
  ) async {
    final missingPairs = <(String, String)>[];
    
    for (int i = 0; i < sortedEvents.length - 1; i++) {
      final currentEvent = sortedEvents[i];
      final nextEvent = sortedEvents[i + 1];
      
      // Skip if either event doesn't have a location
      if (currentEvent.locationId == null || nextEvent.locationId == null) {
        continue;
      }
      
      // Skip if same location
      if (currentEvent.locationId == nextEvent.locationId) {
        continue;
      }
      
      // Check if travel time exists
      final hasTravelTimeSet = await hasTravelTime(
        currentEvent.locationId!,
        nextEvent.locationId!,
      );
      
      if (!hasTravelTimeSet) {
        missingPairs.add((currentEvent.locationId!, nextEvent.locationId!));
      }
    }
    
    return missingPairs;
  }
}
