import 'package:flutter/material.dart';
import 'package:securepass_pro/domain/entities/password_policy.dart';

class PolicyTemplate {
  const PolicyTemplate({
    required this.policy,
    required this.icon,
    required this.category,
    this.isBuiltIn = false,
  });

  final PasswordPolicy policy;
  final IconData icon;
  final String category;
  final bool isBuiltIn;

  static List<PolicyTemplate> builtInTemplates() {
    return const [
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_personal',
          name: 'Personal',
          description: 'Standard policy for personal accounts and services',
          minLength: 12,
        ),
        icon: Icons.person,
        category: 'General',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_developer',
          name: 'Developer',
          description: 'Strong policy for developer tools and code repositories',
          minLength: 16,
          minSymbols: 1,
        ),
        icon: Icons.code,
        category: 'Technical',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_enterprise',
          name: 'Enterprise',
          description: 'Strict policy for enterprise environments',
          minLength: 20,
          minUppercase: 2,
          minLowercase: 2,
          minDigits: 2,
          minSymbols: 1,
          minUniqueChars: 10,
          maxRepeated: 3,
        ),
        icon: Icons.business,
        category: 'Enterprise',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_database',
          name: 'Database',
          description: 'Policy for database and infrastructure credentials',
          minLength: 16,
          minSymbols: 1,
          maxConsecutive: 3,
        ),
        icon: Icons.storage,
        category: 'Technical',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_wifi',
          name: 'Wi-Fi',
          description: 'Policy for Wi-Fi network passwords',
          minLength: 12,
        ),
        icon: Icons.wifi,
        category: 'Network',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_email',
          name: 'Email',
          description: 'Policy for email account passwords',
          minLength: 14,
        ),
        icon: Icons.email,
        category: 'General',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_banking',
          name: 'Banking',
          description: 'Maximum security policy for financial accounts',
          minLength: 20,
          minUppercase: 2,
          minLowercase: 2,
          minDigits: 2,
          minSymbols: 2,
          minUniqueChars: 12,
          maxRepeated: 2,
        ),
        icon: Icons.account_balance,
        category: 'Financial',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_government',
          name: 'Government',
          description: 'Policy meeting government security standards',
          minLength: 16,
          minUppercase: 2,
          minLowercase: 2,
          minDigits: 2,
          minSymbols: 1,
          minUniqueChars: 10,
        ),
        icon: Icons.gavel,
        category: 'Enterprise',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_education',
          name: 'Education',
          description: 'Balanced policy for educational platforms',
          minLength: 12,
        ),
        icon: Icons.school,
        category: 'General',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_research',
          name: 'Research',
          description: 'Policy for research data and lab system access',
          minLength: 18,
          minSymbols: 1,
          minUniqueChars: 8,
        ),
        icon: Icons.science,
        category: 'Technical',
        isBuiltIn: true,
      ),
      PolicyTemplate(
        policy: PasswordPolicy(
          id: 'tpl_custom',
          name: 'Custom',
          description: 'Create your own custom password policy',
          isCustom: true,
        ),
        icon: Icons.tune,
        category: 'Custom',
        isBuiltIn: true,
      ),
    ];
  }
}
