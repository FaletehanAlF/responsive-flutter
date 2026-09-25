class Category {
  final int id;
  final String name;

  const Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _parseId(json['id']),
      name: json['name']?.toString().trim() ?? '',
    );
  }

  static int _parseId(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  @override
  bool operator ==(Object other) => other is Category && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
