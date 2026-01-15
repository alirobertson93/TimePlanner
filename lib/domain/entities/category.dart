/// Pure domain entity representing a category for organizing events
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colourHex,
    this.sortOrder = 0,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String colourHex;
  final int sortOrder;
  final bool isDefault;

  /// Creates a copy of this category with the given fields replaced
  Category copyWith({
    String? id,
    String? name,
    String? colourHex,
    int? sortOrder,
    bool? isDefault,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colourHex: colourHex ?? this.colourHex,
      sortOrder: sortOrder ?? this.sortOrder,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.colourHex == colourHex &&
        other.sortOrder == sortOrder &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, colourHex, sortOrder, isDefault);
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, colourHex: $colourHex)';
  }
}
