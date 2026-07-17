class PolicyViolation {
  const PolicyViolation({
    required this.rule,
    required this.message,
    required this.severity,
    this.currentValue,
    this.requiredValue,
  });

  final String rule;
  final String message;
  final String severity;
  final dynamic currentValue;
  final dynamic requiredValue;

  @override
  String toString() => 'PolicyViolation($severity: $message)';
}

class PolicyValidationResult {
  const PolicyValidationResult({
    required this.isValid,
    required this.violations,
    required this.policyName,
  });

  final bool isValid;
  final List<PolicyViolation> violations;
  final String policyName;

  int get errorCount => violations.where((v) => v.severity == 'error').length;
  int get warningCount =>
      violations.where((v) => v.severity == 'warning').length;

  @override
  String toString() =>
      'PolicyValidationResult(isValid: $isValid, errors: $errorCount, warnings: $warningCount)';
}
