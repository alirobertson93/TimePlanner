/// Type of conflict detected during scheduling
enum ConflictType {
  overlap, // Two events occupy same time
  violatesConstraint, // Event placement violates constraint
  travelImpossible, // Not enough travel time between events
  exceedsCapacity, // Too many events in time period
}

/// Represents a conflict between events or constraints
class Conflict {
  const Conflict({
    this.eventId1,
    this.eventId2,
    required this.type,
    required this.description,
  });

  /// First event involved in conflict (if applicable)
  final String? eventId1;

  /// Second event involved in conflict (if applicable)
  final String? eventId2;

  /// Type of conflict
  final ConflictType type;

  /// Human-readable description of the conflict
  final String description;

  @override
  String toString() {
    return 'Conflict($type: $description)';
  }
}
