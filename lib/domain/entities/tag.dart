import 'package:securepass_pro/domain/enums/tag_color.dart';

class Tag {
  Tag({
    required this.id,
    required this.name,
    this.color = TagColor.blue,
    this.description = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final TagColor color;
  final String description;
  final DateTime createdAt;

  Tag copyWith({String? name, TagColor? color, String? description}) {
    return Tag(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'color': color.name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      color: TagColor.values.firstWhere(
        (e) => e.name == map['color'],
        orElse: () => TagColor.blue,
      ),
      description: map['description'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is Tag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
