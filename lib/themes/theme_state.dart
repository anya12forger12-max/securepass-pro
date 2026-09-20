import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/domain/enums/app_theme_mode.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
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
  ThemeNotifier() : super(_loadPersisted());

  static ThemeState _loadPersisted() {
    return ThemeState(
      mode: _readMode(),
      accentColor: _readAccent(),
    );
  }

  static String? _readPref(String key) {
    try {
      return PreferencesStorage.instance.getString(key);
    } catch (_) {
      return null;
    }
  }

  static AppThemeMode _readMode() {
    final raw = _readPref(AppConstants.themeModeKey);
    if (raw == null) return AppThemeMode.system;
    for (final mode in AppThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return AppThemeMode.system;
  }

  static Color _readAccent() {
    final raw = _readPref(AppConstants.accentColorKey);
    final parsed = raw == null ? null : int.tryParse(raw);
    if (parsed == null) return const Color(0xFF1565C0);
    return Color(0xFF000000 | (parsed & 0xFFFFFF));
  }

  void setMode(AppThemeMode mode) {
    state = state.copyWith(mode: mode);
    unawaited(PreferencesStorage.instance.setString(
      AppConstants.themeModeKey,
      mode.name,
    ));
  }

  void setAccentColor(Color color) {
    state = state.copyWith(accentColor: color);
    unawaited(PreferencesStorage.instance.setString(
      AppConstants.accentColorKey,
      color.toARGB32().toString(),
    ));
  }

  ThemeMode get flutterThemeMode => AppTheme.getFlutterThemeMode(state.mode);

  ThemeData get lightTheme =>
      AppTheme.getTheme(AppThemeMode.light, accentColor: state.accentColor);

  ThemeData get darkTheme =>
      AppTheme.getTheme(state.mode, accentColor: state.accentColor);
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) {
    return ThemeNotifier();
  },
);