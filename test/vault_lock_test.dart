import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';
import 'package:securepass_pro/services/vault_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockEncryptedStorage();
    SharedPreferences.setMockInitialValues({AppConstants.onboardingCompleteKey: true});
    await PreferencesStorage.instance.init();
  });

  const key = Key('vault_pin_field');

  testWidgets('fresh vault with no PIN is not locked and opens directly',
      (tester) async {
    final vault = VaultService();
    vault.pbkdf2IterationsOverride = 1000;
    await vault.initialize();
    expect(vault.hasPin, isFalse);
    expect(vault.isLocked, isFalse);

    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go('/workspace');
    await tester.pumpAndSettle();

    expect(find.text('Your Workspace is empty'), findsOneWidget);
    expect(find.text('Vault locked'), findsNothing);
    container.dispose();
  });

  testWidgets('setting a PIN enables locking and protects entries',
      (tester) async {
    final vault = VaultService();
    vault.pbkdf2IterationsOverride = 1000;
    await vault.initialize();
    await vault.setVaultPin('1234');
    expect(vault.hasPin, isTrue);
    expect(vault.isLocked, isFalse);

    expect(await vault.unlock('9999'), isFalse);
    expect(await vault.unlock('1234'), isTrue);
  });

  testWidgets('locked vault requires the correct PIN to be unlocked',
      (tester) async {
    final vault = VaultService();
    vault.pbkdf2IterationsOverride = 1000;
    await vault.initialize();
    await vault.setVaultPin('2468');
    vault.lock();
    expect(vault.isLocked, isTrue);

    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    container.read(goRouterProvider).go('/workspace');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Vault locked'), findsOneWidget);
    expect(find.byType(WorkspaceScreen), findsOneWidget);
    expect(find.text('Add entry'), findsNothing);

    await tester.enterText(find.byKey(key), '0000');
    await tester.tap(find.text('Unlock'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
    expect(vault.isLocked, isTrue);

    await tester.enterText(find.byKey(key), '2468');
    await tester.tap(find.text('Unlock'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));

    expect(vault.isLocked, isFalse);
    expect(find.text('Add entry'), findsOneWidget);
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