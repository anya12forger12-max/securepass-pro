import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(height: 48),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  child: const Text('Get Started'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  child: const Text('Skip Setup'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
