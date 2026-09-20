import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:securepass_pro/core/crypto/credential_generator.dart';

class UuidGeneratorScreen extends StatefulWidget {
  const UuidGeneratorScreen({super.key});

  @override
  State<UuidGeneratorScreen> createState() => _UuidGeneratorScreenState();
}

class _UuidGeneratorScreenState extends State<UuidGeneratorScreen> {
  late String _result;
  int _count = 1;
  List<String> _results = [];

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    setState(() {
      _results = List.generate(
        _count,
        (_) => CredentialGenerator.generateUuidV4(),
      );
      _result = _results.join('\n');
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _result));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UUIDs copied to clipboard')),
    );
  }

  Future<void> _copySingle(String uuid) async {
    await Clipboard.setData(ClipboardData(text: uuid));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('UUID copied to clipboard')),
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
          Text('UUID Generator', style: theme.textTheme.headlineMedium),
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
                          Text(
                            'Generate cryptographically random UUID v4 values',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final uuid in _results)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: SelectableText(
                                        uuid,
                                        style: theme.textTheme.bodyLarge
                                            ?.copyWith(fontFamily: 'monospace'),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Copy UUID',
                                      icon: const Icon(
                                        Icons.copy_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => _copySingle(uuid),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('Count', style: theme.textTheme.titleSmall),
                              const SizedBox(width: 12),
                              for (final value in const [1, 3, 5, 10])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text('$value'),
                                    selected: _count == value,
                                    onSelected: (_) {
                                      _count = value;
                                      _regenerate();
                                    },
                                  ),
                                ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _regenerate,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Generate'),
                          ),
                          if (_count > 1)
                            TextButton.icon(
                              onPressed: _copyAll,
                              icon: const Icon(Icons.copy_all_outlined),
                              label: const Text('Copy all'),
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
}