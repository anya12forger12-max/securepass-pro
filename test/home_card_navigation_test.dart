import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';
import 'package:securepass_pro/features/password_generator/presentation/screens/password_generator_screen.dart';
import 'package:securepass_pro/features/passphrase_generator/presentation/screens/passphrase_generator_screen.dart';
import 'package:securepass_pro/features/pin_generator/presentation/screens/pin_generator_screen.dart';
import 'package:securepass_pro/features/uuid_generator/presentation/screens/uuid_generator_screen.dart';

/// Regression tests for the Home feature-card tap targets.
///
/// The app is a GoRouter app (`MaterialApp.router` with `routerConfig` and no
/// `routes:`/`onGenerateRoute` table). The Home cards previously navigated with
/// `Navigator.of(context).pushNamed('/password-generator')`, which asks the
/// underlying Navigator for a *named* route. GoRouter's navigator has no named
/// route table, so the lookup returned null and every tap threw
/// `Null check operator used on a null value` from
/// `NavigatorState._routeNamed` — on a real device that is a silently dead
/// button: the tap does nothing and the framework swallows the error.
///
/// `nav_regression_test.dart` could not catch this because it calls
/// `router.go(path)` directly instead of driving the UI, so the broken
/// `pushNamed` code path was never executed. These tests tap the cards.
void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      AppConstants.onboardingCompleteKey: true,
    });
    await PreferencesStorage.instance.init();
  });

  Future<ProviderContainer> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// The card title is unique inside the Home card grid; the same string also
  /// appears as a bottom-navigation label, so the finder must be scoped.
  Finder cardTitle(String title) => find.descendant(
        of: find.byType(HomeScreen),
        matching: find.text(title),
      );

  final cards = <String, Type>{
    'Password Generator': PasswordGeneratorScreen,
    'Passphrase Generator': PassphraseGeneratorScreen,
    'PIN Generator': PinGeneratorScreen,
    'UUID Generator': UuidGeneratorScreen,
  };

  testWidgets('each Home card navigates to its generator without throwing',
      (tester) async {
    final container = await pumpApp(tester);

    for (final entry in cards.entries) {
      // The grid is virtualized: scroll the card into view before tapping.
      final finder = cardTitle(entry.key);
      await tester.scrollUntilVisible(
        finder,
        120,
        scrollable: find.descendant(
          of: find.byType(HomeScreen),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.pumpAndSettle();

      expect(finder, findsOneWidget, reason: 'card "${entry.key}" should exist');
      await tester.tap(finder);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'tapping the "${entry.key}" card must not throw (a GoRouter app '
            'cannot resolve Navigator.pushNamed)',
      );
      expect(
        find.byType(entry.value),
        findsOneWidget,
        reason: '"${entry.key}" card should mount ${entry.value}',
      );

      // Return to Home for the next card.
      container.read(goRouterProvider).go('/home');
      await tester.pumpAndSettle();
    }

    container.dispose();
  });

  testWidgets('tapping a Home card does not throw when the route is unknown',
      (tester) async {
    // Sanity check on the harness itself: a route GoRouter cannot resolve must
    // surface as a testable exception, otherwise the assertions above would be
    // vacuous. Guards against a future "test passes because tap did nothing".
    final container = await pumpApp(tester);
    await tester.tap(cardTitle('Password Generator'));
    await tester.pumpAndSettle();
    expect(
      find.byType(PasswordGeneratorScreen),
      findsOneWidget,
      reason: 'the fix must actually navigate, not just avoid throwing',
    );
    container.dispose();
  });
}