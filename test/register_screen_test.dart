import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/features/login/domain/auth_service.dart';
import 'package:securepass_pro/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:securepass_pro/features/login/presentation/screens/login_screen.dart';
import 'package:securepass_pro/features/login/presentation/screens/register_screen.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';
import 'package:securepass_pro/features/settings/presentation/screens/settings_screen.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:securepass_pro/navigation/app_router.dart';

Future<void> _bootstrap(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const ProviderScope(child: SecurePassApp()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillRegisterForm(
  WidgetTester tester, {
  required String email,
  required String password,
  required String confirm,
}) async {
  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.enterText(find.byType(TextField).at(2), confirm);
}

Future<void> _acceptConsent(WidgetTester tester) async {
  final tile = find.byType(CheckboxListTile);
  if (tester.widget<CheckboxListTile>(tile).value == true) return;
  await tester.ensureVisible(tile);
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

Future<void> _tapUnderFold(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextField).first, email);
  await tester.enterText(find.byType(TextField).last, password);
  await _acceptConsent(tester);
  await _tapUnderFold(tester, find.text('Sign In'));
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PreferencesStorage.instance.init();
    AuthService().pbkdf2IterationsOverride = 1000;
  });

  testWidgets('skip setup then create a new user from the login screen',
      (tester) async {
    final container = ProviderContainer();
    await _bootstrap(tester, container);

    // First launch shows onboarding; Skip Setup is a REAL skip (no account).
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await _tapUnderFold(tester, find.text('Skip Setup'));
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginPinKey),
      isNull,
      reason: 'skipping setup must not create an account',
    );

    // Reach the register flow from the login screen.
    await _tapUnderFold(
      tester,
      find.widgetWithText(OutlinedButton, 'Create Account'),
    );
    expect(find.byType(RegisterScreen), findsOneWidget);

    await _fillRegisterForm(
      tester,
      email: 'newuser@example.com',
      password: 'password123',
      confirm: 'password123',
    );
    await _acceptConsent(tester);
    await _tapUnderFold(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginPinKey),
      isNotNull,
    );
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginEmailKey),
      'newuser@example.com',
    );
    container.dispose();
  });

  testWidgets('register blocks submit without privacy consent', (tester) async {
    await PreferencesStorage.instance
        .setBool(AppConstants.onboardingCompleteKey, true);
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      base64Encode(utf8.encode('securepass_login:old@example.com:oldpass123')),
    );
    final container = ProviderContainer();
    await _bootstrap(tester, container);

    expect(find.byType(LoginScreen), findsOneWidget);
    await _tapUnderFold(
      tester,
      find.widgetWithText(OutlinedButton, 'Create Account'),
    );
    expect(find.byType(RegisterScreen), findsOneWidget);

    await _fillRegisterForm(
      tester,
      email: 'brandnew@example.com',
      password: 'password123',
      confirm: 'password123',
    );
    // No consent ticked.
    await _tapUnderFold(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(
      find.text('You must explicitly accept the Privacy Policy to proceed.'),
      findsOneWidget,
    );
    container.dispose();
  });

  testWidgets('register rejects mismatched confirm password', (tester) async {
    await PreferencesStorage.instance
        .setBool(AppConstants.onboardingCompleteKey, true);
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      base64Encode(utf8.encode('securepass_login:old@example.com:oldpass123')),
    );
    final container = ProviderContainer();
    await _bootstrap(tester, container);

    await _tapUnderFold(tester, find.widgetWithText(OutlinedButton, 'Create Account'));
    await tester.pumpAndSettle();

    await _fillRegisterForm(
      tester,
      email: 'brandnew@example.com',
      password: 'password123',
      confirm: 'password124',
    );
    await _acceptConsent(tester);
    await _tapUnderFold(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginEmailKey),
      isNot('brandnew@example.com'),
    );
    container.dispose();
  });

  testWidgets(
      'creating a new account replaces the old one, sign out lets you switch, '
      'and the new credentials work after restart', (tester) async {
    await PreferencesStorage.instance
        .setBool(AppConstants.onboardingCompleteKey, true);
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      base64Encode(utf8.encode('securepass_login:old@example.com:oldpass123')),
    );
    final container = ProviderContainer();
    await _bootstrap(tester, container);

    // Existing account forces the login gate.
    expect(find.byType(LoginScreen), findsOneWidget);
    await _tapUnderFold(
      tester,
      find.widgetWithText(OutlinedButton, 'Create Account'),
    );

    await _fillRegisterForm(
      tester,
      email: 'switch@example.com',
      password: 'newpass456',
      confirm: 'newpass456',
    );
    await _acceptConsent(tester);
    await _tapUnderFold(
      tester,
      find.widgetWithText(FilledButton, 'Create Account'),
    );
    expect(find.byType(HomeScreen), findsOneWidget);

    // The old credential is gone; the new one is live.
    expect(await AuthService().verify('old@example.com', 'oldpass123'), isFalse);
    expect(await AuthService().verify('switch@example.com', 'newpass456'), isTrue);

    // Sign out from Settings → back at the login gate.
    container.read(goRouterProvider).go('/settings');
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    await _tapUnderFold(tester, find.text('Sign Out'));
    expect(find.byType(LoginScreen), findsOneWidget);

    // Old credentials can no longer sign in...
    await _signIn(tester, 'old@example.com', 'oldpass123');
    expect(find.text('Invalid email or password.'), findsOneWidget);

    // ...but the newly created user can (the persisted credential survives).
    await _signIn(tester, 'switch@example.com', 'newpass456');
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}