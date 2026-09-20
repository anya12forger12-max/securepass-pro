import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/domain/enums/app_theme_mode.dart';
import 'package:securepass_pro/features/theme_studio/presentation/screens/theme_studio_screen.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/themes/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({AppConstants.onboardingCompleteKey: true});
    await PreferencesStorage.instance.init();
  });

  testWidgets('theme mode and accent persist through Theme Studio',
      (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go('/theme-studio');
    await tester.pumpAndSettle();
    expect(find.byType(ThemeStudioScreen), findsOneWidget);

    await tester.tap(find.text('Always dark'));
    await tester.pumpAndSettle();

    expect(container.read(themeProvider).mode, AppThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    expect(
      PreferencesStorage.instance.getString(AppConstants.themeModeKey),
      AppThemeMode.dark.name,
    );

    await tester.scrollUntilVisible(
      find.byTooltip('#ffef6c00'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('#ffef6c00'));
    await tester.pumpAndSettle();

    expect(
      container.read(themeProvider).accentColor.toARGB32(),
      const Color(0xFFEF6C00).toARGB32(),
    );
    expect(
      PreferencesStorage.instance.getString(AppConstants.accentColorKey),
      const Color(0xFFEF6C00).toARGB32().toString(),
    );
    container.dispose();
  });
}