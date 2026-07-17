enum QrType { credential, wifi, recoveryCode, custom }

class QrData {
  QrData({
    required this.content,
    required this.type,
    this.title = '',
    this.metadata = const {},
    DateTime? generatedAt,
    this.expiresAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  final String content;
  final QrType type;
  final String title;
  final Map<String, dynamic> metadata;
  final DateTime generatedAt;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
