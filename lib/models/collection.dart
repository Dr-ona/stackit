class Collection {
  const Collection({
    required this.id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? const _DefaultDateTime(),
       updatedAt = updatedAt ?? const _DefaultDateTime();

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Collection copyWith({
    String? name,
    String? description,
    DateTime? updatedAt,
  }) {
    return Collection(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Collection.fromJson(Map<String, Object?> json) {
    return Collection(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  static DateTime _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime(2026);
    return DateTime(2026);
  }
}

class _DefaultDateTime implements DateTime {
  const _DefaultDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('DefaultDateTime placeholder');
}
