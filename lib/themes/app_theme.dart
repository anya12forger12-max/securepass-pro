import 'package:flutter/material.dart';
import 'package:securepass_pro/domain/enums/app_theme_mode.dart';

class AppTheme {
  const AppTheme._();

  static ThemeMode getFlutterThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
      case AppThemeMode.ultraHighContrast:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.highContrast:
        return ThemeMode.dark;
    }
  }

  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return _lightTheme();
      case AppThemeMode.dark:
        return _darkTheme();
      case AppThemeMode.system:
        return _lightTheme();
      case AppThemeMode.highContrast:
        return _highContrastTheme();
      case AppThemeMode.ultraHighContrast:
        return _ultraHighContrastTheme();
    }
  }

  static ColorScheme _lightColorScheme() => const ColorScheme.light(
    primary: Color(0xFF1565C0),
    primaryContainer: Color(0xFFBBDEFB),
    onPrimaryContainer: Color(0xFF0D47A1),
    secondary: Color(0xFF546E7A),
    secondaryContainer: Color(0xFFCFD8DC),
    onSecondaryContainer: Color(0xFF263238),
    onSurface: Color(0xFF1C1B1F),
    surfaceContainerHighest: Color(0xFFF5F5F5),
    error: Color(0xFFD32F2F),
    outline: Color(0xFFBDBDBD),
  );

  static ColorScheme _darkColorScheme() => const ColorScheme.dark(
    primary: Color(0xFF64B5F6),
    onPrimary: Color(0xFF0D47A1),
    primaryContainer: Color(0xFF1565C0),
    onPrimaryContainer: Color(0xFFBBDEFB),
    secondary: Color(0xFF90A4AE),
    onSecondary: Color(0xFF263238),
    secondaryContainer: Color(0xFF37474F),
    onSecondaryContainer: Color(0xFFCFD8DC),
    surface: Color(0xFF1E1E2E),
    onSurface: Color(0xFFE1E1E1),
    surfaceContainerHighest: Color(0xFF2C2C3E),
    error: Color(0xFFEF5350),
    onError: Color(0xFFB71C1C),
    outline: Color(0xFF616161),
  );

  static ColorScheme _highContrastColorScheme() => const ColorScheme.dark(
    primary: Color(0xFF82B1FF),
    primaryContainer: Color(0xFF2962FF),
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF80CBC4),
    secondaryContainer: Color(0xFF00695C),
    onSecondaryContainer: Colors.white,
    surface: Color(0xFF000000),
    surfaceContainerHighest: Color(0xFF1A1A1A),
    error: Color(0xFFFF5252),
    outline: Color(0xFF9E9E9E),
  );

  static ColorScheme _ultraHighContrastColorScheme() => const ColorScheme.dark(
    primary: Color(0xFFFFD740),
    primaryContainer: Color(0xFFFFC107),
    onPrimaryContainer: Colors.black,
    secondary: Color(0xFF69F0AE),
    secondaryContainer: Color(0xFF00E676),
    onSecondaryContainer: Colors.black,
    surface: Color(0xFF000000),
    surfaceContainerHighest: Color(0xFF111111),
    error: Color(0xFFFF1744),
    outline: Color(0xFFFFFFFF),
  );

  static TextTheme _buildTextTheme(TextTheme base) => base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontWeight: FontWeight.w400),
    headlineLarge: base.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
    titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w500),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
    labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w500),
  );

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final textTheme = _buildTextTheme(
      ThemeData(colorScheme: colorScheme).textTheme,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onPrimaryContainer,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        textStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontSize: 12,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest,
        ),
        dataRowColor: WidgetStateProperty.all(Colors.transparent),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        dividerThickness: 1,
      ),
    );
  }

  static ThemeData _lightTheme() => _buildTheme(_lightColorScheme());

  static ThemeData _darkTheme() => _buildTheme(_darkColorScheme());

  static ThemeData _highContrastTheme() =>
      _buildTheme(_highContrastColorScheme());

  static ThemeData _ultraHighContrastTheme() =>
      _buildTheme(_ultraHighContrastColorScheme());
}
