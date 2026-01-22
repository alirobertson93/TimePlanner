import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/person.dart';
import '../providers/person_providers.dart';
import '../providers/repository_providers.dart';

/// A widget for selecting people to associate with an event
class PeoplePicker extends ConsumerStatefulWidget {
  const PeoplePicker({
    super.key,
    required this.selectedPeopleIds,
    required this.onPeopleChanged,
  });

  /// List of currently selected person IDs
  final List<String> selectedPeopleIds;

  /// Callback when the selection changes
  final void Function(List<String> selectedIds) onPeopleChanged;

  @override
  ConsumerState<PeoplePicker> createState() => _PeoplePickerState();
}

class _PeoplePickerState extends ConsumerState<PeoplePicker> {
  @override
  Widget build(BuildContext context) {
    final allPeopleAsync = ref.watch(allPeopleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'People',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showPeoplePickerDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),

        // Selected people chips
        allPeopleAsync.when(
          data: (allPeople) {
            final selectedPeople = allPeople
                .where((p) => widget.selectedPeopleIds.contains(p.id))
                .toList();

            if (selectedPeople.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'No people selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                ),
              );
            }

            return Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedPeople.map((person) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    radius: 14,
                    child: Text(
                      person.name.isNotEmpty
                          ? person.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  label: Text(person.name),
                  onDeleted: () {
                    final newIds = List<String>.from(widget.selectedPeopleIds)
                      ..remove(person.id);
                    widget.onPeopleChanged(newIds);
                  },
                );
              }).toList(),
            );
          },
          loading: () =>
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          error: (error, _) => Text(
            'Error loading people',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPeoplePickerDialog(BuildContext context) async {
    final allPeopleAsync = ref.read(allPeopleProvider);
    final allPeople = allPeopleAsync.valueOrNull ?? [];

    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PeoplePickerBottomSheet(
        allPeople: allPeople,
        selectedIds: widget.selectedPeopleIds,
        onAddNewPerson: () => _showAddPersonDialog(context),
      ),
    );

    if (result != null) {
      widget.onPeopleChanged(result);
    }
  }

  Future<void> _showAddPersonDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    final result = await showDialog<Person>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Person'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Enter name',
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Enter phone number',
                ),
                keyboardType: TextInputType.phone,
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

              final person = Person(
                id: const Uuid().v4(),
                name: nameController.text.trim(),
                email: emailController.text.trim().isEmpty
                    ? null
                    : emailController.text.trim(),
                phone: phoneController.text.trim().isEmpty
                    ? null
                    : phoneController.text.trim(),
                notes: null,
                createdAt: DateTime.now(),
              );

              try {
                await ref.read(personRepositoryProvider).save(person);
                ref.invalidate(allPeopleProvider);
                if (context.mounted) {
                  Navigator.of(context).pop(person);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
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
    emailController.dispose();
    phoneController.dispose();

    // If a person was added, add them to the selection
    if (result != null) {
      final newIds = List<String>.from(widget.selectedPeopleIds)
        ..add(result.id);
      widget.onPeopleChanged(newIds);
    }
  }
}

/// Bottom sheet for selecting multiple people
class _PeoplePickerBottomSheet extends StatefulWidget {
  const _PeoplePickerBottomSheet({
    required this.allPeople,
    required this.selectedIds,
    required this.onAddNewPerson,
  });

  final List<Person> allPeople;
  final List<String> selectedIds;
  final VoidCallback onAddNewPerson;

  @override
  State<_PeoplePickerBottomSheet> createState() =>
      _PeoplePickerBottomSheetState();
}

class _PeoplePickerBottomSheetState extends State<_PeoplePickerBottomSheet> {
  late List<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredPeople = _searchQuery.isEmpty
        ? widget.allPeople
        : widget.allPeople
            .where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
                    'Select People',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(null);
                          widget.onAddNewPerson();
                        },
                        child: const Text('Add New'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(context).pop(_selectedIds),
                        child: const Text('Done'),
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
                  hintText: 'Search people...',
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

            // People list
            Expanded(
              child: filteredPeople.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No people added yet'
                                : 'No results found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop(null);
                                widget.onAddNewPerson();
                              },
                              icon: const Icon(Icons.person_add),
                              label: const Text('Add Person'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredPeople.length,
                      itemBuilder: (context, index) {
                        final person = filteredPeople[index];
                        final isSelected = _selectedIds.contains(person.id);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedIds.add(person.id);
                              } else {
                                _selectedIds.remove(person.id);
                              }
                            });
                          },
                          secondary: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Text(
                              person.name.isNotEmpty
                                  ? person.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Text(person.name),
                          subtitle: person.email != null
                              ? Text(
                                  person.email!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
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
