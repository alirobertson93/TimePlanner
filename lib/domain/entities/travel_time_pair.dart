/// Pure domain entity representing travel time between two locations
class TravelTimePair {
  const TravelTimePair({
    required this.fromLocationId,
    required this.toLocationId,
    required this.travelTimeMinutes,
    required this.updatedAt,
  });

  /// ID of the starting location
  final String fromLocationId;

  /// ID of the destination location
  final String toLocationId;

  /// Travel time in minutes
  final int travelTimeMinutes;

  /// When this entry was last updated
  final DateTime updatedAt;

  /// Creates a copy of this travel time pair with the given fields replaced
  TravelTimePair copyWith({
    String? fromLocationId,
    String? toLocationId,
    int? travelTimeMinutes,
    DateTime? updatedAt,
  }) {
    return TravelTimePair(
      fromLocationId: fromLocationId ?? this.fromLocationId,
      toLocationId: toLocationId ?? this.toLocationId,
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TravelTimePair &&
        other.fromLocationId == fromLocationId &&
        other.toLocationId == toLocationId &&
        other.travelTimeMinutes == travelTimeMinutes &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      fromLocationId,
      toLocationId,
      travelTimeMinutes,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'TravelTimePair(from: $fromLocationId, to: $toLocationId, minutes: $travelTimeMinutes)';
  }
}
