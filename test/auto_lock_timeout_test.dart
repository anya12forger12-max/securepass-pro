import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockEncryptedStorage();
    SharedPreferences.setMockInitialValues({
      AppConstants.onboardingCompleteKey: true,
    });
    await PreferencesStorage.instance.init();
  });

  testWidgets('auto-lock timeout stores minutes as seconds, default and custom',
      (tester) async {
    final vault = VaultService();
    vault.pbkdf2IterationsOverride = 1000;
    await vault.initialize();

    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go('/settings');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Security'));
    await tester.pumpAndSettle();

    Finder inDialog(Finder matching) =>
        find.descendant(of: find.byType(AlertDialog), matching: matching);

    await tester.enterText(
        inDialog(find.byType(TextField)), '2468');
    await tester.tap(find.text('Set vault PIN'));
    await tester.pumpAndSettle();

    expect(vault.hasPin, isTrue);
    expect(vault.autoLockSeconds, 300,
        reason: 'default 5-minute timeout must not be stored as 5 hours');

    await tester.tap(inDialog(find.byType(DropdownButtonFormField<String>)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutes').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        inDialog(find.byType(TextField)), '1234');
    await tester.tap(find.text('Update PIN'));
    await tester.pumpAndSettle();

    expect(vault.autoLockSeconds, 1800,
        reason: 'selected 30 minutes must persist as 1800 seconds');
    container.dispose();
  });
}

void mockEncryptedStorage() {
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async {
    switch (call.method) {
      case 'read':
        return null;
      case 'readAll':
        return <String, String>{};
      case 'containsKey':
        return true;
      case 'isProtectedDataAvailable':
        return true;
      default:
        return null;
    }
  });
}