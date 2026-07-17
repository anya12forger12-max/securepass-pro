import 'package:flutter/material.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to ${AppConstants.appName}',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.appDescription,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1024
                  ? 3
                  : 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _FeatureCard(
                  icon: Icons.password,
                  title: 'Password Generator',
                  description: 'Generate secure random passwords',
                  onTap: () => Navigator.of(context).pushNamed('/password-generator'),
                ),
                _FeatureCard(
                  icon: Icons.chat,
                  title: 'Passphrase Generator',
                  description: 'Create memorable passphrases',
                  onTap: () => Navigator.of(context).pushNamed('/passphrase-generator'),
                ),
                _FeatureCard(
                  icon: Icons.pin,
                  title: 'PIN Generator',
                  description: 'Generate secure PIN codes',
                  onTap: () => Navigator.of(context).pushNamed('/pin-generator'),
                ),
                _FeatureCard(
                  icon: Icons.fingerprint,
                  title: 'UUID Generator',
                  description: 'Generate unique identifiers',
                  onTap: () => Navigator.of(context).pushNamed('/uuid-generator'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
