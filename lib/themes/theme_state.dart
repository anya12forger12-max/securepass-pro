import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:securepass_pro/domain/enums/app_theme_mode.dart';
import 'package:securepass_pro/themes/app_theme.dart';

class ThemeState {
  const ThemeState({
    this.mode = AppThemeMode.system,
    this.accentColor = const Color(0xFF1565C0),
  });

  final AppThemeMode mode;
  final Color accentColor;

  ThemeState copyWith({AppThemeMode? mode, Color? accentColor}) {
    return ThemeState(
      mode: mode ?? this.mode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState());

  void setMode(AppThemeMode mode) => state = state.copyWith(mode: mode);

  void setAccentColor(Color color) =>
      state = state.copyWith(accentColor: color);

  ThemeMode get flutterThemeMode => AppTheme.getFlutterThemeMode(state.mode);

  ThemeData get lightTheme => AppTheme.getTheme(AppThemeMode.light);

  ThemeData get darkTheme => AppTheme.getTheme(state.mode);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) {
    return ThemeNotifier();
  },
);
