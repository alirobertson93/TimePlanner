/// Pure domain entity representing a person associated with events
class Person {
  const Person({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? notes;
  final DateTime createdAt;

  /// Creates a copy of this person with the given fields replaced
  Person copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? notes,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Person &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      email,
      phone,
      notes,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Person(id: $id, name: $name, email: $email)';
  }
}
