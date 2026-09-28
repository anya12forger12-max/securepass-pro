import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:securepass_pro/features/login/presentation/screens/login_screen.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';
import 'package:securepass_pro/infrastructure/storage/preferences_storage.dart';
import 'package:securepass_pro/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await PreferencesStorage.instance.init();
  });

  testWidgets('first launch shows onboarding, then login setup, then home',
      (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);

    await tester.tap(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Set Up Your PIN'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.enterText(find.byType(TextField).last, '1234');
    await tester.tap(find.text('Set PIN'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      PreferencesStorage.instance.getBool(AppConstants.onboardingCompleteKey),
      isTrue,
    );
    expect(
      PreferencesStorage.instance.getString(AppConstants.loginPinKey),
      isNotNull,
    );
    container.dispose();
  });

  testWidgets('skip setup also goes through login setup', (tester) async {
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Set Up Your PIN'), findsOneWidget);
    container.dispose();
  });

  testWidgets('login screen unlocks with correct PIN', (tester) async {
    await PreferencesStorage.instance.setBool(
      AppConstants.onboardingCompleteKey,
      true,
    );
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      'c2VjdXJlcGFzc19sb2dpbjoxMjM0',
    );
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '1234');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    container.dispose();
  });

  testWidgets('login screen rejects incorrect PIN', (tester) async {
    await PreferencesStorage.instance.setBool(
      AppConstants.onboardingCompleteKey,
      true,
    );
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      'c2VjdXJlcGFzc19sb2dpbjoxMjM0',
    );
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '9999');
    await tester.tap(find.text('Unlock'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
    container.dispose();
  });
}
