import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/features/settings/presentation/screens/settings_screen.dart';

/// Regression tests for the two small-viewport layout defects measured on
/// the published v2.2.32 APK (round 100).
///
/// 1. The bottom navigation bar renders its destination labels as an
///    unconstrained `Text`, so on a narrow viewport "Password Generator"
///    wrapped to three lines and the fixed-height bar clipped it mid-word
///    ("Setting s", "Worksp ace", "Passw ord Ge nerator"). Below the
///    threshold the bar now uses the Material compact form (icons only) and
///    the label stays reachable through the destination tooltip.
///
/// 2. The Settings / Help / Theme Studio screens pinned their heading above
///    an `Expanded(ListView)`. On a short viewport the heading consumed most
///    of the body, leaving the list ~29 logical pixels - the tiles were
///    unreachable. The heading now scrolls with the content.
///
/// The *logical* size is what matters (a 600x1000 physical screen at density
/// 440 is 218x364 logical), exactly as in `home_small_screen_test.dart`.
void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      AppConstants.onboardingCompleteKey: true,
    });
    await PreferencesStorage.instance.init();
  });

  Future<ProviderContainer> pumpAt(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

  Finder navLabel(String label) => find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      );

  /// The opacity the NavigationBar paints a destination label with.
  ///
  /// The bar builds the label as `FadeTransition(opacity: animation)` and
  /// `NavigationDestinationLabelBehavior.alwaysHide` drives that animation to
  /// 0, so the label is not painted at all (it is never clipped, because it
  /// is not visible). The nearest FadeTransition above the label text is the
  /// label's own - the icon transitions are not ancestors of the text.
  double labelOpacity(WidgetTester tester, String label) {
    FadeTransition? nearest;
    tester.element(navLabel(label)).visitAncestorElements((element) {
      if (nearest == null && element.widget is FadeTransition) {
        nearest = element.widget as FadeTransition;
      }
      return true;
    });
    expect(nearest, isNotNull);
    return nearest!.opacity.value;
  }

  testWidgets('bottom nav labels are not painted on a narrow surface', (
    tester,
  ) async {
    // 218 logical px wide - the surface that clipped the labels on device.
    final container = await pumpAt(tester, const Size(218, 364));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(
      labelOpacity(tester, 'Password Generator'),
      0.0,
      reason:
          'on a narrow surface the long destination labels must be replaced '
          'by the compact icon-only form, not painted and clipped',
    );
    // The destinations themselves must still be there and still work.
    expect(find.byType(NavigationDestination), findsNWidgets(5));
    container.dispose();
  });

  testWidgets('bottom nav labels are painted on a regular surface', (
    tester,
  ) async {
    // 393 logical px wide - an ordinary phone.
    final container = await pumpAt(tester, const Size(393, 852));

    expect(
      labelOpacity(tester, 'Password Generator'),
      1.0,
      reason: 'the compact form must only apply to genuinely narrow surfaces',
    );
    expect(navLabel('Workspace'), findsOneWidget);
    container.dispose();
  });

  testWidgets('no RenderFlex overflow is raised by the nav on a narrow surface', (
    tester,
  ) async {
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details.exceptionAsString());
    };
    addTearDown(() => FlutterError.onError = previous);

    final container = await pumpAt(tester, const Size(218, 364));

    expect(
      overflows.where((e) => e.contains('overflowed')),
      isEmpty,
      reason: 'the bottom bar must lay out cleanly on a narrow surface',
    );
    container.dispose();
  });

  testWidgets('the settings heading scrolls with the content on a short surface', (
    tester,
  ) async {
    // 364x218 logical - the 1000x600 physical landscape proxy.
    final container = await pumpAt(tester, const Size(364, 218));
    container.read(goRouterProvider).go('/settings');
    await tester.pumpAndSettle();

    // Scoped to the screen: the bottom navigation bar has a "Settings"
    // destination label of its own.
    final heading = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.text('Settings'),
    );
    expect(heading, findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListView), matching: heading),
      findsOneWidget,
      reason:
          'the heading must live inside the scrollable, otherwise it pins '
          'the body and the tiles below it become unreachable',
    );

    final before = tester.getTopLeft(heading).dy;
    await tester.drag(find.byType(ListView), const Offset(0, -120));
    await tester.pumpAndSettle();
    // The heading must have moved with the content: either it sits higher,
    // or it left the viewport and was unmounted. A heading that is pinned
    // outside the scrollable keeps its position - and with it the body
    // squeezed into a few pixels.
    final scrolledWithContent = heading.evaluate().isEmpty ||
        tester.getTopLeft(heading).dy < before;
    expect(
      scrolledWithContent,
      isTrue,
      reason: 'the heading must scroll away with the content',
    );
    container.dispose();
  });

  testWidgets('every settings tile is reachable on a short surface', (
    tester,
  ) async {
    final container = await pumpAt(tester, const Size(364, 218));
    container.read(goRouterProvider).go('/settings');
    await tester.pumpAndSettle();

    final scrollable = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
    const tiles = [
      'Sign In',
      'Appearance',
      'Security',
      'Notifications',
      'Backup & Restore',
    ];
    for (final tile in tiles) {
      final finder = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.text(tile),
      );
      await tester.scrollUntilVisible(finder, 80, scrollable: scrollable);
      await tester.pumpAndSettle();
      expect(
        finder,
        findsOneWidget,
        reason: '"$tile" must be reachable on a 364x218 surface',
      );
    }
    container.dispose();
  });
}
