import 'dart:convert';

import 'package:securepass_pro/domain/entities/password_policy.dart';
import 'package:securepass_pro/domain/entities/policy_template.dart';
import 'package:securepass_pro/domain/entities/policy_violation.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/infrastructure/logging/app_logger.dart';

class PasswordPolicyService {
  PasswordPolicyService._();
  static final PasswordPolicyService _instance = PasswordPolicyService._();
  static PasswordPolicyService get instance => _instance;

  static const String _policiesKey = 'password_policies';
  static const String _activePolicyKey = 'active_policy_id';

  final Map<String, PasswordPolicy> _policies = {};
  String? _activePolicyId;

  Future<void> initialize() async {
    _loadPolicies();
    _loadActivePolicy();
    AppLogger.instance.info(
      'Password policy service initialized with ${_policies.length} policies',
      category: 'POLICY',
    );
  }

  void _loadPolicies() {
    final stored = PreferencesStorage.instance.getString(_policiesKey);
    if (stored != null && stored.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
        for (final item in decoded) {
          final policy =
              PasswordPolicy.fromMap(item as Map<String, dynamic>);
          _policies[policy.id] = policy;
        }
      } catch (e) {
        AppLogger.instance.warning(
          'Failed to load policies from storage: $e',
          category: 'POLICY',
        );
      }
    }

    if (_policies.isEmpty) {
      _seedBuiltInTemplates();
    }
  }

  void _loadActivePolicy() {
    _activePolicyId = PreferencesStorage.instance.getString(_activePolicyKey);
  }

  Future<void> _savePolicies() async {
    final List<Map<String, dynamic>> encoded =
        _policies.values.map((p) => p.toMap()).toList();
    await PreferencesStorage.instance
        .setString(_policiesKey, jsonEncode(encoded));
  }

  Future<void> _saveActivePolicy() async {
    if (_activePolicyId != null) {
      await PreferencesStorage.instance
          .setString(_activePolicyKey, _activePolicyId!);
    } else {
      await PreferencesStorage.instance.remove(_activePolicyKey);
    }
  }

  void _seedBuiltInTemplates() {
    final templates = PolicyTemplate.builtInTemplates();
    for (final template in templates) {
      _policies[template.policy.id] = template.policy;
    }
    _savePolicies();
    AppLogger.instance.info(
      'Seeded ${templates.length} built-in policy templates',
      category: 'POLICY',
    );
  }

  PasswordPolicy? getActivePolicy() {
    if (_activePolicyId == null) return null;
    return _policies[_activePolicyId];
  }

  Future<void> setActivePolicy(String id) async {
    if (!_policies.containsKey(id)) {
      throw ArgumentError('Policy with id "$id" not found');
    }
    _activePolicyId = id;
    await _saveActivePolicy();
    AppLogger.instance.info(
      'Active policy set to "$id"',
      category: 'POLICY',
    );
  }

  List<PasswordPolicy> getPolicies() {
    return List.unmodifiable(_policies.values);
  }

  PasswordPolicy? getPolicyById(String id) {
    return _policies[id];
  }

  Future<void> createPolicy(PasswordPolicy policy) async {
    if (_policies.containsKey(policy.id)) {
      throw ArgumentError('Policy with id "${policy.id}" already exists');
    }
    _policies[policy.id] = policy.copyWith(isCustom: true);
    await _savePolicies();
    AppLogger.instance.info(
      'Created policy "${policy.name}"',
      category: 'POLICY',
    );
  }

  Future<void> updatePolicy(PasswordPolicy policy) async {
    if (!_policies.containsKey(policy.id)) {
      throw ArgumentError('Policy with id "${policy.id}" not found');
    }
    _policies[policy.id] = policy;
    await _savePolicies();
    AppLogger.instance.info(
      'Updated policy "${policy.name}"',
      category: 'POLICY',
    );
  }

  Future<void> deletePolicy(String id) async {
    final policy = _policies[id];
    if (policy == null) {
      throw ArgumentError('Policy with id "$id" not found');
    }
    if (!policy.isCustom && !id.startsWith('user_')) {
      throw ArgumentError('Cannot delete built-in policy "$id"');
    }
    _policies.remove(id);
    if (_activePolicyId == id) {
      _activePolicyId = null;
      await _saveActivePolicy();
    }
    await _savePolicies();
    AppLogger.instance.info(
      'Deleted policy "$id"',
      category: 'POLICY',
    );
  }

  PasswordPolicy duplicatePolicy(String id, String newName) {
    final original = _policies[id];
    if (original == null) {
      throw ArgumentError('Policy with id "$id" not found');
    }
    final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final duplicate = PasswordPolicy(
      id: newId,
      name: newName,
      description: original.description,
      minLength: original.minLength,
      maxLength: original.maxLength,
      minUppercase: original.minUppercase,
      minLowercase: original.minLowercase,
      minDigits: original.minDigits,
      minSymbols: original.minSymbols,
      minUniqueChars: original.minUniqueChars,
      maxRepeated: original.maxRepeated,
      maxConsecutive: original.maxConsecutive,
      allowUppercase: original.allowUppercase,
      allowLowercase: original.allowLowercase,
      allowDigits: original.allowDigits,
      allowSymbols: original.allowSymbols,
      allowSpaces: original.allowSpaces,
      blockedChars: original.blockedChars,
      requiredPrefix: original.requiredPrefix,
      requiredSuffix: original.requiredSuffix,
      isCustom: true,
    );
    _policies[newId] = duplicate;
    _savePolicies();
    AppLogger.instance.info(
      'Duplicated policy "$id" as "$newName"',
      category: 'POLICY',
    );
    return duplicate;
  }

  PolicyValidationResult validatePassword(
    String password,
    PasswordPolicy policy,
  ) {
    final List<PolicyViolation> violations = [];

    if (password.length < policy.minLength) {
      violations.add(PolicyViolation(
        rule: 'minLength',
        message:
            'Password must be at least ${policy.minLength} characters long',
        severity: 'error',
        currentValue: password.length,
        requiredValue: policy.minLength,
      ));
    }

    if (password.length > policy.maxLength) {
      violations.add(PolicyViolation(
        rule: 'maxLength',
        message:
            'Password must be at most ${policy.maxLength} characters long',
        severity: 'error',
        currentValue: password.length,
        requiredValue: policy.maxLength,
      ));
    }

    if (policy.requiredPrefix.isNotEmpty &&
        !password.startsWith(policy.requiredPrefix)) {
      violations.add(PolicyViolation(
        rule: 'requiredPrefix',
        message: 'Password must start with "${policy.requiredPrefix}"',
        severity: 'error',
        currentValue: password.isEmpty ? '' : password.substring(0, 1),
        requiredValue: policy.requiredPrefix,
      ));
    }

    if (policy.requiredSuffix.isNotEmpty &&
        !password.endsWith(policy.requiredSuffix)) {
      violations.add(PolicyViolation(
        rule: 'requiredSuffix',
        message: 'Password must end with "${policy.requiredSuffix}"',
        severity: 'error',
        currentValue: password.isEmpty ? '' : password.substring(password.length - 1),
        requiredValue: policy.requiredSuffix,
      ));
    }

    for (final char in password.split('')) {
      if (policy.blockedChars.contains(char)) {
        violations.add(PolicyViolation(
          rule: 'blockedChars',
          message: 'Password contains blocked character "$char"',
          severity: 'error',
          currentValue: char,
          requiredValue: 'Not blocked characters',
        ));
      }
    }

    if (!policy.allowSpaces && password.contains(' ')) {
      violations.add(const PolicyViolation(
        rule: 'allowSpaces',
        message: 'Password must not contain spaces',
        severity: 'error',
        currentValue: 'Contains spaces',
        requiredValue: 'No spaces allowed',
      ));
    }

    int upperCount = 0;
    int lowerCount = 0;
    int digitCount = 0;
    int symbolCount = 0;
    bool hasUppercase = false;
    bool hasLowercase = false;
    bool hasDigit = false;
    bool hasSymbol = false;

    for (final codeUnit in password.codeUnits) {
      if (codeUnit >= 65 && codeUnit <= 90) {
        upperCount++;
        hasUppercase = true;
      } else if (codeUnit >= 97 && codeUnit <= 122) {
        lowerCount++;
        hasLowercase = true;
      } else if (codeUnit >= 48 && codeUnit <= 57) {
        digitCount++;
        hasDigit = true;
      } else {
        symbolCount++;
        hasSymbol = true;
      }
    }

    if (!policy.allowUppercase && hasUppercase) {
      violations.add(PolicyViolation(
        rule: 'allowUppercase',
        message: 'Uppercase characters are not allowed',
        severity: 'error',
        currentValue: upperCount,
        requiredValue: 'No uppercase characters',
      ));
    }

    if (!policy.allowLowercase && hasLowercase) {
      violations.add(PolicyViolation(
        rule: 'allowLowercase',
        message: 'Lowercase characters are not allowed',
        severity: 'error',
        currentValue: lowerCount,
        requiredValue: 'No lowercase characters',
      ));
    }

    if (!policy.allowDigits && hasDigit) {
      violations.add(PolicyViolation(
        rule: 'allowDigits',
        message: 'Digit characters are not allowed',
        severity: 'error',
        currentValue: digitCount,
        requiredValue: 'No digit characters',
      ));
    }

    if (!policy.allowSymbols && hasSymbol) {
      violations.add(PolicyViolation(
        rule: 'allowSymbols',
        message: 'Symbol characters are not allowed',
        severity: 'error',
        currentValue: symbolCount,
        requiredValue: 'No symbol characters',
      ));
    }

    if (policy.minUppercase > 0 && upperCount < policy.minUppercase) {
      violations.add(PolicyViolation(
        rule: 'minUppercase',
        message:
            'Password must contain at least ${policy.minUppercase} uppercase character(s)',
        severity: 'error',
        currentValue: upperCount,
        requiredValue: policy.minUppercase,
      ));
    }

    if (policy.minLowercase > 0 && lowerCount < policy.minLowercase) {
      violations.add(PolicyViolation(
        rule: 'minLowercase',
        message:
            'Password must contain at least ${policy.minLowercase} lowercase character(s)',
        severity: 'error',
        currentValue: lowerCount,
        requiredValue: policy.minLowercase,
      ));
    }

    if (policy.minDigits > 0 && digitCount < policy.minDigits) {
      violations.add(PolicyViolation(
        rule: 'minDigits',
        message:
            'Password must contain at least ${policy.minDigits} digit(s)',
        severity: 'error',
        currentValue: digitCount,
        requiredValue: policy.minDigits,
      ));
    }

    if (policy.minSymbols > 0 && symbolCount < policy.minSymbols) {
      violations.add(PolicyViolation(
        rule: 'minSymbols',
        message:
            'Password must contain at least ${policy.minSymbols} symbol(s)',
        severity: 'error',
        currentValue: symbolCount,
        requiredValue: policy.minSymbols,
      ));
    }

    final int uniqueChars = password.split('').toSet().length;
    if (policy.minUniqueChars > 0 && uniqueChars < policy.minUniqueChars) {
      violations.add(PolicyViolation(
        rule: 'minUniqueChars',
        message:
            'Password must contain at least ${policy.minUniqueChars} unique character(s)',
        severity: 'error',
        currentValue: uniqueChars,
        requiredValue: policy.minUniqueChars,
      ));
    }

    if (policy.maxRepeated > 0) {
      int maxRun = 1;
      int currentRun = 1;
      for (int i = 1; i < password.length; i++) {
        if (password.codeUnitAt(i) == password.codeUnitAt(i - 1)) {
          currentRun++;
          if (currentRun > maxRun) maxRun = currentRun;
        } else {
          currentRun = 1;
        }
      }
      if (maxRun > policy.maxRepeated) {
        violations.add(PolicyViolation(
          rule: 'maxRepeated',
          message:
              'Password has $maxRun repeated characters, maximum allowed is ${policy.maxRepeated}',
          severity: 'error',
          currentValue: maxRun,
          requiredValue: policy.maxRepeated,
        ));
      }
    }

    if (policy.maxConsecutive > 0) {
      int maxSeq = 1;
      int currentSeq = 1;
      for (int i = 1; i < password.length; i++) {
        final int prev = password.codeUnitAt(i - 1);
        final int curr = password.codeUnitAt(i);
        if ((curr - prev).abs() == 1) {
          currentSeq++;
          if (currentSeq > maxSeq) maxSeq = currentSeq;
        } else {
          currentSeq = 1;
        }
      }
      if (maxSeq > policy.maxConsecutive) {
        violations.add(PolicyViolation(
          rule: 'maxConsecutive',
          message:
              'Password has $maxSeq consecutive characters, maximum allowed is ${policy.maxConsecutive}',
          severity: 'error',
          currentValue: maxSeq,
          requiredValue: policy.maxConsecutive,
        ));
      }
    }

    return PolicyValidationResult(
      isValid: violations.isEmpty,
      violations: violations,
      policyName: policy.name,
    );
  }

  PolicyValidationResult? validatePasswordAgainstActive(String password) {
    final active = getActivePolicy();
    if (active == null) return null;
    return validatePassword(password, active);
  }

  Map<String, dynamic> exportPolicy(String id) {
    final policy = _policies[id];
    if (policy == null) {
      throw ArgumentError('Policy with id "$id" not found');
    }
    return {
      'policy': policy.toMap(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
    };
  }

  PasswordPolicy importPolicy(Map<String, dynamic> data) {
    final policyData = data['policy'] as Map<String, dynamic>;
    final policy = PasswordPolicy.fromMap(policyData);
    final importedPolicy = policy.copyWith(
      id: 'user_imported_${DateTime.now().millisecondsSinceEpoch}',
      isCustom: true,
    );
    _policies[importedPolicy.id] = importedPolicy;
    _savePolicies();
    AppLogger.instance.info(
      'Imported policy "${importedPolicy.name}"',
      category: 'POLICY',
    );
    return importedPolicy;
  }

  Future<void> resetToDefaults() async {
    _policies.clear();
    _activePolicyId = null;
    _seedBuiltInTemplates();
    await _saveActivePolicy();
    AppLogger.instance.info(
      'Policies reset to defaults',
      category: 'POLICY',
    );
  }

  List<PolicyTemplate> getBuiltInTemplates() {
    return PolicyTemplate.builtInTemplates();
  }
}
