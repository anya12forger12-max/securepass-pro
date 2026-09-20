import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:securepass_pro/core/crypto/credential_generator.dart';
import 'package:securepass_pro/domain/entities/pin_config.dart';

class PinGeneratorScreen extends StatefulWidget {
  const PinGeneratorScreen({super.key});

  @override
  State<PinGeneratorScreen> createState() => _PinGeneratorScreenState();
}

class _PinGeneratorScreenState extends State<PinGeneratorScreen> {
  PinConfig _config = const PinConfig();
  late String _result;

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() {
      _result = CredentialGenerator.generatePin(_config);
    });
  }

  void _updateConfig(PinConfig config) {
    _config = config;
    _regenerate();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _result));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('PIN copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PIN Generator', style: theme.textTheme.headlineMedium),
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
                              Text('Digits', style: theme.textTheme.titleSmall),
                              Expanded(
                                child: Slider(
                                  value: _config.length.toDouble(),
                                  min: 4,
                                  max: 16,
                                  divisions: 12,
                                  label: '${_config.length}',
                                  onChanged: (value) => _updateConfig(
                                    _config.copyWith(length: value.round()),
                                  ),
                                ),
                              ),
                              Text(
                                '${_config.length}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Avoid repeated digits'),
                            subtitle: const Text(
                              'No digit twice in a row (e.g. 11 or 33)',
                            ),
                            value: _config.avoidRepeated,
                            onChanged: (value) => _updateConfig(
                              _config.copyWith(avoidRepeated: value),
                            ),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Avoid sequential digits'),
                            subtitle: const Text(
                              'No digit next to its neighbour (e.g. 12 or 89)',
                            ),
                            value: _config.avoidSequential,
                            onChanged: (value) => _updateConfig(
                              _config.copyWith(avoidSequential: value),
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
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 4,
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
}