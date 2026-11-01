import 'dart:ui';

class Tag {
  const Tag({required this.id, required this.name, this.color = 0xFF356859});

  final String id;
  final String name;
  final int color;

  Color get colorValue => Color(color);

  Tag copyWith({String? name, int? color}) {
    return Tag(id: id, name: name ?? this.name, color: color ?? this.color);
  }

  factory Tag.fromJson(Map<String, Object?> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      color: json['color'] as int? ?? 0xFF356859,
    );
  }

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'color': color};
}
