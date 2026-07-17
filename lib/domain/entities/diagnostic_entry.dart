import 'package:securepass_pro/domain/enums/diagnostic_status.dart';

class DiagnosticEntry {
  DiagnosticEntry({
    required this.id,
    required this.category,
    required this.status,
    required this.message,
    this.details,
    this.recommendation,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String id;
  final String category;
  final DiagnosticStatus status;
  final String message;
  final Map<String, dynamic>? details;
  final String? recommendation;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
    'id': id,
    'category': category,
    'status': status.label,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
  };
}
