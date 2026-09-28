import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  var _privacyAccepted = false;

  Future<void> _complete() async {
    await PreferencesStorage.instance.setBool(
      AppConstants.onboardingCompleteKey,
      true,
    );
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                Icon(
                  Icons.shield,
                  size: 96,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to SecurePass Pro',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enterprise-grade password management and security platform. '
                  'Generate, store, and manage your credentials with confidence.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'Privacy policy consent checkbox',
                  child: CheckboxListTile(
                    title: const Text(
                      'I explicitly accept the Privacy Policy to use SecurePass Pro.',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: _privacyAccepted,
                    onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _privacyAccepted
                      ? _complete
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You must explicitly accept the Privacy Policy to proceed.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Get Started'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _privacyAccepted
                      ? _complete
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'You must explicitly accept the Privacy Policy to proceed.',
                              ),
                            ),
                          );
                        },
                  child: const Text('Skip Setup'),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}