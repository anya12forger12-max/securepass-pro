import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/domain/enums/navigation_section.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';
import 'package:securepass_pro/features/password_generator/presentation/screens/password_generator_screen.dart';
import 'package:securepass_pro/features/passphrase_generator/presentation/screens/passphrase_generator_screen.dart';
import 'package:securepass_pro/features/pin_generator/presentation/screens/pin_generator_screen.dart';
import 'package:securepass_pro/features/uuid_generator/presentation/screens/uuid_generator_screen.dart';
import 'package:securepass_pro/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:securepass_pro/features/diagnostics/presentation/screens/diagnostics_screen.dart';
import 'package:securepass_pro/features/settings/presentation/screens/settings_screen.dart';
import 'package:securepass_pro/features/theme_studio/presentation/screens/theme_studio_screen.dart';
import 'package:securepass_pro/features/help/presentation/screens/help_screen.dart';
import 'package:securepass_pro/features/about/presentation/screens/about_screen.dart';

Type screenFor(NavigationSection section) {
  switch (section) {
    case NavigationSection.home:
      return HomeScreen;
    case NavigationSection.passwordGenerator:
      return PasswordGeneratorScreen;
    case NavigationSection.passphraseGenerator:
      return PassphraseGeneratorScreen;
    case NavigationSection.pinGenerator:
      return PinGeneratorScreen;
    case NavigationSection.randomGenerator:
    case NavigationSection.uuidGenerator:
    case NavigationSection.apiTokens:
    case NavigationSection.recoveryCodes:
    case NavigationSection.randomStrings:
      return UuidGeneratorScreen;
    case NavigationSection.workspace:
      return WorkspaceScreen;
    case NavigationSection.diagnostics:
      return DiagnosticsScreen;
    case NavigationSection.settings:
      return SettingsScreen;
    case NavigationSection.themeStudio:
      return ThemeStudioScreen;
    case NavigationSection.help:
      return HelpScreen;
    case NavigationSection.about:
      return AboutScreen;
  }
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PreferencesStorage.instance.init();
  });

  testWidgets('every NavigationSection path resolves (no GoRouter error page)',
      (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    final router = container.read(goRouterProvider);

    for (final section in NavigationSection.values) {
      final expectedPath = '/${section.path}';
      router.go(expectedPath);
      await tester.pumpAndSettle();

      expect(
        find.byType(screenFor(section), skipOffstage: false),
        findsOneWidget,
        reason: '${section.name} should mount ${screenFor(section)} at $expectedPath',
      );
    }

    container.dispose();
  });

  testWidgets('unknown path renders an error page instead of crashing',
      (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go('/definitely-not-a-route');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(UuidGeneratorScreen), findsNothing);
    expect(find.byType(HomeScreen), findsNothing);
    container.dispose();
  });
}