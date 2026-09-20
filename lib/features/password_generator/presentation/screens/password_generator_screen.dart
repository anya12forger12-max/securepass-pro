import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:securepass_pro/core/crypto/credential_generator.dart';
import 'package:securepass_pro/domain/entities/analysis_report.dart';
import 'package:securepass_pro/domain/entities/generation_config.dart';
import 'package:securepass_pro/domain/enums/character_set_type.dart';
import 'package:securepass_pro/services/password_analysis_service.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  static const Set<String> _ambiguousCharacters = {'O', '0', 'I', 'l', '1'};

  GenerationConfig _config = const GenerationConfig(length: 20);
  late String _result;
  late AnalysisReport _analysis;

  @override
  void initState() {
    super.initState();
    _regenerate();
  }

  void _regenerate() {
    final value = CredentialGenerator.generatePassword(_config);
    final analysis = PasswordAnalysisService.instance.analyzePassword(value);
    setState(() {
      _result = value;
      _analysis = analysis;
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _result));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Password copied to clipboard')));
  }

  bool _isEnabled(CharacterSetType type) => _config.charSets.contains(type);

  void _toggleSet(CharacterSetType type, bool enabled) {
    final updated = {..._config.charSets};
    if (enabled) {
      updated.add(type);
    } else {
      updated.remove(type);
    }
    if (updated.isEmpty) return;
    _config = _config.copyWith(charSets: updated);
    _regenerate();
  }

  void _updateConfig(GenerationConfig config) {
    _config = config;
    _regenerate();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _analysis.strength.score;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Password Generator', style: theme.textTheme.headlineMedium),
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
                          _buildStrength(theme, score),
                          const Divider(height: 32),
                          _buildLengthControl(theme),
                          const SizedBox(height: 8),
                          _buildCharSetToggles(theme),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Exclude ambiguous characters'),
                            subtitle: const Text(
                              'Avoid O/0/I/l/1 which look alike (e.g. for printed passwords)',
                            ),
                            value: _config.exclusions.containsAll(
                              _ambiguousCharacters,
                            ),
                            onChanged: (enabled) => _updateConfig(
                              _config.copyWith(
                                exclusions: enabled
                                    ? _ambiguousCharacters
                                    : const <String>{},
                              ),
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
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'monospace',
                letterSpacing: 1.2,
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

  Widget _buildStrength(ThemeData theme, int score) {
    final color = _strengthColor(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _analysis.strength.label,
              style: theme.textTheme.titleSmall?.copyWith(color: color),
            ),
            Text(
              '${_analysis.strength.score}/100  ·  ${_analysis.entropy.bits.toStringAsFixed(1)} bits',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _analysis.strength.description,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLengthControl(ThemeData theme) {
    return Row(
      children: [
        Text('Length', style: theme.textTheme.titleSmall),
        Expanded(
          child: Slider(
            value: _config.length.toDouble(),
            min: 4,
            max: 64,
            divisions: 60,
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
    );
  }

  Widget _buildCharSetToggles(ThemeData theme) {
    return Column(
      children: [
        for (final type in [
          CharacterSetType.uppercase,
          CharacterSetType.lowercase,
          CharacterSetType.numbers,
          CharacterSetType.symbols,
        ])
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(type.label),
            subtitle: Text(type.example),
            value: _isEnabled(type),
            onChanged: (value) => _toggleSet(type, value ?? false),
          ),
      ],
    );
  }

  Color _strengthColor(int score) {
    if (score < 30) return Colors.red;
    if (score < 60) return Colors.orange;
    if (score < 75) return Colors.amber;
    if (score < 90) return Colors.lightGreen;
    return Colors.green;
  }
}