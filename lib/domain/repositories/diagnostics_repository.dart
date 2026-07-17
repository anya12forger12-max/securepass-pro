import 'package:securepass_pro/domain/entities/diagnostic_entry.dart';

abstract class DiagnosticsRepository {
  Future<List<DiagnosticEntry>> getDiagnostics();
  Future<DiagnosticEntry?> getDiagnosticById(String id);
  Future<void> refresh();
}
