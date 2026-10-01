import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({AppConstants.onboardingCompleteKey: true});
    await PreferencesStorage.instance.init();
  });
  for (final w in [218.0, 240.0, 280.0, 320.0, 360.0]) {
    testWidgets('dest $w', (tester) async {
      tester.view.physicalSize = Size(w, 700); tester.view.devicePixelRatio = 1.0;
      addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
      final seen = <String>[];
      final prev = FlutterError.onError;
      FlutterError.onError = (d) { seen.add(d.toString()); };
      await tester.pumpWidget(const ProviderScope(child: SecurePassApp()));
      await tester.pumpAndSettle();
      for (final t in ['Password Generator','Passphrase Generator','PIN Generator','UUID Generator']) {
        final f = find.descendant(of: find.byType(HomeScreen), matching: find.text(t));
        if (f.evaluate().isEmpty) {
          await tester.scrollUntilVisible(f, 100, scrollable: find.descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable)));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }
      FlutterError.onError = prev;
      final locs = seen.where((s)=>s.contains('overflow')).map((s)=>RegExp(r'([a-z_]+\.dart:\d+:\d+)').firstMatch(s)?.group(1) ?? '?').toSet().toList();
      final amts = seen.where((s)=>s.contains('overflow')).map((s)=>RegExp(r'overflowed by [0-9.]+ pixels').firstMatch(s)?.group(0) ?? '?').toSet().toList();
      print('>> w=$w destOverflow=$locs $amts');
    });
  }
}
