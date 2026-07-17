import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:securepass_pro/domain/enums/navigation_section.dart';
import 'package:securepass_pro/shared/widgets/app_scaffold.dart';
import 'package:securepass_pro/features/home/presentation/screens/home_screen.dart';
import 'package:securepass_pro/features/password_generator/presentation/screens/password_generator_screen.dart';
import 'package:securepass_pro/features/passphrase_generator/presentation/screens/passphrase_generator_screen.dart';
import 'package:securepass_pro/features/pin_generator/presentation/screens/pin_generator_screen.dart';
import 'package:securepass_pro/features/uuid_generator/presentation/screens/uuid_generator_screen.dart';
import 'package:securepass_pro/features/settings/presentation/screens/settings_screen.dart';
import 'package:securepass_pro/features/diagnostics/presentation/screens/diagnostics_screen.dart';
import 'package:securepass_pro/features/about/presentation/screens/about_screen.dart';
import 'package:securepass_pro/features/help/presentation/screens/help_screen.dart';
import 'package:securepass_pro/features/theme_studio/presentation/screens/theme_studio_screen.dart';
import 'package:securepass_pro/features/workspace/presentation/screens/workspace_screen.dart';
import 'package:securepass_pro/features/onboarding/presentation/screens/onboarding_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: NavigationSection.home.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/password-generator',
            name: NavigationSection.passwordGenerator.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PasswordGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/passphrase-generator',
            name: NavigationSection.passphraseGenerator.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PassphraseGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/pin-generator',
            name: NavigationSection.pinGenerator.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PinGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/uuid-generator',
            name: NavigationSection.uuidGenerator.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UuidGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/random-generator',
            name: NavigationSection.randomGenerator.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UuidGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/api-tokens',
            name: NavigationSection.apiTokens.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UuidGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/recovery-codes',
            name: NavigationSection.recoveryCodes.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UuidGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/random-strings',
            name: NavigationSection.randomStrings.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: UuidGeneratorScreen(),
            ),
          ),
          GoRoute(
            path: '/workspace',
            name: NavigationSection.workspace.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorkspaceScreen(),
            ),
          ),
          GoRoute(
            path: '/diagnostics',
            name: NavigationSection.diagnostics.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DiagnosticsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: NavigationSection.settings.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/theme-studio',
            name: NavigationSection.themeStudio.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ThemeStudioScreen(),
            ),
          ),
          GoRoute(
            path: '/help',
            name: NavigationSection.help.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HelpScreen(),
            ),
          ),
          GoRoute(
            path: '/about',
            name: NavigationSection.about.name,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AboutScreen(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      return null;
    },
  );
});
