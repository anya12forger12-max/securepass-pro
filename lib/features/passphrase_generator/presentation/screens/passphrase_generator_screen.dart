import 'package:flutter/material.dart';

class PassphraseGeneratorScreen extends StatelessWidget {
  const PassphraseGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passphrase Generator', style: theme.textTheme.headlineMedium),
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
                          Icons.chat,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Generate memorable passphrases',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create easy-to-remember but hard-to-crack passphrases.',
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
            ),
          ),
        ],
      ),
    );
  }
}
