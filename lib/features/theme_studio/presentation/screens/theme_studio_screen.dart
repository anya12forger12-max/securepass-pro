import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:securepass_pro/domain/enums/app_theme_mode.dart';
import 'package:securepass_pro/themes/theme_state.dart';

class ThemeStudioScreen extends ConsumerWidget {
  const ThemeStudioScreen({super.key});

  static const List<Color> _accentChoices = [
    Color(0xFF1565C0),
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFFAD1457),
    Color(0xFF37474F),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.watch(themeProvider);
    final notifier = ref.read(themeProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Theme Studio', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Personalize how SecurePass Pro looks and feels.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                Text('Theme Mode', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final mode in AppThemeMode.values)
                        ListTile(
                          leading: Icon(
                            switch (mode) {
                              AppThemeMode.system => Icons.brightness_auto,
                              AppThemeMode.light => Icons.light_mode,
                              AppThemeMode.dark => Icons.dark_mode,
                              AppThemeMode.highContrast =>
                                Icons.contrast,
                              AppThemeMode.ultraHighContrast =>
                                Icons.highlight,
                            },
                          ),
                          title: Text(mode.label),
                          subtitle: Text(_modeDescription(mode)),
                          trailing: state.mode == mode
                              ? Icon(
                                  Icons.check_circle,
                                  color: colorScheme.primary,
                                )
                              : null,
                          onTap: () => notifier.setMode(mode),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('Accent Color', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Applied to Light and Dark modes.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in _accentChoices)
                      _AccentSwatch(
                        color: color,
                        selected: state.accentColor.toARGB32() ==
                            color.toARGB32(),
                        onTap: () => notifier.setAccentColor(color),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
        return 'Follow your device setting';
      case AppThemeMode.light:
        return 'Always light';
      case AppThemeMode.dark:
        return 'Always dark';
      case AppThemeMode.highContrast:
        return 'High-contrast dark palette';
      case AppThemeMode.ultraHighContrast:
        return 'Maximum-contrast dark palette';
    }
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '#${color.toARGB32().toRadixString(16).padLeft(8, '0')}',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                : Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  ),
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
      ),
    );
  }
}