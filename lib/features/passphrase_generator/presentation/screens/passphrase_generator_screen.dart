import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:securepass_pro/core/crypto/credential_generator.dart';
import 'package:securepass_pro/domain/entities/passphrase_config.dart';

class PassphraseGeneratorScreen extends StatefulWidget {
  const PassphraseGeneratorScreen({super.key});

  @override
  State<PassphraseGeneratorScreen> createState() =>
      _PassphraseGeneratorScreenState();
}

class _PassphraseGeneratorScreenState extends State<PassphraseGeneratorScreen> {
  PassphraseConfig _config = const PassphraseConfig();
  late String _result;

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() {
      _result = CredentialGenerator.generatePassphrase(_config);
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _result));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passphrase copied to clipboard')),
    );
  }

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
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildResult(theme),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('Words', style: theme.textTheme.titleSmall),
                              Expanded(
                                child: Slider(
                                  value: _config.wordCount.toDouble(),
                                  min: 3,
                                  max: 10,
                                  divisions: 7,
                                  label: '${_config.wordCount}',
                                  onChanged: (value) => _updateConfig(
                                    _config.copyWith(wordCount: value.round()),
                                  ),
                                ),
                              ),
                              Text(
                                '${_config.wordCount}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildSeparatorControl(theme),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Capitalize each word'),
                            value: _config.capitalize,
                            onChanged: (value) => _updateConfig(
                              _config.copyWith(capitalize: value),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Include a number'),
                            value: _config.includeNumber,
                            onChanged: (value) => _updateConfig(
                              _config.copyWith(includeNumber: value),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Include a symbol'),
                            value: _config.includeSymbol,
                            onChanged: (value) => _updateConfig(
                              _config.copyWith(includeSymbol: value),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton.icon(
                            onPressed: _regenerate,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate'),
                          ),
                        ],
                      ),
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

  void _updateConfig(PassphraseConfig config) {
    _config = config;
    _regenerate();
  }

  Widget _buildResult(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              _result,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 1.0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy to clipboard',
            icon: const Icon(Icons.copy_outlined),
            onPressed: _copy,
          ),
        ],
      ),
    );
  }

  Widget _buildSeparatorControl(ThemeData theme) {
    return Row(
      children: [
        Text('Separator', style: theme.textTheme.titleSmall),
        const SizedBox(width: 12),
        for (final separator in const ['-', ' ', '_', '.'])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                separator == ' ' ? 'space' : separator,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              selected: _config.separator == separator,
              onSelected: (_) => _updateConfig(
                _config.copyWith(separator: separator),
              ),
            ),
          ),
      ],
    );
  }
}