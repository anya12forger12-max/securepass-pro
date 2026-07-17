import 'package:flutter/material.dart';

class ThemeStudioScreen extends StatelessWidget {
  const ThemeStudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme Studio', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.palette,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Customize Your Theme',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Adjust colors, fonts, and visual settings to your preference.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
