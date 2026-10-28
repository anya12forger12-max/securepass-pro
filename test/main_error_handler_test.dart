import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('main source-order regression guards', () {
    test('FirebaseCrashlytics init must come after Firebase.initializeApp()', () {
      const mainPath = 'lib/main.dart';
      final content = File(mainPath).readAsStringSync();

      final firebaseInitOffset = content.indexOf('Firebase.initializeApp()');
      final crashlyticsOffset = content.indexOf(
          'FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled');

      expect(firebaseInitOffset, isNot(-1),
          reason: 'Firebase.initializeApp() must be present in main.dart');
      expect(crashlyticsOffset, isNot(-1),
          reason:
              'FirebaseCrashlytics.setCrashlyticsCollectionEnabled must be present in main.dart');
      expect(crashlyticsOffset, greaterThan(firebaseInitOffset),
          reason: 'Crashlytics must be initialized AFTER Firebase.initializeApp() succeeds, '
              'not before — calling setCrashlyticsCollectionEnabled on an uninitialized '
              'Firebase app throws [core/no-app] and crashes every launch');
    });

    test('Crashlytics enable must be gated behind a firebaseReady guard', () {
      const mainPath = 'lib/main.dart';
      final content = File(mainPath).readAsStringSync();

      // The Crashlytics enable call must only run when initialization succeeded.
      // A bare call (no guard) would crash on devices where Firebase cannot init.
      final crashlyticsOffset = content.indexOf(
          'FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled');
      expect(crashlyticsOffset, isNot(-1),
          reason: 'Crashlytics enable call must be present');

      // The firebaseReady flag must be declared and set to true only after
      // Firebase.initializeApp() returns successfully.
      expect(content.contains('bool firebaseReady = false;'), isTrue,
          reason: 'a firebaseReady guard flag must be declared (default false)');
      expect(
          RegExp(r'firebaseReady\s*=\s*true;').hasMatch(content), isTrue,
          reason: 'firebaseReady must be set to true after a successful init');

      // The Crashlytics enable must sit inside an `if (firebaseReady)` block.
      final guardOffset = content.indexOf('if (firebaseReady)');
      expect(guardOffset, isNot(-1),
          reason: 'the Crashlytics enable must be wrapped in `if (firebaseReady)`');
      expect(guardOffset, lessThan(crashlyticsOffset),
          reason: 'the `if (firebaseReady)` guard must precede the Crashlytics enable call');
    });
  });
}
