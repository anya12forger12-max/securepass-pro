import 'package:securepass_pro/domain/enums/backup_status.dart';

class BackupMetadata {
  BackupMetadata({
    required this.id,
    required this.name,
    required this.version,
    required this.sizeBytes,
    DateTime? createdAt,
    this.status = BackupStatus.pending,
    this.isEncrypted = false,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String name;
  final String version;
  final int sizeBytes;
  final DateTime createdAt;
  final BackupStatus status;
  final bool isEncrypted;

  String get sizeDisplay {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }
}
