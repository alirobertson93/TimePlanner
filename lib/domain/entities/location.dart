/// Pure domain entity representing a location associated with events
class Location {
  const Location({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? notes;
  final DateTime createdAt;

  /// Creates a copy of this location with the given fields replaced
  Location copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? notes,
    DateTime? createdAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Location &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      address,
      latitude,
      longitude,
      notes,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, name: $name, address: $address)';
  }
}
