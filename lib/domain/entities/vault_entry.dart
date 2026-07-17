import 'package:securepass_pro/domain/enums/vault_entry_type.dart';

class VaultEntry {
  VaultEntry({
    required this.id,
    required this.title,
    required this.type,
    required this.value,
    required this.workspaceId,
    this.username = '',
    this.url = '',
    this.notes = '',
    this.tags = const [],
    this.isFavorite = false,
    this.folder = '',
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String title;
  final VaultEntryType type;
  final String value;
  final String workspaceId;
  final String username;
  final String url;
  final String notes;
  final List<String> tags;
  final bool isFavorite;
  final String folder;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  VaultEntry copyWith({
    String? title,
    VaultEntryType? type,
    String? value,
    String? username,
    String? url,
    String? notes,
    List<String>? tags,
    bool? isFavorite,
    String? folder,
    Map<String, dynamic>? metadata,
  }) {
    return VaultEntry(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      value: value ?? this.value,
      workspaceId: workspaceId,
      username: username ?? this.username,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      folder: folder ?? this.folder,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'type': type.name,
    'value': value,
    'workspaceId': workspaceId,
    'username': username,
    'url': url,
    'notes': notes,
    'tags': tags,
    'isFavorite': isFavorite,
    'folder': folder,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory VaultEntry.fromMap(Map<String, dynamic> map) {
    return VaultEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      type: VaultEntryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => VaultEntryType.other,
      ),
      value: map['value'] as String,
      workspaceId: map['workspaceId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      url: map['url'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      tags: List<String>.from(map['tags'] as List? ?? []),
      isFavorite: map['isFavorite'] as bool? ?? false,
      folder: map['folder'] as String? ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] as Map? ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }
}
