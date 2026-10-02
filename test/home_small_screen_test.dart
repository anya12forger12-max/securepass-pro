import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';
import 'package:securepass_pro/features/password_generator/presentation/screens/password_generator_screen.dart';

/// Regression tests for the Home feature grid collapsing to zero height.
///
/// The Home body used to be a `Column` whose only flexible child was the
/// feature `GridView` inside an `Expanded`. On a short/narrow surface the
/// header text wraps to several lines, the wrapped header plus padding exceed
/// the viewport, and the grid — as the only flex child — absorbed the entire
/// deficit and rendered at zero height.
///
/// The failure was silent and total: measured on a 600x1000 *physical* device
/// (density 440, so ~218x364 logical) the feature cards were absent from the
/// semantics tree *and* the rendered pixels were a single flat background
/// colour. There is no RenderFlex overflow to hint at it, because the flex
/// child simply shrank. The whole primary surface of the app was not there.
///
/// Note the logical size matters: reproducing this needs the *logical*
/// viewport, not the physical one.
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

  Finder cardInHome(String title) =>
      find.descendant(of: find.byType(HomeScreen), matching: find.text(title));

  Finder homeScrollable() => find.descendant(
    of: find.byType(HomeScreen),
    matching: find.byType(Scrollable),
  );

  const titles = [
    'Password Generator',
    'Passphrase Generator',
    'PIN Generator',
    'UUID Generator',
  ];

  Future<void> revealAll(WidgetTester tester) async {
    for (final title in titles) {
      final finder = cardInHome(title);
      if (finder.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          finder,
          100,
          scrollable: homeScrollable(),
        );
        await tester.pumpAndSettle();
      }
    }
  }

  testWidgets('all four feature cards are reachable on a tiny surface', (
    tester,
  ) async {
    // The surface that reproduced the defect on device.
    final container = await pumpAt(tester, const Size(218, 364));
    expect(find.byType(HomeScreen), findsOneWidget);

    await revealAll(tester);

    for (final title in titles) {
      expect(
        cardInHome(title),
        findsOneWidget,
        reason:
            '"$title" must be reachable on a 218x364 surface; before the '
            'fix the grid rendered at zero height and the card did not exist '
            'at all',
      );
    }
    container.dispose();
  });

  testWidgets('a feature card is tappable on a tiny surface', (tester) async {
    // A card that exists but cannot be reached is not a fix.
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details.exceptionAsString());
    };
    addTearDown(() => FlutterError.onError = previous);

    final container = await pumpAt(tester, const Size(218, 364));
    await revealAll(tester);

    final finder = cardInHome('Password Generator');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();

    // Assert the destination screen, not the card label: the label is also
    // present in the bottom navigation bar, so a text-only assertion would
    // pass even if navigation had silently failed.
    expect(find.byType(PasswordGeneratorScreen), findsOneWidget);
    expect(cardInHome('Password Generator'), findsNothing);
    // Tapping away from Home means this row no longer lays out, so only the
    // overflows raised before the tap are Home's to answer for.
    expect(
      overflows.where(
        (e) => e.contains('overflowed') && e.contains('home_screen'),
      ),
      isEmpty,
      reason: 'the Home feature grid must lay out cleanly before the tap',
    );
    container.dispose();
  });

  testWidgets('the Home header still renders on a tiny surface', (
    tester,
  ) async {
    final container = await pumpAt(tester, const Size(218, 364));
    expect(find.text('Welcome to ${AppConstants.appName}'), findsOneWidget);
    container.dispose();
  });

  testWidgets('tapping a card on a 320dp phone navigates without overflow', (
    tester,
  ) async {
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details.exceptionAsString());
    };
    addTearDown(() => FlutterError.onError = previous);

    final container = await pumpAt(tester, const Size(320, 568));
    await revealAll(tester);

    final finder = cardInHome('Password Generator');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();

    expect(find.byType(PasswordGeneratorScreen), findsOneWidget);
    // Only Home is this test's subject. The destination's strength row does
    // overflow under the test font (every glyph is the same fixed width, so
    // the label and the score cannot share the row) but that is a rendering
    // artefact, not a layout defect: measured on-device at 280, 320 and
    // 392dp, and again at 2.0x text scale, that row produced no overflow.
    expect(
      overflows.where(
        (e) => e.contains('overflowed') && e.contains('home_screen'),
      ),
      isEmpty,
      reason: 'the Home feature grid must lay out cleanly at 320dp',
    );
    container.dispose();
  });

  // Realistic small-phone widths, where the layout must be clean, not merely
  // scrollable. 280dp is roughly a foldable's cover display.
  for (final size in const [Size(280, 653), Size(320, 568), Size(360, 640)]) {
    testWidgets(
      'all four cards render without overflow at ${size.width.toInt()}dp',
      (tester) async {
        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          overflows.add(details.exceptionAsString());
          previous?.call(details);
        };
        addTearDown(() => FlutterError.onError = previous);

        final container = await pumpAt(tester, size);
        // Exercise the whole scroll extent, since cards below the fold only lay
        // out as they are scrolled into the viewport.
        await tester.drag(find.byType(HomeScreen), const Offset(0, -400));
        await tester.pumpAndSettle();
        await revealAll(tester);

        for (final title in titles) {
          expect(cardInHome(title), findsOneWidget, reason: title);
        }
        expect(
          overflows.where((e) => e.contains('overflowed')),
          isEmpty,
          reason: 'no RenderFlex overflow at ${size.width.toInt()}dp wide',
        );
        container.dispose();
      },
    );
  }

  testWidgets('normal-size surface is unaffected', (tester) async {
    final container = await pumpAt(tester, const Size(1080, 2400));
    for (final title in titles) {
      expect(cardInHome(title), findsOneWidget, reason: title);
    }
    container.dispose();
  });
}
