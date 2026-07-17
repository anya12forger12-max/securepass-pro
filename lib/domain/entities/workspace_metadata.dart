class WorkspaceMetadata {
  WorkspaceMetadata({
    required this.id,
    required this.name,
    this.description = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  WorkspaceMetadata copyWith({
    String? name,
    String? description,
    bool? isActive,
    DateTime? updatedAt,
  }) =>
      WorkspaceMetadata(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };
}
