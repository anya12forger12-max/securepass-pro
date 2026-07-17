import 'package:securepass_pro/domain/enums/diagnostic_status.dart';

class SecurityCheck {
  const SecurityCheck({
    required this.name,
    required this.description,
    required this.status,
    this.details,
  });

  final String name;
  final String description;
  final DiagnosticStatus status;
  final String? details;
}

class SecurityStatus {
  const SecurityStatus({
    required this.overallHealth,
    required this.checks,
    required this.lastVerified,
    this.profileName = 'Balanced',
  });

  final DiagnosticStatus overallHealth;
  final List<SecurityCheck> checks;
  final DateTime lastVerified;
  final String profileName;
}
