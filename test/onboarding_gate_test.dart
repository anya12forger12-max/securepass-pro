import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:securepass_pro/core/constants/app_constants.dart';
import 'package:securepass_pro/features/login/domain/auth_service.dart';
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
    AuthService().pbkdf2IterationsOverride = 1000;
  });

  String hashPassword(String email, String password) {
    final bytes = utf8.encode('securepass_login:$email:$password');
    return base64Encode(bytes);
  }

  testWidgets('first launch shows onboarding, then login, then home',
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

    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.ensureVisible(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.ensureVisible(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
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

  testWidgets('login screen rejects incorrect password', (tester) async {
    await PreferencesStorage.instance.setBool(
      AppConstants.onboardingCompleteKey,
      true,
    );
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      hashPassword('test@example.com', 'password123'),
    );
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'wrongpassword');
    await tester.ensureVisible(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I explicitly accept the Privacy Policy to use SecurePass Pro.'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Invalid email or password.'), findsOneWidget);
    container.dispose();
  });

  testWidgets('login screen blocks submit without consent', (tester) async {
    await PreferencesStorage.instance.setBool(
      AppConstants.onboardingCompleteKey,
      true,
    );
    await PreferencesStorage.instance.setString(
      AppConstants.loginPinKey,
      hashPassword('test@example.com', 'password123'),
    );
    final container = ProviderContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ProviderScope(child: SecurePassApp()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(
      find.text('You must explicitly accept the Privacy Policy to proceed.'),
      findsOneWidget,
    );
    container.dispose();
  });
}
