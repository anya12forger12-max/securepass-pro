import 'package:securepass_pro/domain/enums/generator_type.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.value,
    required this.generatorType,
    required this.workspaceId,
    this.label = '',
    this.isFavorite = false,
    this.tags = const [],
    this.metadata = const {},
    this.expiresAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String value;
  final GeneratorType generatorType;
  final String workspaceId;
  final String label;
  final bool isFavorite;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime? expiresAt;
  final DateTime createdAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  HistoryEntry copyWith({
    String? label,
    bool? isFavorite,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
  }) {
    return HistoryEntry(
      id: id,
      value: value,
      generatorType: generatorType,
      workspaceId: workspaceId,
      label: label ?? this.label,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'value': value,
    'generatorType': generatorType.name,
    'workspaceId': workspaceId,
    'label': label,
    'isFavorite': isFavorite,
    'tags': tags,
    'metadata': metadata,
    'expiresAt': expiresAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as String,
      value: map['value'] as String,
      generatorType: GeneratorType.values.firstWhere(
        (e) => e.name == map['generatorType'],
        orElse: () => GeneratorType.password,
      ),
      workspaceId: map['workspaceId'] as String? ?? '',
      label: map['label'] as String? ?? '',
      isFavorite: map['isFavorite'] as bool? ?? false,
      tags: List<String>.from(map['tags'] as List? ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      expiresAt: map['expiresAt'] != null
          ? DateTime.parse(map['expiresAt'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
    );
  }
}
