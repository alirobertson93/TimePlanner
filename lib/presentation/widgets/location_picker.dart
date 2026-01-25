import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/location.dart';
import '../providers/location_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/error_handler_provider.dart';

/// A widget for selecting a location to associate with an event
class LocationPicker extends ConsumerStatefulWidget {
  const LocationPicker({
    super.key,
    required this.selectedLocationId,
    required this.onLocationChanged,
  });

  /// Currently selected location ID (null if none)
  final String? selectedLocationId;

  /// Callback when the selection changes
  final void Function(String? locationId) onLocationChanged;

  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  @override
  Widget build(BuildContext context) {
    final allLocationsAsync = ref.watch(allLocationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showLocationPickerDialog(context),
              icon: const Icon(Icons.add_location, size: 18),
              label: Text(widget.selectedLocationId == null ? 'Add' : 'Change'),
            ),
          ],
        ),

        // Selected location display
        allLocationsAsync.when(
          data: (allLocations) {
            if (widget.selectedLocationId == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No location selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              );
            }

            final selectedLocation = allLocations
                .where((l) => l.id == widget.selectedLocationId)
                .firstOrNull;

            if (selectedLocation == null) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Location not found',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              );
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(selectedLocation.name),
                subtitle: selectedLocation.address != null
                    ? Text(
                        selectedLocation.address!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => widget.onLocationChanged(null),
                  tooltip: 'Remove location',
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => Text(
            'Error loading locations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _showLocationPickerDialog(BuildContext context) async {
    final allLocationsAsync = ref.read(allLocationsProvider);
    final allLocations = allLocationsAsync.valueOrNull ?? [];

    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocationPickerBottomSheet(
        allLocations: allLocations,
        selectedId: widget.selectedLocationId,
        onAddNewLocation: () => _showAddLocationDialog(context),
      ),
    );

    // result can be:
    // - null: user dismissed without selection
    // - '': user clicked "Clear" to remove location
    // - locationId: user selected a location
    if (result != null) {
      // Empty string means explicitly clear selection
      widget.onLocationChanged(result == '' ? null : result);
    }
  }

  Future<void> _showAddLocationDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final notesController = TextEditingController();

    final result = await showDialog<Location>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Location'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g., Office, Home, Coffee Shop',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Enter address',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional details',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name is required')),
                );
                return;
              }

              final location = Location(
                id: const Uuid().v4(),
                name: nameController.text.trim(),
                address: addressController.text.trim().isEmpty
                    ? null
                    : addressController.text.trim(),
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
                createdAt: DateTime.now(),
              );

              try {
                await ref.read(locationRepositoryProvider).save(location);
                ref.invalidate(allLocationsProvider);
                if (context.mounted) {
                  Navigator.of(context).pop(location);
                }
              } catch (e) {
                if (context.mounted) {
                  ref.read(errorHandlerProvider).showErrorSnackBar(
                    context,
                    e,
                    operationContext: 'saving location',
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameController.dispose();
    addressController.dispose();
    notesController.dispose();

    // If a location was added, select it
    if (result != null) {
      widget.onLocationChanged(result.id);
    }
  }
}

/// Bottom sheet for selecting a location
class _LocationPickerBottomSheet extends StatefulWidget {
  const _LocationPickerBottomSheet({
    required this.allLocations,
    required this.selectedId,
    required this.onAddNewLocation,
  });

  final List<Location> allLocations;
  final String? selectedId;
  final VoidCallback onAddNewLocation;

  @override
  State<_LocationPickerBottomSheet> createState() =>
      _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState
    extends State<_LocationPickerBottomSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredLocations = _searchQuery.isEmpty
        ? widget.allLocations
        : widget.allLocations
            .where((l) =>
                l.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (l.address?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      if (widget.selectedId != null)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(''); // Empty string = clear
                          },
                          child: const Text('Clear'),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                          widget.onAddNewLocation();
                        },
                        child: const Text('Add New'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search locations...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Locations list
            Expanded(
              child: filteredLocations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No locations added yet'
                                : 'No results found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(null);
                                widget.onAddNewLocation();
                              },
                              icon: const Icon(Icons.add_location),
                              label: const Text('Add Location'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = filteredLocations[index];
                        final isSelected = location.id == widget.selectedId;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          title: Text(
                            location.name,
                            style: isSelected
                                ? const TextStyle(fontWeight: FontWeight.bold)
                                : null,
                          ),
                          subtitle: location.address != null
                              ? Text(
                                  location.address!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(location.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
