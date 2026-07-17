import 'package:flutter/material.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield,
                          size: 80,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${AppConstants.appVersion}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appDescription,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
